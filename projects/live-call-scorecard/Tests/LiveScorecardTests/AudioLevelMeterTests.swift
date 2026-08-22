import XCTest
@testable import LiveScorecard

final class AudioLevelMeterTests: XCTestCase {
    func testSilenceMapsToZero() {
        XCTAssertEqual(AudioLevelMeter.normalizedLevel(rms: 0), 0)
    }

    func testFullScaleMapsToOne() {
        XCTAssertEqual(AudioLevelMeter.normalizedLevel(rms: 1), 1, accuracy: 0.0001)
    }

    func testMinusThirtyDecibelsMapsToMidpoint() {
        let rms = pow(10.0, -30.0 / 20.0)
        XCTAssertEqual(AudioLevelMeter.normalizedLevel(rms: rms), 0.5, accuracy: 0.0001)
    }
}
