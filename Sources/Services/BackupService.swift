import Foundation
import CryptoKit

// MARK: - Scheduled Backup Service

/// Automatic encrypted backup with versioning.
final class BackupService: ObservableObject {
    static let shared = BackupService()

    enum Schedule: String, CaseIterable {
        case hourly = "每小時"
        case daily = "每天"
        case weekly = "每週"
        case launch = "啟動時"
        case quit = "退出時"
        case never = "從不"
    }

    @Published var lastBackupAt: Date?
    @Published var backupCount: Int = 0
    @Published var schedule: Schedule = .daily

    private var backupDir: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("TokenVault/backups")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() { refreshStats() }

    func refreshStats() {
        let files = (try? FileManager.default.contentsOfDirectory(at: backupDir,
            includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        backupCount = files.filter { $0.pathExtension == "enc" }.count
        lastBackupAt = files.compactMap {
            try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        }.max()
    }

    /// Create an encrypted backup from the current store data.
    func backup(tokens: [TokenItem], groups: [TokenGroup]) -> URL? {
        let snap = DataStore.BackupSnapshot(groups: groups, tokens: tokens)
        guard let jsonData = try? JSONEncoder().encode(snap) else { return nil }

        // Encrypt the JSON data
        let key = SymmetricKey(size: .bits256)
        guard let sealed = try? AES.GCM.seal(jsonData, using: key),
              let combined = sealed.combined else { return nil }

        // Save the key securely (in Keychain)
        let keyTag = "org.wahsun.tokenvault.backupkey".data(using: .utf8)!
        try? KeychainService.write(tag: keyTag, data: key.withUnsafeBytes { Data($0) })

        // Write encrypted backup
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "tv-backup-\(formatter.string(from: Date())).enc"
        let url = backupDir.appendingPathComponent(filename)
        try? combined.write(to: url, options: .atomic)

        // Cleanup old backups (keep last 30)
        cleanupOldBackups(keep: 30)

        refreshStats()
        return url
    }

    /// Restore from an encrypted backup file.
    func restore(from url: URL) -> DataStore.BackupSnapshot? {
        guard let combined = try? Data(contentsOf: url) else { return nil }

        let keyTag = "org.wahsun.tokenvault.backupkey".data(using: .utf8)!
        guard let keyData = try? KeychainService.read(tag: keyTag),
              keyData.count == 32 else { return nil }

        let key = SymmetricKey(data: keyData)
        let sealedBox = try? AES.GCM.SealedBox(combined: combined)
        guard let box = sealedBox,
              let decrypted = try? AES.GCM.open(box, using: key) else { return nil }

        return try? JSONDecoder().decode(DataStore.BackupSnapshot.self, from: decrypted)
    }

    private func cleanupOldBackups(keep: Int) {
        let files = (try? FileManager.default.contentsOfDirectory(at: backupDir,
            includingPropertiesForKeys: [.creationDateKey])) ?? []
        let encFiles = files.filter { $0.pathExtension == "enc" }
            .sorted { a, b in
                let da = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return da > db
            }
        if encFiles.count > keep {
            for url in encFiles.dropFirst(keep) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    /// Export tokens as .env format.
    static func exportEnv(_ tokens: [TokenItem]) -> String {
        tokens.filter { !$0.isDeleted }.map { token in
            let envName = token.name.uppercased()
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "-", with: "_")
            let value = token.decryptedValue()
            return "\(envName)=\(value)  # \(token.provider.rawValue) - \(token.environment.rawValue)"
        }.joined(separator: "\n")
    }

    /// Import tokens from .env content.
    static func parseEnv(_ content: String) -> [(name: String, value: String, note: String)] {
        content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") && $0.contains("=") }
            .compactMap { line -> (String, String, String)? in
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }
                let name = parts[0].trimmingCharacters(in: .whitespaces)
                let rawValue = parts[1].trimmingCharacters(in: .whitespaces)
                // Strip inline comments
                let value = rawValue.components(separatedBy: "#").first?.trimmingCharacters(in: .whitespaces) ?? rawValue
                let note = rawValue.contains("#") ? "從 .env 導入" : ""
                return (name: name, value: value, note: note)
            }
    }
}
