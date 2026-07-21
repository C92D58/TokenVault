import AppKit
import SwiftUI
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var mainWindow: NSWindow?
    private var lockWindow: NSWindow?

    let store = DataStore()
    let auth = AuthService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupMainWindow()
        setupGlobalHotkey()
        buildMenu()

        // Show lock screen first
        showLockScreen()

        // Auto-lock on resign active
        NotificationCenter.default.addObserver(
            self, selector: #selector(autoLock),
            name: NSApplication.didResignActiveNotification, object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    // MARK: - Menu

    private func buildMenu() {
        let main = NSMenu()
        let app = NSMenu()
        app.addItem(NSMenuItem(title: "關於 TokenVault", action: #selector(showAbout), keyEquivalent: ""))
        app.addItem(.separator())
        app.addItem(NSMenuItem(title: "鎖定", action: #selector(lockApp), keyEquivalent: "l"))
        app.addItem(.separator())
        app.addItem(NSMenuItem(title: "隱藏", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        app.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        main.addItem({ let i = NSMenuItem(); i.submenu = app; return i }())
        let file = NSMenu(title: "File")
        file.addItem(NSMenuItem(title: "新增 Token", action: #selector(newToken), keyEquivalent: "n"))
        file.addItem(NSMenuItem(title: "新增分組", action: #selector(newGroup), keyEquivalent: "N"))
        main.addItem({ let i = NSMenuItem(); i.submenu = file; return i }())
        NSApplication.shared.mainMenu = main
    }

    @objc private func newToken() { showMainWindow(); NotificationCenter.default.post(name: .showAddToken, object: nil) }
    @objc private func newGroup() { showMainWindow(); NotificationCenter.default.post(name: .showAddGroup, object: nil) }
    @objc private func lockApp() { auth.lock(); showLockScreen() }

    @objc private func showAbout() {
        let win = NSWindow(contentViewController: NSHostingController(rootView: AboutView()))
        win.title = "關於 TokenVault"; win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 320, height: 280)); win.center(); win.isReleasedWhenClosed = false
        NSApp.activate(ignoringOtherApps: true); win.makeKeyAndOrderFront(nil)
    }

    // MARK: - Lock Screen

    private func showLockScreen() {
        let lockView = LockView(auth: auth) { [weak self] in
            self?.lockWindow?.close()
            self?.lockWindow = nil
            self?.showMainWindow()
        }
        let hosting = NSHostingController(rootView: lockView)

        lockWindow?.close()
        lockWindow = NSWindow(contentViewController: hosting)
        lockWindow?.title = "TokenVault"
        lockWindow?.styleMask = [.titled, .closable, .fullSizeContentView]
        lockWindow?.setContentSize(NSSize(width: 360, height: 400))
        lockWindow?.titlebarAppearsTransparent = true
        lockWindow?.isMovableByWindowBackground = true
        lockWindow?.center()
        lockWindow?.isReleasedWhenClosed = false
        lockWindow?.level = .floating
        lockWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Auto-authenticate
        Task { await auth.authenticate(); /* handled by callback */ }
    }

    @objc private func autoLock() {
        if lockWindow == nil {
            auth.lock()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                if self?.auth.isLocked == true { self?.showLockScreen() }
            }
        }
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "key.horizontal.fill", accessibilityDescription: "TokenVault")
            btn.toolTip = "TokenVault"
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "顯示主視窗", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "鎖定", action: #selector(lockApp), keyEquivalent: "l"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView(store: store))
    }

    // MARK: - Main Window

    private func setupMainWindow() {
        let hosting = NSHostingController(rootView: MainView(store: store))
        mainWindow = NSWindow(contentViewController: hosting)
        mainWindow?.title = "TokenVault"
        mainWindow?.setContentSize(NSSize(width: 540, height: 640))
        mainWindow?.minSize = NSSize(width: 400, height: 400)
        mainWindow?.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        mainWindow?.center()
        mainWindow?.setFrameAutosaveName("TokenVaultMain")
        mainWindow?.titlebarAppearsTransparent = true
        mainWindow?.isReleasedWhenClosed = false
    }

    @objc func showMainWindow() {
        guard !auth.isLocked else { showLockScreen(); return }
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - ⌘⇧T

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
                    ClipboardService.shared.copy(t.decryptedValue()); t.copyCount += 1; d.store.save()
                }
            }
            return noErr
        }, 1, &spec, nil, nil)
    }
}

extension Notification.Name {
    static let showAddToken = Notification.Name("showAddToken")
    static let showAddGroup = Notification.Name("showAddGroup")
}
