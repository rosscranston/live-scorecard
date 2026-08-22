import Foundation
import FoundationModels
import XCTest
@testable import LiveScorecard

final class AppleIntelligenceAccuracyEvaluationTests: XCTestCase {
    private struct Fixture: Decodable {
        let id: String
        let title: String
        let sourceBasis: String
        let turns: [Turn]
        let gold: [GoldFact]
    }

    private struct Turn: Decodable {
        let speaker: String
        let text: String
    }

    private struct GoldFact: Decodable {
        let field: ScorecardField
        let timeline: [ExpectedValue]

        var final: ExpectedValue { timeline.last! }

        func expectedValue(at turn: Int) -> String? {
            timeline.last(where: { $0.turn <= turn })?.value
        }
    }

    private struct ExpectedValue: Decodable {
        let turn: Int
        let value: String
        let evidence: String
    }

    private struct Mutation {
        let turn: Int
        let field: ScorecardField
        let oldValue: String?
        let newValue: String
        let quote: String
    }

    private struct Proposal {
        let turn: Int
        let field: ScorecardField
        let value: String
        let quote: String
        let allowedAtThatTurn: Bool
    }

    func testRunSelectedAccuracyFixtures() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard environment["RUN_APPLE_INTELLIGENCE_EVAL"] == "1" else {
            throw XCTSkip("Set RUN_APPLE_INTELLIGENCE_EVAL=1 to run the on-device generative evaluation.")
        }
        guard SystemLanguageModel.default.availability == .available else {
            XCTFail("Apple Intelligence is unavailable in this test process; the evaluation would not exercise the model.")
            return
        }

        let allFixtures = try loadFixtures()
        let selectedID = environment["EVAL_CALL_ID"]
        let fixtures = selectedID.map { id in allFixtures.filter { $0.id == id } } ?? allFixtures
        XCTAssertFalse(fixtures.isEmpty, "No fixture matched EVAL_CALL_ID=\(selectedID ?? "<all>")")

        let label = environment["EVAL_RUN_LABEL"] ?? "current"
        for fixture in fixtures {
            let report = try await evaluate(fixture)
            if environment["EVAL_REQUIRE_PERFECT"] == "1" {
                XCTAssertTrue(
                    report.contains("- Final accuracy: \(fixture.gold.count)/\(fixture.gold.count)"),
                    "\(fixture.id) did not finish with a perfect scorecard."
                )
                XCTAssertTrue(
                    report.contains("- First-pick accuracy: \(fixture.gold.count)/\(fixture.gold.count)"),
                    "\(fixture.id) did not capture every field correctly the first time."
                )
                XCTAssertTrue(
                    report.contains("- On-time first-pick accuracy: \(fixture.gold.count)/\(fixture.gold.count)"),
                    "\(fixture.id) did not capture every field on its first eligible turn."
                )
                XCTAssertTrue(report.contains("- Wrong scorecard writes: 0"))
                XCTAssertTrue(report.contains("- Wrong extractor proposals: 0"))
            }
            let url = try write(report: report, fixtureID: fixture.id, label: label)
            print("APPLE_INTELLIGENCE_EVAL_REPORT=\(url.path)")
        }
    }

    private func evaluate(_ fixture: Fixture) async throws -> String {
        let suiteName = "AppleIntelligenceAccuracyEvaluation.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let repository = ExtractionAdminRepository(
            defaults: defaults,
            configurationKey: "accuracy-evaluation",
            maximumDecisionCount: 10_000
        )
        repository.updateConfiguration(.standard)

        let extractor = FactExtractionService(admin: repository)
        let reducer = FactReducer(admin: repository)
        let meetingID = UUID()
        var segments: [TranscriptSegment] = []
        var facts: [ScorecardField: ScorecardFact] = [:]
        var mutations: [Mutation] = []
        var proposals: [Proposal] = []

        for (offset, turn) in fixture.turns.enumerated() {
            let turnNumber = offset + 1
            let source: SpeakerSource = turn.speaker == "ROSS" ? .microphone : .meetingAudio
            let segment = TranscriptSegment(
                id: UUID(),
                meetingID: meetingID,
                speaker: turn.speaker,
                source: source,
                text: turn.text,
                timestampSeconds: Double(turnNumber * 15),
                isFinal: true,
                createdAt: Date()
            )
            segments.append(segment)

            let candidates = await extractor.extract(from: segments)
            let goldByField = Dictionary(uniqueKeysWithValues: fixture.gold.map { ($0.field, $0) })
            proposals.append(contentsOf: candidates.map { candidate in
                let expected = goldByField[candidate.field]?.expectedValue(at: turnNumber)
                return Proposal(
                    turn: turnNumber,
                    field: candidate.field,
                    value: candidate.value,
                    quote: candidate.quote,
                    allowedAtThatTurn: expected.map { equivalent(candidate.value, $0, field: candidate.field) } ?? false
                )
            })

            let before = facts
            facts = reducer.applying(candidates, to: facts, meetingID: meetingID)
            for field in ScorecardField.displayOrder {
                guard let after = facts[field], before[field]?.value != after.value else { continue }
                mutations.append(Mutation(
                    turn: turnNumber,
                    field: field,
                    oldValue: before[field]?.value,
                    newValue: after.value,
                    quote: after.quote
                ))
            }
        }

        return render(
            fixture: fixture,
            finalFacts: facts,
            mutations: mutations,
            proposals: proposals,
            decisions: repository.decisions(meetingID: meetingID).reversed()
        )
    }

    private func render(
        fixture: Fixture,
        finalFacts: [ScorecardField: ScorecardFact],
        mutations: [Mutation],
        proposals: [Proposal],
        decisions: ReversedCollection<[ExtractionDecision]>
    ) -> String {
        let goldByField = Dictionary(uniqueKeysWithValues: fixture.gold.map { ($0.field, $0) })
        let correctFinal = fixture.gold.filter { gold in
            finalFacts[gold.field].map { equivalent($0.value, gold.final.value, field: gold.field) } ?? false
        }
        let wrongFinal = fixture.gold.filter { gold in
            guard let actual = finalFacts[gold.field] else { return false }
            return !equivalent(actual.value, gold.final.value, field: gold.field)
        }
        let missingFinal = fixture.gold.filter { finalFacts[$0.field] == nil }
        let unexpectedFinal = finalFacts.keys.filter { goldByField[$0] == nil }
        let firstMutations = Dictionary(grouping: mutations, by: \.field).compactMapValues(\.first)
        let correctFirst = fixture.gold.filter { gold in
            guard let first = firstMutations[gold.field],
                  let expected = gold.expectedValue(at: first.turn),
                  first.turn >= gold.timeline.first!.turn else { return false }
            return equivalent(first.newValue, expected, field: gold.field)
        }
        let onTime = fixture.gold.filter { gold in
            guard let first = firstMutations[gold.field] else { return false }
            return first.turn == gold.timeline.first!.turn &&
                equivalent(first.newValue, gold.timeline.first!.value, field: gold.field)
        }
        let wrongWrites = mutations.filter { mutation in
            guard let gold = goldByField[mutation.field],
                  let expected = gold.expectedValue(at: mutation.turn),
                  mutation.turn >= gold.timeline.first!.turn else { return true }
            return !equivalent(mutation.newValue, expected, field: mutation.field)
        }
        let wrongProposals = proposals.filter { !$0.allowedAtThatTurn }

        var lines: [String] = [
            "# \(fixture.title)",
            "",
            "- Fixture: `\(fixture.id)`",
            "- Basis: \(fixture.sourceBasis)",
            "- Engine: Apple Foundation Models through `FactExtractionService`, followed by the production `FactReducer`",
            "- Final accuracy: \(correctFinal.count)/\(fixture.gold.count)",
            "- First-pick accuracy: \(correctFirst.count)/\(fixture.gold.count)",
            "- On-time first-pick accuracy: \(onTime.count)/\(fixture.gold.count)",
            "- Wrong scorecard writes: \(wrongWrites.count)",
            "- Wrong extractor proposals: \(wrongProposals.count)",
            "",
            "## Transcript",
            ""
        ]

        for (offset, turn) in fixture.turns.enumerated() {
            lines.append("\(offset + 1). **\(turn.speaker):** \(turn.text)")
        }

        lines.append(contentsOf: [
            "",
            "## Gold versus final scorecard",
            "",
            "| Field | Gold | Apple final | First saved | First turn | Eligible turn | Result |",
            "|---|---|---|---|---:|---:|---|"
        ])
        for gold in fixture.gold {
            let actual = finalFacts[gold.field]?.value ?? "—"
            let first = firstMutations[gold.field]?.newValue ?? "—"
            let result = finalFacts[gold.field].map {
                equivalent($0.value, gold.final.value, field: gold.field) ? "PASS" : "WRONG"
            } ?? "MISSED"
            lines.append("| \(gold.field.label) | \(escape(gold.final.value)) | \(escape(actual)) | \(escape(first)) | \(firstMutations[gold.field]?.turn.description ?? "—") | \(gold.timeline.first!.turn) | \(result) |")
        }
        for field in unexpectedFinal.sorted(by: { $0.label < $1.label }) {
            lines.append("| \(field.label) | — | \(escape(finalFacts[field]?.value ?? "")) | \(escape(firstMutations[field]?.newValue ?? "—")) | \(firstMutations[field]?.turn.description ?? "—") | — | UNEXPECTED |")
        }

        lines.append(contentsOf: ["", "## Scorecard mutation history", ""])
        if mutations.isEmpty {
            lines.append("No values were written.")
        } else {
            for mutation in mutations {
                let expected = goldByField[mutation.field]?.expectedValue(at: mutation.turn)
                let isCorrect = expected.map { equivalent(mutation.newValue, $0, field: mutation.field) } ?? false
                lines.append(
                    "- Turn \(mutation.turn) / \(mutation.field.label): `\(mutation.oldValue ?? "blank")` -> `\(mutation.newValue)` / \(isCorrect ? "correct" : "WRONG") / \"\(mutation.quote)\""
                )
            }
        }

        lines.append(contentsOf: ["", "## Wrong extractor proposals", ""])
        if wrongProposals.isEmpty {
            lines.append("None.")
        } else {
            for proposal in wrongProposals {
                lines.append("- Turn \(proposal.turn) / \(proposal.field.label): `\(proposal.value)` / \"\(proposal.quote)\"")
            }
        }

        let rejected = decisions.filter { $0.outcome == .rejected }
        lines.append(contentsOf: [
            "",
            "## Diagnostic totals",
            "",
            "- Model or pattern proposals returned: \(proposals.count)",
            "- Scorecard mutations: \(mutations.count)",
            "- Rejected trace decisions: \(rejected.count)",
            "- Wrong final fields: \(wrongFinal.map { $0.field.label }.joined(separator: ", ").nilIfEmpty ?? "none")",
            "- Missing final fields: \(missingFinal.map { $0.field.label }.joined(separator: ", ").nilIfEmpty ?? "none")",
            "- Unexpected final fields: \(unexpectedFinal.map(\.label).joined(separator: ", ").nilIfEmpty ?? "none")",
            ""
        ])
        return lines.joined(separator: "\n")
    }

    private func loadFixtures() throws -> [Fixture] {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = testsDirectory.appendingPathComponent("Fixtures/AccuracyEvaluation/calls.json")
        return try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: url))
    }

    private func write(report: String, fixtureID: String, label: String) throws -> URL {
        let projectDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let directory = projectDirectory.appendingPathComponent("output/apple-intelligence-evaluation")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(fixtureID)-\(label).md")
        try report.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func equivalent(_ lhs: String, _ rhs: String, field: ScorecardField) -> Bool {
        func normalized(_ value: String) -> String {
            let trimmed = value
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                .lowercased()
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            if field.isNumeric {
                return trimmed
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: "about ", with: "")
                    .replacingOccurrences(of: "around ", with: "")
                    .replacingOccurrences(of: "approximately ", with: "")
                    .replacingOccurrences(of: ",", with: "")
            }
            if field == .supportingSoftware {
                return trimmed.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }.joined(separator: ",")
            }
            return trimmed
        }
        return normalized(lhs) == normalized(rhs)
    }

    private func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "|", with: "\\|")
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
