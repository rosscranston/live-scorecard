import Foundation
import XCTest
@testable import LiveScorecard

final class CallHistoryDatabaseTests: XCTestCase {
    func testHistoryIsNewestFirstAndSearchesNamesTranscriptAndFacts() throws {
        let database = try makeDatabase()
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let older = MeetingRecord(
            id: UUID(),
            title: "Discovery Call",
            firmName: "Meredith Tax Group",
            startedAt: base,
            endedAt: base.addingTimeInterval(600)
        )
        let newer = MeetingRecord(
            id: UUID(),
            title: "100% Tax Follow Up",
            firmName: "Northwind Accounting",
            prospectIdentityKey: "domain:northwindtax.com",
            prospectDisplayName: "northwindtax.com",
            prospectEmail: "owner@northwindtax.com",
            startedAt: base.addingTimeInterval(3_600),
            endedAt: base.addingTimeInterval(4_200)
        )
        try database.createMeeting(older)
        try database.createMeeting(newer)
        try database.endMeeting(id: older.id, at: older.endedAt!)
        try database.endMeeting(id: newer.id, at: newer.endedAt!)

        let segment = TranscriptSegment(
            id: UUID(),
            meetingID: older.id,
            speaker: "PROSPECT",
            source: .meetingAudio,
            text: "We prepare everything in UltraTax.",
            timestampSeconds: 8,
            isFinal: true,
            createdAt: base.addingTimeInterval(8)
        )
        try database.saveSegment(segment)
        try database.upsertFact(ScorecardFact(
            meetingID: newer.id,
            field: .totalReturns,
            value: "1,250",
            quote: "We complete twelve hundred fifty returns.",
            speaker: "PROSPECT",
            timestampSeconds: 12,
            confidence: .exact,
            effectiveAt: base,
            updatedAt: base,
            isPrior: false
        ))

        let completeHistory = try database.loadCallHistory()
        XCTAssertEqual(completeHistory.map(\.id), [newer.id, older.id])
        XCTAssertEqual(completeHistory.first(where: { $0.id == older.id })?.transcriptSegmentCount, 1)
        XCTAssertEqual(completeHistory.first(where: { $0.id == older.id })?.transcriptPreview, segment.text)
        XCTAssertEqual(completeHistory.first(where: { $0.id == newer.id })?.factCount, 1)
        XCTAssertEqual(try database.loadCallHistory(search: "meredith").map(\.id), [older.id])
        XCTAssertEqual(try database.loadCallHistory(search: "ULTRATAX").map(\.id), [older.id])
        XCTAssertEqual(try database.loadCallHistory(search: "meredith ultratax").map(\.id), [older.id])
        XCTAssertEqual(try database.loadCallHistory(search: "twelve fifty").map(\.id), [newer.id])
        XCTAssertEqual(try database.loadCallHistory(search: "100%").map(\.id), [newer.id])
        XCTAssertEqual(try database.loadCallHistory(search: "owner@northwindtax.com").map(\.id), [newer.id])
        XCTAssertEqual(completeHistory.first?.prospectDisplayName, "northwindtax.com")
    }

    func testDetailLoadsCompleteTranscriptChronologicallyAndFactsInDisplayOrder() throws {
        let database = try makeDatabase()
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let meeting = MeetingRecord(
            id: UUID(),
            title: "Detail Test",
            firmName: nil,
            startedAt: base,
            endedAt: base.addingTimeInterval(120)
        )
        try database.createMeeting(meeting)
        try database.endMeeting(id: meeting.id, at: try XCTUnwrap(meeting.endedAt))

        let later = TranscriptSegment(
            id: UUID(),
            meetingID: meeting.id,
            speaker: "ROSS",
            source: .microphone,
            text: "Later segment",
            timestampSeconds: 20,
            isFinal: true,
            createdAt: base.addingTimeInterval(20)
        )
        let earlier = TranscriptSegment(
            id: UUID(),
            meetingID: meeting.id,
            speaker: "PROSPECT",
            source: .meetingAudio,
            text: "Earlier segment",
            timestampSeconds: 5,
            isFinal: true,
            createdAt: base.addingTimeInterval(5)
        )
        try database.saveSegment(later)
        try database.saveSegment(earlier)

        for (field, value) in [(ScorecardField.cpas, "2"), (.firmName, "Detail Tax")] {
            try database.upsertFact(ScorecardFact(
                meetingID: meeting.id,
                field: field,
                value: value,
                quote: "Source quote for \(value)",
                speaker: "PROSPECT",
                timestampSeconds: 5,
                confidence: .exact,
                effectiveAt: base,
                updatedAt: base,
                isPrior: false
            ))
        }

        let detail = try XCTUnwrap(database.loadCallHistoryDetail(meetingID: meeting.id))
        XCTAssertEqual(detail.meeting, meeting)
        XCTAssertEqual(detail.transcriptSegments.map(\.text), ["Earlier segment", "Later segment"])
        XCTAssertEqual(detail.facts.map(\.field), [.firmName, .cpas])
        XCTAssertEqual(detail.facts.map(\.quote), ["Source quote for Detail Tax", "Source quote for 2"])
        XCTAssertNil(try database.loadCallHistoryDetail(meetingID: UUID()))
    }

    func testPostCallTrainingLabelsPreserveOriginalValueAcrossCorrections() throws {
        let database = try makeDatabase()
        let meeting = MeetingRecord(
            id: UUID(),
            title: "Carry call",
            firmName: nil,
            startedAt: Date(),
            endedAt: Date()
        )
        try database.createMeeting(meeting)

        try database.saveTrainingLabel(
            meetingID: meeting.id,
            field: .name,
            originalValue: "Gary",
            correctedValue: "Carry"
        )
        try database.saveTrainingLabel(
            meetingID: meeting.id,
            field: .name,
            originalValue: "Carry",
            correctedValue: "Carry Jones"
        )

        let label = try XCTUnwrap(database.loadTrainingLabels(meetingID: meeting.id).first)
        XCTAssertEqual(label.originalValue, "Gary")
        XCTAssertEqual(label.correctedValue, "Carry Jones")
    }

    func testMeetingCanBeTiedToExactEmailAfterCall() throws {
        let database = try makeDatabase()
        let meeting = MeetingRecord(
            id: UUID(),
            title: "Identity call",
            firmName: nil,
            startedAt: Date(),
            endedAt: Date()
        )
        try database.createMeeting(meeting)
        let identity = try XCTUnwrap(CalendarProspectResolver.identity(
            email: "carry@greenfieldtax.com",
            displayName: "Carry"
        ))

        try database.updateMeetingIdentity(id: meeting.id, identity: identity)

        let updated = try XCTUnwrap(database.loadCallHistoryDetail(meetingID: meeting.id)?.meeting)
        XCTAssertEqual(updated.prospectIdentityKey, "email:carry@greenfieldtax.com")
        XCTAssertEqual(updated.prospectDisplayName, "Carry")
        XCTAssertEqual(updated.prospectEmail, "carry@greenfieldtax.com")
    }

    private func makeDatabase() throws -> ScorecardDatabase {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("live-scorecard-history-tests")
            .appendingPathComponent("\(UUID().uuidString).sqlite3")
        return try ScorecardDatabase(url: url)
    }
}
