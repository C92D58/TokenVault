import Foundation
import Combine

final class DataStore: ObservableObject {
    @Published var groups: [TokenGroup] = []
    @Published var allTokens: [TokenItem] = []

    private var fileURL: URL!
    private var cancellables = Set<AnyCancellable>()
    private var saveWorkItem: DispatchWorkItem?

    init() {
        // iCloud Drive: ~/Library/Mobile Documents/com~apple~CloudDocs/TokenVault/
        let icloud = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/TokenVault")
        try? FileManager.default.createDirectory(at: icloud, withIntermediateDirectories: true)

        if FileManager.default.isWritableFile(atPath: icloud.path) {
            fileURL = icloud.appendingPathComponent("tokens.json")
        } else {
            let asDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("TokenVault")
            try? FileManager.default.createDirectory(at: asDir, withIntermediateDirectories: true)
            fileURL = asDir.appendingPathComponent("tokens.json")
        }

        load()
        observe()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var groups: [TokenGroup]
        var tokens: [TokenItem]
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
        for t in allTokens {
            t.objectWillChange.sink { [weak self] _ in self?.scheduleSave() }.store(in: &cancellables)
        }
        for g in groups {
            g.objectWillChange.sink { [weak self] _ in self?.scheduleSave() }.store(in: &cancellables)
            for t in g.tokens {
                t.objectWillChange.sink { [weak self] _ in self?.scheduleSave() }.store(in: &cancellables)
            }
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
}
