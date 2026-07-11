import AppKit
import Foundation

final class PanelController: ObservableObject {
    static let shared = PanelController()

    private static let lockKey = "panelPositionLocked"

    weak var window: NSWindow? {
        didSet { applyLock() }
    }

    @Published var locked: Bool {
        didSet {
            UserDefaults.standard.set(locked, forKey: Self.lockKey)
            applyLock()
        }
    }

    private init() {
        locked = UserDefaults.standard.bool(forKey: Self.lockKey)
    }

    private func applyLock() {
        window?.isMovableByWindowBackground = !locked
        window?.isMovable = !locked
    }
}
