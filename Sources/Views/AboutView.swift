import SwiftUI

struct AboutView: View {
    @State private var tapped = 0

    var body: some View {
        VStack(spacing: 20) {
            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.quaternary)
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }

            VStack(spacing: 4) {
                Text("TokenVault")
                    .font(.system(size: 20, weight: .bold))
                Text("版本 1.0 (Build 1)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Text("零知識 API Token 管理器")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            // Feature badges
            HStack(spacing: 8) {
                featureBadge("AES-256", icon: "lock.fill", color: .green)
                featureBadge("iCloud", icon: "icloud.fill", color: .blue)
                featureBadge("Face ID", icon: "faceid", color: .orange)
            }

            Divider().frame(width: 240)

            VStack(spacing: 6) {
                Text("© 2026 WAHSUN")
                    .font(.system(size: 12, weight: .medium))
                HStack(spacing: 6) {
                    Link(destination: URL(string: "mailto:x@wahsun.org")!) {
                        Label("x@wahsun.org", systemImage: "envelope")
                            .font(.system(size: 10))
                    }
                    Text("·").foregroundColor(.secondary)
                    Link(destination: URL(string: "https://wahsun.org")!) {
                        Label("wahsun.org", systemImage: "globe")
                            .font(.system(size: 10))
                    }
                }
                .foregroundColor(.secondary)
            }

            // Easter egg: tap version 5 times
            if tapped >= 5 {
                Text("🔐 安全無小事")
                    .font(.system(size: 10))
                    .foregroundColor(.accentColor)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(28)
        .frame(width: 340, height: 340)
        .onTapGesture {
            tapped += 1
        }
    }

    private func featureBadge(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8))
            Text(text).font(.system(size: 9, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.1)))
    }
}
