import AppKit
import Foundation

final class PanelController: ObservableObject {
    static let shared = PanelController()

    private static let lockKey = "panelPositionLocked"
    private static let overlayKey = "panelOverlayMode"
    private static let compactKey = "panelCompactMode"
    private static let expandedFrameKey = "panelExpandedFrame"
    private static let compactHeight: CGFloat = 48

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

    @Published var compact: Bool {
        didSet {
            UserDefaults.standard.set(compact, forKey: Self.compactKey)
            applyCompact(animated: true)
        }
    }

    private init() {
        locked = UserDefaults.standard.bool(forKey: Self.lockKey)
        overlay = UserDefaults.standard.bool(forKey: Self.overlayKey)
        compact = UserDefaults.standard.bool(forKey: Self.compactKey)
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
        applyCompact(animated: false)
        window.orderFrontRegardless()
    }

    private func applyCompact(animated: Bool) {
        guard let window else { return }
        if compact {
            if window.frame.height > Self.compactHeight {
                UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: Self.expandedFrameKey)
            }
            window.contentMinSize = NSSize(width: 280, height: Self.compactHeight)
            window.contentMaxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: Self.compactHeight)
            var frame = window.frame
            frame.origin.y += frame.size.height - Self.compactHeight
            frame.size.height = Self.compactHeight
            window.setFrame(frame, display: true, animate: animated)
        } else {
            window.contentMinSize = NSSize(width: 280, height: 320)
            window.contentMaxSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            let current = window.frame
            var frame: NSRect
            if let saved = UserDefaults.standard.string(forKey: Self.expandedFrameKey) {
                frame = NSRectFromString(saved)
            } else {
                frame = NSRect(x: 0, y: 0, width: max(current.width, 340), height: 440)
            }
            frame.origin.x = current.origin.x
            frame.origin.y = current.maxY - frame.size.height
            window.setFrame(frame, display: true, animate: animated)
        }
    }
}
