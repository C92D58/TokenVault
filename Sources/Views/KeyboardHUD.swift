import SwiftUI

/// Floating keyboard shortcut reference (hold ⌘ for 1.5s to show).
struct KeyboardHUD: View {
    @State private var isVisible = false
    @State private var cmdHeldSince: Date?

    var body: some View {
        Group {
            if isVisible {
                VStack(alignment: .leading, spacing: 10) {
                    Text("快捷鍵")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)

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
                    }
                    .foregroundColor(.secondary.opacity(0.5))
                }
                .padding(16)
                .background(
                    Color(.controlBackgroundColor)
                        .overlay(.ultraThinMaterial)
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 24, y: 10)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            _ = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
                if event.modifierFlags.contains(.command) {
                    if cmdHeldSince == nil { cmdHeldSince = Date() }
                } else {
                    cmdHeldSince = nil
                    isVisible = false
                }
                return event
            }
            let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { t in
                if let since = cmdHeldSince, Date().timeIntervalSince(since) > 1.5 {
                    isVisible = true
                }
            }
            // Prevent timer leak: associate with run loop and clean up
            RunLoop.current.add(timer, forMode: .common)
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
