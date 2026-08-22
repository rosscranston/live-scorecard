import AppKit
import Foundation

enum SyncState: Equatable {
    case disconnected
    case idle
    case syncing
    case synced(Date)
    case failed(String)

    var label: String {
        switch self {
        case .disconnected: return "NOT CONNECTED"
        case .idle: return "READY"
        case .syncing: return "SYNCING"
        case .synced: return "SYNCED"
        case .failed: return "SYNC FAILED"
        }
    }
}

@MainActor
final class StudyStore: ObservableObject {
    static let notionTokenAccount = "notion-integration-token"

    @Published private(set) var snapshot: StudySnapshot
    @Published private(set) var syncState: SyncState = .disconnected
    @Published private(set) var categoryOptions: [String] = []
    @Published private(set) var persistenceError: String?

    private let persistence: SnapshotPersisting
    private let keychain: KeychainStore
    private let resourceLibrary: ResourceLibrary
    private let isDemo: Bool
    private var pendingSave: DispatchWorkItem?
    private var pendingSync: DispatchWorkItem?
    private var periodicTimer: Timer?

    init(
        persistence: SnapshotPersisting = EncryptedSnapshotStore(),
        keychain: KeychainStore = .shared,
        resourceLibrary: ResourceLibrary = .bundled
    ) {
        self.persistence = persistence
        self.keychain = keychain
        self.resourceLibrary = resourceLibrary
        self.isDemo = ProcessInfo.processInfo.environment["TAX_TERMS_DEMO"] == "1"
        if isDemo {
            snapshot = Self.demoSnapshot()
        } else {
            do {
            snapshot = try persistence.load()
            } catch {
                snapshot = StudySnapshot()
                persistenceError = error.localizedDescription
            }
        }

        categoryOptions = Array(Set(snapshot.cards.flatMap(\.content.categories)))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        syncState = hasNotionToken ? .idle : .disconnected
    }

    deinit {
        periodicTimer?.invalidate()
    }

    var cards: [TermCard] {
        snapshot.cards.sorted {
            $0.content.term.localizedCaseInsensitiveCompare($1.content.term) == .orderedAscending
        }
    }

    var lists: [SavedQuizList] {
        snapshot.lists.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var settings: AppSettings { snapshot.settings }
    var conflicts: [SyncConflict] { snapshot.conflicts }
    var hasNotionToken: Bool { (try? keychain.readString(account: Self.notionTokenAccount)) != nil }

    var totalCount: Int { snapshot.cards.count }
    var notStartedCount: Int { snapshot.cards.filter { $0.content.status == .notStarted }.count }
    var reviewCount: Int { snapshot.cards.filter { $0.content.status == .needsReview }.count }
    var memorizedCount: Int { snapshot.cards.filter { $0.content.status == .memorized }.count }
    var dueCount: Int {
        snapshot.cards.filter {
            $0.content.status != .memorized && ($0.review.dueAt == nil || $0.review.isDue)
        }.count
    }

    func beginAutomaticSync() {
        guard !isDemo else { return }
        periodicTimer?.invalidate()
        let interval = TimeInterval(max(1, settings.syncIntervalMinutes) * 60)
        periodicTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.syncNow() }
        }
        if hasNotionToken {
            Task { await syncNow() }
        }
    }

    func card(id: String) -> TermCard? {
        snapshot.cards.first { $0.id == id }
    }

    func cards(matching filter: QuizFilter) -> [TermCard] {
        snapshot.cards.filter { filter.matches($0) }.sorted {
            $0.content.term.localizedCaseInsensitiveCompare($1.content.term) == .orderedAscending
        }
    }

    func cards(in list: SavedQuizList) -> [TermCard] {
        snapshot.cards.filter(list.contains).sorted {
            $0.content.term.localizedCaseInsensitiveCompare($1.content.term) == .orderedAscending
        }
    }

    func replaceContent(cardID: String, with content: TermContent) {
        guard let index = snapshot.cards.firstIndex(where: { $0.id == cardID }) else { return }
        var card = snapshot.cards[index]
        for field in DirtyField.allCases where card.content.value(for: field) != content.value(for: field) {
            card.dirtyFields.insert(field)
        }
        card.content = content
        card.localModifiedAt = Date()
        snapshot.cards[index] = card
        refreshCategoryOptions()
        scheduleSave()
        scheduleAutomaticSync()
    }

    func updateNotes(cardID: String, notes: String) {
        guard let index = snapshot.cards.firstIndex(where: { $0.id == cardID }),
              snapshot.cards[index].content.studyNotes != notes else { return }
        snapshot.cards[index].content.studyNotes = notes
        snapshot.cards[index].dirtyFields.insert(.studyNotes)
        snapshot.cards[index].localModifiedAt = Date()
        scheduleSave()
        scheduleAutomaticSync(delay: 3)
    }

    func record(_ rating: StudyRating, for cardID: String, at date: Date = Date()) {
        guard let index = snapshot.cards.firstIndex(where: { $0.id == cardID }) else { return }
        let scheduled = StudyScheduler.applying(rating, to: snapshot.cards[index].review, now: date)
        snapshot.cards[index].review = scheduled.stats
        snapshot.cards[index].content.status = scheduled.state
        snapshot.cards[index].dirtyFields.insert(.status)
        snapshot.cards[index].localModifiedAt = date
        snapshot.attempts.append(StudyAttempt(cardID: cardID, rating: rating, timestamp: date))
        if snapshot.attempts.count > 10_000 {
            snapshot.attempts.removeFirst(snapshot.attempts.count - 10_000)
        }
        scheduleSave()
        scheduleAutomaticSync(delay: 1)
    }

    func setStudyState(_ state: StudyState, cardID: String) {
        guard let index = snapshot.cards.firstIndex(where: { $0.id == cardID }),
              snapshot.cards[index].content.status != state else { return }
        snapshot.cards[index].content.status = state
        snapshot.cards[index].dirtyFields.insert(.status)
        snapshot.cards[index].localModifiedAt = Date()
        scheduleSave()
        scheduleAutomaticSync(delay: 1)
    }

    func upsertList(_ list: SavedQuizList) {
        if let index = snapshot.lists.firstIndex(where: { $0.id == list.id }) {
            snapshot.lists[index] = list
        } else {
            snapshot.lists.append(list)
        }
        scheduleSave()
    }

    func deleteList(id: UUID) {
        snapshot.lists.removeAll { $0.id == id }
        scheduleSave()
    }

    func toggle(cardID: String, inManualList listID: UUID) {
        guard let index = snapshot.lists.firstIndex(where: { $0.id == listID }),
              snapshot.lists[index].kind == .manual else { return }
        if snapshot.lists[index].cardIDs.contains(cardID) {
            snapshot.lists[index].cardIDs.remove(cardID)
        } else {
            snapshot.lists[index].cardIDs.insert(cardID)
        }
        scheduleSave()
    }

    func updateSettings(_ mutate: (inout AppSettings) -> Void) {
        mutate(&snapshot.settings)
        scheduleSave()
        beginAutomaticSync()
    }

    func saveNotionToken(_ token: String) throws {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            try removeNotionToken()
            return
        }
        try keychain.writeString(trimmed, account: Self.notionTokenAccount)
        syncState = .idle
    }

    func removeNotionToken() throws {
        try keychain.delete(account: Self.notionTokenAccount)
        syncState = .disconnected
    }

    func syncNow() async {
        guard !isDemo else { return }
        guard syncState != .syncing else { return }
        guard let token = try? keychain.readString(account: Self.notionTokenAccount),
              !token.isEmpty else {
            syncState = .disconnected
            return
        }

        syncState = .syncing
        do {
            let client = NotionClient(token: token)
            async let schemaRequest = client.fetchSchema(dataSourceID: settings.dataSourceID)
            async let termsRequest = client.fetchAllTerms(dataSourceID: settings.dataSourceID)
            let (schema, remoteRecords) = try await (schemaRequest, termsRequest)

            let required = Set([
                "Term", "Definition", "Why It Matters", "Example in a Sentence",
                "Priority", "Category", "Status", "Resources", "Study Notes"
            ])
            let missing = required.subtracting(schema.propertyNames)
            guard missing.isEmpty else {
                throw NotionClientError.malformedPage("missing properties: \(missing.sorted().joined(separator: ", "))")
            }

            var locals = Dictionary(uniqueKeysWithValues: snapshot.cards.map { ($0.id, $0) })
            var discoveredConflicts: [SyncConflict] = []

            for remote in remoteRecords {
                if let local = locals[remote.id] {
                    let result = SyncMergeEngine.merge(local: local, remote: remote)
                    locals[remote.id] = result.card
                    discoveredConflicts.append(contentsOf: result.conflicts)
                } else {
                    locals[remote.id] = TermCard(
                        id: remote.id,
                        notionURL: remote.notionURL,
                        content: remote.content,
                        baseline: remote.content,
                        remoteLastEditedAt: remote.lastEditedAt
                    )
                }
            }

            var mergedCards = Array(locals.values)
            for index in mergedCards.indices {
                guard mergedCards[index].content.resources.isEmpty,
                      let seeded = resourceLibrary.resources(for: mergedCards[index].content.term),
                      !seeded.isEmpty else { continue }
                mergedCards[index].content.resources = seeded
                mergedCards[index].dirtyFields.insert(.resources)
            }

            for index in mergedCards.indices where !mergedCards[index].dirtyFields.isEmpty {
                let fields = mergedCards[index].dirtyFields
                try await client.updatePage(mergedCards[index], fields: fields)
                for field in fields {
                    mergedCards[index].baseline.replace(field: field, from: mergedCards[index].content)
                }
                mergedCards[index].dirtyFields.removeAll()
                // Notion's public API is intentionally rate-limited. Keeping this
                // below three writes per second makes first-run resource seeding
                // predictable; the client also honors Retry-After when necessary.
                try await Task.sleep(nanoseconds: 350_000_000)
            }

            snapshot.cards = mergedCards.sorted {
                $0.content.term.localizedCaseInsensitiveCompare($1.content.term) == .orderedAscending
            }
            appendUniqueConflicts(discoveredConflicts)
            snapshot.lastSyncedAt = Date()
            categoryOptions = Array(Set(
                schema.categoryOptions + snapshot.cards.flatMap(\.content.categories)
            )).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            saveNow()
            syncState = .synced(snapshot.lastSyncedAt ?? Date())
        } catch {
            syncState = .failed(error.localizedDescription)
        }
    }

    func clearConflicts() {
        snapshot.conflicts.removeAll()
        scheduleSave()
    }

    func exportPlaintextCopy() throws -> URL {
        let url = AppPaths.exportURL()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONEncoder.taxTerms.encode(snapshot).write(to: url, options: .atomic)
        return url
    }

    func saveNow() {
        guard !isDemo else { return }
        pendingSave?.cancel()
        pendingSave = nil
        do {
            try persistence.save(snapshot)
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveNow() }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }

    private func scheduleAutomaticSync(delay: TimeInterval = 1.5) {
        guard hasNotionToken else { return }
        pendingSync?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in await self?.syncNow() }
        }
        pendingSync = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func refreshCategoryOptions() {
        categoryOptions = Array(Set(categoryOptions + snapshot.cards.flatMap(\.content.categories)))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func appendUniqueConflicts(_ conflicts: [SyncConflict]) {
        for conflict in conflicts {
            let exists = snapshot.conflicts.contains {
                $0.cardID == conflict.cardID
                    && $0.field == conflict.field
                    && $0.localValue == conflict.localValue
                    && $0.remoteValue == conflict.remoteValue
            }
            if !exists { snapshot.conflicts.append(conflict) }
        }
        if snapshot.conflicts.count > 250 {
            snapshot.conflicts.removeFirst(snapshot.conflicts.count - 250)
        }
    }

    private static func demoSnapshot() -> StudySnapshot {
        let samples: [TermContent] = [
            TermContent(
                term: "Adjusted Trial Balance",
                definition: "A trial balance after adjusting journal entries have been posted so balances reflect the final accounting positions used for reporting or tax preparation.",
                whyItMatters: "Prospects often distinguish raw books from the final numbers tax should actually use.",
                example: "“If you already have an adjusted trial balance, the business return should be much cleaner to automate.”",
                priority: "Core",
                categories: ["Accounting", "Documents"],
                status: .needsReview,
                resources: [ResourceLink(title: "Trial balance explained — definition", url: "https://www.youtube.com/watch?v=3_PfoTzSCQE", kind: .video, timestampSeconds: 41)],
                studyNotes: "Connect this to AJEs and the general ledger."
            ),
            TermContent(
                term: "Form 1065",
                definition: "The federal partnership return used to report the partnership’s income, deductions, and other tax items.",
                whyItMatters: "It is one of the most common business-return types in CPA firms.",
                example: "“How many 1065 partnership returns does the firm prepare?”",
                priority: "Core",
                categories: ["Forms & Schedules", "Entity Types"],
                status: .notStarted,
                resources: [ResourceLink(title: "IRS Form 1065", url: "https://www.irs.gov/forms-pubs/about-form-1065", kind: .official)]
            ),
            TermContent(
                term: "Lacerte",
                definition: "Intuit’s professional tax-preparation software for individual and business returns.",
                whyItMatters: "Lacerte appears frequently in migration and desktop-integration conversations.",
                example: "“Do you want current-year values updated while preserving the prior-year rollforward?”",
                priority: "Core",
                categories: ["Software"],
                status: .memorized
            )
        ]
        let cards = samples.enumerated().map { index, content in
            TermCard(id: "demo-\(index)", notionURL: "", content: content, baseline: content)
        }
        return StudySnapshot(
            cards: cards,
            lists: [
                SavedQuizList(
                    name: "CORE SOFTWARE",
                    kind: .smart,
                    filter: QuizFilter(tags: ["Software"], priorities: ["Core"])
                )
            ]
        )
    }
}

struct SeedResourceFile: Codable {
    var schemaVersion: Int
    var resources: [SeedResourceEntry]
}

struct SeedResourceEntry: Codable {
    var term: String
    var links: [ResourceLink]
}

struct ResourceLibrary {
    static let bundled = ResourceLibrary()

    private var byTerm: [String: [ResourceLink]] = [:]

    var termCount: Int { byTerm.count }

    init(bundle: Bundle = .module) {
        guard let url = bundle.url(forResource: "SeedResources", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder.taxTerms.decode(SeedResourceFile.self, from: data) else {
            return
        }
        byTerm = Dictionary(uniqueKeysWithValues: decoded.resources.map {
            ($0.term.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current), $0.links)
        })
    }

    init(entries: [SeedResourceEntry]) {
        byTerm = Dictionary(uniqueKeysWithValues: entries.map {
            ($0.term.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current), $0.links)
        })
    }

    func resources(for term: String) -> [ResourceLink]? {
        byTerm[term.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)]
    }
}
