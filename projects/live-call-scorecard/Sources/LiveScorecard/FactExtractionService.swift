import Foundation
import FoundationModels

private func extractionSpeaker(for segment: TranscriptSegment) -> String {
    guard segment.source == .circleback else { return segment.source.label }
    return segment.speaker.localizedCaseInsensitiveContains("ross") ? "ROSS" : "PROSPECT"
}

@Generable
enum GeneratedField {
    case name
    case firmName
    case location
    case totalReturns
    case personalReturns
    case businessReturns
    case primaryTaxSoftware
    case taxSoftwareEnvironment
    case taxSoftwareHost
    case clientPortal
    case practiceManagement
    case supportingSoftware
    case admins
    case preparers
    case reviewers
    case cpas
    case annualCommitment
    case pilotCommitment
    case otherNumbers

    var scorecardField: ScorecardField {
        switch self {
        case .name: return .name
        case .firmName: return .firmName
        case .location: return .location
        case .totalReturns: return .totalReturns
        case .personalReturns: return .personalReturns
        case .businessReturns: return .businessReturns
        case .primaryTaxSoftware: return .primaryTaxSoftware
        case .taxSoftwareEnvironment: return .taxSoftwareEnvironment
        case .taxSoftwareHost: return .taxSoftwareHost
        case .clientPortal: return .clientPortal
        case .practiceManagement: return .practiceManagement
        case .supportingSoftware: return .supportingSoftware
        case .admins: return .admins
        case .preparers: return .preparers
        case .reviewers: return .reviewers
        case .cpas: return .cpas
        case .annualCommitment: return .annualCommitment
        case .pilotCommitment: return .pilotCommitment
        case .otherNumbers: return .otherNumbers
        }
    }
}

@Generable
struct GeneratedFact {
    @Guide(description: "The scorecard field supported by the quoted words")
    var field: GeneratedField

    @Guide(description: "A value copied verbatim from the quoted answer. Never normalize, paraphrase, calculate, or use a missing-value placeholder.")
    var value: String

    @Guide(description: "An exact contiguous quote copied from the transcript input")
    var quote: String

    @Guide(description: "The transcript speaker label, exactly ROSS or PROSPECT")
    var speaker: String

    @Guide(description: "True for about, around, approximately, or vague converted quantities")
    var approximate: Bool
}

@Generable
struct GeneratedFactBatch {
    @Guide(description: "Only facts directly supported by the transcript", .maximumCount(12))
    var facts: [GeneratedFact]
}

struct ModelEvidenceValidation {
    let accepted: Bool
    let matchingSegment: TranscriptSegment?
    let ruleID: String
    let reason: String

    var isAccepted: Bool { accepted }
}

struct ModelEvidenceValidator {
    private enum QuestionTopic {
        case name
        case firm
        case location
        case totalReturns
        case personalReturns
        case businessReturns
        case primaryTaxSoftware
        case taxSoftwareEnvironment
        case taxSoftwareHost
        case clientPortal
        case practiceManagement
        case supportingSoftware
        case admins
        case preparers
        case reviewers
        case cpas
        case staffGeneral
        case annualCommitment
        case pilotCommitment
        case otherNumbers
    }

    static func validate(
        field: ScorecardField,
        value: String,
        quote: String,
        in segments: [TranscriptSegment],
        minimumCharacters: Int
    ) -> ModelEvidenceValidation {
        let needle = normalizeQuote(quote)
        guard needle.count >= minimumCharacters,
              let match = segments.enumerated().last(where: {
                  normalizeQuote($0.element.text).contains(needle)
              }) else {
            return rejected(
                ruleID: ExtractionRuleCatalog.exactQuoteEvidence,
                reason: "The model's quote was too short or did not appear exactly in the transcript window."
            )
        }

        if isQuestion(quote) {
            return rejected(
                ruleID: ExtractionRuleCatalog.questionEvidence,
                reason: "The quoted words are a question, not a confirmed answer.",
                matchingSegment: match.element
            )
        }

        guard !isPlaceholder(value) else {
            return rejected(
                ruleID: ExtractionRuleCatalog.rejectPlaceholder,
                reason: "The model returned an unknown or missing-value placeholder, so the field remains blank.",
                matchingSegment: match.element
            )
        }

        guard valueAppearsLiterally(value, field: field, in: quote) else {
            return rejected(
                ruleID: ExtractionRuleCatalog.literalValueEvidence,
                reason: "The proposed value does not appear verbatim in the quoted transcript evidence.",
                matchingSegment: match.element
            )
        }

        if isTaxFormIdentifierUsedAsCategory(field: field, value: value, quote: quote) {
            return rejected(
                ruleID: ExtractionRuleCatalog.fieldContextEvidence,
                reason: "A tax-form identifier was used as a category, not as a return-count quantity.",
                matchingSegment: match.element
            )
        }

        if isProspectEchoOfRossLocation(
            field: field,
            value: value,
            matchingIndex: match.offset,
            segments: segments
        ) {
            return rejected(
                ruleID: ExtractionRuleCatalog.fieldContextEvidence,
                reason: "The prospect repeated Ross's first-person location, so it is not evidence of the prospect's location.",
                matchingSegment: match.element
            )
        }

        guard hasFieldContext(
            field: field,
            value: value,
            quote: quote,
            matchingIndex: match.offset,
            segments: segments
        ) else {
            return rejected(
                ruleID: ExtractionRuleCatalog.fieldContextEvidence,
                reason: "The quote neither names this field nor answers the nearest recognized question for this field.",
                matchingSegment: match.element
            )
        }

        return ModelEvidenceValidation(
            accepted: true,
            matchingSegment: match.element,
            ruleID: ExtractionRuleCatalog.fieldContextEvidence,
            reason: "The exact quote and literal value match the transcript and the field's question or explicit context."
        )
    }

    static func isPlaceholder(_ value: String) -> Bool {
        let normalized = value
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return [
            "unknown", "not specified", "not provided", "not mentioned", "not stated",
            "unspecified", "unavailable", "not available", "none", "n/a", "na",
            "no answer", "unclear", "null", "blank"
        ].contains(normalized)
    }

    private static func rejected(
        ruleID: String,
        reason: String,
        matchingSegment: TranscriptSegment? = nil
    ) -> ModelEvidenceValidation {
        ModelEvidenceValidation(
            accepted: false,
            matchingSegment: matchingSegment,
            ruleID: ruleID,
            reason: reason
        )
    }

    private static func valueAppearsLiterally(
        _ value: String,
        field: ScorecardField,
        in quote: String
    ) -> Bool {
        let haystack = literalFold(quote)
        if field.isNumeric, let expected = ExtractionValueCanonicalizer.singleInteger(value) {
            let expression = try? NSRegularExpression(pattern: #"\d[\d,]*"#)
            let tokens = expression?.matches(
                in: quote,
                range: NSRange(quote.startIndex..., in: quote)
            ).compactMap { match -> String? in
                guard let range = Range(match.range, in: quote) else { return nil }
                return String(quote[range])
            } ?? []
            return tokens.contains { ExtractionValueCanonicalizer.singleInteger($0) == expected }
        }
        let components: [String]
        if field == .supportingSoftware {
            components = value.split(separator: ",").map(String.init)
        } else {
            components = [value]
        }
        guard !components.isEmpty else { return false }
        return components.allSatisfy { component in
            let needle = literalFold(component)
            return !needle.isEmpty && haystack.contains(needle)
        }
    }

    private static func hasFieldContext(
        field: ScorecardField,
        value: String,
        quote: String,
        matchingIndex: Int,
        segments: [TranscriptSegment]
    ) -> Bool {
        if explicitlyNamesField(field, value: value, quote: quote) {
            return true
        }
        guard let question = nearestQuestionTopic(before: matchingIndex, in: segments) else {
            return false
        }
        return questionMatches(field: field, topic: question)
    }

    private static func explicitlyNamesField(
        _ field: ScorecardField,
        value: String,
        quote: String
    ) -> Bool {
        let text = literalFold(quote)
        let literalValue = NSRegularExpression.escapedPattern(for: value.trimmingCharacters(in: .whitespacesAndNewlines))
        switch field {
        case .name:
            return regex(#"\b(?:hey|hi|hello)\s*,?\s*"# + literalValue + #"\b"#, in: quote) ||
                regex(#"\b(?:my name is|i am|i'm|this is)\s+"# + literalValue + #"\b"#, in: quote)
        case .firmName:
            return regex(#"\b(?:firm|company|practice|business)(?:'s)?\s+(?:name\s+)?(?:is|is called|is named|called|named)\b"#, in: text)
        case .location:
            return containsAny(text, [
                "calling in from", "calling from", "based in", "located in", "office in",
                "office out of", "we're in", "we are in", "i'm in", "i am in"
            ])
        case .timezone:
            return containsAny(text, ["timezone", "time zone"])
        case .totalReturns:
            let literalValue = NSRegularExpression.escapedPattern(
                for: value.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            let valueBeforeReturns = regex(
                #"\b"# + literalValue + #"\s+(?:total\s+)?(?:tax\s+)?returns?\b"#,
                in: quote
            )
            let labeledValueAfterReturns = regex(
                #"\b(?:total\s+returns?|return\s+(?:count|volume))(?:\s+is|\s+of|:)?\s+"# + literalValue + #"\b"#,
                in: quote
            )
            return (valueBeforeReturns || labeledValueAfterReturns) &&
                !containsAny(text, ["worked on", "not our client", "not our firm"])
        case .personalReturns:
            return text.contains("return") && containsAny(text, ["personal", "individual", "1040"])
        case .businessReturns:
            return text.contains("return") && containsAny(text, ["business", "1065", "1120", "partnership", "corporate"])
        case .primaryTaxSoftware:
            return containsAny(text, ["tax software", "we use", "we're using", "we are using", "i use", "using "]) &&
                !containsAny(text, ["don't use", "do not use", "no longer use", "used to use"])
        case .taxSoftwareEnvironment:
            return containsAny(text, ["desktop", "cloud", "cloud-based", "hosted", "local install"])
        case .taxSoftwareHost:
            return containsAny(text, ["hosted by", "hosting provider", "hosts our", "host is"])
        case .clientPortal:
            return containsAny(text, ["client portal", "clients upload", "client upload", "portal is", "portal called"])
        case .practiceManagement:
            return containsAny(text, ["practice management", "workflow software", "manage our practice"])
        case .supportingSoftware:
            return containsAny(text, ["supporting software", "other software", "other tools", "we also use", "also using"])
        case .admins:
            return containsAny(text, ["admin", "administrator"])
        case .preparers:
            return containsAny(text, ["preparer", "prepare returns"])
        case .reviewers:
            return containsAny(text, ["reviewer", "review returns", "doing review"])
        case .cpas:
            return containsAny(text, ["cpa", "certified public accountant"])
        case .annualCommitment:
            return containsAny(text, [
                "annual commitment", "annual minimum", "full commitment",
                "full package", "minimum commitment", "minimum is"
            ])
        case .pilotCommitment:
            return containsAny(text, [
                "pilot commitment", "pilot minimum", "initial commitment",
                "start with", "start at", "get started with", "begin with"
            ])
        case .otherNumbers:
            return !text.contains("step") && containsAny(text, [
                "client", "document", "user", "seat", "month", "year", "dollar",
                "price", "fee", "cost", "license", "per return"
            ])
        case .notes:
            return false
        }
    }

    private static func isProspectEchoOfRossLocation(
        field: ScorecardField,
        value: String,
        matchingIndex: Int,
        segments: [TranscriptSegment]
    ) -> Bool {
        guard field == .location,
              matchingIndex > 0,
              segments[matchingIndex].source == .meetingAudio else { return false }
        let answerTime = segments[matchingIndex].timestampSeconds
        let foldedValue = literalFold(value)
        return segments[..<matchingIndex].reversed().contains { segment in
            guard answerTime - segment.timestampSeconds <= 60,
                  segment.source == .microphone else { return false }
            let text = literalFold(segment.text)
            let firstPersonLocation = containsAny(text, [
                "i'm in ", "i am in ", "i'm based in ", "i am based in "
            ])
            return firstPersonLocation && text.contains(foldedValue)
        }
    }

    private static func isTaxFormIdentifierUsedAsCategory(
        field: ScorecardField,
        value: String,
        quote: String
    ) -> Bool {
        guard [.personalReturns, .businessReturns].contains(field),
              let number = ExtractionValueCanonicalizer.singleInteger(value),
              ["1040", "1065", "1120", "1120S"].contains(number.uppercased()) else {
            return false
        }
        let text = literalFold(quote)
        return regex(#"\b(?:including|forms?|types?)\s+[^.]*\b"# + NSRegularExpression.escapedPattern(for: number) + #"\b"#, in: text)
    }

    private static func nearestQuestionTopic(
        before answerIndex: Int,
        in segments: [TranscriptSegment]
    ) -> QuestionTopic? {
        guard answerIndex > 0 else { return nil }
        let lowerBound = max(0, answerIndex - 20)
        // Prefer the closest complete question. Joining several turns first can let an
        // older identity question mask a newer location or software question.
        for index in stride(from: answerIndex - 1, through: lowerBound, by: -1) {
            let text = segments[index].text
            if isQuestion(text), let topic = questionTopic(in: text) {
                return topic
            }
        }

        // Speech transcription sometimes splits one question across adjacent segments.
        // Only use combined windows when no complete nearby question was recognized.
        for end in stride(from: answerIndex - 1, through: lowerBound, by: -1) {
            let start = max(lowerBound, end - 2)
            let window = segments[start...end].map(\.text).joined(separator: " ")
            if let topic = questionTopic(in: window) {
                return topic
            }
        }
        return nil
    }

    private static func questionTopic(in raw: String) -> QuestionTopic? {
        let text = literalFold(raw)
        if containsAny(text, ["what is your name", "what's your name", "who am i speaking with", "who is this"]) {
            return .name
        }
        if containsAny(text, ["name of your firm", "name of the firm", "firm name", "company name", "practice name", "what firm"]) {
            return .firm
        }
        if (text.contains("where") && containsAny(text, ["calling in from", "calling from", "located", "based", "office"])) ||
            containsAny(text, ["what part of the country", "what city are you in"]) {
            return .location
        }
        if containsAny(text, ["how many", "number of", "return volume", "returns do you", "returns are you"]) && text.contains("return") {
            if containsAny(text, ["personal", "individual", "1040"]) { return .personalReturns }
            if containsAny(text, ["business", "1065", "1120", "partnership", "corporate"]) { return .businessReturns }
            return .totalReturns
        }
        if containsAny(text, ["other software", "supporting software", "what else do you use", "other tools"]) {
            return .supportingSoftware
        }
        if containsAny(text, ["cloud or desktop", "desktop or cloud", "hosted or local", "software environment"]) {
            return .taxSoftwareEnvironment
        }
        if containsAny(text, ["who hosts", "hosted by whom", "hosting provider", "where is it hosted"]) {
            return .taxSoftwareHost
        }
        if containsAny(text, ["client portal", "clients upload", "client upload"]) {
            return .clientPortal
        }
        if containsAny(text, ["practice management", "manage your practice", "workflow software"]) {
            return .practiceManagement
        }
        if containsAny(text, ["what do you use for software", "what do you guys use for software", "what tax software", "which tax software", "using for tax software"]) {
            return .primaryTaxSoftware
        }
        if text.contains("how many") {
            if containsAny(text, ["admin", "administrator"]) { return .admins }
            if text.contains("preparer") { return .preparers }
            if text.contains("reviewer") { return .reviewers }
            if text.contains("cpa") { return .cpas }
            if containsAny(text, ["people on your team", "people are on your team", "team members", "staff members", "on the team"]) {
                return .staffGeneral
            }
        }
        if containsAny(text, [
            "pilot commitment", "pilot minimum", "start the pilot with",
            "start with", "get started with"
        ]) {
            return .pilotCommitment
        }
        if containsAny(text, [
            "annual commitment", "annual minimum", "full commitment",
            "full package commitment", "minimum commitment",
            "what is the minimum", "what's the minimum"
        ]) {
            return .annualCommitment
        }
        return nil
    }

    private static func questionMatches(field: ScorecardField, topic: QuestionTopic) -> Bool {
        switch (field, topic) {
        case (.name, .name),
             (.firmName, .firm),
             (.location, .location),
             (.totalReturns, .totalReturns),
             (.personalReturns, .personalReturns),
             (.businessReturns, .businessReturns),
             (.primaryTaxSoftware, .primaryTaxSoftware),
             (.taxSoftwareEnvironment, .taxSoftwareEnvironment),
             (.taxSoftwareHost, .taxSoftwareHost),
             (.clientPortal, .clientPortal),
             (.practiceManagement, .practiceManagement),
             (.supportingSoftware, .supportingSoftware),
             (.admins, .admins),
             (.preparers, .preparers),
             (.reviewers, .reviewers),
             (.cpas, .cpas),
             (.annualCommitment, .annualCommitment),
             (.pilotCommitment, .pilotCommitment),
             (.otherNumbers, .otherNumbers):
            return true
        default:
            return false
        }
    }

    static func isQuestion(_ raw: String) -> Bool {
        let text = literalFold(raw)
        if text.hasSuffix("?") { return true }
        return [
            "do you ", "did you ", "are you ", "is your ", "is it ", "how many ",
            "would you ", "could you ", "what is ", "what's ", "where are ",
            "where is ", "who is ", "which "
        ].contains { text.hasPrefix($0) }
    }

    private static func containsAny(_ text: String, _ values: [String]) -> Bool {
        values.contains(where: text.contains)
    }

    private static func regex(_ pattern: String, in text: String) -> Bool {
        text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func normalizeQuote(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .punctuationCharacters)
    }

    private static func literalFold(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

actor FactExtractionService {
    private let fallback: RuleBasedExtractor
    private let contextualFallback: ContextualRuleExtractor
    private let model = SystemLanguageModel.default
    private let admin: ExtractionAdminRepository

    init(admin: ExtractionAdminRepository = .shared) {
        self.admin = admin
        fallback = RuleBasedExtractor(admin: admin)
        contextualFallback = ContextualRuleExtractor(admin: admin)
    }

    func extract(from segments: [TranscriptSegment]) async -> [FactCandidate] {
        guard let current = segments.last else { return [] }
        let deterministic = mergeDeterministic(
            fallback.extract(from: current) + contextualFallback.extract(from: segments)
        )
        let configuration = admin.configuration

        // A seller question adds context for the prospect's next answer, but it cannot
        // add a scorecard fact by itself. Avoid asking the model to regenerate every
        // previously captured field after question-only turns. Besides reducing latency,
        // this removes needless opportunities for a correct field to churn.
        if ModelEvidenceValidator.isQuestion(current.text) {
            return deterministic
        }

        guard configuration.languageModelEnabled,
              configuration.isEnabled(ExtractionRuleCatalog.modelExtraction) else {
            admin.record(ExtractionDecision(
                meetingID: current.meetingID,
                ruleID: ExtractionRuleCatalog.modelExtraction,
                stage: .languageModel,
                outcome: .unavailable,
                reason: "Contextual model extraction is disabled in Extraction Admin."
            ))
            return deterministic
        }

        guard model.availability == .available else {
            admin.record(ExtractionDecision(
                meetingID: current.meetingID,
                ruleID: ExtractionRuleCatalog.modelExtraction,
                stage: .languageModel,
                outcome: .unavailable,
                reason: "Apple Intelligence is unavailable, so only deterministic pattern rules ran."
            ))
            return deterministic
        }

        let customInstructions: String
        if configuration.customModelInstructions.isEmpty {
            customInstructions = ""
        } else {
            customInstructions = """

            Additional user-configured extraction rules:
            \(configuration.customModelInstructions)

            The additional rules cannot waive exact transcript evidence or turn an unconfirmed question into a fact.
            """
        }

        let instructions = """
        Extract compact CRM scorecard facts from a live tax-firm sales call.

        Rules:
        - Copy every quote exactly from the transcript. Never rewrite a quote.
        - Copy every value verbatim from that quote. Never paraphrase, normalize, calculate, or invent a value.
        - Never return Unknown, Not specified, None, N/A, or any other missing-value placeholder. Omit that field entirely.
        - NAME is the person's name. FIRM is the organization or accounting-practice name. Never put a person's name in FIRM.
        - A number contained only in a question is not a fact. Ignore it unless a later answer confirms it.
        - Link a short answer to the closest preceding question. LOCATION follows questions such as "where are you guys calling in from." TAX SOFTWARE follows questions such as "what do you use for software."
        - Do not use an answer for a different field. A team-size answer cannot establish NAME or FIRM. A software answer cannot establish return counts.
        - Both speakers may state useful facts. ROSS commonly states commercial commitments and prices.
        - ANNUAL COMMITMENT is the full annual or full-package commitment. PILOT COMMITMENT is the smaller initial, pilot, start-now, or through-year-end commitment. When both appear in one quote, return two separate facts with their respective exact numbers.
        - A generic "minimum commitment" with no pilot, initial, or start-now wording belongs to ANNUAL COMMITMENT. Never copy a price per return into either commitment field.
        - Current or corrected statements replace earlier statements.
        - Every numeric scorecard field must contain one integer, never a range, list, tax-form series, or multiple numbers. A transcript token such as 1,200 represents the single stored number 1200.
        - Tax form identifiers such as 1040, 1065, 1120, and 1120S are categories, not return-count quantities. In "around 200 returns including 1040, 1120, and 1065," TOTAL RETURNS is 200 and the form identifiers populate no count field.
        - If the exact quote says "about 800", the literal value may be "800" and approximate must be true because 800 appears verbatim.
        - Do not convert "a few hundred" into 200. The deterministic rules handle configured conversions separately.
        - Business returns include partnerships, S corporations, C corporations, and sole proprietorships.
        - Personal returns means Form 1040 returns.
        - Identify primary tax software separately from portals, practice management, hosting, and supporting tools.
        - TAX SOFTWARE ENVIRONMENT must be exactly one of Desktop, Cloud, or Hosted. "Hosted by [provider]" names the host; if the software is also explicitly desktop, the environment is Desktop.
        - Primary tax software names currently configured by the user: \(configuration.primaryTaxSoftwareNames.joined(separator: ", ")).
        - Supporting software names currently configured by the user: \(configuration.supportingSoftwareNames.joined(separator: ", ")).
        - If multiple supporting tools are stated, return one supportingSoftware fact whose value contains every distinct name in spoken order, separated only by commas. Do not include "and" as part of a software name.
        - Do not put the primary tax software into supportingSoftware.
        - Do not infer a fact that was not said. Returning no facts is correct.
        \(customInstructions)
        """

        do {
            let instructionObject = Instructions(instructions)
            let context = await tokenBudgetedContext(
                from: segments,
                instructions: instructionObject,
                instructionText: instructions,
                configuration: configuration
            )
            guard !context.segments.isEmpty else {
                admin.record(ExtractionDecision(
                    meetingID: current.meetingID,
                    ruleID: ExtractionRuleCatalog.adaptiveTokenWindow,
                    stage: .languageModel,
                    outcome: .unavailable,
                    reason: "No transcript segment fit after reserving tokens for instructions, schema, and model output."
                ))
                return deterministic
            }

            let relevant = context.segments
            let transcript = context.prompt
            let session = LanguageModelSession(instructions: instructionObject)
            let response = try await session.respond(
                to: Prompt(transcript),
                generating: GeneratedFactBatch.self
            )

            let generated = response.content.facts.compactMap { fact -> FactCandidate? in
                guard let canonicalValue = ExtractionValueCanonicalizer.modelValue(
                    fact.value,
                    for: fact.field.scorecardField
                ) else {
                    admin.record(ExtractionDecision(
                        meetingID: current.meetingID,
                        ruleID: ExtractionRuleCatalog.fieldContextEvidence,
                        stage: .evidence,
                        outcome: .rejected,
                        field: fact.field.scorecardField,
                        proposedValue: fact.value,
                        reason: "The proposed value has an invalid shape for this field.",
                        quote: fact.quote,
                        speaker: fact.speaker,
                        transcriptTimestamp: current.timestampSeconds
                    ))
                    return nil
                }
                let validation = ModelEvidenceValidator.validate(
                    field: fact.field.scorecardField,
                    value: canonicalValue,
                    quote: fact.quote,
                    in: relevant,
                    minimumCharacters: configuration.minimumEvidenceQuoteCharacters
                )
                guard validation.isAccepted, let matchingSegment = validation.matchingSegment else {
                    admin.record(ExtractionDecision(
                        meetingID: current.meetingID,
                        ruleID: validation.ruleID,
                        stage: .evidence,
                        outcome: .rejected,
                        field: fact.field.scorecardField,
                        proposedValue: fact.value,
                        reason: validation.reason,
                        quote: fact.quote,
                        speaker: validation.matchingSegment.map(extractionSpeaker(for:)) ?? fact.speaker,
                        transcriptTimestamp: validation.matchingSegment?.timestampSeconds ?? current.timestampSeconds
                    ))
                    return nil
                }
                let candidate = FactCandidate(
                    field: fact.field.scorecardField,
                    value: canonicalValue,
                    quote: fact.quote,
                    speaker: extractionSpeaker(for: matchingSegment),
                    timestampSeconds: matchingSegment.timestampSeconds,
                    confidence: fact.approximate ? .approximate : .exact
                )
                admin.record(ExtractionDecision(
                    meetingID: current.meetingID,
                    ruleID: validation.ruleID,
                    stage: .evidence,
                    outcome: .accepted,
                    field: candidate.field,
                    proposedValue: candidate.value,
                    reason: validation.reason,
                    quote: candidate.quote,
                    speaker: candidate.speaker,
                    transcriptTimestamp: candidate.timestampSeconds
                ))
                return candidate
            }
            return merge(
                deterministic: deterministic,
                generated: generated,
                meetingID: current.meetingID,
                configuration: configuration
            )
        } catch {
            admin.record(ExtractionDecision(
                meetingID: current.meetingID,
                ruleID: ExtractionRuleCatalog.modelExtraction,
                stage: .languageModel,
                outcome: .unavailable,
                reason: "Contextual extraction failed: \(error.localizedDescription). Pattern results were kept."
            ))
            return deterministic
        }
    }

    private func merge(
        deterministic: [FactCandidate],
        generated: [FactCandidate],
        meetingID: UUID,
        configuration: ExtractionAdminConfiguration
    ) -> [FactCandidate] {
        let deterministicFields = Set(deterministic.map(\.field))
        var byField: [ScorecardField: FactCandidate] = [:]
        for candidate in deterministic {
            byField[candidate.field] = candidate
        }
        for candidate in generated {
            if candidate.field == .supportingSoftware,
               let previous = byField[.supportingSoftware] {
                let merged = mergeSoftwareCandidates(previous, candidate)
                byField[.supportingSoftware] = merged
                admin.record(ExtractionDecision(
                    meetingID: meetingID,
                    ruleID: ExtractionRuleCatalog.modelMerge,
                    stage: .languageModel,
                    outcome: merged.value == previous.value ? .unchanged : .merged,
                    field: .supportingSoftware,
                    proposedValue: candidate.value,
                    previousValue: previous.value,
                    reason: merged.value == previous.value
                        ? "The model proposed supporting software already present in this extraction batch."
                        : "Distinct supporting-software names from pattern and model results were combined.",
                    quote: candidate.quote,
                    speaker: candidate.speaker,
                    transcriptTimestamp: candidate.timestampSeconds
                ))
                continue
            }
            if let patternCandidate = byField[candidate.field],
               deterministicFields.contains(candidate.field),
               !configuration.modelMayOverrideDeterministic {
                admin.record(ExtractionDecision(
                    meetingID: meetingID,
                    ruleID: ExtractionRuleCatalog.modelMerge,
                    stage: .languageModel,
                    outcome: .rejected,
                    field: candidate.field,
                    proposedValue: candidate.value,
                    previousValue: patternCandidate.value,
                    reason: "A deterministic pattern already found this field, and model override is disabled.",
                    quote: candidate.quote,
                    speaker: candidate.speaker,
                    transcriptTimestamp: candidate.timestampSeconds
                ))
                continue
            }
            let previous = byField[candidate.field]
            byField[candidate.field] = candidate
            admin.record(ExtractionDecision(
                meetingID: meetingID,
                ruleID: ExtractionRuleCatalog.modelMerge,
                stage: .languageModel,
                outcome: previous == nil ? .accepted : .replaced,
                field: candidate.field,
                proposedValue: candidate.value,
                previousValue: previous?.value,
                reason: previous == nil
                    ? "The model filled a field that deterministic patterns did not find."
                    : deterministicFields.contains(candidate.field)
                        ? "Model override is enabled, so the model result replaced the pattern result."
                        : "A later model candidate for the same field replaced the earlier model candidate.",
                quote: candidate.quote,
                speaker: candidate.speaker,
                transcriptTimestamp: candidate.timestampSeconds
            ))
        }
        return ScorecardField.displayOrder.compactMap { byField[$0] }
    }

    private func mergeDeterministic(_ candidates: [FactCandidate]) -> [FactCandidate] {
        var byField: [ScorecardField: FactCandidate] = [:]
        for candidate in candidates where byField[candidate.field] == nil {
            byField[candidate.field] = candidate
        }
        return ScorecardField.displayOrder.compactMap { byField[$0] }
    }

    private func mergeSoftwareCandidates(
        _ existing: FactCandidate,
        _ proposed: FactCandidate
    ) -> FactCandidate {
        var names: [String] = []
        var seen = Set<String>()
        for trimmed in ExtractionValueCanonicalizer.softwareListComponents(
            existing.value + "," + proposed.value
        ) {
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { continue }
            names.append(trimmed)
        }
        let evidence = proposed.timestampSeconds >= existing.timestampSeconds ? proposed : existing
        return FactCandidate(
            field: .supportingSoftware,
            value: names.joined(separator: ", "),
            quote: evidence.quote,
            speaker: evidence.speaker,
            timestampSeconds: max(existing.timestampSeconds, proposed.timestampSeconds),
            confidence: existing.confidence == .exact || proposed.confidence == .exact ? .exact : .approximate
        )
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func tokenBudgetedContext(
        from segments: [TranscriptSegment],
        instructions: Instructions,
        instructionText: String,
        configuration: ExtractionAdminConfiguration
    ) async -> TranscriptContextWindow {
        let contextSize = model.contextSize
        let safetyMargin = 128
        let reserve = min(configuration.responseTokenReserve, max(512, contextSize / 2))
        let render: (TranscriptSegment) -> String = { [self] segment in
            let label: String
            if segment.source == .circleback {
                label = segment.speaker.lowercased().contains("ross") ? "ROSS" : "PROSPECT"
            } else {
                label = segment.source.label
            }
            return "[\(formatTime(segment.timestampSeconds))] \(label): \(segment.text)"
        }

        if #available(macOS 26.4, *) {
            do {
                let instructionTokens = try await model.tokenCount(for: instructions)
                let schemaTokens = try await model.tokenCount(for: GeneratedFactBatch.generationSchema)
                let fixedTokens = instructionTokens + schemaTokens
                let promptBudget = max(0, contextSize - fixedTokens - reserve - safetyMargin)
                return try await TranscriptContextSelector.select(
                    from: segments,
                    promptTokenBudget: promptBudget,
                    usedExactTokenCount: true,
                    render: render
                ) { [model] text in
                    try await model.tokenCount(for: Prompt(text))
                }
            } catch {
                // Token measurement can fail independently of generation. Continue
                // with a conservative character estimate instead of dropping facts.
            }
        }

        let estimatedInstructionTokens = Self.estimatedTokenCount(instructionText)
        let estimatedSchemaTokens = 640
        let promptBudget = max(
            0,
            contextSize - estimatedInstructionTokens - estimatedSchemaTokens - reserve - safetyMargin
        )
        return (try? await TranscriptContextSelector.select(
            from: segments,
            promptTokenBudget: promptBudget,
            usedExactTokenCount: false,
            render: render
        ) { text in
            Self.estimatedTokenCount(text)
        }) ?? TranscriptContextWindow(
            segments: [],
            prompt: "",
            promptTokenCount: 0,
            promptTokenBudget: promptBudget,
            usedExactTokenCount: false
        )
    }

    private static func estimatedTokenCount(_ value: String) -> Int {
        max(1, Int(ceil(Double(value.utf8.count) / 3.0)))
    }
}

struct RuleBasedExtractor: Sendable {
    private let admin: ExtractionAdminRepository

    init(admin: ExtractionAdminRepository = .shared) {
        self.admin = admin
    }

    func extract(from segment: TranscriptSegment) -> [FactCandidate] {
        let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }

        if isUnconfirmedQuestion(text) {
            admin.record(ExtractionDecision(
                meetingID: segment.meetingID,
                ruleID: ExtractionRuleCatalog.questionEvidence,
                stage: .evidence,
                outcome: .rejected,
                reason: "The segment is phrased as a question, so its numbers and names are not treated as confirmed facts.",
                quote: segment.text,
                speaker: extractionSpeaker(for: segment),
                transcriptTimestamp: segment.timestampSeconds
            ))
            return []
        }

        let configuration = admin.configuration

        var candidates: [FactCandidate] = []

        if configuration.isEnabled(ExtractionRuleCatalog.explicitIdentity) {
            candidates.append(contentsOf: identityCandidates(from: text, segment: segment))
        }

        if configuration.isEnabled(ExtractionRuleCatalog.knownTaxSoftware) {
            let matches = orderedNonoverlappingMatches(
                names: configuration.primaryTaxSoftwareNames,
                in: text
            )
            if matches.count == 1,
               let software = matches.first,
               !isExplicitlyNoncurrentSoftware(software, in: text) {
                candidates.append(recordedCandidate(
                    field: .primaryTaxSoftware,
                    value: software,
                    segment: segment,
                    approximate: false,
                    ruleID: ExtractionRuleCatalog.knownTaxSoftware,
                    reason: "Matched a maintained tax-software name."
                ))
            } else if matches.count > 1,
                      let software = explicitlyCurrentSoftware(in: text, names: matches) {
                candidates.append(recordedCandidate(
                    field: .primaryTaxSoftware,
                    value: software,
                    segment: segment,
                    approximate: false,
                    ruleID: ExtractionRuleCatalog.knownTaxSoftware,
                    reason: "Multiple software names were present, and an explicit current-use cue selected the active one."
                ))
            } else if matches.count > 1 {
                admin.record(ExtractionDecision(
                    meetingID: segment.meetingID,
                    ruleID: ExtractionRuleCatalog.knownTaxSoftware,
                    stage: .deterministic,
                    outcome: .unavailable,
                    field: .primaryTaxSoftware,
                    proposedValue: matches.joined(separator: ", "),
                    reason: "Multiple primary tax-software names appeared in one segment, so the contextual model must decide which one is current.",
                    quote: segment.text,
                    speaker: extractionSpeaker(for: segment),
                    transcriptTimestamp: segment.timestampSeconds
                ))
            }
        }

        if configuration.isEnabled(ExtractionRuleCatalog.supportingSoftwareVocabulary) {
            let primaryNames = Set(configuration.primaryTaxSoftwareNames.map { $0.lowercased() })
            let matches = orderedNonoverlappingMatches(
                names: configuration.supportingSoftwareNames.filter {
                    !primaryNames.contains($0.lowercased())
                },
                in: text
            )
            if !matches.isEmpty {
                candidates.append(recordedCandidate(
                    field: .supportingSoftware,
                    value: matches.joined(separator: ", "),
                    segment: segment,
                    approximate: false,
                    ruleID: ExtractionRuleCatalog.supportingSoftwareVocabulary,
                    reason: matches.count == 1
                        ? "Matched an editable supporting-software name."
                        : "Matched multiple supporting-software names and joined them in spoken order."
                ))
            }
        }

        if configuration.isEnabled(ExtractionRuleCatalog.workflowSoftware) {
            candidates.append(contentsOf: workflowSoftwareCandidates(from: text, segment: segment))
        }

        candidates.append(contentsOf: numericCandidates(
            from: text,
            segment: segment,
            configuration: configuration
        ))

        if configuration.isEnabled(ExtractionRuleCatalog.location),
           let location = firstCapture(
            pattern: #"(?i)\b(?:based|located|office)\s+(?:in|out of)\s+([A-Za-z .'-]+(?:,\s*[A-Za-z]{2,})?)"#,
            text: text,
            group: 1
        ) {
            candidates.append(recordedCandidate(
                field: .location,
                value: location,
                segment: segment,
                approximate: false,
                ruleID: ExtractionRuleCatalog.location,
                reason: "Matched a based in, located in, or office out of statement."
            ))
        }

        if configuration.isEnabled(ExtractionRuleCatalog.softwareEnvironment) {
            if text.range(of: "desktop", options: .caseInsensitive) != nil {
                candidates.append(recordedCandidate(field: .taxSoftwareEnvironment, value: "Desktop", segment: segment, approximate: false, ruleID: ExtractionRuleCatalog.softwareEnvironment, reason: "Matched the word desktop."))
            } else if text.range(of: "cloud", options: .caseInsensitive) != nil {
                candidates.append(recordedCandidate(field: .taxSoftwareEnvironment, value: "Cloud", segment: segment, approximate: false, ruleID: ExtractionRuleCatalog.softwareEnvironment, reason: "Matched the word cloud."))
            } else if text.range(of: "hosted", options: .caseInsensitive) != nil {
                candidates.append(recordedCandidate(field: .taxSoftwareEnvironment, value: "Hosted", segment: segment, approximate: false, ruleID: ExtractionRuleCatalog.softwareEnvironment, reason: "Matched the word hosted."))
            }
        }

        return candidates
    }

    private func identityCandidates(
        from text: String,
        segment: TranscriptSegment
    ) -> [FactCandidate] {
        var output: [FactCandidate] = []
        if let name = firstCapture(
            pattern: #"\b(?:My name is|I am|I'm|This is)\s+([A-Z][A-Za-z'-]+(?:\s+[A-Z][A-Za-z'-]+){1,2})\b"#,
            text: text,
            group: 1
        ) {
            output.append(recordedCandidate(
                field: .name,
                value: name,
                segment: segment,
                approximate: false,
                ruleID: ExtractionRuleCatalog.explicitIdentity,
                reason: "Matched an explicit person-name introduction."
            ))
        }

        let firmPatterns = [
            #"(?i)\b(?:firm|company|practice)(?:'s)?\s+(?:name\s+)?(?:is|is called|is named|called|named)\s+([^,.]+)"#,
            #"(?i)\bour new firm is\s+([^,.]+)"#,
            #"(?i)\band\s+([^,.]+)\s+is correct\b"#,
            #"(?i)\bwith\s+([^,]*?(?:CPA(?:s)?|Tax|Accounting|Advisory|Group|Partners|Associates|Services|Lab)(?:\s+(?:Group|Partners|Associates|Services|Lab))?)(?=,|$)"#
        ]
        if let firm = firmPatterns.lazy.compactMap({ pattern in
            firstCapture(pattern: pattern, text: text, group: 1)
        }).first {
            output.append(recordedCandidate(
                field: .firmName,
                value: firm,
                segment: segment,
                approximate: false,
                ruleID: ExtractionRuleCatalog.explicitIdentity,
                reason: "Matched an explicit organization-name statement or confirmation."
            ))
        }
        return output
    }

    private func workflowSoftwareCandidates(
        from text: String,
        segment: TranscriptSegment
    ) -> [FactCandidate] {
        let portalPatterns = [
            #"\b([A-Z][A-Za-z0-9 &'-]*?)\s+(?:is|handles)\s+(?:our\s+)?client portal\b"#,
            #"(?i)\b(?:i|we)\s+(?:currently\s+)?use\s+([A-Z][A-Za-z0-9 &'-]*?\s+Portal)\b"#
        ]
        let practicePatterns = [
            #"\b([A-Z][A-Za-z0-9 &'-]*?)\s+(?:is|handles)\s+(?:our\s+)?practice management\b"#,
            #"\b([A-Z][A-Za-z0-9 &'-]*?)\s+handles\s+(?:our\s+)?client portal and practice management\b"#
        ]
        var output: [FactCandidate] = []
        if let portal = portalPatterns.lazy.compactMap({
            firstCapture(pattern: $0, text: text, group: 1)
        }).first {
            output.append(recordedCandidate(
                field: .clientPortal,
                value: portal,
                segment: segment,
                approximate: false,
                ruleID: ExtractionRuleCatalog.workflowSoftware,
                reason: "Matched an explicitly named client portal."
            ))
        }
        if let practice = practicePatterns.lazy.compactMap({
            firstCapture(pattern: $0, text: text, group: 1)
        }).first {
            output.append(recordedCandidate(
                field: .practiceManagement,
                value: practice,
                segment: segment,
                approximate: false,
                ruleID: ExtractionRuleCatalog.workflowSoftware,
                reason: "Matched an explicitly named practice-management system."
            ))
        }
        return output
    }

    private func explicitlyCurrentSoftware(in text: String, names: [String]) -> String? {
        for name in names.reversed() {
            let escaped = NSRegularExpression.escapedPattern(for: name)
            let pattern = #"(?i)\b(?:currently\s+|now\s+)?(?:use|uses|using|run|runs)\s+"# + escaped + #"\b"#
            guard text.range(of: pattern, options: .regularExpression) != nil else { continue }
            let lower = text.lowercased()
            let nameLower = name.lowercased()
            guard let nameRange = lower.range(of: nameLower) else { continue }
            let prefixStart = lower.index(nameRange.lowerBound, offsetBy: -min(24, lower.distance(from: lower.startIndex, to: nameRange.lowerBound)))
            let prefix = String(lower[prefixStart..<nameRange.lowerBound])
            if ["used to use ", "no longer use ", "previously used "].contains(where: prefix.hasSuffix) {
                continue
            }
            return name
        }
        return nil
    }

    private func isExplicitlyNoncurrentSoftware(_ name: String, in text: String) -> Bool {
        let lower = text.lowercased()
        guard let range = lower.range(of: name.lowercased()) else { return false }
        let distance = lower.distance(from: lower.startIndex, to: range.lowerBound)
        let start = lower.index(range.lowerBound, offsetBy: -min(64, distance))
        let prefix = String(lower[start..<range.lowerBound])
        let escaped = NSRegularExpression.escapedPattern(for: name)
        if text.range(
            of: #"(?i)\b(?:i|we)\s+used\s+"# + escaped + #"\s+for\b"#,
            options: .regularExpression
        ) != nil {
            return true
        }
        return [
            "old firm", "used to", "previously", "no longer", "evaluating",
            "considering", "looking at", "looked at"
        ].contains(where: prefix.contains)
    }

    private func numericCandidates(
        from text: String,
        segment: TranscriptSegment,
        configuration: ExtractionAdminConfiguration
    ) -> [FactCandidate] {
        let patterns: [(ScorecardField, String, String)] = [
            (.totalReturns, #"(?i)\b(?:file|do|prepare|process|have)\s+(?:(?:like|about|around|approximately)\s+){0,2}([\d,]+(?:\s*[-–]\s*[\d,]+)?)\s+(?:total\s+)?(?:tax\s+)?returns?\b"#, ExtractionRuleCatalog.returnVolume),
            (.totalReturns, #"(?i)\btotal(?:\s+returns?)?(?:\s+is|\s+of|:)?\s+(?:about\s+|around\s+|approximately\s+)?([\d,]+(?:\s*[-–]\s*[\d,]+)?)(?=\s+(?:tax\s+)?returns?\b|\s*[.!?]?\s*$)"#, ExtractionRuleCatalog.returnVolume),
            (.totalReturns, #"(?i)\b(?:it\s+is\s+|it's\s+)?(?:about\s+|around\s+|approximately\s+)?([\d,]+(?:\s*[-–]\s*[\d,]+)?)\s+total\s+(?:tax\s+)?returns?\b"#, ExtractionRuleCatalog.returnVolume),
            (.personalReturns, #"(?i)\b([\d,]+(?:\s*[-–]\s*[\d,]+)?)\s+(?:personal|individual|1040)\s+returns?\b"#, ExtractionRuleCatalog.returnVolume),
            (.businessReturns, #"(?i)\b([\d,]+(?:\s*[-–]\s*[\d,]+)?)\s+business\s+returns?\b"#, ExtractionRuleCatalog.returnVolume),
            (.admins, #"(?i)\b([\d,]+)\s+admins?(?:istrators?)?\b"#, ExtractionRuleCatalog.staffCounts),
            (.preparers, #"(?i)\b([\d,]+)\s+(?:tax\s+)?preparers?\b"#, ExtractionRuleCatalog.staffCounts),
            (.reviewers, #"(?i)\b([\d,]+)\s+reviewers?\b"#, ExtractionRuleCatalog.staffCounts),
            (.cpas, #"(?i)\b([\d,]+)\s+CPAs?\b"#, ExtractionRuleCatalog.staffCounts),
            (.annualCommitment, #"(?i)\b([\d,]+)\s+(?:return\s+)?(?:annual|full[- ]year)\s+(?:minimum\s+)?commitment\b"#, ExtractionRuleCatalog.commercialNumbers),
            (.annualCommitment, #"(?i)\b(?:annual\s+(?:minimum\s+)?commitment|annual\s+minimum|full(?:[- ]year)?\s+(?:package\s+)?commitment|(?<!pilot\s)(?<!initial\s)(?<!starter\s)minimum(?:\s+commitment)?)(?:\s+is|\s+of|:)?\s+([\d,]+)\b"#, ExtractionRuleCatalog.commercialNumbers),
            (.pilotCommitment, #"(?i)\b([\d,]+)\s+(?:return\s+)?(?:pilot|initial|starter)\s+(?:minimum\s+)?commitment\b"#, ExtractionRuleCatalog.commercialNumbers),
            (.pilotCommitment, #"(?i)\b(?:pilot|initial|starter)\s+(?:minimum\s+)?commitment(?:\s+is|\s+of|:)?\s+([\d,]+)\b"#, ExtractionRuleCatalog.commercialNumbers),
            (.pilotCommitment, #"(?i)\b(?:can\s+|could\s+|we\s+can\s+|you\s+can\s+)?(?:start|begin|get\s+started)(?:\s+(?:the\s+)?pilot)?\s+(?:with|at)\s+([\d,]+)\b"#, ExtractionRuleCatalog.commercialNumbers)
        ]

        var output: [FactCandidate] = []
        var populatedFields = Set<ScorecardField>()
        for (field, pattern, ruleID) in patterns where configuration.isEnabled(ruleID) {
            guard !populatedFields.contains(field) else { continue }
            guard let value = firstCapture(pattern: pattern, text: text, group: 1) else { continue }
            let approximate = text.range(of: #"(?i)\b(?:about|around|approximately)\b"#, options: .regularExpression) != nil
            output.append(recordedCandidate(
                field: field,
                value: value,
                segment: segment,
                approximate: approximate,
                ruleID: ruleID,
                reason: "Matched an explicit labeled count."
            ))
            populatedFields.insert(field)
        }

        if configuration.isEnabled(ExtractionRuleCatalog.commercialNumbers),
           let price = firstCapture(
            pattern: #"(?i)(\$\s*[\d,]+(?:\.\d{1,2})?\s+per\s+(?:return|month|year|user|seat))\b"#,
            text: text,
            group: 1
           ) {
            output.append(recordedCandidate(
                field: .otherNumbers,
                value: price.replacingOccurrences(of: #"\$\s+"#, with: "$", options: .regularExpression),
                segment: segment,
                approximate: false,
                ruleID: ExtractionRuleCatalog.commercialNumbers,
                reason: "Matched an explicitly stated commercial amount and unit."
            ))
        }

        let vaguePatterns: [(ScorecardField, String)] = [
            (.totalReturns, #"(?i)\b(?:a few|a couple(?:\s+of)?)\s+hundred\s+(?:total\s+)?(?:tax\s+)?returns?\b"#),
            (.personalReturns, #"(?i)\b(?:a few|a couple(?:\s+of)?)\s+hundred\s+(?:personal|individual|1040)\s+returns?\b"#),
            (.businessReturns, #"(?i)\b(?:a few|a couple(?:\s+of)?)\s+hundred\s+business\s+returns?\b"#)
        ]
        if configuration.isEnabled(ExtractionRuleCatalog.vagueHundreds) {
            for (field, pattern) in vaguePatterns where text.range(of: pattern, options: .regularExpression) != nil {
                output.append(recordedCandidate(
                    field: field,
                    value: "200",
                    segment: segment,
                    approximate: true,
                    ruleID: ExtractionRuleCatalog.vagueHundreds,
                    reason: "Normalized a few or a couple hundred to the configured approximate display value 200."
                ))
            }
        }
        return output
    }

    private func orderedNonoverlappingMatches(names: [String], in text: String) -> [String] {
        struct LocatedName {
            let name: String
            let start: Int
            let end: Int
        }

        var located: [LocatedName] = []
        for name in names {
            var searchStart = text.startIndex
            while searchStart < text.endIndex,
                  let range = text.range(
                    of: name,
                    options: [.caseInsensitive, .diacriticInsensitive],
                    range: searchStart..<text.endIndex
                  ) {
                let start = text.distance(from: text.startIndex, to: range.lowerBound)
                let end = text.distance(from: text.startIndex, to: range.upperBound)
                located.append(LocatedName(name: name, start: start, end: end))
                searchStart = range.upperBound
            }
        }

        located.sort {
            if $0.start == $1.start { return ($0.end - $0.start) > ($1.end - $1.start) }
            return $0.start < $1.start
        }

        var selected: [LocatedName] = []
        var selectedNames = Set<String>()
        for match in located {
            guard selectedNames.insert(match.name.lowercased()).inserted else { continue }
            guard !selected.contains(where: { existing in
                match.start < existing.end && existing.start < match.end
            }) else {
                selectedNames.remove(match.name.lowercased())
                continue
            }
            selected.append(match)
        }
        return selected.sorted { $0.start < $1.start }.map(\.name)
    }

    private func recordedCandidate(
        field: ScorecardField,
        value: String,
        segment: TranscriptSegment,
        approximate: Bool,
        ruleID: String,
        reason: String
    ) -> FactCandidate {
        let candidate = FactCandidate(
            field: field,
            value: value,
            quote: segment.text,
            speaker: extractionSpeaker(for: segment),
            timestampSeconds: segment.timestampSeconds,
            confidence: approximate ? .approximate : .exact
        )
        admin.record(ExtractionDecision(
            meetingID: segment.meetingID,
            ruleID: ruleID,
            stage: .deterministic,
            outcome: .accepted,
            field: candidate.field,
            proposedValue: candidate.value,
            reason: reason,
            quote: candidate.quote,
            speaker: candidate.speaker,
            transcriptTimestamp: candidate.timestampSeconds
        ))
        return candidate
    }

    private func isUnconfirmedQuestion(_ text: String) -> Bool {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasSuffix("?") { return true }
        let questionStarts = [
            "do you ", "did you ", "are you ", "is your ", "is it ",
            "how many ", "would you ", "could you ", "what is ", "what's "
        ]
        return questionStarts.contains { normalized.hasPrefix($0) }
    }

    private func firstCapture(pattern: String, text: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let captureRange = Range(match.range(at: group), in: text)
        else { return nil }
        return String(text[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum ExtractionValueCanonicalizer {
    static func modelValue(_ raw: String, for field: ScorecardField) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        switch field {
        case _ where field.isNumeric:
            return singleInteger(trimmed)
        case .primaryTaxSoftware:
            let value = trimmed.replacingOccurrences(
                of: #"(?i)\s+(?:desktop|cloud|hosted)\s*$"#,
                with: "",
                options: .regularExpression
            )
            return value.isEmpty ? nil : value
        case .taxSoftwareEnvironment:
            switch trimmed.lowercased().trimmingCharacters(in: .punctuationCharacters) {
            case "desktop": return "Desktop"
            case "cloud": return "Cloud"
            case "hosted": return "Hosted"
            default: return nil
            }
        case .supportingSoftware:
            let names = softwareListComponents(trimmed)
            return names.isEmpty ? nil : names.joined(separator: ", ")
        default:
            return trimmed
        }
    }

    static func singleInteger(_ raw: String) -> String? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "about ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "around ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "approximately ", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard value.range(
            of: #"^(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$"#,
            options: .regularExpression
        ) != nil else { return nil }
        let digits = value.replacingOccurrences(of: ",", with: "")
        guard let number = Int(digits), number >= 0 else { return nil }
        return String(number)
    }

    static func softwareListComponents(_ raw: String) -> [String] {
        var seen = Set<String>()
        let components = raw.split(separator: ",").compactMap { component -> String? in
            var value = component.trimmingCharacters(in: .whitespacesAndNewlines)
            value = value.replacingOccurrences(
                of: #"(?i)^(?:and|&)\s+"#,
                with: "",
                options: .regularExpression
            )
            value = value.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            guard !value.isEmpty, seen.insert(value.lowercased()).inserted else { return nil }
            return value
        }
        if components.contains(where: { $0.caseInsensitiveCompare("QuickBooks Online") == .orderedSame }) {
            return components.filter { $0.caseInsensitiveCompare("QuickBooks") != .orderedSame }
        }
        return components
    }
}

struct ContextualRuleExtractor: Sendable {
    private let admin: ExtractionAdminRepository

    init(admin: ExtractionAdminRepository = .shared) {
        self.admin = admin
    }

    func extract(from segments: [TranscriptSegment]) -> [FactCandidate] {
        guard let answer = segments.last,
              answer.source != .microphone,
              !ModelEvidenceValidator.isQuestion(answer.text),
              let question = segments.dropLast().reversed().prefix(20).first(where: {
                  ModelEvidenceValidator.isQuestion($0.text)
              }) else { return [] }

        let questionText = question.text.lowercased()
        if questionText.contains("name"),
           ["firm", "practice", "company"].contains(where: questionText.contains) {
            return shortIdentity(from: answer).map { identity in
                recordedCandidate(
                    field: identity.field,
                    value: identity.value,
                    answer: answer,
                    reason: "A labeled short identity answer followed the nearest name-and-firm question."
                )
            }
        }
        if questionText.contains("where"),
           ["calling", "based", "located", "office", "city"].contains(where: questionText.contains),
           let location = shortLocation(from: answer.text) {
            return [recordedCandidate(
                field: .location,
                value: location,
                answer: answer,
                reason: "A short place-name answer followed the nearest location question."
            )]
        }
        if questionText.contains("return") {
            return shortReturnCounts(from: answer)
        }
        return []
    }

    private func shortIdentity(from answer: TranscriptSegment) -> [(field: ScorecardField, value: String)] {
        let parts = answer.text
            .components(separatedBy: CharacterSet(charactersIn: ".;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters)) }
            .filter { !$0.isEmpty }
        guard parts.count >= 2 else { return [] }
        let namePattern = #"^[A-Z][A-Za-z'-]+(?:\s+[A-Z][A-Za-z'-]+){1,2}$"#
        let firmPattern = #"(?i)\b(?:CPA(?:s)?|Tax|Accounting|Advisory|Group|Partners|Associates|Services|Lab)\b"#
        guard parts[0].range(of: namePattern, options: .regularExpression) != nil,
              parts[1].range(of: firmPattern, options: .regularExpression) != nil else { return [] }
        return [(.name, parts[0]), (.firmName, parts[1])]
    }

    private func shortReturnCounts(from answer: TranscriptSegment) -> [FactCandidate] {
        let patterns: [(ScorecardField, String)] = [
            (.totalReturns, #"(?i)\b(?:about\s+|around\s+|approximately\s+)?([\d,]+)\s+total\b"#),
            (.personalReturns, #"(?i)\b([\d,]+)\s+(?:personal|individual|1040)\b"#),
            (.businessReturns, #"(?i)\b([\d,]+)\s+business\b"#)
        ]
        return patterns.compactMap { field, pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(
                    in: answer.text,
                    range: NSRange(answer.text.startIndex..., in: answer.text)
                  ),
                  let valueRange = Range(match.range(at: 1), in: answer.text)
            else { return nil }
            let approximate: Bool
            if let fullRange = Range(match.range(at: 0), in: answer.text) {
                let full = answer.text[fullRange]
                approximate = full.range(
                    of: #"(?i)\b(?:about|around|approximately)\b"#,
                    options: .regularExpression
                ) != nil
            } else {
                approximate = false
            }
            return recordedCandidate(
                field: field,
                value: String(answer.text[valueRange]),
                answer: answer,
                confidence: approximate ? .approximate : .exact,
                reason: "A labeled short return count answered the nearest return-volume question."
            )
        }
    }

    private func shortLocation(from raw: String) -> String? {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let words = value.split(whereSeparator: \.isWhitespace)
        guard (1...5).contains(words.count),
              value.rangeOfCharacter(from: .decimalDigits) == nil,
              value.range(of: #"^[A-Za-z .'-]+(?:,\s*[A-Za-z .'-]+)?$"#, options: .regularExpression) != nil
        else { return nil }
        return value
    }

    private func recordedCandidate(
        field: ScorecardField,
        value: String,
        answer: TranscriptSegment,
        confidence: FactConfidence = .exact,
        reason: String
    ) -> FactCandidate {
        let candidate = FactCandidate(
            field: field,
            value: value,
            quote: answer.text,
            speaker: extractionSpeaker(for: answer),
            timestampSeconds: answer.timestampSeconds,
            confidence: confidence
        )
        admin.record(ExtractionDecision(
            meetingID: answer.meetingID,
            ruleID: ExtractionRuleCatalog.contextualAnswers,
            stage: .deterministic,
            outcome: .accepted,
            field: field,
            proposedValue: value,
            reason: reason,
            quote: answer.text,
            speaker: extractionSpeaker(for: answer),
            transcriptTimestamp: answer.timestampSeconds
        ))
        return candidate
    }
}
