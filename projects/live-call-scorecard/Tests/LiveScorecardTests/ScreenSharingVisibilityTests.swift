import AppKit
import XCTest
@testable import LiveScorecard

@MainActor
final class ScreenSharingVisibilityTests: XCTestCase {
    func testVisibleModeAllowsOtherProcessesToCaptureWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        ScreenSharingVisibility.apply(to: window, isVisible: true)

        XCTAssertEqual(window.sharingType, .readOnly)
    }

    func testPrivateModePreventsOtherProcessesFromCapturingWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        ScreenSharingVisibility.apply(to: window, isVisible: false)

        XCTAssertEqual(window.sharingType, .none)
    }

    func testTransparencyAppliesToEntireNativeWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        AppWindowTransparency.apply(to: window, transparency: 0.40)

        XCTAssertEqual(window.alphaValue, 0.60, accuracy: 0.001)
    }

    func testTransparencyIsClampedToRecoverableRange() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        AppWindowTransparency.apply(to: window, transparency: 2)

        XCTAssertEqual(window.alphaValue, 0.25, accuracy: 0.001)
        XCTAssertEqual(AppWindowTransparency.sanitized(-1), 0)
    }
}
