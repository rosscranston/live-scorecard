import XCTest
@testable import TaxTerms

final class WindowLayoutTests: XCTestCase {
    func testDefaultSizeUsesRequestedScreenRatios() {
        let frame = NSRect(x: 0, y: 0, width: 1600, height: 1000)
        let size = TaxTermsWindowLayout.defaultSize(visibleFrame: frame)
        XCTAssertEqual(size.width, 400)
        XCTAssertEqual(size.height, 400)
    }

    func testTopRightFrameHonorsMargin() {
        let visible = NSRect(x: 0, y: 0, width: 1600, height: 1000)
        let size = NSSize(width: 400, height: 400)
        let result = TaxTermsWindowLayout.frame(for: .topRight, windowSize: size, visibleFrame: visible)
        XCTAssertEqual(result.maxX, 1588)
        XCTAssertEqual(result.maxY, 988)
    }
}
