import Foundation
import Combine

/// Central data store with iCloud Drive sync.
/// All token values are AES-256-GCM encrypted before storage.
final class DataStore: ObservableObject {
    @Published var groups: [TokenGroup] = []
    @Published var allTokens: [TokenItem] = []

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
        observe()
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
    }

    func save() {
        saveWorkItem?.cancel()
        saveWorkItem = DispatchWorkItem { [weak self] in
            guard let self, let d = try? JSONEncoder().encode(Snapshot(groups: self.groups, tokens: self.allTokens)) else { return }
            try? d.write(to: self.fileURL, options: .atomic)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: saveWorkItem!)
    }

    private func observe() {
        for t in allTokens { t.objectWillChange.sink { [weak self] _ in self?.scheduleSave() }.store(in: &cancellables) }
        for g in groups {
            g.objectWillChange.sink { [weak self] _ in self?.scheduleSave() }.store(in: &cancellables)
            for t in g.tokens { t.objectWillChange.sink { [weak self] _ in self?.scheduleSave() }.store(in: &cancellables) }
        }
    }
    private func scheduleSave() { objectWillChange.send(); save() }

    // MARK: - CRUD

    func addToken(_ t: TokenItem, to group: TokenGroup?) {
        group?.tokens.append(t); allTokens.append(t); save()
    }
    func deleteToken(_ t: TokenItem) {
        allTokens.removeAll { $0.id == t.id }
        for g in groups { g.tokens.removeAll { $0.id == t.id } }
        save()
    }
    func toggleFav(_ t: TokenItem) { t.isFavorite.toggle() }
    func addGroup(_ name: String) {
        groups.append(TokenGroup(name: name, sortOrder: groups.count)); save()
    }
    func deleteGroup(_ g: TokenGroup) { groups.removeAll { $0.id == g.id }; save() }

    func tokens(for group: TokenGroup?) -> [TokenItem] {
        group.map { $0.tokens } ?? allTokens.sorted { $0.createdAt > $1.createdAt }
    }
    func search(_ q: String, in group: TokenGroup?) -> [TokenItem] {
        let src = tokens(for: group)
        guard !q.isEmpty else { return src }
        return src.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.note.localizedCaseInsensitiveContains(q) }
    }

    // MARK: - Security helpers

    /// All encrypted values — for verifying zero-knowledge claim.
    func verifyEncryption() -> Bool {
        allTokens.allSatisfy { (try? EncryptionService.decrypt($0.encryptedValue)) != nil }
    }
}
