import SwiftUI

/// Face ID / Touch ID lock screen shown on launch and when app returns from background.
struct LockView: View {
    @ObservedObject var auth: AuthService
    let onUnlock: () -> Void

    @State private var animate = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon with subtle pulse
            ZStack {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 80, height: 80)
                    .scaleEffect(animate ? 1.05 : 1.0)
                    .opacity(animate ? 0.5 : 0.3)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)
            }

            Text("TokenVault")
                .font(.system(size: 22, weight: .bold))

            Text("需要 \(auth.biometryType) 解鎖")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            if auth.authFailed {
                Text("認證失敗，請重試")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .padding(.top, -8)
            }

            Button {
                Task {
                    let ok = await auth.authenticate()
                    if ok { onUnlock() }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: auth.biometryType == "Face ID" ? "faceid" : "touchid")
                        .font(.system(size: 16))
                    Text("解鎖")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 24).padding(.vertical, 10)
                .background(Capsule().fill(.quaternary))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return)

            Spacer()

            Text("WAHSUN")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary.opacity(0.25))
                .padding(.bottom, 20)
        }
        .frame(width: 360, height: 400)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { animate = true }
        }
    }
}
