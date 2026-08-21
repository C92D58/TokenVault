import Foundation
import Combine

/// Central data store with iCloud Drive sync.
/// All token values are AES-256-GCM encrypted before storage.
final class DataStore: ObservableObject {
    @Published var groups: [TokenGroup] = []
    @Published var allTokens: [TokenItem] = []

    /// Active (non-deleted) tokens only.
    var activeTokens: [TokenItem] { allTokens.filter { !$0.isDeleted } }
    /// Soft-deleted tokens (trash).
    var trashedTokens: [TokenItem] { allTokens.filter { $0.isDeleted } }

    let undoManager = UndoManager()
    private var fileURL: URL!
    private var cancellables = Set<AnyCancellable>()
    private var saveWorkItem: DispatchWorkItem?

    init() {
        let icloud = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/TokenVault")
        try? FileManager.default.createDirectory(at: icloud, withIntermediateDirectories: true)

        fileURL = FileManager.default.isWritableFile(atPath: icloud.path)
            ? icloud.appendingPathComponent("tokens.json")
            : FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("TokenVault/tokens.json")

        // Ensure directory exists for fallback
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)

        load()
        rebuildSubscriptions()
    }

    // MARK: - Persistence

    struct BackupSnapshot: Codable {
        var groups: [TokenGroup]; var tokens: [TokenItem]
    }

    private struct Snapshot: Codable {
        var groups: [TokenGroup]; var tokens: [TokenItem]
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        groups = snap.groups; allTokens = snap.tokens
        // Auto-purge tokens deleted > 30 days ago
        purgeExpiredTrash()
    }

    func save() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, let d = try? JSONEncoder().encode(Snapshot(groups: self.groups, tokens: self.allTokens)) else { return }
            try? d.write(to: self.fileURL, options: .atomic)
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    /// Notify SwiftUI and schedule a debounced save.
    private func notify() {
        objectWillChange.send()
        save()
    }

    // MARK: - Subscriptions (memory-leak-safe)

    /// Rebuild all Combine subscriptions. Called when tokens/groups change structurally.
    private func rebuildSubscriptions() {
        cancellables.removeAll()
        for t in allTokens {
            t.objectWillChange.sink { [weak self] _ in self?.notify() }.store(in: &cancellables)
        }
        for g in groups {
            g.objectWillChange.sink { [weak self] _ in self?.notify() }.store(in: &cancellables)
            for t in g.tokens {
                t.objectWillChange.sink { [weak self] _ in self?.notify() }.store(in: &cancellables)
            }
        }
    }

    // MARK: - CRUD

    func addToken(_ t: TokenItem, to group: TokenGroup?) {
        group?.tokens.append(t); allTokens.append(t)
        rebuildSubscriptions()
        notify()
    }
    func deleteToken(_ t: TokenItem) {
        allTokens.removeAll { $0.id == t.id }
        for g in groups { g.tokens.removeAll { $0.id == t.id } }
        rebuildSubscriptions()
        notify()
    }
    func toggleFav(_ t: TokenItem) { t.isFavorite.toggle(); notify() }

    /// Soft-delete: move to trash (30-day recovery window). Supports undo.
    func softDeleteToken(_ t: TokenItem) {
        let tokenID = t.id
        let oldGroups: [(TokenGroup, Int)] = groups.compactMap { g in
            if let idx = g.tokens.firstIndex(where: { $0.id == tokenID }) { return (g, idx) }
            return nil
        }
        t.deletedAt = Date()
        for g in groups { g.tokens.removeAll { $0.id == tokenID } }
        SecurityLogService.shared.log(.deleted, tokenID: t.id, name: t.name, provider: t.provider.rawValue)
        undoManager.registerUndo(withTarget: self) { store in
            store.restoreToken(t)
            for (group, idx) in oldGroups {
                if idx <= group.tokens.count { group.tokens.insert(t, at: idx) }
            }
            ToastService.shared.show("已復原刪除「\(t.name)」", icon: "arrow.uturn.backward")
        }
        undoManager.setActionName("刪除「\(t.name)」")
        notify()
    }

    /// Restore a soft-deleted token. Supports undo.
    func restoreToken(_ t: TokenItem) {
        t.deletedAt = nil
        SecurityLogService.shared.log(.restored, tokenID: t.id, name: t.name, provider: t.provider.rawValue)
        undoManager.registerUndo(withTarget: self) { store in
            store.softDeleteToken(t)
            ToastService.shared.show("已復原", icon: "arrow.uturn.backward")
        }
        undoManager.setActionName("恢復「\(t.name)」")
        notify()
    }

    /// Permanently delete tokens that were soft-deleted > 30 days ago.
    func purgeExpiredTrash() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        allTokens.removeAll { ($0.deletedAt ?? .distantFuture) < cutoff }
        rebuildSubscriptions()
        notify()
    }

    func addGroup(_ name: String) {
        groups.append(TokenGroup(name: name, sortOrder: groups.count)); notify()
    }
    func deleteGroup(_ g: TokenGroup) {
        groups.removeAll { $0.id == g.id }; rebuildSubscriptions(); notify()
    }

    func tokens(for group: TokenGroup?) -> [TokenItem] {
        (group.map { $0.tokens } ?? activeTokens).sorted { $0.createdAt > $1.createdAt }
    }

    func search(_ q: String, in group: TokenGroup?) -> [TokenItem] {
        let src = tokens(for: group).filter { !$0.isDeleted }
        guard !q.isEmpty else { return src }
        let query = q.trimmingCharacters(in: .whitespaces)

        // Support advanced search syntax: tag:xxx, cat:xxx, provider:xxx, expired:true, fav:true
        var results = src
        var searchTerms = query

        // Extract special filters
        for word in query.components(separatedBy: .whitespaces) {
            if word.hasPrefix("tag:") {
                let tag = String(word.dropFirst(4)).lowercased()
                results = results.filter { $0.tags.contains { $0.lowercased() == tag } }
                searchTerms = searchTerms.replacingOccurrences(of: word, with: "")
            } else if word.hasPrefix("cat:") {
                let cat = String(word.dropFirst(4))
                results = results.filter { $0.category.rawValue.localizedCaseInsensitiveContains(cat) }
                searchTerms = searchTerms.replacingOccurrences(of: word, with: "")
            } else if word.hasPrefix("provider:") {
                let prov = String(word.dropFirst(9))
                results = results.filter { $0.provider.rawValue.localizedCaseInsensitiveContains(prov) }
                searchTerms = searchTerms.replacingOccurrences(of: word, with: "")
            } else if word == "expired:true" {
                results = results.filter(\.isExpired)
                searchTerms = searchTerms.replacingOccurrences(of: word, with: "")
            } else if word == "fav:true" || word == "favorite:true" {
                results = results.filter(\.isFavorite)
                searchTerms = searchTerms.replacingOccurrences(of: word, with: "")
            }
        }

        let finalQuery = searchTerms.trimmingCharacters(in: .whitespaces)
        guard !finalQuery.isEmpty else { return results }

        return results.filter {
            $0.name.localizedCaseInsensitiveContains(finalQuery)
            || $0.note.localizedCaseInsensitiveContains(finalQuery)
            || $0.environment.rawValue.localizedCaseInsensitiveContains(finalQuery)
            || $0.provider.rawValue.localizedCaseInsensitiveContains(finalQuery)
            || $0.category.rawValue.localizedCaseInsensitiveContains(finalQuery)
            || $0.tags.contains { $0.localizedCaseInsensitiveContains(finalQuery) }
            || (finalQuery.count >= 3 && $0.decryptedValue().localizedCaseInsensitiveContains(finalQuery))
        }
    }

    /// Find duplicate secrets
    func findDuplicates() -> [(TokenItem, TokenItem)] {
        HealthCheckService.findDuplicates(in: allTokens)
    }

    // MARK: - Security helpers

    /// All encrypted values — for verifying zero-knowledge claim.
    func verifyEncryption() -> Bool {
        allTokens.allSatisfy { (try? EncryptionService.decrypt($0.encryptedValue)) != nil }
    }

    /// Copy a token and update usage stats.
    func useToken(_ t: TokenItem) {
        t.lastUsedAt = Date()
        t.copyCount += 1
        SecurityLogService.shared.log(.copied, tokenID: t.id, name: t.name, provider: t.provider.rawValue)
        notify()
    }
}
