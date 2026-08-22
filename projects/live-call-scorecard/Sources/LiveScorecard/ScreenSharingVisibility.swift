import AppKit

enum ScreenSharingVisibility {
    static let preferenceKey = "live-scorecard.show-in-screen-sharing"
    static let defaultValue = true

    @MainActor
    static func apply(to window: NSWindow, isVisible: Bool) {
        // readOnly means another process may read the window for capture, but
        // cannot modify it. none prevents window capture by other processes.
        window.sharingType = isVisible ? .readOnly : .none
    }
}

enum AppWindowTransparency {
    static let preferenceKey = "live-scorecard.window-transparency"
    static let defaultValue = 0.0
    static let maximumValue = 0.75

    static func sanitized(_ transparency: Double) -> Double {
        min(max(transparency, 0), maximumValue)
    }

    @MainActor
    static func apply(to window: NSWindow, transparency: Double) {
        window.alphaValue = CGFloat(1 - sanitized(transparency))
    }
}
