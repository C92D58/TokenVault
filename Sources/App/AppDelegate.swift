import SwiftUI
#if os(macOS)
import AppKit
import Carbon
#endif

/// AppDelegate shared across platforms.
/// - macOS: NSApplicationDelegate with menu bar, global hotkey, lock screen
/// - iOS: will use UIApplicationDelegate / SwiftUI App protocol
final class AppDelegate: NSObject, ObservableObject {
    let store = DataStore()
    let auth = AuthService()
    let settings = SettingsService.shared

#if os(macOS)
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var mainWindow: NSWindow?
    private var lockWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var helpWindow: NSWindow?
#endif
}

// MARK: - Shared Actions

extension AppDelegate {
    @objc func newToken() {
        showMainContent()
        NotificationCenter.default.post(name: .showAddToken, object: nil)
    }
    @objc func newGroup() {
        showMainContent()
        NotificationCenter.default.post(name: .showAddGroup, object: nil)
    }
    @objc func lockApp() { auth.lock(); showLockScreen() }
    func toggleFav(_ token: TokenItem) { store.toggleFav(token); store.save() }
    func deleteToken(_ token: TokenItem) { store.deleteToken(token) }
    func copyToken(_ token: TokenItem) {
        let value = token.decryptedValue()
        ClipboardService.shared.copy(value, clearAfter: TimeInterval(settings.clipboardClearSeconds))
        token.copyCount += 1; store.save()
#if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
#endif
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let showAddToken = Notification.Name("showAddToken")
    static let showAddGroup = Notification.Name("showAddGroup")
}

// MARK: - macOS: NSApplicationDelegate

#if os(macOS)
extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.applyAppearance()
        setupMenuBar()
        setupMainWindow()
        setupGlobalHotkey()
        buildMenu()
        showLockScreen()

        NotificationCenter.default.addObserver(
            self, selector: #selector(autoLock),
            name: NSApplication.didResignActiveNotification, object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // ── Menu ──

    private func buildMenu() {
        let main = NSMenu()
        let app = NSMenu()
        app.addItem(NSMenuItem(title: "關於 TokenVault", action: #selector(showAbout), keyEquivalent: ""))
        app.addItem(.separator())
        app.addItem(NSMenuItem(title: "設定...", action: #selector(showSettings), keyEquivalent: ","))
        app.addItem(.separator())
        app.addItem(NSMenuItem(title: "鎖定", action: #selector(lockApp), keyEquivalent: "l"))
        app.addItem(.separator())
        app.addItem(NSMenuItem(title: "隱藏", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        app.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        main.addItem({ let i = NSMenuItem(); i.submenu = app; return i }())

        let file = NSMenu(title: "File")
        file.addItem(NSMenuItem(title: "新增 Token", action: #selector(newToken), keyEquivalent: "n"))
        file.addItem(NSMenuItem(title: "新增分組", action: #selector(newGroup), keyEquivalent: "N"))
        file.addItem(.separator())
        file.addItem(NSMenuItem(title: "匯出備份...", action: #selector(exportBackup), keyEquivalent: "e"))
        file.addItem(NSMenuItem(title: "匯入備份...", action: #selector(importBackup), keyEquivalent: "i"))
        main.addItem({ let i = NSMenuItem(); i.submenu = file; return i }())

        let help = NSMenu(title: "Help")
        help.addItem(NSMenuItem(title: "TokenVault 說明", action: #selector(showHelp), keyEquivalent: "?"))
        main.addItem({ let i = NSMenuItem(); i.submenu = help; return i }())
        NSApplication.shared.mainMenu = main
    }

    // ── Menu Bar ──

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "key.horizontal.fill", accessibilityDescription: "TokenVault")
            btn.toolTip = "TokenVault"
            btn.action = #selector(togglePopover)
            btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "顯示主視窗", action: #selector(showMainContent), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "鎖定", action: #selector(lockApp), keyEquivalent: "l"))
        menu.addItem(NSMenuItem(title: "設定...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(store: store))
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown { popover.performClose(nil) }
        else { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY); popover.contentViewController?.view.window?.makeKey() }
    }

    // ── Windows ──

    private func setupMainWindow() {
        let hosting = NSHostingController(rootView: MainView(store: store))
        mainWindow = NSWindow(contentViewController: hosting)
        mainWindow?.title = "TokenVault"
        mainWindow?.setContentSize(NSSize(width: 560, height: 680))
        mainWindow?.minSize = NSSize(width: 400, height: 440)
        mainWindow?.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        mainWindow?.center(); mainWindow?.setFrameAutosaveName("TokenVaultMain")
        mainWindow?.titlebarAppearsTransparent = true; mainWindow?.isReleasedWhenClosed = false
    }

    @objc func showMainContent() {
        guard !auth.isLocked else { showLockScreen(); return }
        NSApp.activate(ignoringOtherApps: true); mainWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            settingsWindow?.title = "設定"; settingsWindow?.styleMask = [.titled, .closable]
            settingsWindow?.setContentSize(NSSize(width: 420, height: 340))
            settingsWindow?.isReleasedWhenClosed = false; settingsWindow?.center()
        }
        NSApp.activate(ignoringOtherApps: true); settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func showHelp() {
        if helpWindow == nil {
            helpWindow = NSWindow(contentViewController: NSHostingController(rootView: HelpView()))
            helpWindow?.title = "TokenVault 說明"; helpWindow?.styleMask = [.titled, .closable]
            helpWindow?.setContentSize(NSSize(width: 460, height: 380))
            helpWindow?.isReleasedWhenClosed = false; helpWindow?.center()
        }
        NSApp.activate(ignoringOtherApps: true); helpWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showAbout() {
        let win = NSWindow(contentViewController: NSHostingController(rootView: AboutView()))
        win.title = "關於 TokenVault"; win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 360, height: 420)); win.center(); win.isReleasedWhenClosed = false
        NSApp.activate(ignoringOtherApps: true); win.makeKeyAndOrderFront(nil)
    }

    // ── Lock Screen ──

    private func showLockScreen() {
        let lockView = LockView(auth: auth) { [weak self] in
            self?.lockWindow?.close(); self?.lockWindow = nil; self?.showMainContent()
        }
        lockWindow?.close()
        lockWindow = NSWindow(contentViewController: NSHostingController(rootView: lockView))
        lockWindow?.title = "TokenVault"; lockWindow?.styleMask = [.titled, .closable, .fullSizeContentView]
        lockWindow?.setContentSize(NSSize(width: 380, height: 440))
        lockWindow?.titlebarAppearsTransparent = true; lockWindow?.isMovableByWindowBackground = true
        lockWindow?.center(); lockWindow?.isReleasedWhenClosed = false; lockWindow?.level = .floating
        lockWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        Task { await auth.authenticate() }
    }

    @objc private func autoLock() {
        guard settings.autoLockEnabled, lockWindow == nil else { return }
        auth.lock()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self?.auth.isLocked == true { self?.showLockScreen() }
        }
    }

    // ── Backup ──

    @objc func exportBackup() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "tokenvault-backup-\(Date().formatted(date: .abbreviated, time: .omitted)).json"
        panel.allowedContentTypes = [.json]
        panel.begin { [weak self] r in
            guard let self, r == .OK, let url = panel.url else { return }
            let snap = DataStore.BackupSnapshot(groups: store.groups, tokens: store.allTokens)
            if let d = try? JSONEncoder().encode(snap) { try? d.write(to: url) }
        }
    }

    @objc func importBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.begin { [weak self] r in
            guard let self, r == .OK, let url = panel.url, let data = try? Data(contentsOf: url) else { return }
            DispatchQueue.main.async {
                if let snap = try? JSONDecoder().decode(DataStore.BackupSnapshot.self, from: data) {
                    self.store.groups = snap.groups; self.store.allTokens = snap.tokens; self.store.save()
                }
            }
        }
    }

    // ── ⌘⇧T ──

    private func setupGlobalHotkey() {
        var ref: EventHotKeyRef?
        var gid = EventHotKeyID(signature: 0x544B5654, id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_T), UInt32(cmdKey | shiftKey), gid, GetApplicationEventTarget(), 0, &ref)
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hid = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hid)
            if hid.id == 1 {
                DispatchQueue.main.async {
                    guard let d = NSApp.delegate as? AppDelegate, !d.auth.isLocked,
                          let t = d.store.allTokens.sorted(by: { $0.copyCount > $1.copyCount }).first
                    else { return }
                    d.copyToken(t)
                }
            }
            return noErr
        }, 1, &spec, nil, nil)
    }
}
#endif
