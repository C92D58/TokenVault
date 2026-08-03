import SwiftUI

struct LockView: View {
    @ObservedObject var auth: AuthService
    let onUnlock: () -> Void

    @State private var pulse = false
    @State private var appear = false
    @State private var isActive = true
    @State private var glowRotation: Double = 0

    var body: some View {
        ZStack {
            // Glass material background with particles
            Color(.windowBackgroundColor).opacity(0.3)
            DS.Color.accentGradientSubtle.opacity(0.5)
            ParticleField(count: 20, color: DS.Color.accentLight)

            VStack(spacing: 0) {
                Spacer()

                // Shield icon — thick glass
                ZStack {
                    // Outer glow pulse
                    Circle()
                        .fill(DS.Color.accent.opacity(0.06))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulse && isActive ? 1.15 : 1.0)
                        .opacity(pulse && isActive ? 0.6 : 0.2)

                    // Ring
                    Circle()
                        .stroke(DS.Color.accentGradient, lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .opacity(0.2)

                    // Shield card — glass material
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.controlBackgroundColor))
                        .frame(width: 80, height: 80)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.10), radius: 16, y: 6)

                    // Lock icon
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(DS.Color.accentGradient)
                }

                Spacer().frame(height: 32)

                // Brand
                Text("TokenVault")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.6)

                Text("API Token 管理器")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                Spacer().frame(height: 10)

                // Auth prompt
                Text("需要 \(auth.biometryType) 解鎖")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                if auth.authFailed {
                    Text("認證失敗，再試一次")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(Capsule().fill(Color.red.opacity(0.08)))
                        .padding(.top, 6)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer().frame(height: 24)

                // Unlock button — glass pill
                Button {
                    Task {
                        let ok = await auth.authenticate()
                        if ok { onUnlock() }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: auth.biometryType == "Face ID" ? "faceid" : "touchid")
                            .font(.system(size: 18))
                        Text("使用 \(auth.biometryType) 解鎖")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 32).padding(.vertical, 12)
                    .background(Capsule().fill(DS.Color.accent.opacity(0.12)))
                    .overlay(Capsule().stroke(DS.Color.accent.opacity(0.2), lineWidth: 1))
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                }
                .buttonStyle(.plain).focusEffectDisabled().keyboardShortcut(.return)

                Spacer()

                // Security note
                VStack(spacing: 6) {
                    Divider().frame(width: 160).opacity(0.3)

                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.green.opacity(0.5))
                        Text("AES-256-GCM 加密 · Secure Enclave")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.35))
                    }
                }
                .padding(.bottom, 32)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 12)
        }
        .frame(width: 420, height: 520)
        .background(.ultraThinMaterial)
        .onAppear {
            isActive = true
            withAnimation(DS.Animation.fade) { appear = true }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { pulse = true }
        }
        .onDisappear {
            isActive = false
            pulse = false
        }
    }
}
