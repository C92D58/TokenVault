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
    private var aboutWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var helpWindow: NSWindow?
    private var lastUnlockTime = Date.distantPast
    private var idleTimer: Timer?
#endif
}

// MARK: - Shared Actions

extension AppDelegate {
    @objc func undoAction() { store.undoManager.undo() }
    @objc func redoAction() { store.undoManager.redo() }

    @objc func newToken() {
        showMainContent()
        NotificationCenter.default.post(name: .showAddToken, object: nil)
    }
    @objc func newGroup() {
        showMainContent()
        NotificationCenter.default.post(name: .showAddGroup, object: nil)
    }
    @objc func lockApp() {
        idleTimer?.invalidate(); idleTimer = nil; auth.lock(); showLockScreen()
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
    func toggleFav(_ token: TokenItem) { store.toggleFav(token); store.save() }
    func deleteToken(_ token: TokenItem) { store.deleteToken(token) }
    func copyToken(_ token: TokenItem) {
        let value = token.decryptedValue()
        ClipboardService.shared.copy(value, clearAfter: TimeInterval(settings.clipboardClearSeconds))
        store.useToken(token)
        ToastService.shared.show("已複製「\(token.name)」", icon: "doc.on.clipboard")
#if os(macOS)
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
#endif
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let showAddToken = Notification.Name("showAddToken")
    static let showAddGroup = Notification.Name("showAddGroup")
    static let showImportWizard = Notification.Name("showImportWizard")
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

        // Notifications
        NotificationService.requestPermission()
        NotificationService.scheduleExpiryReminders(for: store.allTokens)

        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidResignActive),
            name: NSApplication.didResignActiveNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification, object: nil
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

        let file = NSMenu(title: "檔案")
        file.addItem(NSMenuItem(title: "新增 Token", action: #selector(newToken), keyEquivalent: "n"))
        file.addItem(NSMenuItem(title: "新增分組", action: #selector(newGroup), keyEquivalent: "N"))
        file.addItem(.separator())
        file.addItem(NSMenuItem(title: "匯入...", action: #selector(showImport), keyEquivalent: "i"))
        file.addItem(NSMenuItem(title: "匯出備份...", action: #selector(exportBackup), keyEquivalent: "e"))
        main.addItem({ let i = NSMenuItem(); i.submenu = file; return i }())

        let edit = NSMenu(title: "編輯")
        edit.addItem(NSMenuItem(title: "還原", action: #selector(undoAction), keyEquivalent: "z"))
        edit.addItem(NSMenuItem(title: "重做", action: #selector(redoAction), keyEquivalent: "Z"))
        main.addItem({ let i = NSMenuItem(); i.submenu = edit; return i }())

        let help = NSMenu(title: "輔助說明")
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
        popover.contentSize = NSSize(width: 360, height: 480)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: PopoverView(store: store))
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown { popover.performClose(nil) }
        else { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY); popover.contentViewController?.view.window?.makeKey() }
    }

    // ── Windows ──

    /// Standard window configuration with solid background.
    private func applyGlassStyle(_ window: NSWindow?, title: String, size: NSSize,
                                  minSize: NSSize? = nil, movable: Bool = false,
                                  floating: Bool = false, fullSize: Bool = true) {
        guard let w = window else { return }
        w.title = title
        w.setContentSize(size)
        if let m = minSize { w.minSize = m }
        w.titlebarAppearsTransparent = true
        w.isReleasedWhenClosed = false
        w.isMovableByWindowBackground = movable
        w.backgroundColor = .windowBackgroundColor
        w.isOpaque = true
        w.hasShadow = true
        if floating { w.level = .floating }
        if fullSize {
            w.styleMask.insert(.fullSizeContentView)
        } else {
            w.styleMask.remove(.fullSizeContentView)
        }
        w.center()
    }

    private func setupMainWindow() {
        let hosting = NSHostingController(rootView: MainView(store: store))
        mainWindow = NSWindow(contentViewController: hosting)
        mainWindow?.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        applyGlassStyle(mainWindow, title: "TokenVault",
                        size: NSSize(width: 900, height: 680),
                        minSize: NSSize(width: 640, height: 500))
        mainWindow?.setFrameAutosaveName("TokenVaultMain")
    }

    @objc func showMainContent() {
        guard !auth.isLocked else { showLockScreen(); return }
        NSApp.activate(ignoringOtherApps: true); mainWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            settingsWindow?.styleMask = [.titled, .closable, .fullSizeContentView]
            applyGlassStyle(settingsWindow, title: "設定",
                            size: NSSize(width: 480, height: 520),
                            minSize: NSSize(width: 440, height: 440))
            settingsWindow?.setFrameAutosaveName("TokenVaultSettings")
        }
        NSApp.activate(ignoringOtherApps: true); settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func showHelp() {
        if helpWindow == nil {
            helpWindow = NSWindow(contentViewController: NSHostingController(rootView: HelpView()))
            helpWindow?.styleMask = [.titled, .closable, .fullSizeContentView]
            applyGlassStyle(helpWindow, title: "TokenVault 說明",
                            size: NSSize(width: 520, height: 500),
                            minSize: NSSize(width: 480, height: 420))
            helpWindow?.setFrameAutosaveName("TokenVaultHelp")
        }
        NSApp.activate(ignoringOtherApps: true); helpWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func showAbout() {
        if aboutWindow == nil {
            let win = NSWindow(contentViewController: NSHostingController(rootView: AboutView()))
            win.styleMask = [.titled, .closable, .fullSizeContentView]
            aboutWindow = win
            applyGlassStyle(aboutWindow, title: "關於 TokenVault",
                            size: NSSize(width: 380, height: 420))
            aboutWindow?.setFrameAutosaveName("TokenVaultAbout")
        }
        NSApp.activate(ignoringOtherApps: true); aboutWindow?.makeKeyAndOrderFront(nil)
    }

    // ── Lock Screen ──

    private func showLockScreen() {
        let lockView = LockView(auth: auth) { [weak self] in
            self?.lastUnlockTime = Date()
            self?.lockWindow?.close(); self?.lockWindow = nil; self?.showMainContent()
        }
        lockWindow?.close()
        lockWindow = NSWindow(contentViewController: NSHostingController(rootView: lockView))
        lockWindow?.styleMask = [.titled, .closable, .fullSizeContentView]
        applyGlassStyle(lockWindow, title: "TokenVault",
                        size: NSSize(width: 420, height: 520),
                        movable: true, floating: true)
        lockWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        Task { await auth.authenticate() }
    }

    @objc private func appDidResignActive() {
        guard settings.autoLockEnabled, lockWindow == nil else { return }
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(settings.autoLockSeconds), repeats: false) { [weak self] _ in
            self?.performLock()
        }
    }

    @objc private func appDidBecomeActive() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    private func performLock() {
        guard lockWindow == nil else { return }
        auth.lock()
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        DispatchQueue.main.async { [weak self] in
            if self?.auth.isLocked == true { self?.showLockScreen() }
        }
    }

    // ── Backup ──

    @objc func exportBackup() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "tokenvault-backup-\(Date().formatted(date: .abbreviated, time: .omitted)).json"
        panel.allowedContentTypes = [.json, .plainText, .commaSeparatedText]
        panel.begin { [weak self] r in
            guard let self, r == .OK, let url = panel.url else { return }
            let tokens = store.activeTokens
            let ext = url.pathExtension.lowercased()
            let content: String
            if ext == "csv" {
                content = ImportExportHelper.exportCSV(tokens)
            } else if ext == "env" || ext == "txt" {
                content = ImportExportHelper.exportEnv(tokens)
            } else {
                // JSON backup (default)
                let snap = DataStore.BackupSnapshot(groups: store.groups, tokens: store.allTokens)
                if let d = try? JSONEncoder().encode(snap) { try? d.write(to: url); return }
                return
            }
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    @objc func showImport() {
        showMainContent()
        NotificationCenter.default.post(name: .showImportWizard, object: nil)
    }

    // Legacy: JSON-only backup import
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
        let gid = EventHotKeyID(signature: 0x544B5654, id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_T), UInt32(cmdKey | shiftKey), gid, GetApplicationEventTarget(), 0, &ref)
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hid = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hid)
            if hid.id == 1 {
                DispatchQueue.main.async {
                    guard let d = NSApp.delegate as? AppDelegate, !d.auth.isLocked else { return }
                    let token = d.store.activeTokens
                        .filter { $0.isFavorite }
                        .sorted(by: { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }).first
                        ?? d.store.activeTokens
                        .sorted(by: { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }).first
                    guard let t = token else { return }
                    d.copyToken(t)
                }
            }
            return noErr
        }, 1, &spec, nil, nil)
    }
}
#endif
