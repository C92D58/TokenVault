import SwiftUI

// MARK: - Dashboard Bar

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
            statCard(title: "總數", value: "\(stats.total)", icon: "key.horizontal.fill", color: .accentColor)
            Divider().frame(height: 36)
            statCard(title: "即將到期", value: "\(stats.expiringSoon)", icon: "clock.badge.exclamationmark", color: stats.expiringSoon > 0 ? .orange : .secondary)
            Divider().frame(height: 36)
            statCard(title: "已過期", value: "\(stats.expired)", icon: "xmark.shield.fill", color: stats.expired > 0 ? .red : .secondary)
            Divider().frame(height: 36)
            statCard(title: "最常用", value: stats.mostUsed?.name ?? "—", icon: "flame.fill", color: .orange, subtitle: stats.mostUsed.map { "\($0.copyCount) 次" })
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
                Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(color).lineLimit(1).truncationMode(.tail)
                if let sub = subtitle { Text(sub).font(.system(size: 9)).foregroundColor(.secondary) }
                else { Text(title).font(.system(size: 9)).foregroundColor(.secondary) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 8)
    }
}

// MARK: - Token Generator + JWT Decoder

/// Token Generator + JWT Decoder
struct TokenGeneratorView: View {
    @State private var generatedToken = ""
    @State private var tokenLength = 32
    @State private var includeSpecial = true
    @State private var jwtInput = ""
    @State private var jwtOutput = ""
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Token 工具箱", systemImage: "wand.and.stars")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button {
                    NSApp.keyWindow?.close()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)

            Divider()

            TabView {
                generateTab
                    .tabItem { Label("隨機生成", systemImage: "dice") }
                jwtTab
                    .tabItem { Label("JWT 解碼", systemImage: "doc.text.magnifyingglass") }
            }
            .padding(16)
        }
        .frame(minWidth: 460, minHeight: 360)
        .frame(width: 480, height: 400)
    }

    // MARK: - Generate Tab

    private var generateTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Length selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Token 長度").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                Picker("", selection: $tokenLength) {
                    Text("16").tag(16)
                    Text("32").tag(32)
                    Text("48").tag(48)
                    Text("64").tag(64)
                }
                .pickerStyle(.segmented)
            }

            Toggle(isOn: $includeSpecial) {
                Label("包含特殊字元 (!@#$%^&*)", systemImage: "textformat.alt")
                    .font(.system(size: 12))
            }

            // Generate button
            HStack {
                Button {
                    generateToken()
                    NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
                } label: {
                    Label("產生", systemImage: "wand.and.stars")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 16).padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    generatedToken = ""
                } label: {
                    Text("清除").font(.system(size: 11))
                }
                .buttonStyle(.bordered).controlSize(.small)
                .disabled(generatedToken.isEmpty)
            }

            // Output
            if !generatedToken.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    VStack(spacing: 6) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(generatedToken)
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                                .padding(12)
                        }
                        .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
                        .frame(maxWidth: .infinity)
                    }

                    HStack(spacing: 8) {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(generatedToken, forType: .string)
                            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                            withAnimation(.spring(response: 0.3)) { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copied = false } }
                        } label: {
                            Label(copied ? "已複製" : "複製到剪貼板", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(copied ? Color.green.opacity(0.12) : Color.accentColor.opacity(0.1)))
                                .foregroundColor(copied ? .green : .accentColor)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("\(generatedToken.count) 字元")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - JWT Tab

    private var jwtTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("貼上 JWT Token").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                TextEditor(text: $jwtInput)
                    .font(.system(size: 10, design: .monospaced))
                    .frame(height: 50)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.06), lineWidth: 1))
            }

            HStack {
                Button {
                    decodeJWT()
                } label: {
                    Label("解碼", systemImage: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 14).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .disabled(jwtInput.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    jwtInput = ""; jwtOutput = ""
                } label: {
                    Text("清除").font(.system(size: 11))
                }
                .buttonStyle(.bordered).controlSize(.small)
                .disabled(jwtInput.isEmpty && jwtOutput.isEmpty)
            }

            if !jwtOutput.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("解碼結果").font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)

                    ScrollView {
                        Text(jwtOutput)
                            .font(.system(size: 10, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                    }
                    .frame(maxHeight: 160)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.06), lineWidth: 1))
                }
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func generateToken() {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            + (includeSpecial ? "!@#$%^&*()-_=+[]{}|;:,.<>?" : "")
        generatedToken = String((0..<tokenLength).map { _ in chars.randomElement()! })
    }

    private func decodeJWT() {
        let parts = jwtInput.components(separatedBy: ".")
        guard parts.count == 3 else {
            jwtOutput = "❌ 無效的 JWT 格式（應為 header.payload.signature）"
            return
        }
        var output = ""
        for (i, part) in parts.enumerated() {
            let label = ["HEADER", "PAYLOAD", "SIGNATURE"][i]
            if i < 2, let decoded = decodeBase64URL(part),
               let obj = try? JSONSerialization.jsonObject(with: decoded),
               let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
               let str = String(data: pretty, encoding: .utf8) {
                output += "═══ \(label) ═══\n\(str)\n\n"
            } else {
                output += "═══ \(label) ═══\n\(part.count > 50 ? part.prefix(50) + "..." : part)\n\n"
            }
        }
        jwtOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeBase64URL(_ str: String) -> Data? {
        var base64 = str.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        return Data(base64Encoded: base64)
    }
}
