import Foundation
import XCTest
@testable import LiveScorecard

final class DatabaseTests: XCTestCase {
    func testPersistsMeetingSegmentAndFact() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("live-scorecard-tests")
            .appendingPathComponent("\(UUID().uuidString).sqlite3")
        let database = try ScorecardDatabase(url: url)
        let meeting = MeetingRecord(
            id: UUID(),
            title: "Test Meeting",
            firmName: "Example Tax",
            startedAt: Date(),
            endedAt: nil
        )
        try database.createMeeting(meeting)

        let segment = TranscriptSegment(
            id: UUID(),
            meetingID: meeting.id,
            speaker: "PROSPECT",
            source: .meetingAudio,
            text: "We file 900 returns.",
            timestampSeconds: 12,
            isFinal: true,
            createdAt: Date()
        )
        try database.saveSegment(segment)

        let fact = ScorecardFact(
            meetingID: meeting.id,
            field: .totalReturns,
            value: "900",
            quote: segment.text,
            speaker: segment.speaker,
            timestampSeconds: segment.timestampSeconds,
            confidence: .exact,
            effectiveAt: Date(),
            updatedAt: Date(),
            isPrior: false
        )
        try database.upsertFact(fact)

        let loaded = try database.loadFacts(meetingID: meeting.id)

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.field, .totalReturns)
        XCTAssertEqual(loaded.first?.value, "900")
        XCTAssertEqual(loaded.first?.quote, "We file 900 returns.")
    }

    func testCorrectionReplacesCurrentFactInsteadOfCreatingHistory() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("live-scorecard-tests")
            .appendingPathComponent("\(UUID().uuidString).sqlite3")
        let database = try ScorecardDatabase(url: url)
        let meeting = MeetingRecord(id: UUID(), title: "Test", firmName: nil, startedAt: Date(), endedAt: nil)
        try database.createMeeting(meeting)

        var fact = ScorecardFact(
            meetingID: meeting.id,
            field: .totalReturns,
            value: "800",
            quote: "We do 800.",
            speaker: "PROSPECT",
            timestampSeconds: 1,
            confidence: .exact,
            effectiveAt: Date(),
            updatedAt: Date(),
            isPrior: false
        )
        try database.upsertFact(fact)
        fact.value = "900"
        fact.quote = "Actually, 900."
        try database.upsertFact(fact)

        let loaded = try database.loadFacts(meetingID: meeting.id)

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.value, "900")
        XCTAssertEqual(loaded.first?.quote, "Actually, 900.")
    }

    func testPriorFactsAreIsolatedByProspectIdentity() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("live-scorecard-tests")
            .appendingPathComponent("\(UUID().uuidString).sqlite3")
        let database = try ScorecardDatabase(url: url)

        let northwind = MeetingRecord(
            id: UUID(),
            title: "Northwind",
            firmName: "Northwind Tax",
            prospectIdentityKey: "domain:northwindtax.com",
            prospectDisplayName: "northwindtax.com",
            prospectEmail: "owner@northwindtax.com",
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 200)
        )
        let contoso = MeetingRecord(
            id: UUID(),
            title: "Contoso",
            firmName: "Northwind Tax",
            prospectIdentityKey: "domain:contoso.com",
            prospectDisplayName: "contoso.com",
            prospectEmail: "owner@contoso.com",
            startedAt: Date(timeIntervalSince1970: 300),
            endedAt: Date(timeIntervalSince1970: 400)
        )
        let nextNorthwind = MeetingRecord(
            id: UUID(),
            title: "Northwind follow-up",
            firmName: nil,
            prospectIdentityKey: "domain:northwindtax.com",
            prospectDisplayName: "northwindtax.com",
            prospectEmail: "owner@northwindtax.com",
            startedAt: Date(timeIntervalSince1970: 500),
            endedAt: nil
        )

        for meeting in [northwind, contoso, nextNorthwind] {
            try database.createMeeting(meeting)
        }
        try database.upsertFact(makeFact(meetingID: northwind.id, value: "800"))
        try database.upsertFact(makeFact(meetingID: contoso.id, value: "2,000"))

        let prior = try database.loadPriorFacts(
            prospectIdentityKey: "domain:northwindtax.com",
            excluding: nextNorthwind.id
        )

        XCTAssertEqual(prior.count, 1)
        XCTAssertEqual(prior.first?.value, "800")
        XCTAssertTrue(prior.first?.isPrior == true)
        XCTAssertEqual(prior.first?.confidence, .prior)
        XCTAssertEqual(prior.first?.timestampSeconds, 0)
    }

    func testProspectFieldLocksPersistByIdentity() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("live-scorecard-tests")
            .appendingPathComponent("\(UUID().uuidString).sqlite3")
        let database = try ScorecardDatabase(url: url)
        let identity = ProspectIdentity(
            key: "domain:northwindtax.com",
            displayName: "northwindtax.com",
            primaryEmail: "owner@northwindtax.com",
            organizationDomain: "northwindtax.com"
        )
        try database.upsertProspect(identity)

        try database.setProspectFieldLock(
            prospectIdentityKey: identity.key,
            field: .totalReturns,
            isLocked: true
        )
        try database.setProspectFieldLock(
            prospectIdentityKey: identity.key,
            field: .primaryTaxSoftware,
            isLocked: true
        )

        XCTAssertEqual(
            try database.loadProspectFieldLocks(prospectIdentityKey: identity.key),
            [.totalReturns, .primaryTaxSoftware]
        )

        try database.setProspectFieldLock(
            prospectIdentityKey: identity.key,
            field: .totalReturns,
            isLocked: false
        )
        XCTAssertEqual(
            try database.loadProspectFieldLocks(prospectIdentityKey: identity.key),
            [.primaryTaxSoftware]
        )
    }

    func testExtractionDecisionsPersistChronologicallyWithEvidence() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("live-scorecard-tests")
            .appendingPathComponent("\(UUID().uuidString).sqlite3")
        let database = try ScorecardDatabase(url: url)
        let meeting = MeetingRecord(id: UUID(), title: "Trace Test", firmName: nil, startedAt: Date(), endedAt: nil)
        try database.createMeeting(meeting)

        let later = ExtractionDecision(
            recordedAt: Date(timeIntervalSince1970: 200),
            meetingID: meeting.id,
            ruleID: ExtractionRuleCatalog.rejectOlder,
            stage: .replacement,
            outcome: .rejected,
            field: .totalReturns,
            proposedValue: "700",
            previousValue: "800",
            reason: "Older evidence cannot replace the saved value.",
            quote: "Years ago it was 700.",
            speaker: "PROSPECT",
            transcriptTimestamp: 44
        )
        let earlier = ExtractionDecision(
            recordedAt: Date(timeIntervalSince1970: 100),
            meetingID: meeting.id,
            ruleID: ExtractionRuleCatalog.returnVolume,
            stage: .deterministic,
            outcome: .accepted,
            field: .totalReturns,
            proposedValue: "800",
            reason: "Matched an explicit annual return count.",
            quote: "We file 800 returns.",
            speaker: "PROSPECT",
            transcriptTimestamp: 12
        )
        try database.saveExtractionDecision(later)
        try database.saveExtractionDecision(earlier)

        let loaded = try database.loadExtractionDecisions(meetingID: meeting.id)
        XCTAssertEqual(loaded, [earlier, later])
    }

    func testEvaluationExporterWritesOrderedFactsAndCompleteTrace() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("live-scorecard-export-tests")
            .appendingPathComponent(UUID().uuidString)
        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let meeting = MeetingRecord(
            id: UUID(),
            title: "Ross / Example: Discovery",
            firmName: "Example Tax",
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(60)
        )
        let fact = makeFact(meetingID: meeting.id, value: "800")
        let decision = ExtractionDecision(
            meetingID: meeting.id,
            ruleID: ExtractionRuleCatalog.returnVolume,
            stage: .deterministic,
            outcome: .accepted,
            field: .totalReturns,
            proposedValue: "800",
            reason: "Matched an explicit annual return count.",
            quote: "We file 800 returns.",
            speaker: "PROSPECT",
            transcriptTimestamp: 10
        )

        let result = try EvaluationExporter.export(
            meeting: meeting,
            facts: [fact],
            decisions: [decision],
            databaseURL: directory.appendingPathComponent("scorecard.sqlite3"),
            destinationDirectory: directory
        )
        let output = try String(contentsOf: result, encoding: .utf8)

        XCTAssertTrue(result.lastPathComponent.contains("Ross - Example- Discovery"))
        XCTAssertTrue(output.contains("| TOTAL RETURNS | 800 | EXACT | PROSPECT | 00:10 | We file 800 returns. |"))
        XCTAssertTrue(output.contains("Total decisions: 1"))
        XCTAssertTrue(output.contains("ACCEPTED · PATTERN · \(ExtractionRuleCatalog.returnVolume)"))
        XCTAssertTrue(output.contains("- Exact evidence: `We file 800 returns.`"))
        XCTAssertLessThan(
            output.range(of: "| FIRM |")!.lowerBound,
            output.range(of: "| TOTAL RETURNS |")!.lowerBound
        )
    }

    private func makeFact(meetingID: UUID, value: String) -> ScorecardFact {
        ScorecardFact(
            meetingID: meetingID,
            field: .totalReturns,
            value: value,
            quote: "We file \(value) returns.",
            speaker: "PROSPECT",
            timestampSeconds: 10,
            confidence: .exact,
            effectiveAt: Date(),
            updatedAt: Date(),
            isPrior: false
        )
    }
}
