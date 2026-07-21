import SwiftUI

struct AboutView: View {
    @State private var tapped = 0

    private let accentGradient = LinearGradient(
        colors: [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.45, green: 0.35, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(spacing: 22) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(width: 76, height: 76)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1))
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 33))
                    .foregroundStyle(accentGradient)
            }

            VStack(spacing: 4) {
                Text("TokenVault")
                    .font(.system(size: 21, weight: .bold))
                    .tracking(-0.5)
                Text("版本 1.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 6) {
                Text("零知識 API Token 管理器")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                // Feature badges
                HStack(spacing: 6) {
                    badge("AES-256", icon: "lock.fill", color: .green)
                    badge("iCloud", icon: "icloud.fill", color: .blue)
                    badge("Face ID", icon: "faceid", color: .orange)
                }
            }

            // Purchase model
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "cart.fill").font(.system(size: 10))
                    Text("一次性買斷 · 永久使用").font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Capsule().fill(accentGradient.opacity(0.1)))
                .overlay(Capsule().stroke(accentGradient.opacity(0.2), lineWidth: 1))
            }

            Divider().frame(width: 200)

            // Brand
            VStack(spacing: 6) {
                Text("© 2026 WAHSUN").font(.system(size: 11, weight: .medium))
                HStack(spacing: 6) {
                    Link(destination: URL(string: "mailto:x@wahsun.org")!) {
                        Label("x@wahsun.org", systemImage: "envelope").font(.system(size: 10))
                    }
                    Text("·").foregroundColor(.secondary)
                    Link(destination: URL(string: "https://wahsun.org")!) {
                        Label("wahsun.org", systemImage: "globe").font(.system(size: 10))
                    }
                }.foregroundColor(.secondary)
            }

            // Platform badge
            HStack(spacing: 6) {
                Image(systemName: "macbook").font(.system(size: 9))
                Text("macOS")
                Text("·").foregroundColor(.secondary.opacity(0.5))
                Image(systemName: "iphone").font(.system(size: 9))
                Text("iOS (即將推出)")
            }
            .font(.system(size: 9))
            .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(28)
        .frame(width: 360, height: 420)
        .onTapGesture { tapped += 1 }
        .overlay(alignment: .bottom) {
            if tapped >= 5 {
                Text("🔐 安全無小事")
                    .font(.system(size: 10))
                    .foregroundStyle(accentGradient)
                    .padding(.bottom, 8)
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
