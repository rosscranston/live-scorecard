import Foundation

struct CallHistorySummary: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let firmName: String?
    let startedAt: Date
    let endedAt: Date?
    let transcriptSegmentCount: Int
    let factCount: Int
    let transcriptPreview: String
    let prospectDisplayName: String?
    let prospectEmail: String?

    init(
        id: UUID,
        title: String,
        firmName: String?,
        startedAt: Date,
        endedAt: Date?,
        transcriptSegmentCount: Int,
        factCount: Int,
        transcriptPreview: String,
        prospectDisplayName: String? = nil,
        prospectEmail: String? = nil
    ) {
        self.id = id
        self.title = title
        self.firmName = firmName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.transcriptSegmentCount = transcriptSegmentCount
        self.factCount = factCount
        self.transcriptPreview = transcriptPreview
        self.prospectDisplayName = prospectDisplayName
        self.prospectEmail = prospectEmail
    }

    var displayName: String {
        let cleanedFirm = firmName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !cleanedFirm.isEmpty { return cleanedFirm }
        let cleanedProspect = prospectDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !cleanedProspect.isEmpty { return cleanedProspect }
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedTitle.isEmpty ? "Untitled Call" : cleanedTitle
    }
}

struct CallHistoryDetail: Equatable, Sendable {
    let meeting: MeetingRecord
    let transcriptSegments: [TranscriptSegment]
    let facts: [ScorecardFact]
}
