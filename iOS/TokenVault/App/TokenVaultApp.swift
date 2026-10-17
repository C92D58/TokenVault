import SwiftUI

@main
struct TokenVaultApp: App {
    @StateObject private var app = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .environmentObject(app.vault)
                .environmentObject(app.settings)
                .environmentObject(app.toast)
                .tint(Theme.accent)
                .preferredColorScheme(app.settings.appearance.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if app.isLocked {
                LockView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            }
        }
        .animation(Theme.Motion.appear, value: app.isLocked)
        .overlay {
            if app.isShielded {
                PrivacyShield()
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottom) { ToastHost() }
        .onChange(of: scenePhase) { _, phase in
            app.scenePhaseChanged(phase)
        }
        .task { await app.prepare() }
    }
}

/// Drawn over the whole app whenever it leaves the foreground, so the app switcher never
/// photographs a vault. Also the visual that stops a shoulder without any extra chrome.
struct PrivacyShield: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: Theme.Space.s) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .semibold))
                Text("TokenVault")
                    .font(Theme.heading)
            }
            .foregroundStyle(Theme.textSecondary)
        }
        .ignoresSafeArea()
    }
}
