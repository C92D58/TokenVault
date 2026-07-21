import SwiftUI

struct LockView: View {
    @ObservedObject var auth: AuthService
    let onUnlock: () -> Void

    @State private var pulse = false
    @State private var appear = false

    private let gradient = LinearGradient(
        colors: [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.45, green: 0.35, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color(.controlBackgroundColor)
            gradient.opacity(0.04)

            VStack(spacing: 0) {
                Spacer()

                // Shield icon
                ZStack {
                    Circle().fill(gradient.opacity(0.08)).frame(width: 100, height: 100)
                        .scaleEffect(pulse ? 1.12 : 1.0).opacity(pulse ? 0.4 : 0.15)
                    Circle().stroke(gradient.opacity(0.15), lineWidth: 2).frame(width: 86, height: 86)
                    ZStack {
                        RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial).frame(width: 70, height: 70)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.1), lineWidth: 1))
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                        Image(systemName: "lock.shield.fill").font(.system(size: 30, weight: .medium))
                            .foregroundStyle(gradient)
                    }
                }

                Spacer().frame(height: 28)

                // App name
                Text("TokenVault")
                    .font(.system(size: 26, weight: .bold)).tracking(-0.6)

                Text("零知識 API Token 管理器")
                    .font(.system(size: 12)).foregroundColor(.secondary).padding(.top, 4)

                Spacer().frame(height: 8)

                // Auth prompt
                Text("需要 \(auth.biometryType) 解鎖")
                    .font(.system(size: 14)).foregroundColor(.secondary)

                if auth.authFailed {
                    Text("認證失敗，再試一次")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(.red)
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(Capsule().fill(Color.red.opacity(0.08)))
                        .padding(.top, 4)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer().frame(height: 20)

                // Unlock button
                Button {
                    Task {
                        let ok = await auth.authenticate()
                        if ok { onUnlock() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: auth.biometryType == "Face ID" ? "faceid" : "touchid").font(.system(size: 18))
                        Text("使用 \(auth.biometryType) 解鎖").font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 28).padding(.vertical, 11)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                }
                .buttonStyle(.plain).focusEffectDisabled().keyboardShortcut(.return)

                Spacer()

                // Branding
                VStack(spacing: 8) {
                    Divider().frame(width: 160).opacity(0.3)

                    HStack(spacing: 6) {
                        Text("WAHSUN").font(.system(size: 11, weight: .bold))
                            .foregroundStyle(gradient)
                        Text("·").foregroundColor(.secondary.opacity(0.3))
                        Text("© 2026").font(.system(size: 10)).foregroundColor(.secondary.opacity(0.4))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill").font(.system(size: 7)).foregroundColor(.green.opacity(0.5))
                        Text("AES-256-GCM 加密 · 零知識架構").font(.system(size: 8))
                            .foregroundColor(.secondary.opacity(0.35))
                    }
                }
                .padding(.bottom, 28)
            }
            .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 12)
        }
        .frame(width: 400, height: 480)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appear = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
