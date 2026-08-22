import Foundation
import XCTest
@testable import LiveScorecard

final class ExtractionAdminTests: XCTestCase {
    func testRuleCatalogIsOrderedAndKeepsSafetyRulesUntunable() {
        let rules = ExtractionRuleCatalog.ordered

        XCTAssertEqual(rules.map(\.order), rules.map(\.order).sorted())
        XCTAssertFalse(rules.first(where: { $0.id == ExtractionRuleCatalog.questionEvidence })!.isTunable)
        XCTAssertFalse(rules.first(where: { $0.id == ExtractionRuleCatalog.protectManual })!.isTunable)
        XCTAssertTrue(rules.first(where: { $0.id == ExtractionRuleCatalog.returnVolume })!.isTunable)
    }

    func testConfigurationPersistsAndClampsUnsafeBounds() throws {
        let defaults = try makeDefaults()
        let key = "test.extraction.configuration"
        let repository = ExtractionAdminRepository(defaults: defaults, configurationKey: key)
        var configuration = repository.configuration
        configuration.responseTokenReserve = 10_000
        configuration.minimumEvidenceQuoteCharacters = 0
        configuration.disabledRuleIDs = [
            ExtractionRuleCatalog.knownTaxSoftware,
            ExtractionRuleCatalog.questionEvidence
        ]

        repository.updateConfiguration(configuration)
        let reloaded = ExtractionAdminRepository(defaults: defaults, configurationKey: key)

        XCTAssertEqual(reloaded.configuration.responseTokenReserve, 1_536)
        XCTAssertEqual(reloaded.configuration.minimumEvidenceQuoteCharacters, 2)
        XCTAssertTrue(reloaded.configuration.disabledRuleIDs.contains(ExtractionRuleCatalog.knownTaxSoftware))
        XCTAssertFalse(reloaded.configuration.disabledRuleIDs.contains(ExtractionRuleCatalog.questionEvidence))
    }

    func testEditableVocabularyCustomInstructionsAndFieldPoliciesPersist() throws {
        let defaults = try makeDefaults()
        let key = "test.extraction.configuration.v2"
        let repository = ExtractionAdminRepository(defaults: defaults, configurationKey: key)
        var configuration = repository.configuration
        configuration.primaryTaxSoftwareCSV = "TaxShark, CustomTax, taxshark"
        configuration.supportingSoftwareCSV = "LedgerLink, DocFlow"
        configuration.customModelInstructions = "Treat an explicitly stated annual count as current."
        configuration.microphoneActsAsProspectForTesting = true
        configuration.setSourcePolicy(.rossOnly, for: .annualCommitment)
        configuration.setReplacementPolicy(.keepExisting, for: .primaryTaxSoftware)

        repository.updateConfiguration(configuration)
        let reloaded = ExtractionAdminRepository(defaults: defaults, configurationKey: key)

        XCTAssertEqual(reloaded.configuration.primaryTaxSoftwareNames, ["TaxShark", "CustomTax"])
        XCTAssertEqual(reloaded.configuration.supportingSoftwareNames, ["LedgerLink", "DocFlow"])
        XCTAssertEqual(
            reloaded.configuration.customModelInstructions,
            "Treat an explicitly stated annual count as current."
        )
        XCTAssertEqual(reloaded.configuration.replacementPolicy(for: .primaryTaxSoftware), .keepExisting)
        XCTAssertEqual(reloaded.configuration.replacementPolicy(for: .name), .confirmationRequired)
        XCTAssertEqual(reloaded.configuration.replacementPolicy(for: .totalReturns), .confirmationRequired)
        XCTAssertEqual(reloaded.configuration.replacementPolicy(for: .annualCommitment), .confirmationRequired)
        XCTAssertEqual(reloaded.configuration.replacementPolicy(for: .pilotCommitment), .confirmationRequired)
        XCTAssertTrue(reloaded.configuration.microphoneActsAsProspectForTesting)
        XCTAssertEqual(reloaded.configuration.sourcePolicy(for: .location), .prospectOnly)
        XCTAssertEqual(reloaded.configuration.sourcePolicy(for: .annualCommitment), .rossOnly)
        XCTAssertEqual(reloaded.configuration.sourcePolicy(for: .notes), .eitherSpeaker)
    }

    func testVersionTwoConfigurationMigratesToAdaptiveTokenContextAndProtectedName() throws {
        let defaults = try makeDefaults()
        let key = "test.extraction.configuration.migration.v3"
        var legacy = ExtractionAdminConfiguration()
        legacy.version = 2
        legacy.fieldReplacementPolicies.removeValue(forKey: ScorecardField.name.rawValue)
        defaults.set(try JSONEncoder().encode(legacy), forKey: key)

        let repository = ExtractionAdminRepository(defaults: defaults, configurationKey: key)

        XCTAssertEqual(repository.configuration.version, 8)
        XCTAssertEqual(repository.configuration.responseTokenReserve, 1_024)
        XCTAssertEqual(repository.configuration.replacementPolicy(for: .name), .confirmationRequired)
    }

    func testManualOnlySourceMigratesToEitherBecauseManualEntryIsAlwaysAvailable() throws {
        let defaults = try makeDefaults()
        let key = "test.extraction.configuration.migration.v8"
        var legacy = ExtractionAdminConfiguration()
        legacy.version = 7
        legacy.setSourcePolicy(.manualOnly, for: .notes)
        defaults.set(try JSONEncoder().encode(legacy), forKey: key)

        let repository = ExtractionAdminRepository(defaults: defaults, configurationKey: key)

        XCTAssertEqual(repository.configuration.version, 8)
        XCTAssertEqual(repository.configuration.sourcePolicy(for: .notes), .eitherSpeaker)
        XCTAssertEqual(FieldSourcePolicy.speakerChoices.map(\.shortLabel), ["P", "R", "E"])
    }

    func testDisabledRecognitionRuleStopsItsCandidates() throws {
        let repository = ExtractionAdminRepository(defaults: try makeDefaults(), configurationKey: UUID().uuidString)
        repository.setRule(ExtractionRuleCatalog.knownTaxSoftware, enabled: false)
        let segment = makeSegment("We use Lacerte and file 800 tax returns.")

        let candidates = RuleBasedExtractor(admin: repository).extract(from: segment)

        XCTAssertNil(candidates.first(where: { $0.field == .primaryTaxSoftware }))
        XCTAssertEqual(candidates.first(where: { $0.field == .totalReturns })?.value, "800")
    }

    func testEditableSoftwareVocabularyExtractsEverySupportingToolInSpokenOrder() throws {
        let repository = ExtractionAdminRepository(defaults: try makeDefaults(), configurationKey: UUID().uuidString)
        var configuration = repository.configuration
        configuration.primaryTaxSoftwareCSV = "TaxShark, CustomTax"
        configuration.supportingSoftwareCSV = "QuickBooks, QuickBooks Online, SurePrep, LedgerLink"
        repository.updateConfiguration(configuration)
        let segment = makeSegment(
            "We use CustomTax with QuickBooks Online, SurePrep, and QuickBooks for bookkeeping."
        )

        let candidates = RuleBasedExtractor(admin: repository).extract(from: segment)

        XCTAssertEqual(candidates.first(where: { $0.field == .primaryTaxSoftware })?.value, "CustomTax")
        XCTAssertEqual(
            candidates.first(where: { $0.field == .supportingSoftware })?.value,
            "QuickBooks Online, SurePrep, QuickBooks"
        )
    }

    func testReducerRejectsOlderChangedEvidenceAndExplainsWhy() throws {
        let repository = ExtractionAdminRepository(defaults: try makeDefaults(), configurationKey: UUID().uuidString)
        let meetingID = UUID()
        let reducer = FactReducer(admin: repository)
        let current = ScorecardFact(
            meetingID: meetingID,
            field: .totalReturns,
            value: "1,000",
            quote: "Actually it is 1,000.",
            speaker: "PROSPECT",
            timestampSeconds: 40,
            confidence: .exact,
            effectiveAt: Date(),
            updatedAt: Date(),
            isPrior: false
        )
        let older = FactCandidate(
            field: .totalReturns,
            value: "800",
            quote: "We do 800 returns.",
            speaker: "PROSPECT",
            timestampSeconds: 10,
            confidence: .exact
        )

        let result = reducer.applying([older], to: [.totalReturns: current], meetingID: meetingID)

        XCTAssertEqual(result[.totalReturns]?.value, "1,000")
        let decision = repository.decisions(meetingID: meetingID).first
        XCTAssertEqual(decision?.outcome, .rejected)
        XCTAssertEqual(decision?.ruleID, ExtractionRuleCatalog.rejectOlder)
        XCTAssertTrue(decision?.reason.contains("older transcript evidence") == true)
    }

    func testReducerRejectsApproximateReplacementOfExactValue() throws {
        let repository = ExtractionAdminRepository(defaults: try makeDefaults(), configurationKey: UUID().uuidString)
        let meetingID = UUID()
        let current = ScorecardFact(
            meetingID: meetingID,
            field: .businessReturns,
            value: "250",
            quote: "250 business returns.",
            speaker: "PROSPECT",
            timestampSeconds: 10,
            confidence: .exact,
            effectiveAt: Date(),
            updatedAt: Date(),
            isPrior: false
        )
        let estimate = FactCandidate(
            field: .businessReturns,
            value: "200",
            quote: "A few hundred business returns.",
            speaker: "PROSPECT",
            timestampSeconds: 20,
            confidence: .approximate
        )

        let result = FactReducer(admin: repository).applying(
            [estimate],
            to: [.businessReturns: current],
            meetingID: meetingID
        )

        XCTAssertEqual(result[.businessReturns]?.value, "250")
        XCTAssertEqual(repository.decisions(meetingID: meetingID).first?.ruleID, ExtractionRuleCatalog.confidenceGate)
    }

    func testManualValueActsAsSafeLock() throws {
        let repository = ExtractionAdminRepository(defaults: try makeDefaults(), configurationKey: UUID().uuidString)
        let meetingID = UUID()
        let reducer = FactReducer(admin: repository)
        let manual = reducer.manualFact(field: .cpas, value: "4", meetingID: meetingID)!
        let automated = FactCandidate(
            field: .cpas,
            value: "5",
            quote: "We have 5 CPAs.",
            speaker: "PROSPECT",
            timestampSeconds: 30,
            confidence: .exact
        )

        let result = reducer.applying([automated], to: [.cpas: manual], meetingID: meetingID)

        XCTAssertEqual(result[.cpas]?.value, "4")
        XCTAssertEqual(repository.decisions(meetingID: meetingID).first?.ruleID, ExtractionRuleCatalog.protectManual)
    }

    func testNewerExactCorrectionReplacesOlderExactValue() throws {
        let repository = ExtractionAdminRepository(defaults: try makeDefaults(), configurationKey: UUID().uuidString)
        let meetingID = UUID()
        let current = ScorecardFact(
            meetingID: meetingID,
            field: .personalReturns,
            value: "700",
            quote: "We do 700 personal returns.",
            speaker: "PROSPECT",
            timestampSeconds: 10,
            confidence: .exact,
            effectiveAt: Date(),
            updatedAt: Date(),
            isPrior: false
        )
        let correction = FactCandidate(
            field: .personalReturns,
            value: "800",
            quote: "Actually, 800 personal returns.",
            speaker: "PROSPECT",
            timestampSeconds: 20,
            confidence: .exact
        )

        let result = FactReducer(admin: repository).applying(
            [correction],
            to: [.personalReturns: current],
            meetingID: meetingID
        )

        XCTAssertEqual(result[.personalReturns]?.value, "800")
        XCTAssertEqual(repository.decisions(meetingID: meetingID).first?.outcome, .replaced)
    }

    func testTotalReturnPolicyRejectsUnmarkedSameCallChange() throws {
        let repository = ExtractionAdminRepository(defaults: try makeDefaults(), configurationKey: UUID().uuidString)
        let meetingID = UUID()
        let current = ScorecardFact(
            meetingID: meetingID,
            field: .totalReturns,
            value: "800",
            quote: "We file 800 total returns.",
            speaker: "PROSPECT",
            timestampSeconds: 10,
            confidence: .exact,
            effectiveAt: Date(),
            updatedAt: Date(),
            isPrior: false
        )
        let unmarkedChange = FactCandidate(
            field: .totalReturns,
            value: "900",
            quote: "We file 900 total returns.",
            speaker: "PROSPECT",
            timestampSeconds: 20,
            confidence: .exact
        )

        let result = FactReducer(admin: repository).applying(
            [unmarkedChange],
            to: [.totalReturns: current],
            meetingID: meetingID
        )

        XCTAssertEqual(result[.totalReturns]?.value, "800")
        XCTAssertEqual(repository.decisions(meetingID: meetingID).first?.ruleID, ExtractionRuleCatalog.fieldReplacementPolicy)
    }

    func testTotalReturnPolicyAcceptsExplicitCorrectionAndDirectPriorConfirmation() throws {
        let repository = ExtractionAdminRepository(defaults: try makeDefaults(), configurationKey: UUID().uuidString)
        let meetingID = UUID()
        let sameCall = ScorecardFact(
            meetingID: meetingID,
            field: .totalReturns,
            value: "800",
            quote: "We file 800 total returns.",
            speaker: "PROSPECT",
            timestampSeconds: 10,
            confidence: .exact,
            effectiveAt: Date(),
            updatedAt: Date(),
            isPrior: false
        )
        let correction = FactCandidate(
            field: .totalReturns,
            value: "900",
            quote: "Actually, we file 900 total returns.",
            speaker: "PROSPECT",
            timestampSeconds: 20,
            confidence: .exact
        )
        let corrected = FactReducer(admin: repository).applying(
            [correction],
            to: [.totalReturns: sameCall],
            meetingID: meetingID
        )
        XCTAssertEqual(corrected[.totalReturns]?.value, "900")

        var prior = sameCall
        prior.confidence = .prior
        prior.isPrior = true
        let currentConfirmation = FactCandidate(
            field: .totalReturns,
            value: "1,000",
            quote: "We file 1,000 total returns.",
            speaker: "PROSPECT",
            timestampSeconds: 30,
            confidence: .exact
        )
        let confirmed = FactReducer(admin: repository).applying(
            [currentConfirmation],
            to: [.totalReturns: prior],
            meetingID: meetingID
        )
        XCTAssertEqual(confirmed[.totalReturns]?.value, "1000")
    }

    func testTotalReturnPolicyAcceptsLetMeCorrectLanguage() throws {
        let repository = ExtractionAdminRepository(defaults: try makeDefaults(), configurationKey: UUID().uuidString)
        let meetingID = UUID()
        let current = ScorecardFact(
            meetingID: meetingID,
            field: .totalReturns,
            value: "900",
            quote: "About 900 total returns.",
            speaker: "PROSPECT",
            timestampSeconds: 10,
            confidence: .approximate,
            effectiveAt: Date(),
            updatedAt: Date(),
            isPrior: false
        )
        let correction = FactCandidate(
            field: .totalReturns,
            value: "940",
            quote: "Let me correct the total: it is 940 total returns.",
            speaker: "PROSPECT",
            timestampSeconds: 20,
            confidence: .exact
        )

        let result = FactReducer(admin: repository).applying(
            [correction],
            to: [.totalReturns: current],
            meetingID: meetingID
        )

        XCTAssertEqual(result[.totalReturns]?.value, "940")
        XCTAssertEqual(repository.decisions(meetingID: meetingID).first?.outcome, .replaced)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "ExtractionAdminTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
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
