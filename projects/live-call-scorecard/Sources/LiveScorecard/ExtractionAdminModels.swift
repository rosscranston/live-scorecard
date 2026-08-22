import Foundation

enum ExtractionRuleStage: String, Codable, CaseIterable, Sendable {
    case evidence = "EVIDENCE"
    case deterministic = "PATTERN"
    case languageModel = "MODEL"
    case replacement = "UPDATE"
    case inference = "INFERENCE"
}

struct ExtractionAdminRule: Identifiable, Equatable, Sendable {
    let id: String
    let order: Int
    let stage: ExtractionRuleStage
    let title: String
    let explanation: String
    let affectedFields: [ScorecardField]
    let isTunable: Bool
}

enum ExtractionDecisionOutcome: String, Codable, Sendable {
    case accepted = "ACCEPTED"
    case rejected = "REJECTED"
    case replaced = "REPLACED"
    case merged = "MERGED"
    case inferred = "INFERRED"
    case unchanged = "UNCHANGED"
    case unavailable = "UNAVAILABLE"
}

struct ExtractionDecision: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let recordedAt: Date
    let meetingID: UUID?
    let ruleID: String
    let stage: ExtractionRuleStage
    let outcome: ExtractionDecisionOutcome
    let field: ScorecardField?
    let proposedValue: String?
    let previousValue: String?
    let reason: String
    let quote: String?
    let speaker: String?
    let transcriptTimestamp: Double?

    init(
        id: UUID = UUID(),
        recordedAt: Date = Date(),
        meetingID: UUID? = nil,
        ruleID: String,
        stage: ExtractionRuleStage,
        outcome: ExtractionDecisionOutcome,
        field: ScorecardField? = nil,
        proposedValue: String? = nil,
        previousValue: String? = nil,
        reason: String,
        quote: String? = nil,
        speaker: String? = nil,
        transcriptTimestamp: Double? = nil
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.meetingID = meetingID
        self.ruleID = ruleID
        self.stage = stage
        self.outcome = outcome
        self.field = field
        self.proposedValue = proposedValue
        self.previousValue = previousValue
        self.reason = reason
        self.quote = quote
        self.speaker = speaker
        self.transcriptTimestamp = transcriptTimestamp
    }
}

enum FieldReplacementPolicy: String, Codable, CaseIterable, Sendable {
    case latestEvidence = "latest"
    case confirmationRequired = "confirm"
    case keepExisting = "keep"

    var compactLabel: String {
        switch self {
        case .latestEvidence: return "LATEST"
        case .confirmationRequired: return "CONFIRM"
        case .keepExisting: return "KEEP"
        }
    }

    var explanation: String {
        switch self {
        case .latestEvidence:
            return "A newer supported statement may replace the saved value."
        case .confirmationRequired:
            return "A prior-call value needs a direct field statement; a value already captured in this call needs correction language."
        case .keepExisting:
            return "Once populated, only a manual edit may change this field."
        }
    }
}

enum FieldSourcePolicy: String, Codable, CaseIterable, Sendable {
    case prospectOnly = "prospect"
    case rossOnly = "ross"
    case eitherSpeaker = "either"
    case manualOnly = "manual"

    static let speakerChoices: [FieldSourcePolicy] = [
        .prospectOnly,
        .rossOnly,
        .eitherSpeaker
    ]

    var shortLabel: String {
        switch self {
        case .prospectOnly: return "P"
        case .rossOnly: return "R"
        case .eitherSpeaker: return "E"
        case .manualOnly: return "M"
        }
    }

    var compactLabel: String {
        switch self {
        case .prospectOnly: return "PROSPECT"
        case .rossOnly: return "ROSS"
        case .eitherSpeaker: return "EITHER"
        case .manualOnly: return "MANUAL"
        }
    }

    var explanation: String {
        switch self {
        case .prospectOnly:
            return "Only prospect transcript evidence may populate this field. Manual edits remain allowed."
        case .rossOnly:
            return "Only Ross transcript evidence may populate this field. Manual edits remain allowed."
        case .eitherSpeaker:
            return "Either speaker may populate this field when the evidence rules pass."
        case .manualOnly:
            return "Automated extraction cannot populate this field; it must be entered manually."
        }
    }

    func allowsAutomatedCandidate(speaker: String) -> Bool {
        switch self {
        case .prospectOnly: return speaker.uppercased() == "PROSPECT"
        case .rossOnly: return speaker.uppercased() == "ROSS"
        case .eitherSpeaker: return ["PROSPECT", "ROSS"].contains(speaker.uppercased())
        case .manualOnly: return false
        }
    }
}

struct ExtractionAdminConfiguration: Codable, Equatable, Sendable {
    static let currentVersion = 8

    static let defaultPrimaryTaxSoftware =
        "Lacerte, Drake, UltraTax, ProSeries, CCH Axcess, CCH ProSystem fx, ProSystem fx, GoSystem, TaxAct, TaxShark"
    static let defaultSupportingSoftware =
        "QuickBooks, QuickBooks Online, SurePrep, GruntWorx, Adobe Acrobat, DocuSign, Microsoft 365, Google Workspace"

    var version = currentVersion
    var disabledRuleIDs: Set<String> = []
    var languageModelEnabled = true
    var responseTokenReserve = 1_024
    var minimumEvidenceQuoteCharacters = 2
    var modelMayOverrideDeterministic = false
    var protectManualValues = true
    var rejectOlderChangedValues = true
    var approximateMayReplaceExact = false
    var microphoneActsAsProspectForTesting = false
    var primaryTaxSoftwareCSV = defaultPrimaryTaxSoftware
    var supportingSoftwareCSV = defaultSupportingSoftware
    var customModelInstructions = ""
    var fieldSourcePolicies: [String: FieldSourcePolicy] = Self.defaultFieldSourcePolicies
    var fieldReplacementPolicies: [String: FieldReplacementPolicy] = [
        ScorecardField.name.rawValue: .confirmationRequired,
        ScorecardField.firmName.rawValue: .confirmationRequired,
        ScorecardField.location.rawValue: .confirmationRequired,
        ScorecardField.totalReturns.rawValue: .confirmationRequired,
        ScorecardField.primaryTaxSoftware.rawValue: .confirmationRequired,
        ScorecardField.taxSoftwareEnvironment.rawValue: .confirmationRequired,
        ScorecardField.taxSoftwareHost.rawValue: .confirmationRequired,
        ScorecardField.clientPortal.rawValue: .confirmationRequired,
        ScorecardField.practiceManagement.rawValue: .confirmationRequired,
        ScorecardField.annualCommitment.rawValue: .confirmationRequired,
        ScorecardField.pilotCommitment.rawValue: .confirmationRequired
    ]

    static let standard = ExtractionAdminConfiguration()

    static let defaultFieldSourcePolicies: [String: FieldSourcePolicy] = {
        var policies = Dictionary(
            uniqueKeysWithValues: ScorecardField.displayOrder.map {
                ($0.rawValue, FieldSourcePolicy.prospectOnly)
            }
        )
        for field in [ScorecardField.annualCommitment, .pilotCommitment, .otherNumbers] {
            policies[field.rawValue] = .rossOnly
        }
        // Manual entry is available for every field independently of speaker policy.
        // Timezone inference and manual Notes do not require a separate MANUAL source state.
        policies[ScorecardField.timezone.rawValue] = .eitherSpeaker
        policies[ScorecardField.notes.rawValue] = .eitherSpeaker
        return policies
    }()

    static let configurableReplacementFields: [ScorecardField] =
        ScorecardField.displayOrder.filter { field in
            field != .timezone && field != .supportingSoftware
        }

    init() {}

    private enum CodingKeys: String, CodingKey {
        case version
        case disabledRuleIDs
        case languageModelEnabled
        case responseTokenReserve
        // Retained only so version 3 preferences decode cleanly. Context is now
        // selected dynamically by tokens instead of a fixed segment count.
        case contextSegmentCount
        case minimumEvidenceQuoteCharacters
        case modelMayOverrideDeterministic
        case protectManualValues
        case rejectOlderChangedValues
        case approximateMayReplaceExact
        case microphoneActsAsProspectForTesting
        case primaryTaxSoftwareCSV
        case supportingSoftwareCSV
        case customModelInstructions
        case fieldSourcePolicies
        case fieldReplacementPolicies
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = try values.decodeIfPresent(Int.self, forKey: .version) ?? 1
        disabledRuleIDs = try values.decodeIfPresent(Set<String>.self, forKey: .disabledRuleIDs) ?? []
        languageModelEnabled = try values.decodeIfPresent(Bool.self, forKey: .languageModelEnabled) ?? true
        responseTokenReserve = try values.decodeIfPresent(Int.self, forKey: .responseTokenReserve) ?? 1_024
        _ = try values.decodeIfPresent(Int.self, forKey: .contextSegmentCount)
        minimumEvidenceQuoteCharacters = try values.decodeIfPresent(Int.self, forKey: .minimumEvidenceQuoteCharacters) ?? 2
        modelMayOverrideDeterministic = try values.decodeIfPresent(Bool.self, forKey: .modelMayOverrideDeterministic) ?? false
        protectManualValues = try values.decodeIfPresent(Bool.self, forKey: .protectManualValues) ?? true
        rejectOlderChangedValues = try values.decodeIfPresent(Bool.self, forKey: .rejectOlderChangedValues) ?? true
        approximateMayReplaceExact = try values.decodeIfPresent(Bool.self, forKey: .approximateMayReplaceExact) ?? false
        microphoneActsAsProspectForTesting = try values.decodeIfPresent(
            Bool.self,
            forKey: .microphoneActsAsProspectForTesting
        ) ?? false
        primaryTaxSoftwareCSV = try values.decodeIfPresent(String.self, forKey: .primaryTaxSoftwareCSV)
            ?? Self.defaultPrimaryTaxSoftware
        supportingSoftwareCSV = try values.decodeIfPresent(String.self, forKey: .supportingSoftwareCSV)
            ?? Self.defaultSupportingSoftware
        customModelInstructions = try values.decodeIfPresent(String.self, forKey: .customModelInstructions) ?? ""
        fieldSourcePolicies = try values.decodeIfPresent(
            [String: FieldSourcePolicy].self,
            forKey: .fieldSourcePolicies
        ) ?? Self.defaultFieldSourcePolicies
        fieldReplacementPolicies = try values.decodeIfPresent(
            [String: FieldReplacementPolicy].self,
            forKey: .fieldReplacementPolicies
        ) ?? [
            ScorecardField.name.rawValue: .confirmationRequired,
            ScorecardField.firmName.rawValue: .confirmationRequired,
            ScorecardField.location.rawValue: .confirmationRequired,
            ScorecardField.totalReturns.rawValue: .confirmationRequired,
            ScorecardField.primaryTaxSoftware.rawValue: .confirmationRequired,
            ScorecardField.taxSoftwareEnvironment.rawValue: .confirmationRequired,
            ScorecardField.taxSoftwareHost.rawValue: .confirmationRequired,
            ScorecardField.clientPortal.rawValue: .confirmationRequired,
            ScorecardField.practiceManagement.rawValue: .confirmationRequired,
            ScorecardField.annualCommitment.rawValue: .confirmationRequired,
            ScorecardField.pilotCommitment.rawValue: .confirmationRequired
        ]
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(version, forKey: .version)
        try values.encode(disabledRuleIDs, forKey: .disabledRuleIDs)
        try values.encode(languageModelEnabled, forKey: .languageModelEnabled)
        try values.encode(responseTokenReserve, forKey: .responseTokenReserve)
        try values.encode(minimumEvidenceQuoteCharacters, forKey: .minimumEvidenceQuoteCharacters)
        try values.encode(modelMayOverrideDeterministic, forKey: .modelMayOverrideDeterministic)
        try values.encode(protectManualValues, forKey: .protectManualValues)
        try values.encode(rejectOlderChangedValues, forKey: .rejectOlderChangedValues)
        try values.encode(approximateMayReplaceExact, forKey: .approximateMayReplaceExact)
        try values.encode(microphoneActsAsProspectForTesting, forKey: .microphoneActsAsProspectForTesting)
        try values.encode(primaryTaxSoftwareCSV, forKey: .primaryTaxSoftwareCSV)
        try values.encode(supportingSoftwareCSV, forKey: .supportingSoftwareCSV)
        try values.encode(customModelInstructions, forKey: .customModelInstructions)
        try values.encode(fieldSourcePolicies, forKey: .fieldSourcePolicies)
        try values.encode(fieldReplacementPolicies, forKey: .fieldReplacementPolicies)
    }

    func isEnabled(_ ruleID: String) -> Bool {
        !disabledRuleIDs.contains(ruleID)
    }

    var primaryTaxSoftwareNames: [String] {
        Self.softwareNames(from: primaryTaxSoftwareCSV)
    }

    var supportingSoftwareNames: [String] {
        Self.softwareNames(from: supportingSoftwareCSV)
    }

    func replacementPolicy(for field: ScorecardField) -> FieldReplacementPolicy {
        fieldReplacementPolicies[field.rawValue] ?? .latestEvidence
    }

    func sourcePolicy(for field: ScorecardField) -> FieldSourcePolicy {
        fieldSourcePolicies[field.rawValue]
            ?? Self.defaultFieldSourcePolicies[field.rawValue]
            ?? .eitherSpeaker
    }

    mutating func setSourcePolicy(_ policy: FieldSourcePolicy, for field: ScorecardField) {
        fieldSourcePolicies[field.rawValue] = policy
    }

    mutating func setReplacementPolicy(_ policy: FieldReplacementPolicy, for field: ScorecardField) {
        if policy == .latestEvidence {
            fieldReplacementPolicies.removeValue(forKey: field.rawValue)
        } else {
            fieldReplacementPolicies[field.rawValue] = policy
        }
    }

    func sanitized() -> ExtractionAdminConfiguration {
        let tunableIDs = Set(ExtractionRuleCatalog.ordered.filter(\.isTunable).map(\.id))
        var copy = self
        if version < 3 {
            if copy.fieldReplacementPolicies[ScorecardField.name.rawValue] == nil {
                copy.fieldReplacementPolicies[ScorecardField.name.rawValue] = .keepExisting
            }
        }
        if version < 5 {
            for field in [
                ScorecardField.firmName,
                .location,
                .totalReturns,
                .primaryTaxSoftware,
                .taxSoftwareEnvironment,
                .taxSoftwareHost,
                .clientPortal,
                .practiceManagement
            ] where copy.fieldReplacementPolicies[field.rawValue] == nil {
                copy.fieldReplacementPolicies[field.rawValue] = .confirmationRequired
            }
        }
        if version < 6 {
            for field in [ScorecardField.annualCommitment, .pilotCommitment]
            where copy.fieldReplacementPolicies[field.rawValue] == nil {
                copy.fieldReplacementPolicies[field.rawValue] = .confirmationRequired
            }
        }
        if version < 7 {
            for (field, policy) in Self.defaultFieldSourcePolicies
            where copy.fieldSourcePolicies[field] == nil {
                copy.fieldSourcePolicies[field] = policy
            }
            if copy.fieldReplacementPolicies[ScorecardField.name.rawValue] == .keepExisting {
                copy.fieldReplacementPolicies[ScorecardField.name.rawValue] = .confirmationRequired
            }
        }
        if version < 8 {
            for (field, policy) in copy.fieldSourcePolicies where policy == .manualOnly {
                copy.fieldSourcePolicies[field] = .eitherSpeaker
            }
        }
        copy.version = Self.currentVersion
        copy.disabledRuleIDs = disabledRuleIDs.intersection(tunableIDs)
        copy.responseTokenReserve = min(max(responseTokenReserve, 512), 1_536)
        copy.minimumEvidenceQuoteCharacters = min(max(minimumEvidenceQuoteCharacters, 2), 80)
        copy.primaryTaxSoftwareCSV = Self.softwareNames(from: primaryTaxSoftwareCSV).joined(separator: ", ")
        copy.supportingSoftwareCSV = Self.softwareNames(from: supportingSoftwareCSV).joined(separator: ", ")
        copy.customModelInstructions = String(
            customModelInstructions
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(4_000)
        )
        let allowedFields = Set(Self.configurableReplacementFields.map(\.rawValue))
        copy.fieldReplacementPolicies = copy.fieldReplacementPolicies.filter { allowedFields.contains($0.key) }
        let sourceFields = Set(ScorecardField.displayOrder.map(\.rawValue))
        copy.fieldSourcePolicies = copy.fieldSourcePolicies.filter { sourceFields.contains($0.key) }
        for (field, policy) in copy.fieldSourcePolicies where policy == .manualOnly {
            copy.fieldSourcePolicies[field] = .eitherSpeaker
        }
        for (field, policy) in Self.defaultFieldSourcePolicies where copy.fieldSourcePolicies[field] == nil {
            copy.fieldSourcePolicies[field] = policy
        }
        return copy
    }

    private static func softwareNames(from value: String) -> [String] {
        var seen = Set<String>()
        let names = value
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { name in
                guard !name.isEmpty else { return false }
                return seen.insert(name.lowercased()).inserted
            }
        return Array(names.prefix(100))
    }
}

enum ExtractionRuleCatalog {
    static let questionEvidence = "evidence.ignore-question"
    static let exactQuoteEvidence = "evidence.require-exact-quote"
    static let rejectPlaceholder = "evidence.reject-placeholder"
    static let literalValueEvidence = "evidence.require-literal-value"
    static let fieldContextEvidence = "evidence.require-field-context"
    static let fieldSourceEvidence = "evidence.require-field-speaker"
    static let explicitIdentity = "pattern.explicit-identity"
    static let contextualAnswers = "pattern.contextual-answer"
    static let knownTaxSoftware = "pattern.known-tax-software"
    static let returnVolume = "pattern.return-volume"
    static let vagueHundreds = "pattern.vague-hundreds"
    static let staffCounts = "pattern.staff-counts"
    static let commercialNumbers = "pattern.commercial-numbers"
    static let location = "pattern.location"
    static let softwareEnvironment = "pattern.software-environment"
    static let supportingSoftwareVocabulary = "pattern.supporting-software"
    static let workflowSoftware = "pattern.workflow-software"
    static let adaptiveTokenWindow = "model.adaptive-token-window"
    static let modelExtraction = "model.context-extraction"
    static let modelMerge = "model.merge-with-patterns"
    static let protectManual = "update.protect-manual"
    static let rejectOlder = "update.reject-older-evidence"
    static let fieldReplacementPolicy = "update.field-policy"
    static let confidenceGate = "update.confidence-gate"
    static let supportingSoftwareMerge = "update.merge-supporting-software"
    static let calendarIdentity = "inference.calendar-identity"
    static let locationTimezone = "inference.location-timezone"
    static let calculateReturnTotal = "inference.calculate-total-returns"

    static let ordered: [ExtractionAdminRule] = [
        rule(10, questionEvidence, .evidence, "Ignore unconfirmed questions", "A number in a question is not evidence unless a later statement confirms it.", ScorecardField.displayOrder, false),
        rule(20, exactQuoteEvidence, .evidence, "Require transcript evidence", "Model facts are accepted only when their exact quote appears in the recent transcript window.", ScorecardField.displayOrder, false),
        rule(22, rejectPlaceholder, .evidence, "Leave unknown fields blank", "Unknown, not specified, none, and similar model placeholders are rejected instead of being written to the scorecard.", ScorecardField.displayOrder, false),
        rule(24, literalValueEvidence, .evidence, "Require literal value words", "Every model value must appear verbatim in its quoted transcript evidence. Comma-separated supporting tools are checked one by one.", ScorecardField.displayOrder, false),
        rule(26, fieldContextEvidence, .evidence, "Match answers to field questions", "A model value must either explicitly name its field or answer the nearest recognized question for that field.", ScorecardField.displayOrder, false),
        rule(27, fieldSourceEvidence, .evidence, "Require configured speaker", "Each field can require prospect evidence, Ross evidence, either speaker, or manual entry only. Manual corrections remain allowed.", ScorecardField.displayOrder, false),
        rule(28, explicitIdentity, .deterministic, "Recognize explicit identity", "Recognizes a person's direct introduction and an explicitly named or confirmed firm without guessing from unrelated answers.", [.name, .firmName], false),
        rule(29, contextualAnswers, .deterministic, "Link short contextual answers", "Links a short prospect identity, location, or labeled return-count answer to the closest explicit question without borrowing older topics.", [.name, .firmName, .location, .totalReturns, .personalReturns, .businessReturns], false),
        rule(30, knownTaxSoftware, .deterministic, "Recognize primary tax software", "Matches the editable primary tax-software vocabulary and uses explicit current-use language when historical or evaluated products are also named.", [.primaryTaxSoftware], true),
        rule(40, returnVolume, .deterministic, "Recognize explicit return counts", "Recognizes one total, personal or 1040, or business return count and stores it without display commas.", [.totalReturns, .personalReturns, .businessReturns], true),
        rule(50, vagueHundreds, .deterministic, "Normalize vague hundreds", "Converts a few hundred or a couple hundred returns to 200 and marks the value approximate.", [.totalReturns, .personalReturns, .businessReturns], true),
        rule(60, staffCounts, .deterministic, "Recognize staff by role", "Keeps administrators, preparers, reviewers, and CPAs as separate counts.", [.admins, .preparers, .reviewers, .cpas], true),
        rule(65, commercialNumbers, .deterministic, "Recognize commercial numbers", "Keeps the full annual commitment separate from the smaller pilot or start-now commitment, and recognizes prices only with an explicit unit.", [.annualCommitment, .pilotCommitment, .otherNumbers], true),
        rule(70, location, .deterministic, "Recognize stated location", "Matches statements such as based in, located in, or office out of a place.", [.location], true),
        rule(80, softwareEnvironment, .deterministic, "Recognize software environment", "Classifies an explicit desktop, cloud, or hosted statement.", [.taxSoftwareEnvironment], true),
        rule(85, supportingSoftwareVocabulary, .deterministic, "Recognize supporting software", "Matches every editable supporting-software name in a transcript segment and stores distinct names as one comma-separated value.", [.supportingSoftware], true),
        rule(86, workflowSoftware, .deterministic, "Recognize workflow systems", "Recognizes an explicitly named client portal or practice-management system from role language.", [.clientPortal, .practiceManagement], false),
        rule(88, adaptiveTokenWindow, .languageModel, "Fit transcript to token window", "Measures instructions, schema, and transcript with Apple's tokenizer, then includes the largest recent transcript suffix that leaves the configured response reserve.", ScorecardField.displayOrder, false),
        rule(90, modelExtraction, .languageModel, "Extract contextual facts", "When Apple Intelligence is enabled and available, evaluates the token-fitted recent transcript window and returns only quoted facts.", ScorecardField.displayOrder, false),
        rule(100, modelMerge, .languageModel, "Merge model and pattern results", "Pattern results remain authoritative by default. The model fills fields the patterns did not find, unless model override is explicitly enabled.", ScorecardField.displayOrder, false),
        rule(110, protectManual, .replacement, "Protect manual or locked values", "Automated candidates cannot replace a value marked manual while protection is enabled.", ScorecardField.displayOrder, false),
        rule(120, rejectOlder, .replacement, "Reject older changed evidence", "A changed value with an older transcript timestamp cannot replace newer evidence while this guard is enabled.", ScorecardField.displayOrder, false),
        rule(125, fieldReplacementPolicy, .replacement, "Apply field replacement policy", "Each field can accept the latest evidence, require confirmation or correction, or keep its first populated value until manually edited.", ExtractionAdminConfiguration.configurableReplacementFields, false),
        rule(130, confidenceGate, .replacement, "Protect exact values from estimates", "An approximate changed value cannot replace an exact value unless that override is explicitly enabled.", ScorecardField.displayOrder, false),
        rule(140, supportingSoftwareMerge, .replacement, "Merge supporting software", "Supporting tools are appended case-insensitively instead of replacing the existing list.", [.supportingSoftware], false),
        rule(145, calendarIdentity, .inference, "Seed calendar identity", "Uses the attendee name and email domain as editable identity seeds while keeping transcript speaker rules intact.", [.name, .firmName], false),
        rule(150, locationTimezone, .inference, "Infer timezone from location", "Adds a timezone only when the location resolves unambiguously.", [.location, .timezone], false),
        rule(160, calculateReturnTotal, .inference, "Calculate missing total returns", "Adds personal and business returns only when no direct total exists, or refreshes a previously inferred total.", [.totalReturns, .personalReturns, .businessReturns], false)
    ]

    private static func rule(
        _ order: Int,
        _ id: String,
        _ stage: ExtractionRuleStage,
        _ title: String,
        _ explanation: String,
        _ fields: [ScorecardField],
        _ isTunable: Bool
    ) -> ExtractionAdminRule {
        ExtractionAdminRule(
            id: id,
            order: order,
            stage: stage,
            title: title,
            explanation: explanation,
            affectedFields: fields,
            isTunable: isTunable
        )
    }
}
