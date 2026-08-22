import Foundation
import XCTest
@testable import LiveScorecard

final class RuleBasedExtractorTests: XCTestCase {
    func testIgnoresNumberInQuestion() {
        let segment = makeSegment("Do you file 800 returns?")

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertTrue(facts.isEmpty)
    }

    func testExtractsReturnVolumeAndSoftware() {
        let segment = makeSegment("We file about 1,200 tax returns and use Lacerte on desktop.")

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .totalReturns })?.value, "1,200")
        XCTAssertEqual(facts.first(where: { $0.field == .totalReturns })?.confidence, .approximate)
        XCTAssertEqual(facts.first(where: { $0.field == .primaryTaxSoftware })?.value, "Lacerte")
        XCTAssertEqual(facts.first(where: { $0.field == .taxSoftwareEnvironment })?.value, "Desktop")
    }

    func testConvertsFewHundredToApproximateTwoHundred() {
        let segment = makeSegment("We do a few hundred business returns.")

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .businessReturns })?.value, "200")
        XCTAssertEqual(facts.first(where: { $0.field == .businessReturns })?.confidence, .approximate)
    }

    func testExtractsSeparateStaffRoles() {
        let segment = makeSegment("We have 3 admins, 8 preparers, 4 reviewers, and 5 CPAs.")

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .admins })?.value, "3")
        XCTAssertEqual(facts.first(where: { $0.field == .preparers })?.value, "8")
        XCTAssertEqual(facts.first(where: { $0.field == .reviewers })?.value, "4")
        XCTAssertEqual(facts.first(where: { $0.field == .cpas })?.value, "5")
    }

    func testKeepsFirstExplicitTotalWhenBreakdownFollowsInSameSegment() {
        let segment = makeSegment(
            "We file 1,240 total returns: 980 personal returns and 260 business returns."
        )

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .totalReturns })?.value, "1,240")
        XCTAssertEqual(facts.first(where: { $0.field == .personalReturns })?.value, "980")
        XCTAssertEqual(facts.first(where: { $0.field == .businessReturns })?.value, "260")
    }

    func testExtractsNumberBeforeTotalReturnsForExplicitCorrection() {
        let segment = makeSegment(
            "Let me correct the total: it is 940 total returns, made up of 700 personal returns and 240 business returns."
        )

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .totalReturns })?.value, "940")
    }

    func testExtractsCommercialPriceWithUnitButNotDemoNumbers() {
        let price = makeSegment("The minimum is 100 returns and the price is $40 per return.")
        let demo = makeSegment("The demo is three steps and this sample has 15 documents.")

        let priceFacts = RuleBasedExtractor().extract(from: price)
        let demoFacts = RuleBasedExtractor().extract(from: demo)

        XCTAssertEqual(priceFacts.first(where: { $0.field == .annualCommitment })?.value, "100")
        XCTAssertEqual(priceFacts.first(where: { $0.field == .otherNumbers })?.value, "$40 per return")
        XCTAssertNil(demoFacts.first(where: { $0.field == .otherNumbers }))
    }

    func testSeparatesAnnualAndPilotCommitmentsFromOneStatement() {
        let segment = makeSegment(
            "There is a 250 annual commitment, but we can start with 40 between now and the end of the year, and that will convert into the full package."
        )

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .annualCommitment })?.value, "250")
        XCTAssertEqual(facts.first(where: { $0.field == .pilotCommitment })?.value, "40")
        XCTAssertEqual(facts.first(where: { $0.field == .annualCommitment })?.quote, segment.text)
        XCTAssertEqual(facts.first(where: { $0.field == .pilotCommitment })?.quote, segment.text)
    }

    func testPilotMinimumDoesNotPopulateAnnualCommitment() {
        let segment = makeSegment("The pilot minimum commitment is 40 returns.")

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertNil(facts.first(where: { $0.field == .annualCommitment }))
        XCTAssertEqual(facts.first(where: { $0.field == .pilotCommitment })?.value, "40")
    }

    func testActualCarryCallReturnFormsDoNotBecomeBreakdownCounts() {
        let segment = makeSegment(
            "I prepare like around 200 returns every year, including 1040, 1120, 1065, and all different types of taxes."
        )

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .totalReturns })?.value, "200")
        XCTAssertNil(facts.first(where: { $0.field == .personalReturns }))
        XCTAssertNil(facts.first(where: { $0.field == .businessReturns }))
    }

    func testCirclebackDiarizedParticipantIsTreatedAsProspectForSourcePolicies() {
        let segment = TranscriptSegment(
            id: UUID(),
            meetingID: UUID(),
            speaker: "Participant 1",
            source: .circleback,
            text: "I prepare around 200 returns every year.",
            timestampSeconds: 10,
            isFinal: true,
            createdAt: Date()
        )

        let candidate = RuleBasedExtractor().extract(from: segment).first {
            $0.field == .totalReturns
        }
        XCTAssertEqual(candidate?.speaker, "PROSPECT")
        let facts = FactReducer().applying(
            [candidate].compactMap { $0 },
            to: [:],
            meetingID: segment.meetingID
        )
        XCTAssertEqual(facts[.totalReturns]?.value, "200")
    }

    func testHistoricalATXDoesNotBlockCurrentDrake() {
        let historical = makeSegment("I used ATX for over 8 or 9 years.")
        let current = makeSegment("We put the return and do the data entry into Drake.")

        XCTAssertNil(
            RuleBasedExtractor().extract(from: historical)
                .first(where: { $0.field == .primaryTaxSoftware })
        )
        XCTAssertEqual(
            RuleBasedExtractor().extract(from: current)
                .first(where: { $0.field == .primaryTaxSoftware })?.value,
            "Drake"
        )
    }

    func testExtractsExplicitIdentityWithoutTurningPersonIntoFirm() {
        let segment = makeSegment("I'm Priya Shah with Redwood CPA Group, based in Portland, Oregon.")

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .name })?.value, "Priya Shah")
        XCTAssertEqual(facts.first(where: { $0.field == .firmName })?.value, "Redwood CPA Group")
    }

    func testSelectsCurrentSoftwareInsteadOfHistoricalOrEvaluatedSoftware() {
        let historical = makeSegment(
            "At my old firm we had Lacerte, but Ortiz Accounting uses ProSeries desktop now."
        )
        let evaluated = makeSegment(
            "We're evaluating Drake, but we currently use CCH Axcess hosted by Cetrom."
        )

        let historicalFacts = RuleBasedExtractor().extract(from: historical)
        let evaluatedFacts = RuleBasedExtractor().extract(from: evaluated)

        XCTAssertEqual(
            historicalFacts.first(where: { $0.field == .primaryTaxSoftware })?.value,
            "ProSeries"
        )
        XCTAssertEqual(
            evaluatedFacts.first(where: { $0.field == .primaryTaxSoftware })?.value,
            "CCH Axcess"
        )
    }

    func testReturnBreakdownWithDoesNotBecomeFirmName() {
        let segment = makeSegment(
            "We file 600 total returns, with 500 personal returns and 100 business returns."
        )

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertNil(facts.first(where: { $0.field == .firmName }))
    }

    func testExtractsExplicitPortalAndPracticeManagement() {
        let shared = makeSegment(
            "TaxDome handles our client portal and practice management."
        )
        let separate = makeSegment(
            "SmartVault is our client portal, Canopy is our practice management."
        )

        let sharedFacts = RuleBasedExtractor().extract(from: shared)
        let separateFacts = RuleBasedExtractor().extract(from: separate)

        XCTAssertEqual(sharedFacts.first(where: { $0.field == .clientPortal })?.value, "TaxDome")
        XCTAssertEqual(sharedFacts.first(where: { $0.field == .practiceManagement })?.value, "TaxDome")
        XCTAssertEqual(separateFacts.first(where: { $0.field == .clientPortal })?.value, "SmartVault")
        XCTAssertEqual(separateFacts.first(where: { $0.field == .practiceManagement })?.value, "Canopy")
    }

    func testPracticeManagementCaptureDoesNotCrossSentenceBoundary() {
        let segment = makeSegment(
            "We use Drake desktop. Canopy is practice management, and QuickBooks Online is another tool."
        )

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .practiceManagement })?.value, "Canopy")
    }

    func testTotalBreakdownAfterColonCannotReplaceExplicitTotal() {
        let segment = makeSegment(
            "Harbor Ledger expects 75 total returns: 60 personal returns and 15 business returns."
        )

        let facts = RuleBasedExtractor().extract(from: segment)

        XCTAssertEqual(facts.first(where: { $0.field == .totalReturns })?.value, "75")
    }

    func testContextualExtractorCapturesShortLocationOnFirstAnswer() {
        let meetingID = UUID()
        let question = TranscriptSegment(
            id: UUID(), meetingID: meetingID, speaker: "ROSS", source: .microphone,
            text: "Where are you calling in from?", timestampSeconds: 1, isFinal: true, createdAt: Date()
        )
        let answer = TranscriptSegment(
            id: UUID(), meetingID: meetingID, speaker: "PROSPECT", source: .meetingAudio,
            text: "Fresno, California.", timestampSeconds: 2, isFinal: true, createdAt: Date()
        )

        let facts = ContextualRuleExtractor().extract(from: [question, answer])

        XCTAssertEqual(facts.first(where: { $0.field == .location })?.value, "Fresno, California")
    }

    func testContextualExtractorCapturesTwoPartIdentityAnswer() {
        let meetingID = UUID()
        let question = TranscriptSegment(
            id: UUID(), meetingID: meetingID, speaker: "ROSS", source: .microphone,
            text: "What is your name and practice name?", timestampSeconds: 1, isFinal: true, createdAt: Date()
        )
        let answer = TranscriptSegment(
            id: UUID(), meetingID: meetingID, speaker: "PROSPECT", source: .meetingAudio,
            text: "Elena Brooks. Brooks Tax Lab.", timestampSeconds: 2, isFinal: true, createdAt: Date()
        )

        let facts = ContextualRuleExtractor().extract(from: [question, answer])

        XCTAssertEqual(facts.first(where: { $0.field == .name })?.value, "Elena Brooks")
        XCTAssertEqual(facts.first(where: { $0.field == .firmName })?.value, "Brooks Tax Lab")
    }

    func testContextualExtractorCapturesLabeledShortReturnFragments() {
        let meetingID = UUID()
        let question = TranscriptSegment(
            id: UUID(), meetingID: meetingID, speaker: "ROSS", source: .microphone,
            text: "How many total returns, personal returns, and business returns do you file?",
            timestampSeconds: 1, isFinal: true, createdAt: Date()
        )
        let answer = TranscriptSegment(
            id: UUID(), meetingID: meetingID, speaker: "PROSPECT", source: .meetingAudio,
            text: "About 800 total. 650 personal. 150 business.",
            timestampSeconds: 2, isFinal: true, createdAt: Date()
        )

        let facts = ContextualRuleExtractor().extract(from: [question, answer])

        XCTAssertEqual(facts.first(where: { $0.field == .totalReturns })?.value, "800")
        XCTAssertEqual(facts.first(where: { $0.field == .totalReturns })?.confidence, .approximate)
        XCTAssertEqual(facts.first(where: { $0.field == .personalReturns })?.value, "650")
        XCTAssertEqual(facts.first(where: { $0.field == .businessReturns })?.value, "150")
    }

    private func makeSegment(_ text: String) -> TranscriptSegment {
        TranscriptSegment(
            id: UUID(),
            meetingID: UUID(),
            speaker: "PROSPECT",
            source: .meetingAudio,
            text: text,
            timestampSeconds: 10,
            isFinal: true,
            createdAt: Date()
        )
    }
}
