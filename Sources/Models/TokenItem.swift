import Foundation
import SwiftUI
import CryptoKit

// MARK: - Token Environment

enum TokenEnvironment: String, Codable, CaseIterable {
    case development = "開發"
    case staging = "預發"
    case production = "正式"

    var color: (bg: String, fg: String) {
        switch self {
        case .development: return ("#3B82F6", "#DBEAFE")   // blue
        case .staging: return ("#F59E0B", "#FEF3C7")       // amber
        case .production: return ("#EF4444", "#FEE2E2")     // red
        }
    }
    var icon: String {
        switch self {
        case .development: return "hammer.fill"
        case .staging: return "testtube.2"
        case .production: return "shield.checkered"
        }
    }
}

// MARK: - Token Type

enum TokenType: String, Codable, CaseIterable {
    case github, gitlab, aws, openai, cloudflare, slack, stripe, tailscale, other

    var label: String {
        switch self {
        case .github: return "GitHub"
        case .gitlab: return "GitLab"
        case .aws: return "AWS"
        case .openai: return "OpenAI"
        case .cloudflare: return "Cloudflare"
        case .slack: return "Slack"
        case .stripe: return "Stripe"
        case .tailscale: return "Tailscale"
        case .other: return "其他"
        }
    }
    var icon: String {
        switch self {
        case .github: return "cat.fill"
        case .gitlab: return "fox"
        case .aws: return "cloud.fill"
        case .openai: return "brain.fill"
        case .cloudflare: return "globe"
        case .slack: return "tag.fill"
        case .stripe: return "creditcard.fill"
        case .tailscale: return "point.3.connected.trianglepath.dotted"
        case .other: return "key.fill"
        }
    }
    var color: String {
        switch self {
        case .github: return "#8B5CF6"
        case .gitlab: return "#FC6D26"
        case .aws: return "#FF9900"
        case .openai: return "#10A37F"
        case .cloudflare: return "#F38020"
        case .slack: return "#7C3AED"
        case .stripe: return "#635BFF"
        case .tailscale: return "#6B7280"
        case .other: return "#9CA3AF"
        }
    }

    /// Refined display color for glass UI — slightly desaturated for modern aesthetic.
    var glassColor: String {
        switch self {
        case .github: return "#7C5CBF"
        case .gitlab: return "#E05D2E"
        case .aws: return "#E68A00"
        case .openai: return "#0E9270"
        case .cloudflare: return "#E07520"
        case .slack: return "#6E34B8"
        case .stripe: return "#5850D8"
        case .tailscale: return "#6B7280"
        case .other: return "#9CA3AF"
        }
    }
    /// Service dashboard URL for this token type.
    var serviceURL: URL? {
        switch self {
        case .github: return URL(string: "https://github.com/settings/tokens")
        case .gitlab: return URL(string: "https://gitlab.com/-/user_settings/personal_access_tokens")
        case .aws: return URL(string: "https://console.aws.amazon.com/iam/home#/security_credentials")
        case .openai: return URL(string: "https://platform.openai.com/api-keys")
        case .cloudflare: return URL(string: "https://dash.cloudflare.com/profile/api-tokens")
        case .slack: return URL(string: "https://api.slack.com/apps")
        case .stripe: return URL(string: "https://dashboard.stripe.com/apikeys")
        case .tailscale: return URL(string: "https://login.tailscale.com/admin/settings/keys")
        case .other: return nil
        }
    }

    /// Auto-detect from token prefix / name
    static func detect(from name: String, value: String) -> TokenType {
        let q = "\(name) \(value.prefix(12))".lowercased()
        if q.contains("ghp_") || q.contains("github") { return .github }
        if q.contains("glpat-") || q.contains("gitlab") { return .gitlab }
        if q.contains("akia") || q.contains("aws") { return .aws }
        if q.contains("sk-") || q.contains("openai") { return .openai }
        if q.contains("cloudflare") || q.contains("cf_") { return .cloudflare }
        if q.contains("xoxb-") || q.contains("slack") { return .slack }
        if q.contains("sk_live") || q.contains("sk_test") || q.contains("stripe") { return .stripe }
        if q.contains("tskey-") || q.contains("tailscale") { return .tailscale }
        return .other
    }
}

// MARK: - Group

final class TokenGroup: ObservableObject, Identifiable, Codable, Hashable {
    let id: UUID
    @Published var name: String
    @Published var icon: String
    @Published var sortOrder: Int
    @Published var tokens: [TokenItem]

    enum CodingKeys: String, CodingKey { case id, name, icon, sortOrder, tokens }

    init(name: String, icon: String = "folder", sortOrder: Int = 0, tokens: [TokenItem] = []) {
        self.id = UUID(); self.name = name; self.icon = icon; self.sortOrder = sortOrder; self.tokens = tokens
    }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id); name = try c.decode(String.self, forKey: .name)
        icon = try c.decode(String.self, forKey: .icon); sortOrder = try c.decode(Int.self, forKey: .sortOrder)
        tokens = try c.decode([TokenItem].self, forKey: .tokens)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name)
        try c.encode(icon, forKey: .icon); try c.encode(sortOrder, forKey: .sortOrder)
        try c.encode(tokens, forKey: .tokens)
    }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: TokenGroup, rhs: TokenGroup) -> Bool { lhs.id == rhs.id }
}

// MARK: - Token Item  (Personal Secret Vault)

final class TokenItem: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    @Published var name: String
    var encryptedValue: String
    @Published var note: String
    @Published var environment: TokenEnvironment
    @Published var tokenType: TokenType
    @Published var provider: SecretProvider
    @Published var category: SecretCategory
    @Published var secretType: SecretType
    @Published var tags: [String]
    @Published var expiresAt: Date?
    @Published var createdAt: Date
    @Published var lastUsedAt: Date?
    @Published var deletedAt: Date?
    @Published var copyCount: Int
    @Published var isFavorite: Bool
    @Published var groupID: UUID?
    @Published var rotatedAt: Date?
    @Published var rotationDueAt: Date?
    @Published var customFields: [String: String]

    enum CodingKeys: String, CodingKey {
        case id, name, encryptedValue, note, environment, tokenType
        case provider, category, secretType, tags, expiresAt, createdAt
        case lastUsedAt, deletedAt, copyCount, isFavorite, groupID
        case rotatedAt, rotationDueAt, customFields
    }

    init(name: String, plainValue: String, note: String = "",
         environment: TokenEnvironment = .production, tokenType: TokenType? = nil,
         provider: SecretProvider? = nil, category: SecretCategory? = nil,
         secretType: SecretType = .apiKey, tags: [String] = [],
         expiresAt: Date? = nil, groupID: UUID? = nil,
         customFields: [String: String] = [:]) {
        let detectedType = tokenType ?? TokenType.detect(from: name, value: plainValue)
        let detectedProvider = provider ?? SecretProvider.detect(from: name, value: plainValue)
        self.id = UUID(); self.name = name; self.note = note
        self.environment = environment; self.expiresAt = expiresAt; self.createdAt = Date()
        self.lastUsedAt = nil; self.deletedAt = nil
        self.copyCount = 0; self.isFavorite = false; self.groupID = groupID
        self.secretType = secretType
        self.tags = tags
        self.customFields = customFields
        self.rotatedAt = nil; self.rotationDueAt = nil
        self.tokenType = detectedType
        self.provider = detectedProvider
        self.category = category ?? detectedProvider.category
        self.encryptedValue = (try? EncryptionService.encrypt(plainValue)) ?? plainValue
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        encryptedValue = try c.decode(String.self, forKey: .encryptedValue)
        note = try c.decode(String.self, forKey: .note)
        environment = (try? c.decode(TokenEnvironment.self, forKey: .environment)) ?? .production
        tokenType = (try? c.decode(TokenType.self, forKey: .tokenType)) ?? .other
        provider = (try? c.decode(SecretProvider.self, forKey: .provider)) ?? .custom
        category = (try? c.decode(SecretCategory.self, forKey: .category)) ?? .other
        secretType = (try? c.decode(SecretType.self, forKey: .secretType)) ?? .apiKey
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        expiresAt = try c.decodeIfPresent(Date.self, forKey: .expiresAt)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        lastUsedAt = try c.decodeIfPresent(Date.self, forKey: .lastUsedAt)
        deletedAt = try c.decodeIfPresent(Date.self, forKey: .deletedAt)
        copyCount = try c.decode(Int.self, forKey: .copyCount)
        isFavorite = try c.decode(Bool.self, forKey: .isFavorite)
        groupID = try c.decodeIfPresent(UUID.self, forKey: .groupID)
        rotatedAt = try c.decodeIfPresent(Date.self, forKey: .rotatedAt)
        rotationDueAt = try c.decodeIfPresent(Date.self, forKey: .rotationDueAt)
        customFields = (try? c.decode([String: String].self, forKey: .customFields)) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(name, forKey: .name)
        try c.encode(encryptedValue, forKey: .encryptedValue); try c.encode(note, forKey: .note)
        try c.encode(environment, forKey: .environment); try c.encode(tokenType, forKey: .tokenType)
        try c.encode(provider, forKey: .provider); try c.encode(category, forKey: .category)
        try c.encode(secretType, forKey: .secretType); try c.encode(tags, forKey: .tags)
        try c.encodeIfPresent(expiresAt, forKey: .expiresAt); try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(lastUsedAt, forKey: .lastUsedAt); try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try c.encode(copyCount, forKey: .copyCount); try c.encode(isFavorite, forKey: .isFavorite)
        try c.encodeIfPresent(groupID, forKey: .groupID)
        try c.encodeIfPresent(rotatedAt, forKey: .rotatedAt); try c.encodeIfPresent(rotationDueAt, forKey: .rotationDueAt)
        try c.encode(customFields, forKey: .customFields)
    }

    static func == (lhs: TokenItem, rhs: TokenItem) -> Bool { lhs.id == rhs.id }

    func decryptedValue() -> String { (try? EncryptionService.decrypt(encryptedValue)) ?? encryptedValue }
    var maskedValue: String {
        let v = encryptedValue
        guard v.count > 8 else { return String(repeating: "•", count: 8) }
        return "\(v.prefix(4))\(String(repeating: "•", count: 8))\(v.suffix(4))"
    }
    var isDeleted: Bool { deletedAt != nil }
    var isExpired: Bool { expiresAt.map { $0 < Date() } ?? false }
    var expiresSoon: Bool {
        guard let e = expiresAt else { return false }
        return e < Calendar.current.date(byAdding: .day, value: 7, to: Date())! && !isExpired
    }
    var needsRotation: Bool {
        guard let due = rotationDueAt else { return false }
        return due < Date()
    }
    var envColor: Color {
        switch environment {
        case .development: return Color(red: 0.23, green: 0.51, blue: 0.96)
        case .staging: return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .production: return Color(red: 0.94, green: 0.27, blue: 0.27)
        }
    }

    /// Duplicate detection: check if plain value matches another token
    func hasDuplicate(in tokens: [TokenItem]) -> Bool {
        let myVal = decryptedValue()
        return tokens.contains { $0.id != self.id && $0.decryptedValue() == myVal }
    }
}
