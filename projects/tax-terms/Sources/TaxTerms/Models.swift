import Foundation

enum StudyState: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case needsReview
    case memorized

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notStarted: return "NOT STARTED"
        case .needsReview: return "NEEDS REVIEW"
        case .memorized: return "MEMORIZED"
        }
    }

    var notionStatus: String {
        switch self {
        case .notStarted: return "Not started"
        case .needsReview: return "In progress"
        case .memorized: return "Done"
        }
    }

    static func fromNotion(_ value: String?) -> StudyState {
        switch value?.lowercased() {
        case "done": return .memorized
        case "learn", "in progress": return .needsReview
        default: return .notStarted
        }
    }
}

enum StudyRating: String, Codable, CaseIterable, Identifiable {
    case again
    case review
    case memorized

    var id: String { rawValue }

    var label: String {
        switch self {
        case .again: return "AGAIN"
        case .review: return "REVIEW"
        case .memorized: return "MEMORIZED"
        }
    }
}

enum ResourceKind: String, Codable, CaseIterable {
    case official
    case article
    case video
    case reference
}

struct ResourceLink: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var url: String
    var kind: ResourceKind = .reference
    var timestampSeconds: Int?

    var destinationURL: URL? {
        guard var components = URLComponents(string: url) else { return nil }
        if let timestampSeconds, components.host?.contains("youtube.com") == true {
            var items = components.queryItems ?? []
            items.removeAll { $0.name == "t" }
            items.append(URLQueryItem(name: "t", value: "\(timestampSeconds)s"))
            components.queryItems = items
        }
        return components.url
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, url, kind, timestampSeconds
    }

    init(
        id: UUID = UUID(),
        title: String,
        url: String,
        kind: ResourceKind = .reference,
        timestampSeconds: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.kind = kind
        self.timestampSeconds = timestampSeconds
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try values.decode(String.self, forKey: .title)
        url = try values.decode(String.self, forKey: .url)
        kind = try values.decodeIfPresent(ResourceKind.self, forKey: .kind) ?? .reference
        timestampSeconds = try values.decodeIfPresent(Int.self, forKey: .timestampSeconds)
    }
}

struct ReviewStats: Codable, Equatable {
    var intervalDays: Double = 0
    var easeFactor: Double = 2.5
    var dueAt: Date?
    var reviewCount: Int = 0
    var lapseCount: Int = 0
    var lastReviewedAt: Date?

    var isDue: Bool {
        guard let dueAt else { return true }
        return dueAt <= Date()
    }
}

struct StudyAttempt: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var cardID: String
    var rating: StudyRating
    var timestamp: Date
}

enum DirtyField: String, Codable, CaseIterable, Hashable {
    case term
    case definition
    case whyItMatters
    case example
    case priority
    case categories
    case status
    case resources
    case studyNotes
}

struct TermContent: Codable, Equatable {
    var term: String = ""
    var definition: String = ""
    var whyItMatters: String = ""
    var example: String = ""
    var priority: String = ""
    var categories: [String] = []
    var status: StudyState = .notStarted
    var resources: [ResourceLink] = []
    var studyNotes: String = ""

    func value(for field: DirtyField) -> String {
        switch field {
        case .term: return term
        case .definition: return definition
        case .whyItMatters: return whyItMatters
        case .example: return example
        case .priority: return priority
        case .categories: return categories.sorted().joined(separator: "\u{1F}")
        case .status: return status.rawValue
        case .resources:
            return resources
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
                .map { "\($0.title)\u{1E}\($0.url)\u{1E}\($0.kind.rawValue)\u{1E}\($0.timestampSeconds ?? -1)" }
                .joined(separator: "\u{1F}")
        case .studyNotes: return studyNotes
        }
    }

    mutating func replace(field: DirtyField, from other: TermContent) {
        switch field {
        case .term: term = other.term
        case .definition: definition = other.definition
        case .whyItMatters: whyItMatters = other.whyItMatters
        case .example: example = other.example
        case .priority: priority = other.priority
        case .categories: categories = other.categories
        case .status: status = other.status
        case .resources: resources = other.resources
        case .studyNotes: studyNotes = other.studyNotes
        }
    }
}

struct TermCard: Codable, Identifiable, Equatable {
    var id: String
    var notionURL: String
    var content: TermContent
    var baseline: TermContent
    var dirtyFields: Set<DirtyField> = []
    var review: ReviewStats = ReviewStats()
    var remoteLastEditedAt: Date?
    var localModifiedAt: Date = Date()

    var isDirty: Bool { !dirtyFields.isEmpty }
}

enum TagMatchMode: String, Codable, CaseIterable, Identifiable {
    case any
    case all
    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
}

struct QuizFilter: Codable, Equatable {
    var search: String = ""
    var tags: Set<String> = []
    var tagMatchMode: TagMatchMode = .any
    var priorities: Set<String> = []
    var states: Set<StudyState> = []
    var dueOnly: Bool = false

    func matches(_ card: TermCard, now: Date = Date()) -> Bool {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            let haystack = [
                card.content.term,
                card.content.definition,
                card.content.whyItMatters,
                card.content.categories.joined(separator: " ")
            ].joined(separator: " ")
            if haystack.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) == nil {
                return false
            }
        }

        if !tags.isEmpty {
            let cardTags = Set(card.content.categories)
            switch tagMatchMode {
            case .any where cardTags.isDisjoint(with: tags): return false
            case .all where !tags.isSubset(of: cardTags): return false
            default: break
            }
        }

        if !priorities.isEmpty, !priorities.contains(card.content.priority) { return false }
        if !states.isEmpty, !states.contains(card.content.status) { return false }
        if dueOnly {
            if card.content.status == .memorized { return false }
            if let due = card.review.dueAt, due > now { return false }
        }
        return true
    }
}

enum QuizListKind: String, Codable, CaseIterable, Identifiable {
    case smart
    case manual
    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
}

struct SavedQuizList: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var kind: QuizListKind
    var filter: QuizFilter = QuizFilter()
    var cardIDs: Set<String> = []
    var createdAt: Date = Date()

    func contains(_ card: TermCard) -> Bool {
        switch kind {
        case .smart: return filter.matches(card)
        case .manual: return cardIDs.contains(card.id)
        }
    }
}

enum BackField: String, Codable, CaseIterable, Identifiable {
    case definition
    case whyItMatters
    case example
    case priority
    case categories
    case resources
    case studyNotes

    var id: String { rawValue }
    var label: String {
        switch self {
        case .definition: return "DEFINITION"
        case .whyItMatters: return "WHY IT MATTERS"
        case .example: return "EXAMPLE"
        case .priority: return "PRIORITY"
        case .categories: return "TAGS"
        case .resources: return "RESOURCES"
        case .studyNotes: return "NOTES"
        }
    }
}

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case dark
    case light
    var id: String { rawValue }
    var label: String { rawValue.uppercased() }
}

struct AppSettings: Codable, Equatable {
    var theme: AppTheme = .dark
    var visibleBackFields: Set<BackField> = Set(BackField.allCases)
    var alwaysOnTop: Bool = true
    var transparency: Double = 0
    var autoCurtainWhenInactive: Bool = false
    var shuffleQuiz: Bool = true
    var dataSourceID: String = "6f4f4725-f14a-4cf3-be9e-91c8e54093a6"
    var syncIntervalMinutes: Int = 5
}

struct SyncConflict: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var cardID: String
    var term: String
    var field: DirtyField
    var localValue: String
    var remoteValue: String
    var detectedAt: Date = Date()
    var resolution: String = "LOCAL KEPT"
}

struct StudySnapshot: Codable, Equatable {
    var cards: [TermCard] = []
    var lists: [SavedQuizList] = []
    var attempts: [StudyAttempt] = []
    var settings: AppSettings = AppSettings()
    var conflicts: [SyncConflict] = []
    var lastSyncedAt: Date?
    var schemaVersion: Int = 1
}

enum StudyScheduler {
    static func applying(
        _ rating: StudyRating,
        to stats: ReviewStats,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (state: StudyState, stats: ReviewStats) {
        var next = stats
        next.reviewCount += 1
        next.lastReviewedAt = now

        switch rating {
        case .again:
            next.lapseCount += 1
            next.intervalDays = 0
            next.easeFactor = max(1.3, next.easeFactor - 0.2)
            next.dueAt = calendar.date(byAdding: .minute, value: 10, to: now)
            return (.needsReview, next)

        case .review:
            next.intervalDays = next.intervalDays < 1
                ? 1
                : max(1, (next.intervalDays * next.easeFactor).rounded())
            next.easeFactor = min(3.0, next.easeFactor + 0.05)
            next.dueAt = calendar.date(
                byAdding: .minute,
                value: Int(next.intervalDays * 1_440),
                to: now
            )
            return (.needsReview, next)

        case .memorized:
            next.intervalDays = max(7, (max(1, next.intervalDays) * 2.5).rounded())
            next.easeFactor = min(3.0, next.easeFactor + 0.1)
            next.dueAt = calendar.date(
                byAdding: .minute,
                value: Int(next.intervalDays * 1_440),
                to: now
            )
            return (.memorized, next)
        }
    }
}
