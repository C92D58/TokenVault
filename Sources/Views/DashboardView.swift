import SwiftUI

// MARK: - Dashboard Bar

struct DashboardBar: View {
    @ObservedObject var store: DataStore
    @State private var appeared = false

    private var stats: (total: Int, expired: Int, expiringSoon: Int, healthScore: Int, mostUsed: TokenItem?, recent: TokenItem?) {
        let active = store.activeTokens
        let total = active.count
        let expired = active.filter(\.isExpired).count
        let soon = active.filter(\.expiresSoon).count
        let mostUsed = active.max(by: { $0.copyCount < $1.copyCount })
        let recent = active.filter { $0.lastUsedAt != nil }.max(by: { ($0.lastUsedAt ?? .distantPast) < ($1.lastUsedAt ?? .distantPast) })

        // Health score: 100 - penalties
        var score = 100
        if total > 0 {
            score -= (expired * 20)
            score -= (soon * 8)
            let missedRenewal = active.filter {
                guard let e = $0.expiresAt else { return false }
                return e < Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            }.count
            score -= (missedRenewal * 5)
        }
        score = max(0, min(100, score))

        return (total, expired, soon, score, mostUsed, recent)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Health ring — fixed width, left-aligned
            healthSection
                .frame(width: 120)

            // Stat cards — equally distributed
            HStack(spacing: 0) {
                statCell(title: "即將到期", value: "\(stats.expiringSoon)",
                         icon: "clock.badge.exclamationmark",
                         color: stats.expiringSoon > 0 ? .orange : .secondary)

                statCell(title: "已過期", value: "\(stats.expired)",
                         icon: "xmark.shield.fill",
                         color: stats.expired > 0 ? .red : .secondary)

                statCell(title: recentLabel, value: recentName,
                         icon: recentIcon,
                         color: recentColor,
                         subtitle: recentSubtitle)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .padding(.horizontal, 14).padding(.top, 8)
        .scaleEffect(appeared ? 1 : 0.97)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    // MARK: - Health Section

    private var healthSection: some View {
        HStack(spacing: 10) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 3)
                    .frame(width: 36, height: 36)
                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(stats.healthScore) / 100.0)
                    .stroke(
                        healthColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: stats.healthScore)
                // Score text
                Text("\(stats.healthScore)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(healthColor)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("安全分數")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text(stats.total > 0 ? "\(stats.total) 個 Token" : "尚無資料")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .help("安全分數：過期扣 20 分，即將到期扣 8 分，過期超過 30 天扣 5 分")
    }

    // MARK: - Stat Cell

    private func statCell(title: String, value: String, icon: String,
                          color: Color, subtitle: String? = nil) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1, height: 32)

            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(color)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(title)
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
    }

    // MARK: - Recent Helpers

    private var recentLabel: String {
        stats.recent != nil ? "最近使用" : "最常用"
    }

    private var recentName: String {
        if stats.recent != nil {
            return stats.recent!.name
        } else if let most = stats.mostUsed {
            return most.name
        }
        return "—"
    }

    private var recentSubtitle: String {
        if let recent = stats.recent, let lu = recent.lastUsedAt {
            return relativeTime(lu)
        } else if let most = stats.mostUsed {
            return "已使用 \(most.copyCount) 次"
        }
        return "尚無記錄"
    }

    private var recentIcon: String {
        stats.recent != nil ? "clock.arrow.2.circlepath" : (stats.mostUsed != nil ? "flame.fill" : "clock")
    }

    private var recentColor: Color {
        stats.recent != nil ? .blue : (stats.mostUsed != nil ? .orange : .secondary)
    }

    private func relativeTime(_ date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        switch diff {
        case ..<60: return "剛剛"
        case ..<3600: return "\(diff / 60) 分鐘前"
        case ..<86400: return "\(diff / 3600) 小時前"
        case ..<604800: return "\(diff / 86400) 天前"
        default: return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    private var healthColor: Color {
        stats.healthScore >= 80 ? .green : stats.healthScore >= 50 ? .orange : .red
    }
}

// MARK: - Token Generator + JWT Decoder

/// Token Generator + JWT Decoder
struct TokenGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
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
                    dismiss()
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
                            ClipboardService.shared.copy(generatedToken, clearAfter: TimeInterval(SettingsService.shared.clipboardClearSeconds))
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
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))
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
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))
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
