import SwiftUI

struct AboutView: View {
    @State private var tapped = 0

    var body: some View {
        VStack(spacing: 24) {
            // App icon — glass card
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.controlBackgroundColor))
                    .frame(width: 84, height: 84)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.10), radius: 14, y: 5)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(DS.Color.accentGradient)
            }

            VStack(spacing: 4) {
                Text("TokenVault")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.5)
                Text("版本 1.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                Text("API Token 管理器")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    badge("AES-256", icon: "lock.fill", color: .green)
                    badge("iCloud", icon: "icloud.fill", color: .blue)
                    badge("Face ID", icon: "faceid", color: .orange)
                }
            }

            // Personal tool badge
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill").font(.system(size: 10))
                    Text("個人私用工具").font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(DS.Color.accent)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Capsule().fill(DS.Color.accent.opacity(0.1)))
                .overlay(Capsule().stroke(DS.Color.accent.opacity(0.2), lineWidth: 1))
            }

            Divider().frame(width: 200)

            VStack(spacing: 6) {
                Text("© 2026 WAHSUN").font(.system(size: 11, weight: .medium))
            }

            HStack(spacing: 6) {
                Image(systemName: "macbook").font(.system(size: 9))
                Text("macOS 專用")
            }
            .font(.system(size: 9))
            .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(30)
        .frame(width: 380, height: 420)
        .background(
            ZStack {
                Color(.controlBackgroundColor)
                DS.Color.accentGradientSubtle.opacity(0.5)
            }
        )
        .onTapGesture { tapped += 1 }
        .overlay(alignment: .bottom) {
            if tapped >= 5 {
                Text("🔐 安全無小事")
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.accentGradient)
                    .padding(.bottom, 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: tapped)
    }

    private func badge(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 7))
            Text(text).font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.1)))
    }
}
