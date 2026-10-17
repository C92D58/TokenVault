import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var app: AppState
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            VaultView()
                .tabItem { Label("保險庫", systemImage: "key.fill") }
                .tag(0)

            ToolsView()
                .tabItem { Label("工具", systemImage: "wand.and.stars") }
                .tag(1)

            SecurityLogView()
                .tabItem { Label("日誌", systemImage: "clock.arrow.circlepath") }
                .tag(2)

            SettingsView()
                .tabItem { Label("設定", systemImage: "slider.horizontal.3") }
                .tag(3)
        }
        .tint(Theme.accent)
        .onChange(of: tab) { _, _ in
            if app.isLocked { tab = 0 }
        }
    }
}
