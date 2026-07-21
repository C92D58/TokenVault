import SwiftUI

/// Floating keyboard shortcut reference (hold ⌘ for 1.5s to show).
struct KeyboardHUD: View {
    @State private var isVisible = false
    @State private var cmdHeldSince: Date?

    var body: some View {
        Group {
            if isVisible {
                VStack(alignment: .leading, spacing: 8) {
                    Text("快捷鍵").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)

                    shortcutRow("⌘N", "新增 Token")
                    shortcutRow("⇧⌘N", "新增分組")
                    shortcutRow("⌘⇧T", "貼上最近 Token")
                    shortcutRow("⌘L", "鎖定")
                    shortcutRow("⌘,", "設定")
                    shortcutRow("⌘?", "說明")
                    shortcutRow("⌘E", "匯出備份")
                    shortcutRow("⌘I", "匯入備份")
                    shortcutRow("雙擊", "複製 Token")

                    Divider().opacity(0.3)

                    HStack {
                        Image(systemName: "hand.tap.fill").font(.system(size: 9))
                        Text("按住 ⌘ 顯示此面板").font(.system(size: 9))
                    }.foregroundColor(.secondary.opacity(0.5))
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
                if event.modifierFlags.contains(.command) {
                    if cmdHeldSince == nil { cmdHeldSince = Date() }
                } else {
                    cmdHeldSince = nil
                    withAnimation { isVisible = false }
                }
                return event
            }
            // Timer to check if ⌘ held > 1.5s
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                if let since = cmdHeldSince, Date().timeIntervalSince(since) > 1.5 {
                    withAnimation { isVisible = true }
                }
            }
        }
    }

    private func shortcutRow(_ key: String, _ desc: String) -> some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.accentColor)
                .frame(width: 52, alignment: .trailing)
            Text(desc).font(.system(size: 11))
            Spacer()
        }
    }
}
