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
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window?.makeKeyAndOrderFront(nil)
        return true
    }
}
