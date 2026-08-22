import AppKit
import XCTest
@testable import PrivateCallNotepad

@MainActor
final class WindowManagementTests: XCTestCase {
    func testTransparencyIsClampedToRecoverableRange() {
        XCTAssertEqual(WindowTransparency.sanitized(-1), 0)
        XCTAssertEqual(WindowTransparency.sanitized(0.4), 0.4)
        XCTAssertEqual(WindowTransparency.sanitized(2), 0.75)
    }

    func testTransparencyAppliesToEntireWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        WindowTransparency.apply(to: window, transparency: 0.4)

        XCTAssertEqual(window.alphaValue, 0.6, accuracy: 0.001)
    }

    func testPrivatePolicyAppliesFloatingAndLegacyCaptureOptOutHints() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 600),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        PrivateWindowPolicy.apply(to: window)

        XCTAssertEqual(window.sharingType, .none)
        XCTAssertEqual(window.level, .floating)
        XCTAssertTrue(window.collectionBehavior.contains(.canJoinAllSpaces))
        XCTAssertTrue(window.collectionBehavior.contains(.fullScreenAuxiliary))
    }

    func testTopRightPositionRespectsVisibleFrameAndMargin() {
        let visible = NSRect(x: 100, y: 50, width: 1400, height: 900)
        let frame = WindowLayout.frame(
            for: .topRight,
            windowSize: NSSize(width: 320, height: 600),
            visibleFrame: visible
        )

        XCTAssertEqual(frame.maxX, visible.maxX - WindowLayout.margin, accuracy: 0.001)
        XCTAssertEqual(frame.maxY, visible.maxY - WindowLayout.margin, accuracy: 0.001)
    }

    func testCenterPositionCentersWindowWithinVisibleFrame() {
        let visible = NSRect(x: -1000, y: 20, width: 1000, height: 700)
        let frame = WindowLayout.frame(
            for: .center,
            windowSize: NSSize(width: 300, height: 500),
            visibleFrame: visible
        )

        XCTAssertEqual(frame.midX, visible.midX, accuracy: 0.001)
        XCTAssertEqual(frame.midY, visible.midY, accuracy: 0.001)
    }

    func testShortcutNumbersFollowNumpadGrid() {
        XCTAssertEqual(WindowPosition.bottomLeft.rawValue, 1)
        XCTAssertEqual(WindowPosition.center.rawValue, 5)
        XCTAssertEqual(WindowPosition.topRight.rawValue, 9)
        XCTAssertEqual(WindowPosition.gridOrder.first, .topLeft)
        XCTAssertEqual(WindowPosition.gridOrder.last, .bottomRight)
    }

    func testWindowFrameRoundTripsAndRequiresVisibleArea() {
        let frame = NSRect(x: 125, y: 80, width: 344, height: 612)
        let encoded = WindowFramePersistence.encode(frame)

        XCTAssertEqual(WindowFramePersistence.decode(encoded), frame)
        XCTAssertTrue(WindowFramePersistence.isUsable(
            frame,
            on: [NSRect(x: 0, y: 0, width: 1440, height: 900)]
        ))
        XCTAssertFalse(WindowFramePersistence.isUsable(
            frame,
            on: [NSRect(x: 2000, y: 0, width: 1440, height: 900)]
        ))
        XCTAssertNil(WindowFramePersistence.decode("{0, 0, 0, 0}"))
    }
}
