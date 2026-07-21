import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var mainWindow: NSWindow?
    let store = DataStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupMainWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "key.horizontal.fill", accessibilityDescription: "TokenVault")
            button.action = #selector(togglePopover)
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 480)
        popover.behavior = .transient

        let menuBarContent = MenuBarContentView(store: store)
        popover.contentViewController = NSHostingController(rootView: menuBarContent)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - Main Window

    private func setupMainWindow() {
        let contentView = ContentView(store: store)
        let hosting = NSHostingController(rootView: contentView)

        mainWindow = NSWindow(contentViewController: hosting)
        mainWindow?.title = "TokenVault"
        mainWindow?.setContentSize(NSSize(width: 850, height: 560))
        mainWindow?.minSize = NSSize(width: 700, height: 400)
        mainWindow?.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        mainWindow?.center()
        mainWindow?.setFrameAutosaveName("TokenVaultMainWindow")
        mainWindow?.titlebarAppearsTransparent = true
        mainWindow?.isReleasedWhenClosed = false
    }

    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Menu Bar Content

struct MenuBarContentView: View {
    @ObservedObject var store: DataStore
    @State private var searchText = ""
    @State private var showCopied: UUID?

    var filteredTokens: [TokenItem] {
        let tokens = store.allTokens.sorted { $0.copyCount > $1.copyCount }
        if searchText.isEmpty { return Array(tokens.prefix(10)) }
        return tokens.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TokenVault")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Button {
                    if let delegate = NSApp.delegate as? AppDelegate {
                        delegate.showMainWindow()
                    }
                    NSApp.keyWindow?.performClose(nil)
                } label: {
                    Image(systemName: "rectangle.expand.vertical")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("開啟完整視窗")
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("快速搜尋...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.08)))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredTokens) { token in
                        TokenMenuBarRow(
                            token: token,
                            store: store,
                            showCopied: $showCopied
                        )
                    }
                }
                .padding(.bottom, 4)
            }

            Divider()
            HStack {
                Text("TokenVault")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 340)
    }
}

struct TokenMenuBarRow: View {
    @ObservedObject var token: TokenItem
    @ObservedObject var store: DataStore
    @Binding var showCopied: UUID?

    var body: some View {
        HStack {
            Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                .font(.system(size: 10))
                .foregroundColor(token.isFavorite ? .orange : .secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(token.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text(token.maskedValue)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if showCopied == token.id {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .onTapGesture {
            ClipboardService.shared.copy(token.value)
            token.copyCount += 1
            store.save()
            let id = token.id
            withAnimation { showCopied = id }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if showCopied == id { withAnimation { showCopied = nil } }
            }
        }
    }
}
