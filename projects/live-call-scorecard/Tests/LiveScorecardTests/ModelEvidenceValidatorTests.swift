import Foundation
import XCTest
@testable import LiveScorecard

final class ModelEvidenceValidatorTests: XCTestCase {
    func testRejectsHallucinatedValueEvenWhenQuoteIsReal() {
        let segments = [segment("It's just three steps.", at: 10)]

        let result = ModelEvidenceValidator.validate(
            field: .otherNumbers,
            value: "800-1,000",
            quote: "It's just three steps.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertFalse(result.isAccepted)
        XCTAssertEqual(result.ruleID, ExtractionRuleCatalog.literalValueEvidence)
    }

    func testRejectsUnknownPlaceholderAndLeavesFieldBlank() {
        let segments = [segment("Hey, David.", at: 10)]

        let result = ModelEvidenceValidator.validate(
            field: .location,
            value: "Unknown",
            quote: "Hey, David.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertFalse(result.isAccepted)
        XCTAssertEqual(result.ruleID, ExtractionRuleCatalog.rejectPlaceholder)
    }

    func testGreetingMapsPersonToNameNotFirm() {
        let segments = [segment("Hey, David.", at: 10)]

        let name = ModelEvidenceValidator.validate(
            field: .name,
            value: "David",
            quote: "Hey, David.",
            in: segments,
            minimumCharacters: 2
        )
        let firm = ModelEvidenceValidator.validate(
            field: .firmName,
            value: "David",
            quote: "Hey, David.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertTrue(name.isAccepted)
        XCTAssertFalse(firm.isAccepted)
        XCTAssertEqual(firm.ruleID, ExtractionRuleCatalog.fieldContextEvidence)
    }

    func testShortLocationAnswerUsesNearestLocationQuestion() {
        let segments = [
            segment("Where are you guys calling in from?", at: 10),
            segment("Phoenix.", at: 12)
        ]

        let result = ModelEvidenceValidator.validate(
            field: .location,
            value: "Phoenix",
            quote: "Phoenix.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertTrue(result.isAccepted)
    }

    func testShortSoftwareAnswerUsesNearestSoftwareQuestion() {
        let segments = [
            segment("What do you use for software?", at: 10),
            segment("Drake.", at: 12)
        ]

        let result = ModelEvidenceValidator.validate(
            field: .primaryTaxSoftware,
            value: "Drake",
            quote: "Drake.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertTrue(result.isAccepted)
    }

    func testClosestQuestionWinsOverOlderIdentityQuestion() {
        let segments = [
            segment("What is your name?", at: 5),
            segment("Daniel Ortiz.", at: 7),
            segment("Where are you calling in from?", at: 10),
            segment("Fresno, California.", at: 12)
        ]

        let result = ModelEvidenceValidator.validate(
            field: .location,
            value: "Fresno, California",
            quote: "Fresno, California.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertTrue(result.isAccepted)
    }

    func testTeamQuestionCannotPopulateFirmName() {
        let segments = [
            segment("How many people are on your team?", at: 10),
            segment("Smith Tax.", at: 12)
        ]

        let result = ModelEvidenceValidator.validate(
            field: .firmName,
            value: "Smith Tax",
            quote: "Smith Tax.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertFalse(result.isAccepted)
        XCTAssertEqual(result.ruleID, ExtractionRuleCatalog.fieldContextEvidence)
    }

    func testPriorEmployerWorkloadIsNotCurrentFirmReturnVolume() {
        let quote = "At Deloitte we each worked on around 250 returns, but those are not Harbor Ledger clients."
        let segments = [segment(quote, at: 10)]

        let result = ModelEvidenceValidator.validate(
            field: .totalReturns,
            value: "250",
            quote: "At Deloitte we each worked on around 250 returns",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertFalse(result.isAccepted)
        XCTAssertEqual(result.ruleID, ExtractionRuleCatalog.fieldContextEvidence)
    }

    func testPrimarySoftwareCanonicalizerRemovesEnvironmentSuffix() {
        XCTAssertEqual(
            ExtractionValueCanonicalizer.modelValue("Drake desktop", for: .primaryTaxSoftware),
            "Drake"
        )
    }

    func testInventedPlausibleSentenceIsRejectedAsAbsentQuote() {
        let segments = [segment("Hey, David.", at: 10)]

        let result = ModelEvidenceValidator.validate(
            field: .totalReturns,
            value: "1,000",
            quote: "We're working with a total of 1,000 returns.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertFalse(result.isAccepted)
        XCTAssertEqual(result.ruleID, ExtractionRuleCatalog.exactQuoteEvidence)
    }

    func testAllSupportingSoftwareValuesMustAppearInQuote() {
        let segments = [
            segment("What other software do you use?", at: 10),
            segment("QuickBooks Online and SurePrep.", at: 12)
        ]

        let accepted = ModelEvidenceValidator.validate(
            field: .supportingSoftware,
            value: "QuickBooks Online, SurePrep",
            quote: "QuickBooks Online and SurePrep.",
            in: segments,
            minimumCharacters: 2
        )
        let rejected = ModelEvidenceValidator.validate(
            field: .supportingSoftware,
            value: "QuickBooks Online, SurePrep, GruntWorx",
            quote: "QuickBooks Online and SurePrep.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertTrue(accepted.isAccepted)
        XCTAssertFalse(rejected.isAccepted)
        XCTAssertEqual(rejected.ruleID, ExtractionRuleCatalog.literalValueEvidence)
    }

    func testAnnualAndPilotValuesUseSeparateContextInSameQuote() {
        let quote = "There is a 250 annual commitment, but we can start with 40 through year end."
        let segments = [segment(quote, at: 10)]

        let annual = ModelEvidenceValidator.validate(
            field: .annualCommitment,
            value: "250",
            quote: quote,
            in: segments,
            minimumCharacters: 2
        )
        let pilot = ModelEvidenceValidator.validate(
            field: .pilotCommitment,
            value: "40",
            quote: quote,
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertTrue(annual.isAccepted)
        XCTAssertTrue(pilot.isAccepted)
    }

    func testTaxFormIdentifiersAreNotAcceptedAsReturnCounts() {
        let quote = "I prepare around 200 returns every year, including 1040, 1120, and 1065."
        let segments = [segment(quote, at: 10)]

        let total = ModelEvidenceValidator.validate(
            field: .totalReturns,
            value: "200",
            quote: quote,
            in: segments,
            minimumCharacters: 2
        )
        let personalForm = ModelEvidenceValidator.validate(
            field: .personalReturns,
            value: "1040",
            quote: quote,
            in: segments,
            minimumCharacters: 2
        )
        let businessForm = ModelEvidenceValidator.validate(
            field: .businessReturns,
            value: "1120",
            quote: quote,
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertTrue(total.isAccepted)
        XCTAssertFalse(personalForm.isAccepted)
        XCTAssertFalse(businessForm.isAccepted)
    }

    func testProspectEchoOfRossLocationDoesNotSetProspectLocation() {
        let segments = [
            segment("Where are you calling in from?", at: 10, source: .microphone),
            segment("I'm in California.", at: 20, source: .microphone),
            segment("Oh, California.", at: 22, source: .meetingAudio)
        ]

        let result = ModelEvidenceValidator.validate(
            field: .location,
            value: "California",
            quote: "Oh, California.",
            in: segments,
            minimumCharacters: 2
        )

        XCTAssertFalse(result.isAccepted)
    }

    func testSingleIntegerCanonicalizerRemovesThousandsSeparatorAndRejectsListsAndRanges() {
        XCTAssertEqual(ExtractionValueCanonicalizer.singleInteger("1,250"), "1250")
        XCTAssertEqual(ExtractionValueCanonicalizer.singleInteger("around 200"), "200")
        XCTAssertNil(ExtractionValueCanonicalizer.singleInteger("1040,1120,1065"))
        XCTAssertNil(ExtractionValueCanonicalizer.singleInteger("800-1000"))
    }

    private func segment(
        _ text: String,
        at timestamp: Double,
        source: SpeakerSource = .meetingAudio
    ) -> TranscriptSegment {
        TranscriptSegment(
            id: UUID(),
            meetingID: UUID(),
            speaker: source.label,
            source: source,
            text: text,
            timestampSeconds: timestamp,
            isFinal: true,
            createdAt: Date()
        )
    }
}
