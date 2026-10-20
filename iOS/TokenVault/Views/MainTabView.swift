import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var app: AppState
    /// `-uiStartSettings` / `-uiStartTab N` open a specific tab on launch (used for screenshots).
    @State private var tab: Int = {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-uiStartSettings") { return 3 }
        if let i = args.firstIndex(of: "-uiStartTab"), i + 1 < args.count, let n = Int(args[i + 1]) { return n }
        return 0
    }()

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
