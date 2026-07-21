import Foundation
import Combine

final class DataStore: ObservableObject {
    @Published var groups: [TokenGroup] = []
    @Published var allTokens: [TokenItem] = []

    private var fileURL: URL!
    private var cancellables = Set<AnyCancellable>()
    private var saveWorkItem: DispatchWorkItem?

    init() {
        // iCloud Drive storage
        let icloud = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .deletingLastPathComponent()
            .appendingPathComponent("Mobile Documents/com~apple~CloudDocs/TokenVault")
        try? FileManager.default.createDirectory(at: icloud, withIntermediateDirectories: true)
        fileURL = icloud.appendingPathComponent("tokens.json")

        // Fallback: local storage if iCloud unavailable
        if !FileManager.default.isWritableFile(atPath: icloud.path) {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let folder = appSupport.appendingPathComponent("TokenVault")
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            fileURL = folder.appendingPathComponent("data.json")
        }

        load()
        observeChanges()
    }

    // MARK: - Persistence

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let persisted = try JSONDecoder().decode(PersistedData.self, from: data)
            self.groups = persisted.groups
            self.allTokens = persisted.tokens
        } catch {
            print("Load error: \(error)")
        }
    }

    func save() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let persisted = PersistedData(groups: self.groups, tokens: self.allTokens)
            if let data = try? JSONEncoder().encode(persisted) {
                try? data.write(to: self.fileURL, options: .atomic)
            }
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func observeChanges() {
        func observeToken(_ token: TokenItem) {
            token.objectWillChange.sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)
        }
        func observeGroup(_ group: TokenGroup) {
            group.objectWillChange.sink { [weak self] _ in self?.scheduleSave() }
                .store(in: &cancellables)
        }
        for token in allTokens { observeToken(token) }
        for group in groups {
            observeGroup(group)
            for token in group.tokens { observeToken(token) }
        }
    }

    private func scheduleSave() {
        objectWillChange.send()
        save()
    }

    // MARK: - CRUD

    func addToken(_ token: TokenItem, to group: TokenGroup?) {
        if let group = group { group.tokens.append(token) }
        allTokens.append(token)
        save()
    }

    func deleteToken(_ token: TokenItem) {
        allTokens.removeAll { $0.id == token.id }
        for group in groups { group.tokens.removeAll { $0.id == token.id } }
        save()
    }

    func toggleFavorite(_ token: TokenItem) { token.isFavorite.toggle() }

    func addGroup(_ name: String, icon: String = "folder") {
        groups.append(TokenGroup(name: name, icon: icon, sortOrder: groups.count))
        save()
    }

    func deleteGroup(_ group: TokenGroup) {
        groups.removeAll { $0.id == group.id }
        save()
    }

    func tokens(for group: TokenGroup?) -> [TokenItem] {
        if let group = group { return group.tokens }
        return allTokens.sorted { $0.createdAt > $1.createdAt }
    }

    func search(_ query: String, in group: TokenGroup? = nil) -> [TokenItem] {
        let source = tokens(for: group)
        guard !query.isEmpty else { return source }
        return source.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.note.localizedCaseInsensitiveContains(query)
        }
    }

    private struct PersistedData: Codable {
        var groups: [TokenGroup]
        var tokens: [TokenItem]
    }
}
