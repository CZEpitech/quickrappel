import AppKit
import SwiftUI

@main
struct QuickRappelApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

final class PanelWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: PanelWindow?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let content = NSHostingController(rootView: DeskletView())
        let panel = PanelWindow(contentViewController: content)
        panel.styleMask = [.borderless, .fullSizeContentView]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        if !panel.setFrameUsingName("QuickRappelDesklet") {
            if let screen = NSScreen.main {
                let frame = screen.visibleFrame
                panel.setFrameOrigin(NSPoint(
                    x: frame.maxX - panel.frame.width - 40,
                    y: frame.maxY - panel.frame.height - 60
                ))
            }
        }
        panel.setFrameAutosaveName("QuickRappelDesklet")
        panel.makeKeyAndOrderFront(nil)
        window = panel
        PanelController.shared.window = panel
        setupStatusItem()
        setupUndoShortcut()
    }

    private func setupUndoShortcut() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isUndoKey = event.charactersIgnoringModifiers?.lowercased() == "z"
            if isUndoKey && (modifiers == .command || modifiers == .control) {
                ReminderViewModel.shared.undo()
                return nil
            }
            return event
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window?.makeKeyAndOrderFront(nil)
        return true
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "QuickRappel")
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    @objc private func togglePanel() {
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func toggleLock() {
        PanelController.shared.locked.toggle()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let visible = window?.isVisible ?? false
        let toggleItem = NSMenuItem(
            title: visible ? "Masquer le panneau" : "Afficher le panneau",
            action: #selector(togglePanel),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        let lockItem = NSMenuItem(
            title: "Verrouiller la position",
            action: #selector(toggleLock),
            keyEquivalent: ""
        )
        lockItem.target = self
        lockItem.state = PanelController.shared.locked ? .on : .off
        menu.addItem(lockItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quitter QuickRappel",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
}
