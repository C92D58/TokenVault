import SwiftUI

/// Dashboard bar showing token health overview at a glance.
struct DashboardBar: View {
    @ObservedObject var store: DataStore

    private var stats: (total: Int, expired: Int, expiringSoon: Int, mostUsed: TokenItem?) {
        let total = store.allTokens.count
        let expired = store.allTokens.filter(\.isExpired).count
        let soon = store.allTokens.filter(\.expiresSoon).count
        let mostUsed = store.allTokens.max(by: { $0.copyCount < $1.copyCount })
        return (total, expired, soon, mostUsed)
    }

    var body: some View {
        HStack(spacing: 0) {
            statCard(
                title: "總數", value: "\(stats.total)",
                icon: "key.horizontal.fill", color: .accentColor
            )
            Divider().frame(height: 36)

            statCard(
                title: "即將到期", value: "\(stats.expiringSoon)",
                icon: "clock.badge.exclamationmark", color: stats.expiringSoon > 0 ? .orange : .secondary
            )

            Divider().frame(height: 36)

            statCard(
                title: "已過期", value: "\(stats.expired)",
                icon: "xmark.shield.fill", color: stats.expired > 0 ? .red : .secondary
            )

            Divider().frame(height: 36)

            statCard(
                title: "最常用",
                value: stats.mostUsed?.name ?? "—",
                icon: "flame.fill",
                color: .orange,
                subtitle: stats.mostUsed.map { "\($0.copyCount) 次" }
            )
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.06), lineWidth: 1))
        .padding(.horizontal, 14).padding(.top, 8)
    }

    private func statCard(title: String, value: String, icon: String, color: Color, subtitle: String? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(color).frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(color)
                    .lineLimit(1).truncationMode(.tail)
                if let sub = subtitle {
                    Text(sub).font(.system(size: 9)).foregroundColor(.secondary)
                } else {
                    Text(title).font(.system(size: 9)).foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
}

// MARK: - Token Generator View

struct TokenGeneratorView: View {
    @State private var generatedToken = ""
    @State private var tokenLength = 32
    @State private var includeSpecial = true
    @State private var jwtInput = ""
    @State private var jwtOutput = ""
    @State private var copied = false

    var body: some View {
        TabView {
            generateTab.tabItem { Label("生成", systemImage: "wand.and.stars") }
            jwtTab.tabItem { Label("JWT", systemImage: "doc.text.magnifyingglass") }
        }
        .frame(width: 440, height: 300)
    }

    private var generateTab: some View {
        VStack(spacing: 16) {
            Text("安全 Token 產生器").font(.system(size: 14, weight: .bold))

            HStack {
                Text("長度:").font(.system(size: 12)).foregroundColor(.secondary)
                Picker("", selection: $tokenLength) {
                    Text("16").tag(16); Text("32").tag(32); Text("48").tag(48); Text("64").tag(64)
                }.pickerStyle(.segmented).frame(width: 200)
            }

            Toggle("包含特殊字元", isOn: $includeSpecial).font(.system(size: 12))

            Button("產生") { generateToken() }.buttonStyle(.borderedProminent).controlSize(.small)

            if !generatedToken.isEmpty {
                VStack(spacing: 8) {
                    Text(generatedToken)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 8) {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(generatedToken, forType: .string)
                            withAnimation(.spring(response: 0.3)) { copied = true }
                            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copied = false } }
                        } label: {
                            Label(copied ? "已複製" : "複製", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11)).padding(.horizontal, 12).padding(.vertical, 5)
                                .background(Capsule().fill(copied ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.1)))
                        }.buttonStyle(.plain)

                        Button("儲存為 Token") {
                            NotificationCenter.default.post(name: .showAddToken, object: nil)
                        }.buttonStyle(.bordered).controlSize(.small)
                    }
                }
            }
        }.padding()
    }

    private var jwtTab: some View {
        VStack(spacing: 12) {
            Text("JWT 解碼器").font(.system(size: 14, weight: .bold))

            TextEditor(text: $jwtInput)
                .font(.system(size: 10, design: .monospaced))
                .frame(height: 60)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1))
                .cornerRadius(8)

            Button("解碼") { decodeJWT() }.buttonStyle(.borderedProminent).controlSize(.small)

            if !jwtOutput.isEmpty {
                ScrollView {
                    Text(jwtOutput)
                        .font(.system(size: 10, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
                }
            }
        }.padding()
    }

    private func generateToken() {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" + (includeSpecial ? "!@#$%^&*()-_=+[]{}|;:,.<>?" : "")
        generatedToken = String((0..<tokenLength).map { _ in chars.randomElement()! })
    }

    private func decodeJWT() {
        let parts = jwtInput.components(separatedBy: ".")
        guard parts.count == 3 else { jwtOutput = "無效的 JWT 格式"; return }
        var output = ""
        for (i, part) in parts.enumerated() {
            let label = ["HEADER", "PAYLOAD", "SIGNATURE"][i]
            if i < 2, let decoded = decodeBase64URL(part) {
                if let obj = try? JSONSerialization.jsonObject(with: decoded),
                   let pretty = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted),
                   let str = String(data: pretty, encoding: .utf8) {
                    output += "=== \(label) ===\n\(str)\n\n"
                }
            } else {
                output += "=== \(label) ===\n\(part)\n\n"
            }
        }
        jwtOutput = output
    }

    private func decodeBase64URL(_ str: String) -> Data? {
        var base64 = str.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        return Data(base64Encoded: base64)
    }
}

// MARK: - Import/Export Helper

struct ImportExportHelper {
    /// Parse .env format: KEY=VALUE
    static func parseEnv(_ content: String) -> [(name: String, value: String, note: String)] {
        content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") && $0.contains("=") }
            .compactMap { line in
                let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { return nil }
                return (parts[0].trimmingCharacters(in: .whitespaces),
                        parts[1].trimmingCharacters(in: .whitespaces)
                            .replacingOccurrences(of: "\"", with: "")
                            .replacingOccurrences(of: "'", with: ""),
                        "從 .env 匯入")
            }
    }

    /// Parse CSV: name,value,note,environment
    static func parseCSV(_ content: String) -> [(name: String, value: String, note: String, env: TokenEnvironment)] {
        content.components(separatedBy: .newlines)
            .dropFirst() // Skip header
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .compactMap { line in
                let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                guard parts.count >= 2 else { return nil }
                let env = parts.count >= 4 ? TokenEnvironment(rawValue: parts[3]) ?? .production : .production
                return (parts[0], parts[1], parts.count >= 3 ? parts[2] : "", env)
            }
    }

    /// Export as .env
    static func exportEnv(_ tokens: [TokenItem]) -> String {
        tokens.map { "\($0.name.sanitizedForEnv)=\($0.decryptedValue())" }.joined(separator: "\n")
    }

    /// Export as CSV
    static func exportCSV(_ tokens: [TokenItem]) -> String {
        var csv = "名稱,值,備註,環境,類型,到期日\n"
        for t in tokens {
            csv += "\"\(t.name)\",\"\(t.decryptedValue())\",\"\(t.note)\",\(t.environment.rawValue),\(t.tokenType.label),\(t.expiresAt?.ISO8601Format() ?? "")\n"
        }
        return csv
    }
}

extension String {
    var sanitizedForEnv: String {
        replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .uppercased()
    }
}
