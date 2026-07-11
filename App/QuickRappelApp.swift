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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        showPanel()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        showPanel()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        return true
    }

    private func showPanel() {
        if window == nil {
            let content = NSHostingController(rootView: CaptureView(onDone: {
                NSApp.terminate(nil)
            }))
            let panel = NSWindow(contentViewController: content)
            panel.styleMask = [.titled, .fullSizeContentView]
            panel.titlebarAppearsTransparent = true
            panel.titleVisibility = .hidden
            panel.isMovableByWindowBackground = true
            panel.level = .floating
            panel.standardWindowButton(.closeButton)?.isHidden = true
            panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
            panel.standardWindowButton(.zoomButton)?.isHidden = true
            window = panel
        }
        positionTopCenter()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private func positionTopCenter() {
        guard let window, let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let size = window.frame.size
        let x = frame.midX - size.width / 2
        let y = frame.maxY - size.height - frame.height * 0.18
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
