import AppKit
import Foundation

final class PanelController: ObservableObject {
    static let shared = PanelController()

    private static let lockKey = "panelPositionLocked"
    private static let overlayKey = "panelOverlayMode"

    weak var window: NSWindow? {
        didSet { apply() }
    }

    @Published var locked: Bool {
        didSet {
            UserDefaults.standard.set(locked, forKey: Self.lockKey)
            apply()
        }
    }

    @Published var overlay: Bool {
        didSet {
            UserDefaults.standard.set(overlay, forKey: Self.overlayKey)
            apply()
        }
    }

    private init() {
        locked = UserDefaults.standard.bool(forKey: Self.lockKey)
        overlay = UserDefaults.standard.bool(forKey: Self.overlayKey)
    }

    private func apply() {
        guard let window else { return }
        window.isMovableByWindowBackground = !locked
        window.isMovable = !locked
        if locked {
            window.styleMask.remove(.resizable)
        } else {
            window.styleMask.insert(.resizable)
        }
        if overlay {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        } else {
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        }
        window.orderFrontRegardless()
    }
}
