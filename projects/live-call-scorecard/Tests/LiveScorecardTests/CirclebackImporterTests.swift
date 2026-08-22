import Foundation
import XCTest
@testable import LiveScorecard

final class CirclebackImporterTests: XCTestCase {
    func testDecodesAndSortsWebhookTranscript() throws {
        let json = """
        {
          "id": "meeting-123",
          "name": "Example Tax Discovery",
          "createdAt": "2026-08-20T18:00:00Z",
          "transcript": [
            {"speaker": "Ross Gates", "text": "The minimum is 100 returns.", "timestamp": 30.0},
            {"speaker": "Jamie", "text": "We file 900 returns.", "timestamp": 10.0}
          ]
        }
        """

        let meetingID = UUID()
        let segments = try CirclebackImporter().decode(
            data: Data(json.utf8),
            meetingID: meetingID
        )

        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments.first?.speaker, "Jamie")
        XCTAssertEqual(segments.first?.timestampSeconds, 10)
        XCTAssertEqual(segments.last?.speaker, "Ross Gates")
        XCTAssertTrue(segments.allSatisfy { $0.source == .circleback && $0.isFinal })
    }

    func testRejectsEmptyTranscript() {
        let json = """
        {"id":"meeting-123","name":"Empty","transcript":[]}
        """

        XCTAssertThrowsError(
            try CirclebackImporter().decode(data: Data(json.utf8), meetingID: UUID())
        )
    }
}
