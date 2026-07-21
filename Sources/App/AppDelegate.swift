import AppKit
import SwiftUI
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var mainWindow: NSWindow?
    let store = DataStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupMainWindow()
        setupGlobalHotkey()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showMainWindow()
        }

        buildAppMenu()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func buildAppMenu() {
        let mainMenu = NSMenu()

        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "關於 TokenVault", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "隱藏", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        mainMenu.addItem({ let i = NSMenuItem(); i.submenu = appMenu; return i }())

        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(NSMenuItem(title: "新增 Token", action: #selector(newToken), keyEquivalent: "n"))
        fileMenu.addItem(NSMenuItem(title: "新增分組", action: #selector(newGroup), keyEquivalent: "N"))
        mainMenu.addItem({ let i = NSMenuItem(); i.submenu = fileMenu; return i }())

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func newToken() { showMainWindow(); NotificationCenter.default.post(name: .showAddToken, object: nil) }
    @objc private func newGroup() { showMainWindow(); NotificationCenter.default.post(name: .showAddGroup, object: nil) }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "key.horizontal.fill", accessibilityDescription: "TokenVault")
            button.toolTip = "TokenVault"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "顯示主視窗", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarPopover(store: store))
    }

    private func setupMainWindow() {
        let hosting = NSHostingController(rootView: MainView(store: store))
        mainWindow = NSWindow(contentViewController: hosting)
        mainWindow?.title = "TokenVault"
        mainWindow?.setContentSize(NSSize(width: 520, height: 600))
        mainWindow?.minSize = NSSize(width: 400, height: 400)
        mainWindow?.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        mainWindow?.center()
        mainWindow?.setFrameAutosaveName("TokenVaultMain")
        mainWindow?.titlebarAppearsTransparent = true
        mainWindow?.isReleasedWhenClosed = false
    }

    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Global Hotkey ⌘⇧T

    private func setupGlobalHotkey() {
        var hotKeyRef: EventHotKeyRef?
        var id = EventHotKeyID(signature: 0x544B5654, id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_T), UInt32(cmdKey | shiftKey), id,
            GetApplicationEventTarget(), 0, &hotKeyRef)
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hid = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                nil, MemoryLayout<EventHotKeyID>.size, nil, &hid)
            if hid.id == 1 {
                DispatchQueue.main.async {
                    if let d = NSApp.delegate as? AppDelegate,
                       let t = d.store.allTokens.sorted(by: { $0.copyCount > $1.copyCount }).first {
                        ClipboardService.shared.copy(t.value); t.copyCount += 1; d.store.save()
                    }
                }
            }
            return noErr
        }, 1, &spec, nil, nil)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let showAddToken = Notification.Name("showAddToken")
    static let showAddGroup = Notification.Name("showAddGroup")
}
