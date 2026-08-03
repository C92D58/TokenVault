import Foundation

// MARK: - Health Check Service

/// Validates API tokens against their providers to detect expired/invalid credentials.
final class HealthCheckService: ObservableObject {
    static let shared = HealthCheckService()

    enum Status: String {
        case valid = "valid"
        case invalid = "invalid"
        case expired = "expired"
        case unknown = "unknown"
        case rateLimited = "rate_limited"

        var icon: String {
            switch self {
            case .valid: return "checkmark.circle.fill"
            case .invalid: return "xmark.circle.fill"
            case .expired: return "clock.badge.xmark"
            case .unknown: return "questionmark.circle"
            case .rateLimited: return "exclamationmark.triangle.fill"
            }
        }

        var color: String {
            switch self {
            case .valid: return "#22C55E"
            case .invalid: return "#EF4444"
            case .expired: return "#F59E0B"
            case .unknown: return "#9CA3AF"
            case .rateLimited: return "#F59E0B"
            }
        }
    }

    struct HealthResult: Identifiable {
        let id: UUID
        let secretName: String
        let provider: SecretProvider
        let status: Status
        let message: String
        let scopes: [String]
        let timestamp: Date
    }

    @Published var lastResults: [HealthResult] = []
    @Published var isChecking = false

    /// Check a single secret against its provider.
    func check(_ token: TokenItem) async -> HealthResult {
        switch token.provider {
        case .github:
            return await checkGitHub(token)
        case .openai:
            return await checkOpenAI(token)
        case .cloudflare:
            return await checkCloudflare(token)
        default:
            return HealthResult(
                id: token.id, secretName: token.name, provider: token.provider,
                status: .unknown, message: "此服務尚未支援自動檢測",
                scopes: [], timestamp: Date()
            )
        }
    }

    /// Check all non-deleted tokens.
    func checkAll(_ tokens: [TokenItem]) async {
        await MainActor.run { isChecking = true }
        var results: [HealthResult] = []
        for token in tokens where !token.isDeleted {
            results.append(await check(token))
        }
        let finalResults = results
        await MainActor.run {
            lastResults = finalResults
            isChecking = false
        }
    }

    /// Duplicate detection across all tokens.
    static func findDuplicates(in tokens: [TokenItem]) -> [(TokenItem, TokenItem)] {
        var pairs: [(TokenItem, TokenItem)] = []
        let active = tokens.filter { !$0.isDeleted }
        for i in 0..<active.count {
            for j in (i+1)..<active.count {
                if active[i].decryptedValue() == active[j].decryptedValue() {
                    pairs.append((active[i], active[j]))
                }
            }
        }
        return pairs
    }

    // MARK: - Provider-specific checks

    private func checkGitHub(_ token: TokenItem) async -> HealthResult {
        guard let url = URL(string: "https://api.github.com/user") else {
            return HealthResult(id: token.id, secretName: token.name, provider: .github,
                                status: .unknown, message: "無法建立請求", scopes: [], timestamp: Date())
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token.decryptedValue())", forHTTPHeaderField: "Authorization")
        req.setValue("TokenVault-HealthCheck/1.0", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 10

        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let httpResp = resp as? HTTPURLResponse {
                if httpResp.statusCode == 200 {
                    let scopes = httpResp.allHeaderFields["X-OAuth-Scopes"] as? String
                    return HealthResult(id: token.id, secretName: token.name, provider: .github,
                                        status: .valid, message: "有效",
                                        scopes: scopes?.components(separatedBy: ", ") ?? [],
                                        timestamp: Date())
                } else if httpResp.statusCode == 401 {
                    return HealthResult(id: token.id, secretName: token.name, provider: .github,
                                        status: .invalid, message: "認證失敗 — Token 無效或已撤銷",
                                        scopes: [], timestamp: Date())
                } else if httpResp.statusCode == 403 {
                    return HealthResult(id: token.id, secretName: token.name, provider: .github,
                                        status: .rateLimited, message: "請求過於頻繁",
                                        scopes: [], timestamp: Date())
                }
            }
        } catch {
            return HealthResult(id: token.id, secretName: token.name, provider: .github,
                                status: .unknown, message: "網路錯誤: \(error.localizedDescription)",
                                scopes: [], timestamp: Date())
        }
        return HealthResult(id: token.id, secretName: token.name, provider: .github,
                            status: .unknown, message: "未知錯誤", scopes: [], timestamp: Date())
    }

    private func checkOpenAI(_ token: TokenItem) async -> HealthResult {
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            return HealthResult(id: token.id, secretName: token.name, provider: .openai,
                                status: .unknown, message: "無法建立請求", scopes: [], timestamp: Date())
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token.decryptedValue())", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 10

        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let httpResp = resp as? HTTPURLResponse, httpResp.statusCode == 200 {
                return HealthResult(id: token.id, secretName: token.name, provider: .openai,
                                    status: .valid, message: "有效", scopes: [], timestamp: Date())
            } else {
                return HealthResult(id: token.id, secretName: token.name, provider: .openai,
                                    status: .invalid, message: "API Key 無效", scopes: [], timestamp: Date())
            }
        } catch {
            return HealthResult(id: token.id, secretName: token.name, provider: .openai,
                                status: .unknown, message: "網路錯誤", scopes: [], timestamp: Date())
        }
    }

    private func checkCloudflare(_ token: TokenItem) async -> HealthResult {
        guard let url = URL(string: "https://api.cloudflare.com/client/v4/user/tokens/verify") else {
            return HealthResult(id: token.id, secretName: token.name, provider: .cloudflare,
                                status: .unknown, message: "無法建立請求", scopes: [], timestamp: Date())
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token.decryptedValue())", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["success"] as? Bool == true {
                return HealthResult(id: token.id, secretName: token.name, provider: .cloudflare,
                                    status: .valid, message: "有效", scopes: [], timestamp: Date())
            } else {
                return HealthResult(id: token.id, secretName: token.name, provider: .cloudflare,
                                    status: .invalid, message: "API Token 無效", scopes: [], timestamp: Date())
            }
        } catch {
            return HealthResult(id: token.id, secretName: token.name, provider: .cloudflare,
                                status: .unknown, message: "網路錯誤", scopes: [], timestamp: Date())
        }
    }
}
