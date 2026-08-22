import Foundation
import XCTest
@testable import LiveScorecard

final class FactReducerTests: XCTestCase {
    func testCalculatesTotalFromPersonalAndBusiness() {
        let meetingID = UUID()
        let candidates = [
            FactCandidate(
                field: .personalReturns,
                value: "800",
                quote: "We do 800 personal returns.",
                speaker: "PROSPECT",
                timestampSeconds: 10,
                confidence: .exact
            ),
            FactCandidate(
                field: .businessReturns,
                value: "200",
                quote: "We do 200 business returns.",
                speaker: "PROSPECT",
                timestampSeconds: 15,
                confidence: .exact
            )
        ]

        let facts = FactReducer().applying(candidates, to: [:], meetingID: meetingID)

        XCTAssertEqual(facts[.totalReturns]?.value, "1000")
        XCTAssertEqual(facts[.totalReturns]?.confidence, .inferred)
    }

    func testDirectTotalIsNotOverwrittenByCalculatedTotal() {
        let meetingID = UUID()
        let candidates = [
            FactCandidate(field: .totalReturns, value: "1,250", quote: "We do 1,250 total.", speaker: "PROSPECT", timestampSeconds: 1, confidence: .exact),
            FactCandidate(field: .personalReturns, value: "800", quote: "800 personal.", speaker: "PROSPECT", timestampSeconds: 2, confidence: .exact),
            FactCandidate(field: .businessReturns, value: "200", quote: "200 business.", speaker: "PROSPECT", timestampSeconds: 3, confidence: .exact)
        ]

        let facts = FactReducer().applying(candidates, to: [:], meetingID: meetingID)

        XCTAssertEqual(facts[.totalReturns]?.value, "1250")
        XCTAssertEqual(facts[.totalReturns]?.confidence, .exact)
    }

    func testLocationAddsTimezone() {
        let candidate = FactCandidate(
            field: .location,
            value: "Austin, TX",
            quote: "We're based in Austin, Texas.",
            speaker: "PROSPECT",
            timestampSeconds: 20,
            confidence: .exact
        )

        let facts = FactReducer().applying([candidate], to: [:], meetingID: UUID())

        XCTAssertEqual(facts[.timezone]?.value, "America/Chicago")
        XCTAssertEqual(facts[.timezone]?.confidence, .inferred)
    }

    func testSupportingSoftwareMergesWithoutDuplicates() {
        let meetingID = UUID()
        let reducer = FactReducer()
        let first = FactCandidate(field: .supportingSoftware, value: "TaxDome", quote: "TaxDome", speaker: "PROSPECT", timestampSeconds: 1, confidence: .exact)
        let second = FactCandidate(field: .supportingSoftware, value: "taxdome, QuickBooks", quote: "QuickBooks", speaker: "PROSPECT", timestampSeconds: 2, confidence: .exact)

        let once = reducer.applying([first], to: [:], meetingID: meetingID)
        let twice = reducer.applying([second], to: once, meetingID: meetingID)

        XCTAssertEqual(twice[.supportingSoftware]?.value, "TaxDome, QuickBooks")
    }

    func testSupportingSoftwareRemovesConjunctionsBeforeDeduplicating() {
        let meetingID = UUID()
        let candidate = FactCandidate(
            field: .supportingSoftware,
            value: "QuickBooks Online, SurePrep, and GruntWorx, GruntWorx",
            quote: "QuickBooks Online, SurePrep, and GruntWorx.",
            speaker: "PROSPECT",
            timestampSeconds: 1,
            confidence: .exact
        )

        let facts = FactReducer().applying([candidate], to: [:], meetingID: meetingID)

        XCTAssertEqual(facts[.supportingSoftware]?.value, "QuickBooks Online, SurePrep, GruntWorx")
    }

    func testEnvironmentIsCanonicalAndRejectsMultipleCategories() {
        let meetingID = UUID()
        let desktop = FactCandidate(
            field: .taxSoftwareEnvironment,
            value: "desktop",
            quote: "We use UltraTax on desktop.",
            speaker: "PROSPECT",
            timestampSeconds: 1,
            confidence: .exact
        )
        let invalid = FactCandidate(
            field: .taxSoftwareEnvironment,
            value: "desktop, hosted",
            quote: "We use UltraTax on desktop, hosted by Rightworks.",
            speaker: "PROSPECT",
            timestampSeconds: 2,
            confidence: .exact
        )

        let first = FactReducer().applying([desktop], to: [:], meetingID: meetingID)
        let second = FactReducer().applying([invalid], to: first, meetingID: meetingID)

        XCTAssertEqual(first[.taxSoftwareEnvironment]?.value, "Desktop")
        XCTAssertEqual(second[.taxSoftwareEnvironment]?.value, "Desktop")
    }

    func testSupportingSoftwareDropsGenericQuickBooksWhenOnlineIsPresent() {
        let candidate = FactCandidate(
            field: .supportingSoftware,
            value: "QuickBooks Online, QuickBooks",
            quote: "QuickBooks Online is the supporting software we use.",
            speaker: "PROSPECT",
            timestampSeconds: 1,
            confidence: .exact
        )

        let facts = FactReducer().applying([candidate], to: [:], meetingID: UUID())

        XCTAssertEqual(facts[.supportingSoftware]?.value, "QuickBooks Online")
    }

    func testFieldSpeakerPolicyRejectsRossForProspectFactAndAllowsManualCorrection() {
        let meetingID = UUID()
        let rossLocation = FactCandidate(
            field: .location,
            value: "California",
            quote: "I'm in California.",
            speaker: "ROSS",
            timestampSeconds: 10,
            confidence: .exact
        )

        let rejected = FactReducer().applying([rossLocation], to: [:], meetingID: meetingID)
        let manual = FactReducer().manualFact(
            field: .location,
            value: "New Jersey",
            meetingID: meetingID
        )!
        let accepted = FactReducer().applying([
            FactCandidate(
                field: .location,
                value: manual.value,
                quote: manual.quote,
                speaker: manual.speaker,
                timestampSeconds: 0,
                confidence: .manual
            )
        ], to: rejected, meetingID: meetingID)

        XCTAssertNil(rejected[.location])
        XCTAssertEqual(accepted[.location]?.value, "New Jersey")
    }

    func testRejectsMultipleNumbersInsteadOfConcatenatingThem() {
        let candidate = FactCandidate(
            field: .businessReturns,
            value: "1040,1120,1065",
            quote: "Around 200 returns including 1040, 1120, and 1065.",
            speaker: "PROSPECT",
            timestampSeconds: 10,
            confidence: .exact
        )

        let facts = FactReducer().applying([candidate], to: [:], meetingID: UUID())

        XCTAssertNil(facts[.businessReturns])
    }
}
