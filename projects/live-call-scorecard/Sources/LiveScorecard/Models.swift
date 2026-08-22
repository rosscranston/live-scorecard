import Foundation

struct MicrophoneDeviceOption: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let isSystemDefault: Bool

    var displayName: String {
        isSystemDefault ? "\(name) / SYSTEM" : name
    }
}

enum SpeakerSource: String, Codable, CaseIterable, Sendable, Hashable {
    case microphone
    case meetingAudio
    case circleback
    case manual

    var label: String {
        switch self {
        case .microphone: return "ROSS"
        case .meetingAudio: return "PROSPECT"
        case .circleback: return "CIRCLEBACK"
        case .manual: return "MANUAL"
        }
    }
}

enum ScorecardField: String, Codable, CaseIterable, Identifiable, Sendable, Hashable {
    case name
    case firmName = "firm_name"
    case location
    case timezone
    case totalReturns = "total_returns"
    case personalReturns = "personal_returns"
    case businessReturns = "business_returns"
    case primaryTaxSoftware = "primary_tax_software"
    case taxSoftwareEnvironment = "tax_software_environment"
    case taxSoftwareHost = "tax_software_host"
    case clientPortal = "client_portal"
    case practiceManagement = "practice_management"
    case supportingSoftware = "supporting_software"
    case admins
    case preparers
    case reviewers
    case cpas
    // Keep the original persisted key so existing minimum-commitment facts become
    // the annual commitment instead of disappearing after this field split.
    case annualCommitment = "minimum_commitment"
    case pilotCommitment = "pilot_commitment"
    case otherNumbers = "other_numbers"
    case notes

    var id: String { rawValue }

    var label: String {
        switch self {
        case .name: return "NAME"
        case .firmName: return "FIRM"
        case .location: return "LOCATION"
        case .timezone: return "TIMEZONE"
        case .totalReturns: return "TOTAL RETURNS"
        case .personalReturns: return "PERSONAL"
        case .businessReturns: return "BUSINESS"
        case .primaryTaxSoftware: return "TAX SOFTWARE"
        case .taxSoftwareEnvironment: return "ENVIRONMENT"
        case .taxSoftwareHost: return "HOSTED BY"
        case .clientPortal: return "CLIENT PORTAL"
        case .practiceManagement: return "PRACTICE MGMT"
        case .supportingSoftware: return "SUPPORTING"
        case .admins: return "ADMINS"
        case .preparers: return "PREPARERS"
        case .reviewers: return "REVIEWERS"
        case .cpas: return "CPAS"
        case .annualCommitment: return "ANNUAL COMMIT"
        case .pilotCommitment: return "PILOT COMMIT"
        case .otherNumbers: return "OTHER NUMBERS"
        case .notes: return "NOTES"
        }
    }

    var isNumeric: Bool {
        switch self {
        case .totalReturns, .personalReturns, .businessReturns,
             .admins, .preparers, .reviewers, .cpas,
             .annualCommitment, .pilotCommitment:
            return true
        default:
            return false
        }
    }

    static let displayOrder: [ScorecardField] = [
        .name,
        .firmName,
        .location,
        .timezone,
        .totalReturns,
        .personalReturns,
        .businessReturns,
        .primaryTaxSoftware,
        .taxSoftwareEnvironment,
        .taxSoftwareHost,
        .clientPortal,
        .practiceManagement,
        .supportingSoftware,
        .admins,
        .preparers,
        .reviewers,
        .cpas,
        .annualCommitment,
        .pilotCommitment,
        .otherNumbers,
        .notes
    ]
}

enum FactConfidence: String, Codable, Sendable {
    case exact
    case approximate
    case inferred
    case manual
    case conflict
    case prior

    var marker: String {
        switch self {
        case .exact: return "="
        case .approximate: return "~"
        case .inferred: return "+"
        case .manual: return "*"
        case .conflict: return "!"
        case .prior: return "<"
        }
    }
}

struct ScorecardFact: Identifiable, Codable, Equatable, Sendable {
    var id: String { field.rawValue }
    let meetingID: UUID
    let field: ScorecardField
    var value: String
    var quote: String
    var speaker: String
    var timestampSeconds: Double
    var confidence: FactConfidence
    var effectiveAt: Date
    var updatedAt: Date
    var isPrior: Bool
}

struct FactCandidate: Equatable, Sendable {
    let field: ScorecardField
    let value: String
    let quote: String
    let speaker: String
    let timestampSeconds: Double
    let confidence: FactConfidence
}

struct TranscriptSegment: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let meetingID: UUID
    let speaker: String
    let source: SpeakerSource
    let text: String
    let timestampSeconds: Double
    let isFinal: Bool
    let createdAt: Date
}

struct MeetingRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var firmName: String?
    var prospectIdentityKey: String?
    var prospectDisplayName: String?
    var prospectEmail: String?
    var calendarEventIdentifier: String?
    let startedAt: Date
    var endedAt: Date?

    init(
        id: UUID,
        title: String,
        firmName: String?,
        prospectIdentityKey: String? = nil,
        prospectDisplayName: String? = nil,
        prospectEmail: String? = nil,
        calendarEventIdentifier: String? = nil,
        startedAt: Date,
        endedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.firmName = firmName
        self.prospectIdentityKey = prospectIdentityKey
        self.prospectDisplayName = prospectDisplayName
        self.prospectEmail = prospectEmail
        self.calendarEventIdentifier = calendarEventIdentifier
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

struct SyncEnvelope: Codable, Sendable {
    let version: String
    let idempotencyKey: String
    let meeting: MeetingRecord
    let facts: [ScorecardFact]
    let createdAt: Date
}

struct FactTrainingLabel: Equatable, Sendable {
    let meetingID: UUID
    let field: ScorecardField
    let originalValue: String?
    let correctedValue: String
    let correctedAt: Date
}
