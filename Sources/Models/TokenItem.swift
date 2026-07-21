import Foundation

final class TokenGroup: ObservableObject, Identifiable, Codable, Hashable {
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: TokenGroup, rhs: TokenGroup) -> Bool { lhs.id == rhs.id }
    let id: UUID
    @Published var name: String
    @Published var icon: String
    @Published var sortOrder: Int
    @Published var tokens: [TokenItem]

    enum CodingKeys: String, CodingKey {
        case id, name, icon, sortOrder, tokens
    }

    init(name: String, icon: String = "key.fill", sortOrder: Int = 0, tokens: [TokenItem] = []) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.tokens = tokens
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decode(String.self, forKey: .icon)
        sortOrder = try c.decode(Int.self, forKey: .sortOrder)
        tokens = try c.decode([TokenItem].self, forKey: .tokens)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(icon, forKey: .icon)
        try c.encode(sortOrder, forKey: .sortOrder)
        try c.encode(tokens, forKey: .tokens)
    }
}

final class TokenItem: ObservableObject, Identifiable, Codable, Equatable {
    static func == (lhs: TokenItem, rhs: TokenItem) -> Bool { lhs.id == rhs.id }
    let id: UUID
    @Published var name: String
    @Published var value: String
    @Published var note: String
    @Published var expiresAt: Date?
    @Published var createdAt: Date
    @Published var copyCount: Int
    @Published var isFavorite: Bool
    @Published var groupID: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, value, note, expiresAt, createdAt, copyCount, isFavorite, groupID
    }

    init(name: String, value: String, note: String = "", expiresAt: Date? = nil, groupID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.value = value
        self.note = note
        self.expiresAt = expiresAt
        self.createdAt = Date()
        self.copyCount = 0
        self.isFavorite = false
        self.groupID = groupID
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        value = try c.decode(String.self, forKey: .value)
        note = try c.decode(String.self, forKey: .note)
        expiresAt = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        copyCount = try c.decode(Int.self, forKey: .copyCount)
        isFavorite = try c.decode(Bool.self, forKey: .isFavorite)
        groupID = try c.decodeIfPresent(UUID.self, forKey: .groupID)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(value, forKey: .value)
        try c.encode(note, forKey: .note)
        try c.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(copyCount, forKey: .copyCount)
        try c.encode(isFavorite, forKey: .isFavorite)
        try c.encodeIfPresent(groupID, forKey: .groupID)
    }

    var maskedValue: String {
        guard value.count > 8 else { return String(repeating: "•", count: min(value.count, 8)) }
        let prefix = String(value.prefix(4))
        let suffix = String(value.suffix(4))
        return "\(prefix)\(String(repeating: "•", count: 8))\(suffix)"
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    var expiresSoon: Bool {
        guard let expiresAt else { return false }
        let week = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return expiresAt < week && !isExpired
    }
}
