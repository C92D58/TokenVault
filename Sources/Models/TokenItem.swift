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
        case .github: return "#6E40C9"
        case .gitlab: return "#FC6D26"
        case .aws: return "#FF9900"
        case .openai: return "#10A37F"
        case .cloudflare: return "#F38020"
        case .slack: return "#4A154B"
        case .stripe: return "#635BFF"
        case .tailscale: return "#1A1A1A"
        case .other: return "#6B7280"
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

// MARK: - Token Item

final class TokenItem: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    @Published var name: String
    var encryptedValue: String
    @Published var note: String
    @Published var environment: TokenEnvironment
    @Published var tokenType: TokenType
    @Published var expiresAt: Date?
    @Published var createdAt: Date
    @Published var copyCount: Int
    @Published var isFavorite: Bool
    @Published var groupID: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, encryptedValue, note, environment, tokenType, expiresAt, createdAt, copyCount, isFavorite, groupID
    }

    init(name: String, plainValue: String, note: String = "", environment: TokenEnvironment = .production, tokenType: TokenType? = nil, expiresAt: Date? = nil, groupID: UUID? = nil) {
        self.id = UUID(); self.name = name; self.note = note
        self.environment = environment; self.expiresAt = expiresAt; self.createdAt = Date()
        self.copyCount = 0; self.isFavorite = false; self.groupID = groupID
        self.tokenType = tokenType ?? TokenType.detect(from: name, value: plainValue)
        self.encryptedValue = (try? EncryptionService.encrypt(plainValue)) ?? plainValue
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id); name = try c.decode(String.self, forKey: .name)
        encryptedValue = try c.decode(String.self, forKey: .encryptedValue)
        note = try c.decode(String.self, forKey: .note)
        environment = (try? c.decode(TokenEnvironment.self, forKey: .environment)) ?? .production
        tokenType = (try? c.decode(TokenType.self, forKey: .tokenType)) ?? .other
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
        try c.encode(environment, forKey: .environment); try c.encode(tokenType, forKey: .tokenType)
        try c.encodeIfPresent(expiresAt, forKey: .expiresAt); try c.encode(createdAt, forKey: .createdAt)
        try c.encode(copyCount, forKey: .copyCount); try c.encode(isFavorite, forKey: .isFavorite)
        try c.encodeIfPresent(groupID, forKey: .groupID)
    }

    static func == (lhs: TokenItem, rhs: TokenItem) -> Bool { lhs.id == rhs.id }

    func decryptedValue() -> String { (try? EncryptionService.decrypt(encryptedValue)) ?? encryptedValue }
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
    var envColor: Color {
        switch environment {
        case .development: return Color(red: 0.23, green: 0.51, blue: 0.96)
        case .staging: return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .production: return Color(red: 0.94, green: 0.27, blue: 0.27)
        }
    }
}
