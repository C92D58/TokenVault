import Foundation
import Combine

/// Central data store replacing SwiftData
final class DataStore: ObservableObject {
    @Published var groups: [TokenGroup] = []
    @Published var allTokens: [TokenItem] = []

    private let fileURL: URL
    private var cancellables = Set<AnyCancellable>()
    private var saveWorkItem: DispatchWorkItem?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("TokenVault")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("data.json")
        load()
        observeChanges()
    }

    // MARK: - Persistence

    private struct PersistedData: Codable {
        var groups: [TokenGroup]
        var orphanTokens: [TokenItem]
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return
        }
        do {
            let persisted = try JSONDecoder().decode(PersistedData.self, from: data)
            self.groups = persisted.groups
            self.allTokens = persisted.orphanTokens
            // Collect group tokens
            for group in groups {
                allTokens.append(contentsOf: group.tokens)
            }
        } catch {
            print("Load error: \(error)")
        }
    }

    func save() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let orphanTokens = self.allTokens.filter { token in
                !self.groups.contains { $0.tokens.contains { $0.id == token.id } }
            }
            let persisted = PersistedData(groups: self.groups, orphanTokens: orphanTokens)
            if let data = try? JSONEncoder().encode(persisted) {
                try? data.write(to: self.fileURL, options: .atomic)
            }
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    private func observeChanges() {
        // Observe all tokens and groups for changes
        func observeToken(_ token: TokenItem) {
            token.objectWillChange.sink { [weak self] _ in
                self?.scheduleSave()
            }.store(in: &cancellables)
        }
        func observeGroup(_ group: TokenGroup) {
            group.objectWillChange.sink { [weak self] _ in
                self?.scheduleSave()
            }.store(in: &cancellables)
        }

        // Initial observation
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

    // MARK: - Token CRUD

    func addToken(_ token: TokenItem, to group: TokenGroup?) {
        if let group = group {
            group.tokens.append(token)
        }
        allTokens.append(token)
        save()
    }

    func deleteToken(_ token: TokenItem) {
        allTokens.removeAll { $0.id == token.id }
        for group in groups {
            group.tokens.removeAll { $0.id == token.id }
        }
        save()
    }

    func toggleFavorite(_ token: TokenItem) {
        token.isFavorite.toggle()
    }

    // MARK: - Group CRUD

    func addGroup(_ name: String, icon: String = "key.fill") {
        let group = TokenGroup(name: name, icon: icon, sortOrder: groups.count)
        groups.append(group)
        save()
    }

    func deleteGroup(_ group: TokenGroup) {
        // Move tokens to ungrouped
        groups.removeAll { $0.id == group.id }
        save()
    }

    // MARK: - Queries

    func tokens(for group: TokenGroup?) -> [TokenItem] {
        if let group = group {
            return group.tokens
        }
        return allTokens.sorted { $0.createdAt > $1.createdAt }
    }

    func searchTokens(_ query: String, in group: TokenGroup?) -> [TokenItem] {
        let source = tokens(for: group)
        guard !query.isEmpty else { return source }
        return source.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.note.localizedCaseInsensitiveContains(query)
        }
    }
}
