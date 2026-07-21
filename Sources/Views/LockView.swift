import SwiftUI

/// Refined lock screen with glass-morphism and animated shield.
struct LockView: View {
    @ObservedObject var auth: AuthService
    let onUnlock: () -> Void

    @State private var pulse = false
    @State private var appear = false

    private let accentGradient = LinearGradient(
        colors: [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.45, green: 0.35, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            // Background
            Color(.controlBackgroundColor)
            accentGradient.opacity(0.04)

            VStack(spacing: 28) {
                Spacer()

                // Animated shield
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(accentGradient.opacity(0.08))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulse ? 1.15 : 1.0)
                        .opacity(pulse ? 0.4 : 0.15)

                    // Inner ring
                    Circle()
                        .stroke(accentGradient.opacity(0.15), lineWidth: 2)
                        .frame(width: 86, height: 86)

                    // Center icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .frame(width: 70, height: 70)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(accentGradient)
                    }
                }

                VStack(spacing: 6) {
                    Text("TokenVault")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(-0.5)
                    Text("需要 \(auth.biometryType) 解鎖")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                if auth.authFailed {
                    Text("認證失敗，再試一次")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(Capsule().fill(Color.red.opacity(0.08)))
                        .transition(.scale.combined(with: .opacity))
                }

                // Unlock button
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
                    .padding(.horizontal, 28).padding(.vertical, 11)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return)

                Spacer()

                // Footer
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 8)).foregroundColor(.green.opacity(0.6))
                    Text("AES-256-GCM · 零知識").font(.system(size: 9))
                }
                .foregroundColor(.secondary.opacity(0.4))
                .padding(.bottom, 24)
            }
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 12)
        }
        .frame(width: 380, height: 440)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appear = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
