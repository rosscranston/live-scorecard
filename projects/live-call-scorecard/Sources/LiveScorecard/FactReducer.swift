import Foundation

struct FactReducer: Sendable {
    private let timeZoneResolver = TimeZoneResolver()
    private let admin: ExtractionAdminRepository

    init(admin: ExtractionAdminRepository = .shared) {
        self.admin = admin
    }

    func applying(
        _ candidates: [FactCandidate],
        to existing: [ScorecardField: ScorecardFact],
        meetingID: UUID,
        now: Date = Date()
    ) -> [ScorecardField: ScorecardFact] {
        var result = existing
        let configuration = admin.configuration

        for candidate in candidates {
            if candidate.confidence != .manual,
               ModelEvidenceValidator.isPlaceholder(candidate.value) {
                record(
                    candidate,
                    meetingID: meetingID,
                    ruleID: ExtractionRuleCatalog.rejectPlaceholder,
                    outcome: .rejected,
                    previousValue: result[candidate.field]?.value,
                    reason: "Unknown or missing-value placeholders are left blank."
                )
                continue
            }
            if candidate.confidence != .manual {
                let sourcePolicy = configuration.sourcePolicy(for: candidate.field)
                guard sourcePolicy.allowsAutomatedCandidate(speaker: candidate.speaker) else {
                    record(
                        candidate,
                        meetingID: meetingID,
                        ruleID: ExtractionRuleCatalog.fieldSourceEvidence,
                        outcome: .rejected,
                        previousValue: result[candidate.field]?.value,
                        reason: "\(candidate.field.label) is locked to \(sourcePolicy.compactLabel) evidence; \(candidate.speaker.uppercased()) cannot populate it."
                    )
                    continue
                }
            }
            let normalizedValue = normalize(candidate.value, for: candidate.field)
            guard !normalizedValue.isEmpty else {
                record(
                    candidate,
                    meetingID: meetingID,
                    ruleID: ExtractionRuleCatalog.confidenceGate,
                    outcome: .rejected,
                    previousValue: result[candidate.field]?.value,
                    reason: "The proposed value was empty after normalization."
                )
                continue
            }

            if candidate.field == .supportingSoftware,
               let current = result[candidate.field] {
                let merged = mergeList(current.value, normalizedValue)
                guard merged != current.value else {
                    record(
                        candidate,
                        meetingID: meetingID,
                        ruleID: ExtractionRuleCatalog.supportingSoftwareMerge,
                        outcome: .unchanged,
                        previousValue: current.value,
                        reason: "Every proposed supporting tool is already in the saved list."
                    )
                    continue
                }
                result[candidate.field] = makeFact(
                    candidate: candidate,
                    value: merged,
                    meetingID: meetingID,
                    now: now
                )
                record(
                    candidate,
                    meetingID: meetingID,
                    ruleID: ExtractionRuleCatalog.supportingSoftwareMerge,
                    outcome: .merged,
                    previousValue: current.value,
                    reason: "New supporting tools were appended without duplicating existing names."
                )
            } else if let current = result[candidate.field] {
                let decision = replacementDecision(
                    candidate: candidate,
                    normalizedValue: normalizedValue,
                    current: current,
                    configuration: configuration
                )
                record(
                    candidate,
                    meetingID: meetingID,
                    ruleID: decision.ruleID,
                    outcome: decision.outcome,
                    previousValue: current.value,
                    reason: decision.reason
                )
                guard decision.shouldReplace else { continue }
                result[candidate.field] = makeFact(
                    candidate: candidate,
                    value: normalizedValue,
                    meetingID: meetingID,
                    now: now
                )
            } else {
                result[candidate.field] = makeFact(
                    candidate: candidate,
                    value: normalizedValue,
                    meetingID: meetingID,
                    now: now
                )
                record(
                    candidate,
                    meetingID: meetingID,
                    ruleID: ExtractionRuleCatalog.confidenceGate,
                    outcome: .accepted,
                    previousValue: nil,
                    reason: "The field was empty, so the normalized candidate became its first value."
                )
            }
        }

        if let location = result[.location] {
            switch timeZoneResolver.resolve(location.value) {
            case .resolved(let identifier):
                let candidate = FactCandidate(
                    field: .timezone,
                    value: identifier,
                    quote: location.quote,
                    speaker: location.speaker,
                    timestampSeconds: location.timestampSeconds,
                    confidence: .inferred
                )
                if let current = result[.timezone],
                   current.confidence == .manual,
                   configuration.protectManualValues {
                    record(
                        candidate,
                        meetingID: meetingID,
                        ruleID: ExtractionRuleCatalog.protectManual,
                        outcome: .rejected,
                        previousValue: current.value,
                        reason: "The inferred timezone cannot replace a manual or locked timezone."
                    )
                } else if result[.timezone]?.value != identifier || result[.timezone]?.confidence != .inferred {
                    let previous = result[.timezone]
                    result[.timezone] = makeFact(
                        candidate: candidate,
                        value: identifier,
                        meetingID: meetingID,
                        now: now
                    )
                    record(
                        candidate,
                        meetingID: meetingID,
                        ruleID: ExtractionRuleCatalog.locationTimezone,
                        outcome: .inferred,
                        previousValue: previous?.value,
                        reason: "The location resolved unambiguously to this timezone."
                    )
                }
            case .ambiguous:
                if result[.timezone]?.confidence == .inferred {
                    let previous = result[.timezone]
                    result.removeValue(forKey: .timezone)
                    admin.record(ExtractionDecision(
                        meetingID: meetingID,
                        ruleID: ExtractionRuleCatalog.locationTimezone,
                        stage: .inference,
                        outcome: .rejected,
                        field: .timezone,
                        previousValue: previous?.value,
                        reason: "The updated location is ambiguous, so the previous inferred timezone was removed.",
                        quote: location.quote,
                        speaker: location.speaker,
                        transcriptTimestamp: location.timestampSeconds
                    ))
                }
            case .unknown:
                admin.record(ExtractionDecision(
                    meetingID: meetingID,
                    ruleID: ExtractionRuleCatalog.locationTimezone,
                    stage: .inference,
                    outcome: .rejected,
                    field: .timezone,
                    previousValue: result[.timezone]?.value,
                    reason: "The location was not specific enough to infer a timezone.",
                    quote: location.quote,
                    speaker: location.speaker,
                    transcriptTimestamp: location.timestampSeconds
                ))
            }
        }

        if result[.totalReturns] == nil || result[.totalReturns]?.confidence == .inferred,
           let personal = integerValue(result[.personalReturns]?.value),
           let business = integerValue(result[.businessReturns]?.value) {
            let candidate = FactCandidate(
                field: .totalReturns,
                value: String(personal + business),
                quote: "Calculated from personal and business returns",
                speaker: "SYSTEM",
                timestampSeconds: max(
                    result[.personalReturns]?.timestampSeconds ?? 0,
                    result[.businessReturns]?.timestampSeconds ?? 0
                ),
                confidence: .inferred
            )
            result[.totalReturns] = makeFact(
                candidate: candidate,
                value: candidate.value,
                meetingID: meetingID,
                now: now
            )
            record(
                candidate,
                meetingID: meetingID,
                ruleID: ExtractionRuleCatalog.calculateReturnTotal,
                outcome: .inferred,
                previousValue: existing[.totalReturns]?.value,
                reason: "No direct total was present, so personal and business return counts were added."
            )
        }

        return result
    }

    func manualFact(
        field: ScorecardField,
        value: String,
        meetingID: UUID,
        now: Date = Date()
    ) -> ScorecardFact? {
        let normalized = normalize(value, for: field)
        guard !normalized.isEmpty else { return nil }
        let fact = ScorecardFact(
            meetingID: meetingID,
            field: field,
            value: normalized,
            quote: "Manually entered",
            speaker: "ROSS",
            timestampSeconds: 0,
            confidence: .manual,
            effectiveAt: now,
            updatedAt: now,
            isPrior: false
        )
        admin.record(ExtractionDecision(
            meetingID: meetingID,
            ruleID: ExtractionRuleCatalog.protectManual,
            stage: .replacement,
            outcome: .accepted,
            field: field,
            proposedValue: normalized,
            reason: "The value was entered manually and is protected from automated replacement by default.",
            quote: fact.quote,
            speaker: fact.speaker,
            transcriptTimestamp: fact.timestampSeconds
        ))
        return fact
    }

    private func replacementDecision(
        candidate: FactCandidate,
        normalizedValue: String,
        current: ScorecardFact,
        configuration: ExtractionAdminConfiguration
    ) -> (shouldReplace: Bool, ruleID: String, outcome: ExtractionDecisionOutcome, reason: String) {
        if current.confidence == .manual,
           candidate.confidence != .manual,
           configuration.protectManualValues {
            return (
                false,
                ExtractionRuleCatalog.protectManual,
                .rejected,
                "The existing value is manual or locked, so automated evidence cannot replace it."
            )
        }

        if normalizedValue == current.value {
            if confidenceRank(candidate.confidence) > confidenceRank(current.confidence) {
                return (
                    true,
                    ExtractionRuleCatalog.confidenceGate,
                    .replaced,
                    "The value is unchanged, but the new evidence has stronger confidence."
                )
            }
            return (
                false,
                ExtractionRuleCatalog.confidenceGate,
                .unchanged,
                "The normalized value already matches the saved value, so no update was needed."
            )
        }

        if candidate.timestampSeconds < current.timestampSeconds,
           configuration.rejectOlderChangedValues {
            return (
                false,
                ExtractionRuleCatalog.rejectOlder,
                .rejected,
                "The changed value came from older transcript evidence than the saved value."
            )
        }

        switch configuration.replacementPolicy(for: candidate.field) {
        case .latestEvidence:
            break
        case .keepExisting where candidate.confidence != .manual:
            return (
                false,
                ExtractionRuleCatalog.fieldReplacementPolicy,
                .rejected,
                "This field is configured to keep its existing value until Ross edits it manually."
            )
        case .confirmationRequired where candidate.confidence != .manual:
            guard isConfirmedReplacement(candidate, current: current) else {
                return (
                    false,
                    ExtractionRuleCatalog.fieldReplacementPolicy,
                    .rejected,
                    current.isPrior || current.confidence == .inferred
                        ? "Replacing this prior or calculated value requires a direct statement naming the field."
                        : "Changing a value already captured in this call requires explicit correction or confirmation language."
                )
            }
        case .keepExisting, .confirmationRequired:
            break
        }

        if current.confidence == .exact,
           candidate.confidence == .approximate,
           !configuration.approximateMayReplaceExact {
            return (
                false,
                ExtractionRuleCatalog.confidenceGate,
                .rejected,
                "An approximate value cannot replace an exact value while the confidence guard is enabled."
            )
        }

        return (
            true,
            ExtractionRuleCatalog.confidenceGate,
            .replaced,
            candidate.timestampSeconds > current.timestampSeconds
                ? "Newer transcript evidence changed the value."
                : "Evidence at the same transcript time changed the value with allowed confidence."
        )
    }

    private func isConfirmedReplacement(
        _ candidate: FactCandidate,
        current: ScorecardFact
    ) -> Bool {
        let quote = candidate.quote
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !quote.isEmpty, !quote.hasSuffix("?") else { return false }

        let correctionCues = [
            "actually", "correction", "correct that", "let me correct", "correct the",
            "i meant", "make that",
            "rather", "instead", "not ", "sorry", "should be", "changed to",
            "updated to", "we now", "currently", "that's right", "that is right",
            "yes,", "yes "
        ]
        if correctionCues.contains(where: quote.contains) { return true }

        guard current.isPrior || current.confidence == .inferred else { return false }
        return directStatementKeywords(for: candidate.field).contains(where: quote.contains)
    }

    private func directStatementKeywords(for field: ScorecardField) -> [String] {
        switch field {
        case .name: return ["my name is", "i am ", "i'm ", "this is "]
        case .firmName: return ["firm", "company", "practice", "we're ", "we are "]
        case .location: return ["based in", "located in", "office in", "office out of"]
        case .timezone: return ["timezone", "time zone"]
        case .totalReturns: return ["total return", "tax return", "returns"]
        case .personalReturns: return ["personal", "individual", "1040"]
        case .businessReturns: return ["business", "1065", "1120", "partnership", "corporate"]
        case .primaryTaxSoftware: return ["tax software", "use ", "using "]
        case .taxSoftwareEnvironment: return ["desktop", "cloud", "hosted"]
        case .taxSoftwareHost: return ["host", "hosting"]
        case .clientPortal: return ["portal", "client upload", "clients upload"]
        case .practiceManagement: return ["practice management", "workflow", "manage the practice"]
        case .supportingSoftware: return ["software", "tool", "use ", "using "]
        case .admins: return ["admin", "administrator"]
        case .preparers: return ["preparer", "prepare returns"]
        case .reviewers: return ["reviewer", "doing review", "review returns"]
        case .cpas: return ["cpa", "certified public accountant"]
        case .annualCommitment: return ["annual", "commitment", "minimum", "full package"]
        case .pilotCommitment: return ["pilot", "initial", "start with", "get started"]
        case .otherNumbers: return ["number", "amount", "fee", "price", "cost"]
        case .notes: return ["note"]
        }
    }

    private func confidenceRank(_ confidence: FactConfidence) -> Int {
        switch confidence {
        case .manual: return 5
        case .exact: return 4
        case .approximate: return 3
        case .inferred: return 2
        case .conflict: return 1
        case .prior: return 0
        }
    }

    private func record(
        _ candidate: FactCandidate,
        meetingID: UUID,
        ruleID: String,
        outcome: ExtractionDecisionOutcome,
        previousValue: String?,
        reason: String
    ) {
        let stage = ExtractionRuleCatalog.ordered.first(where: { $0.id == ruleID })?.stage ?? .replacement
        admin.record(ExtractionDecision(
            meetingID: meetingID,
            ruleID: ruleID,
            stage: stage,
            outcome: outcome,
            field: candidate.field,
            proposedValue: candidate.value,
            previousValue: previousValue,
            reason: reason,
            quote: candidate.quote,
            speaker: candidate.speaker,
            transcriptTimestamp: candidate.timestampSeconds
        ))
    }

    private func makeFact(
        candidate: FactCandidate,
        value: String,
        meetingID: UUID,
        now: Date
    ) -> ScorecardFact {
        ScorecardFact(
            meetingID: meetingID,
            field: candidate.field,
            value: value,
            quote: candidate.quote,
            speaker: candidate.speaker,
            timestampSeconds: candidate.timestampSeconds,
            confidence: candidate.confidence,
            effectiveAt: now,
            updatedAt: now,
            isPrior: false
        )
    }

    private func normalize(_ raw: String, for field: ScorecardField) -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }

        if field == .taxSoftwareEnvironment {
            return ExtractionValueCanonicalizer.modelValue(value, for: field) ?? ""
        }

        if field == .supportingSoftware {
            return ExtractionValueCanonicalizer.softwareListComponents(value).joined(separator: ", ")
        }

        if field.isNumeric {
            return ExtractionValueCanonicalizer.singleInteger(value) ?? ""
        }

        return value
    }

    private func integerValue(_ value: String?) -> Int? {
        guard let value,
              let normalized = ExtractionValueCanonicalizer.singleInteger(value) else { return nil }
        return Int(normalized)
    }

    private func mergeList(_ old: String, _ new: String) -> String {
        var seen = Set<String>()
        let values = ExtractionValueCanonicalizer.softwareListComponents(old + ", " + new)
        return values.filter { seen.insert($0.lowercased()).inserted }.joined(separator: ", ")
    }
}
