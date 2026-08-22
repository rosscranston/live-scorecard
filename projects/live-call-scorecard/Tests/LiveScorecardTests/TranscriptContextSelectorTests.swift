import Foundation
import XCTest
@testable import LiveScorecard

final class TranscriptContextSelectorTests: XCTestCase {
    func testSelectsLargestRecentSuffixWithinMeasuredBudget() async throws {
        let segments = (1...6).map { segment("line-\($0)", at: Double($0)) }
        let twoLinePrompt = "line-5\nline-6"

        let selected = try await TranscriptContextSelector.select(
            from: segments,
            promptTokenBudget: twoLinePrompt.count,
            usedExactTokenCount: true,
            render: { $0.text },
            countTokens: { $0.count }
        )

        XCTAssertEqual(selected.segments.map(\.text), ["line-5", "line-6"])
        XCTAssertEqual(selected.prompt, twoLinePrompt)
        XCTAssertEqual(selected.promptTokenCount, twoLinePrompt.count)
        XCTAssertTrue(selected.usedExactTokenCount)
    }

    func testSelectsEverySegmentWhenAllFit() async throws {
        let segments = (1...4).map { segment("answer-\($0)", at: Double($0)) }

        let selected = try await TranscriptContextSelector.select(
            from: segments,
            promptTokenBudget: 10_000,
            usedExactTokenCount: false,
            render: { $0.text },
            countTokens: { $0.count }
        )

        XCTAssertEqual(selected.segments.count, segments.count)
        XCTAssertFalse(selected.usedExactTokenCount)
    }

    func testReturnsEmptyWindowWhenNewestSegmentCannotFit() async throws {
        let segments = [segment("This answer is longer than the budget.", at: 1)]

        let selected = try await TranscriptContextSelector.select(
            from: segments,
            promptTokenBudget: 3,
            usedExactTokenCount: true,
            render: { $0.text },
            countTokens: { $0.count }
        )

        XCTAssertTrue(selected.segments.isEmpty)
        XCTAssertTrue(selected.prompt.isEmpty)
        XCTAssertEqual(selected.promptTokenCount, 0)
    }

    private func segment(_ text: String, at timestamp: Double) -> TranscriptSegment {
        TranscriptSegment(
            id: UUID(),
            meetingID: UUID(),
            speaker: "PROSPECT",
            source: .meetingAudio,
            text: text,
            timestampSeconds: timestamp,
            isFinal: true,
            createdAt: Date()
        )
    }
}
