import Foundation

enum EvaluationExporter {
    static func export(
        meeting: MeetingRecord,
        facts: [ScorecardFact],
        decisions: [ExtractionDecision],
        databaseURL: URL,
        destinationDirectory: URL? = nil
    ) throws -> URL {
        let directory = destinationDirectory
            ?? databaseURL.deletingLastPathComponent().appendingPathComponent("Evaluations", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let baseName = "\(dayFormatter.string(from: meeting.startedAt)) - \(safeFilename(meeting.title))"
        var destination = directory.appendingPathComponent(baseName).appendingPathExtension("md")
        if FileManager.default.fileExists(atPath: destination.path) {
            destination = directory
                .appendingPathComponent("\(baseName) - \(meeting.id.uuidString.prefix(8))")
                .appendingPathExtension("md")
        }

        let contents = markdown(meeting: meeting, facts: facts, decisions: decisions)
        try Data(contents.utf8).write(to: destination, options: .atomic)
        return destination
    }

    static func markdown(
        meeting: MeetingRecord,
        facts: [ScorecardFact],
        decisions: [ExtractionDecision]
    ) -> String {
        let factsByField = Dictionary(uniqueKeysWithValues: facts.map { ($0.field, $0) })
        let completedAt = meeting.endedAt.map(timestampFormatter.string) ?? "IN PROGRESS"
        var lines = [
            "# \(meeting.title)",
            "",
            "- Meeting ID: `\(meeting.id.uuidString)`",
            "- Started: \(timestampFormatter.string(from: meeting.startedAt))",
            "- Ended: \(completedAt)",
            "- Prospect: \(meeting.prospectDisplayName ?? "NOT IDENTIFIED")",
            "- Prospect email: \(meeting.prospectEmail ?? "NOT IDENTIFIED")",
            "- Calendar event: \(meeting.calendarEventIdentifier ?? "NOT IDENTIFIED")",
            "",
            "## Final scorecard",
            "",
            "| Field | Value | Confidence | Speaker | Time | Exact evidence |",
            "|---|---|---|---|---:|---|"
        ]

        for field in ScorecardField.displayOrder {
            if let fact = factsByField[field] {
                lines.append(
                    "| \(escape(field.label)) | \(escape(fact.value)) | \(escape(fact.confidence.rawValue.uppercased())) | \(escape(fact.speaker)) | \(formatDuration(fact.timestampSeconds)) | \(escape(fact.quote)) |"
                )
            } else {
                lines.append("| \(escape(field.label)) | NOT CAPTURED |  |  |  |  |")
            }
        }

        lines.append(contentsOf: [
            "",
            "## Extraction trace",
            "",
            "Total decisions: \(decisions.count)",
            ""
        ])

        if decisions.isEmpty {
            lines.append("No extraction decisions were recorded.")
        } else {
            for (index, decision) in decisions.enumerated() {
                lines.append("### \(index + 1). \(decision.outcome.rawValue) · \(decision.stage.rawValue) · \(decision.ruleID)")
                lines.append("")
                lines.append("- Recorded: \(timestampFormatter.string(from: decision.recordedAt))")
                lines.append("- Field: \(decision.field?.label ?? "NONE")")
                lines.append("- Previous: \(inline(decision.previousValue))")
                lines.append("- Proposed: \(inline(decision.proposedValue))")
                lines.append("- Reason: \(decision.reason)")
                lines.append("- Speaker: \(decision.speaker ?? "NONE")")
                lines.append("- Transcript time: \(decision.transcriptTimestamp.map(formatDuration) ?? "NONE")")
                lines.append("- Exact evidence: \(inline(decision.quote))")
                lines.append("")
            }
        }

        lines.append(contentsOf: [
            "## Playback notes",
            "",
            "- This meeting was replayed from a Circleback recording through Chrome.",
            "- Because both recorded speakers arrive through Chrome system audio, the live app may label both voices as PROSPECT.",
            ""
        ])
        return lines.joined(separator: "\n")
    }

    private static func safeFilename(_ value: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let clean = value
            .components(separatedBy: forbidden)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? "Untitled Meeting" : String(clean.prefix(120))
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }

    private static func inline(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "NONE" }
        return "`\(value.replacingOccurrences(of: "`", with: "'").replacingOccurrences(of: "\n", with: " "))`"
    }

    private static func formatDuration(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "NONE" }
        let whole = Int(seconds.rounded(.down))
        return String(format: "%02d:%02d", whole / 60, whole % 60)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
