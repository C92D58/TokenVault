import Foundation

// MARK: - Security Audit Log

/// Local-only audit trail for all secret access operations.
struct SecurityLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let action: Action
    let secretID: UUID
    let secretName: String
    let provider: String

    enum Action: String, Codable, CaseIterable {
        case copied = "複製"
        case viewed = "檢視"
        case exported = "匯出"
        case imported = "匯入"
        case created = "建立"
        case edited = "編輯"
        case deleted = "刪除"
        case restored = "恢復"
        case locked = "鎖定"
        case unlocked = "解鎖"
        case rotation = "輪換"

        var icon: String {
            switch self {
            case .copied: return "doc.on.doc"
            case .viewed: return "eye"
            case .exported: return "square.and.arrow.up"
            case .imported: return "square.and.arrow.down"
            case .created: return "plus.circle"
            case .edited: return "pencil"
            case .deleted: return "trash"
            case .restored: return "arrow.uturn.backward"
            case .locked: return "lock"
            case .unlocked: return "lock.open"
            case .rotation: return "arrow.triangle.2.circlepath"
            }
        }
    }

    var relativeTime: String {
        let diff = Int(Date().timeIntervalSince(timestamp))
        switch diff {
        case ..<60: return "剛剛"
        case ..<3600: return "\(diff / 60) 分鐘前"
        case ..<86400: return "\(diff / 3600) 小時前"
        default: return timestamp.formatted(date: .abbreviated, time: .shortened)
        }
    }
}

// MARK: - Security Log Store

final class SecurityLogService: ObservableObject {
    static let shared = SecurityLogService()

    @Published var entries: [SecurityLogEntry] = []
    private let maxEntries = 500

    private var fileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("TokenVault/security_log.json")
    }

    init() {
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        load()
    }

    func log(_ action: SecurityLogEntry.Action, secretID: UUID, name: String, provider: String) {
        let entry = SecurityLogEntry(
            id: UUID(), timestamp: Date(), action: action,
            secretID: secretID, secretName: name, provider: provider
        )
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        save()
    }

    func entriesForToday() -> [SecurityLogEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDateInToday($0.timestamp) }
    }

    func entries(for secretID: UUID) -> [SecurityLogEntry] {
        entries.filter { $0.secretID == secretID }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([SecurityLogEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
