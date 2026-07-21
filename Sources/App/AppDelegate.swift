import AppKit
import SwiftUI
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var mainWindow: NSWindow?
    private var eventMonitor: Any?
    let store = DataStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupMainWindow()
        setupGlobalHotkey()

        // Show main window on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showMainWindow()
        }

        // Build app menu
        buildAppMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // MARK: - App Menu

    private func buildAppMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "關於 TokenVault", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "隱藏 TokenVault", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "退出 TokenVault", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        // File menu
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(NSMenuItem(title: "新增 Token", action: #selector(newToken), keyEquivalent: "n"))
        fileMenu.addItem(NSMenuItem(title: "新增分組", action: #selector(newGroup), keyEquivalent: "N"))
        fileMenu.addItem(.separator())
        fileMenu.addItem(NSMenuItem(title: "關閉視窗", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

        let fileItem = NSMenuItem()
        fileItem.submenu = fileMenu
        mainMenu.addItem(fileItem)

        // View menu
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(NSMenuItem(title: "顯示主視窗", action: #selector(showMainWindow), keyEquivalent: "0"))
        viewMenu.addItem(NSMenuItem(title: "切換側邊欄", action: #selector(toggleSidebar), keyEquivalent: "s"))

        let viewItem = NSMenuItem()
        viewItem.submenu = viewMenu
        mainMenu.addItem(viewItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func newToken() {
        showMainWindow()
        // Post notification for ContentView to show add sheet
        NotificationCenter.default.post(name: .showAddToken, object: nil)
    }

    @objc private func newGroup() {
        showMainWindow()
        NotificationCenter.default.post(name: .showAddGroup, object: nil)
    }

    @objc private func toggleSidebar() {
        // Not really needed for NavigationSplitView but good to have
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "key.horizontal.fill", accessibilityDescription: "TokenVault")
            button.toolTip = "TokenVault"
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Right-click menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "顯示主視窗", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient

        let menuBarContent = MenuBarContentView(store: store)
        popover.contentViewController = NSHostingController(rootView: menuBarContent)

        // Close popover when clicking outside
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.popover.isShown else { return }
            self.popover.performClose(nil)
        }
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
        mainWindow?.setContentSize(NSSize(width: 900, height: 600))
        mainWindow?.minSize = NSSize(width: 750, height: 450)
        mainWindow?.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        mainWindow?.center()
        mainWindow?.setFrameAutosaveName("TokenVaultMainWindow")
        mainWindow?.titlebarAppearsTransparent = true
        mainWindow?.isReleasedWhenClosed = false
        mainWindow?.backgroundColor = NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0)
        mainWindow?.appearance = NSAppearance(named: .darkAqua)

        // Custom titlebar with traffic lights offset
        if let titlebar = mainWindow?.standardWindowButton(.closeButton)?.superview {
            titlebar.isHidden = true
        }
    }

    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Global Hotkey (Cmd+Shift+T)

    private func setupGlobalHotkey() {
        var hotKeyRef: EventHotKeyRef?
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.signature = OSType(0x544B5654) // "TKVT"
        gMyHotKeyID.id = 1

        let modifierFlags: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_T)

        RegisterEventHotKey(keyCode, modifierFlags, gMyHotKeyID,
            GetApplicationEventTarget(), 0, &hotKeyRef)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            if hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    // Copy most recently used token
                    if let delegate = NSApp.delegate as? AppDelegate {
                        let tokens = delegate.store.allTokens.sorted { $0.copyCount > $1.copyCount }
                        if let token = tokens.first {
                            ClipboardService.shared.copy(token.value)
                            token.copyCount += 1
                            delegate.store.save()
                        }
                    }
                }
            }
            return noErr
        }, 1, &eventType, nil, nil)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let showAddToken = Notification.Name("showAddToken")
    static let showAddGroup = Notification.Name("showAddGroup")
}

// MARK: - Menu Bar Content

struct MenuBarContentView: View {
    @ObservedObject var store: DataStore
    @State private var searchText = ""
    @State private var showCopied: UUID?

    var filteredTokens: [TokenItem] {
        let tokens = store.allTokens.sorted { $0.copyCount > $1.copyCount }
        if searchText.isEmpty { return Array(tokens.prefix(12)) }
        return tokens.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with title
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "key.horizontal.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                    Text("TokenVault")
                        .font(.system(size: 13, weight: .bold))
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        if let delegate = NSApp.delegate as? AppDelegate {
                            delegate.showMainWindow()
                            NotificationCenter.default.post(name: .showAddToken, object: nil)
                        }
                        NSApp.keyWindow?.performClose(nil)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("新增 Token")

                    Button {
                        if let delegate = NSApp.delegate as? AppDelegate {
                            delegate.showMainWindow()
                        }
                        NSApp.keyWindow?.performClose(nil)
                    } label: {
                        Image(systemName: "rectangle.split.3x3")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("開啟完整視窗")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                TextField("搜尋 Token...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider().opacity(0.3)

            // Token list
            if filteredTokens.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "key.slash")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.3))
                    Text(searchText.isEmpty ? "尚無 Token" : "無匹配結果")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Button("新增第一個 Token") {
                            if let delegate = NSApp.delegate as? AppDelegate {
                                delegate.showMainWindow()
                                NotificationCenter.default.post(name: .showAddToken, object: nil)
                            }
                            NSApp.keyWindow?.performClose(nil)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredTokens) { token in
                            Button {
                                ClipboardService.shared.copy(token.value)
                                token.copyCount += 1
                                store.save()
                                let id = token.id
                                withAnimation(.spring(response: 0.3)) { showCopied = id }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    if showCopied == id { withAnimation { showCopied = nil } }
                                }
                                // Close popover after copy
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    NSApp.keyWindow?.performClose(nil)
                                }
                            } label: {
                                MenuBarTokenRow(token: token, isCopied: showCopied == token.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Footer
            Divider().opacity(0.3)
            HStack {
                Text("⌘⇧T 貼上最近 Token")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.5))
                Spacer()
                Text("\(store.allTokens.count) tokens")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 360)
        .background(Color(red: 0.09, green: 0.09, blue: 0.11))
    }
}

struct MenuBarTokenRow: View {
    @ObservedObject var token: TokenItem
    let isCopied: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                .font(.system(size: 10))
                .foregroundColor(token.isFavorite ? .orange : .secondary)
                .frame(width: 18, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(token.isFavorite ? Color.orange.opacity(0.15) : Color.white.opacity(0.05))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(token.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                Text(token.maskedValue)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if token.isExpired {
                Text("!")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.red.opacity(0.2)))
            }

            if isCopied {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
