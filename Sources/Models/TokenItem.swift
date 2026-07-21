import Foundation

final class TokenGroup: ObservableObject, Identifiable, Codable, Hashable {
    let id: UUID
    @Published var name: String
    @Published var sortOrder: Int
    @Published var tokens: [TokenItem]

    enum CodingKeys: String, CodingKey { case id, name, sortOrder, tokens }

    init(name: String, sortOrder: Int = 0, tokens: [TokenItem] = []) {
        self.id = UUID(); self.name = name; self.sortOrder = sortOrder; self.tokens = tokens
    }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        sortOrder = try c.decode(Int.self, forKey: .sortOrder)
        tokens = try c.decode([TokenItem].self, forKey: .tokens)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name)
        try c.encode(sortOrder, forKey: .sortOrder); try c.encode(tokens, forKey: .tokens)
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: TokenGroup, rhs: TokenGroup) -> Bool { lhs.id == rhs.id }
}

final class TokenItem: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    @Published var name: String
    /// AES-256-GCM encrypted value (base64). Never stored as plaintext on disk/cloud.
    var encryptedValue: String
    @Published var note: String
    @Published var expiresAt: Date?
    @Published var createdAt: Date
    @Published var copyCount: Int
    @Published var isFavorite: Bool
    @Published var groupID: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, encryptedValue, note, expiresAt, createdAt, copyCount, isFavorite, groupID
    }

    init(name: String, plainValue: String, note: String = "", expiresAt: Date? = nil, groupID: UUID? = nil) {
        self.id = UUID(); self.name = name; self.note = note
        self.expiresAt = expiresAt; self.createdAt = Date(); self.copyCount = 0
        self.isFavorite = false; self.groupID = groupID
        // Encrypt on creation
        self.encryptedValue = (try? EncryptionService.encrypt(plainValue)) ?? plainValue
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        encryptedValue = try c.decode(String.self, forKey: .encryptedValue)
        note = try c.decode(String.self, forKey: .note)
        expiresAt = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        copyCount = try c.decode(Int.self, forKey: .copyCount)
        isFavorite = try c.decode(Bool.self, forKey: .isFavorite)
        groupID = try c.decodeIfPresent(UUID.self, forKey: .groupID)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name)
        try c.encode(encryptedValue, forKey: .encryptedValue); try c.encode(note, forKey: .note)
        try c.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try c.encode(createdAt, forKey: .createdAt); try c.encode(copyCount, forKey: .copyCount)
        try c.encode(isFavorite, forKey: .isFavorite); try c.encodeIfPresent(groupID, forKey: .groupID)
    }

    static func == (lhs: TokenItem, rhs: TokenItem) -> Bool { lhs.id == rhs.id }

    // MARK: - Decrypted access

    /// Decrypt on-the-fly. Cache in memory for the session?
    func decryptedValue() -> String {
        (try? EncryptionService.decrypt(encryptedValue)) ?? encryptedValue
    }

    var maskedValue: String {
        let v = encryptedValue
        guard v.count > 8 else { return String(repeating: "•", count: 8) }
        return "\(v.prefix(4))\(String(repeating: "•", count: 8))\(v.suffix(4))"
    }
    var isExpired: Bool { expiresAt.map { $0 < Date() } ?? false }
    var expiresSoon: Bool {
        guard let e = expiresAt else { return false }
        return e < Calendar.current.date(byAdding: .day, value: 7, to: Date())! && !isExpired
    }
}
