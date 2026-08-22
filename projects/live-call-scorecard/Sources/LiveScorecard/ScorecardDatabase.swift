import CSQLite
import Foundation

enum DatabaseError: Error, LocalizedError {
    case open(String)
    case prepare(String)
    case execute(String)

    var errorDescription: String? {
        switch self {
        case .open(let message): return "Could not open scorecard database: \(message)"
        case .prepare(let message): return "Could not prepare database statement: \(message)"
        case .execute(let message): return "Could not update scorecard database: \(message)"
        }
    }
}

final class ScorecardDatabase: @unchecked Sendable {
    private var db: OpaquePointer?
    private let lock = NSRecursiveLock()
    let url: URL

    init(url: URL? = nil) throws {
        self.url = try url ?? Self.defaultURL()
        try FileManager.default.createDirectory(
            at: self.url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if sqlite3_open(self.url.path, &db) != SQLITE_OK {
            let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown SQLite error"
            throw DatabaseError.open(message)
        }
        try migrate()
    }

    deinit {
        sqlite3_close(db)
    }

    static func defaultURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base
            .appendingPathComponent("Cranston Live Scorecard", isDirectory: true)
            .appendingPathComponent("scorecard.sqlite3")
    }

    func createMeeting(_ meeting: MeetingRecord) throws {
        try execute(
            """
            INSERT INTO meetings
            (id, title, firm_name, prospect_identity_key, prospect_display_name,
             prospect_email, calendar_event_identifier, started_at, ended_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, NULL)
            """,
            bindings: [
                meeting.id.uuidString,
                meeting.title,
                meeting.firmName,
                meeting.prospectIdentityKey,
                meeting.prospectDisplayName,
                meeting.prospectEmail,
                meeting.calendarEventIdentifier,
                meeting.startedAt.timeIntervalSince1970
            ]
        )
    }

    func upsertProspect(_ identity: ProspectIdentity) throws {
        let now = Date().timeIntervalSince1970
        try execute(
            """
            INSERT INTO prospects
            (identity_key, display_name, primary_email, organization_domain, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT(identity_key) DO UPDATE SET
                display_name = excluded.display_name,
                primary_email = excluded.primary_email,
                organization_domain = excluded.organization_domain,
                updated_at = excluded.updated_at
            """,
            bindings: [
                identity.key,
                identity.displayName,
                identity.primaryEmail,
                identity.organizationDomain,
                now,
                now
            ]
        )
    }

    func setProspectFieldLock(
        prospectIdentityKey: String,
        field: ScorecardField,
        isLocked: Bool
    ) throws {
        if isLocked {
            try execute(
                """
                INSERT INTO prospect_field_locks (prospect_identity_key, field, locked_at)
                VALUES (?, ?, ?)
                ON CONFLICT(prospect_identity_key, field) DO UPDATE SET
                    locked_at = excluded.locked_at
                """,
                bindings: [prospectIdentityKey, field.rawValue, Date().timeIntervalSince1970]
            )
        } else {
            try execute(
                "DELETE FROM prospect_field_locks WHERE prospect_identity_key = ? AND field = ?",
                bindings: [prospectIdentityKey, field.rawValue]
            )
        }
    }

    func loadProspectFieldLocks(prospectIdentityKey: String) throws -> Set<ScorecardField> {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { throw DatabaseError.open("Database is closed") }

        let sql = "SELECT field FROM prospect_field_locks WHERE prospect_identity_key = ? ORDER BY field"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        try bind([prospectIdentityKey], to: statement)

        var fields = Set<ScorecardField>()
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let rawValue = textColumn(statement, 0),
                  let field = ScorecardField(rawValue: rawValue) else { continue }
            fields.insert(field)
        }
        return fields
    }

    func saveExtractionDecision(_ decision: ExtractionDecision) throws {
        guard let meetingID = decision.meetingID else { return }
        try execute(
            """
            INSERT OR REPLACE INTO extraction_decisions
            (id, recorded_at, meeting_id, rule_id, stage, outcome, field,
             proposed_value, previous_value, reason, quote, speaker, transcript_timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            bindings: [
                decision.id.uuidString,
                decision.recordedAt.timeIntervalSince1970,
                meetingID.uuidString,
                decision.ruleID,
                decision.stage.rawValue,
                decision.outcome.rawValue,
                decision.field?.rawValue,
                decision.proposedValue,
                decision.previousValue,
                decision.reason,
                decision.quote,
                decision.speaker,
                decision.transcriptTimestamp
            ]
        )
    }

    func loadExtractionDecisions(meetingID: UUID) throws -> [ExtractionDecision] {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { throw DatabaseError.open("Database is closed") }

        let sql = """
        SELECT id, recorded_at, meeting_id, rule_id, stage, outcome, field,
               proposed_value, previous_value, reason, quote, speaker, transcript_timestamp
        FROM extraction_decisions
        WHERE meeting_id = ?
        ORDER BY recorded_at ASC, rowid ASC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        try bind([meetingID.uuidString], to: statement)

        var decisions: [ExtractionDecision] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idText = textColumn(statement, 0),
                  let id = UUID(uuidString: idText),
                  let storedMeetingIDText = textColumn(statement, 2),
                  let storedMeetingID = UUID(uuidString: storedMeetingIDText),
                  let ruleID = textColumn(statement, 3),
                  let stageText = textColumn(statement, 4),
                  let stage = ExtractionRuleStage(rawValue: stageText),
                  let outcomeText = textColumn(statement, 5),
                  let outcome = ExtractionDecisionOutcome(rawValue: outcomeText),
                  let reason = textColumn(statement, 9)
            else { continue }

            decisions.append(ExtractionDecision(
                id: id,
                recordedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 1)),
                meetingID: storedMeetingID,
                ruleID: ruleID,
                stage: stage,
                outcome: outcome,
                field: textColumn(statement, 6).flatMap(ScorecardField.init(rawValue:)),
                proposedValue: textColumn(statement, 7),
                previousValue: textColumn(statement, 8),
                reason: reason,
                quote: textColumn(statement, 10),
                speaker: textColumn(statement, 11),
                transcriptTimestamp: sqlite3_column_type(statement, 12) == SQLITE_NULL
                    ? nil
                    : sqlite3_column_double(statement, 12)
            ))
        }
        return decisions
    }

    func updateMeetingFirm(id: UUID, firmName: String) throws {
        try execute(
            "UPDATE meetings SET firm_name = ?, title = CASE WHEN title = 'New Meeting' THEN ? ELSE title END WHERE id = ?",
            bindings: [firmName, firmName, id.uuidString]
        )
    }

    func updateMeetingIdentity(id: UUID, identity: ProspectIdentity) throws {
        try upsertProspect(identity)
        try execute(
            """
            UPDATE meetings
            SET prospect_identity_key = ?, prospect_display_name = ?, prospect_email = ?
            WHERE id = ?
            """,
            bindings: [
                identity.key,
                identity.displayName,
                identity.primaryEmail,
                id.uuidString
            ]
        )
    }

    func endMeeting(id: UUID, at date: Date) throws {
        try execute(
            "UPDATE meetings SET ended_at = ? WHERE id = ?",
            bindings: [date.timeIntervalSince1970, id.uuidString]
        )
    }

    func saveSegment(_ segment: TranscriptSegment) throws {
        try execute(
            """
            INSERT OR REPLACE INTO transcript_segments
            (id, meeting_id, speaker, source, text, timestamp_seconds, is_final, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            bindings: [
                segment.id.uuidString,
                segment.meetingID.uuidString,
                segment.speaker,
                segment.source.rawValue,
                segment.text,
                segment.timestampSeconds,
                segment.isFinal ? 1 : 0,
                segment.createdAt.timeIntervalSince1970
            ]
        )
    }

    func upsertFact(_ fact: ScorecardFact) throws {
        try execute(
            """
            INSERT INTO facts
            (meeting_id, field, value, quote, speaker, timestamp_seconds, confidence, effective_at, updated_at, is_prior)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(meeting_id, field) DO UPDATE SET
                value = excluded.value,
                quote = excluded.quote,
                speaker = excluded.speaker,
                timestamp_seconds = excluded.timestamp_seconds,
                confidence = excluded.confidence,
                effective_at = excluded.effective_at,
                updated_at = excluded.updated_at,
                is_prior = excluded.is_prior
            """,
            bindings: [
                fact.meetingID.uuidString,
                fact.field.rawValue,
                fact.value,
                fact.quote,
                fact.speaker,
                fact.timestampSeconds,
                fact.confidence.rawValue,
                fact.effectiveAt.timeIntervalSince1970,
                fact.updatedAt.timeIntervalSince1970,
                fact.isPrior ? 1 : 0
            ]
        )
    }

    func deleteFact(meetingID: UUID, field: ScorecardField) throws {
        try execute(
            "DELETE FROM facts WHERE meeting_id = ? AND field = ?",
            bindings: [meetingID.uuidString, field.rawValue]
        )
    }

    func saveTrainingLabel(
        meetingID: UUID,
        field: ScorecardField,
        originalValue: String?,
        correctedValue: String,
        correctedAt: Date = Date()
    ) throws {
        try execute(
            """
            INSERT INTO fact_training_labels
            (meeting_id, field, original_value, corrected_value, corrected_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(meeting_id, field) DO UPDATE SET
                corrected_value = excluded.corrected_value,
                corrected_at = excluded.corrected_at
            """,
            bindings: [
                meetingID.uuidString,
                field.rawValue,
                originalValue,
                correctedValue,
                correctedAt.timeIntervalSince1970
            ]
        )
    }

    func loadTrainingLabels(meetingID: UUID) throws -> [FactTrainingLabel] {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { throw DatabaseError.open("Database is closed") }

        let sql = """
        SELECT meeting_id, field, original_value, corrected_value, corrected_at
        FROM fact_training_labels
        WHERE meeting_id = ?
        ORDER BY corrected_at ASC, field ASC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        try bind([meetingID.uuidString], to: statement)

        var labels: [FactTrainingLabel] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let meetingText = textColumn(statement, 0),
                  let storedMeetingID = UUID(uuidString: meetingText),
                  let fieldText = textColumn(statement, 1),
                  let field = ScorecardField(rawValue: fieldText),
                  let correctedValue = textColumn(statement, 3) else { continue }
            labels.append(FactTrainingLabel(
                meetingID: storedMeetingID,
                field: field,
                originalValue: textColumn(statement, 2),
                correctedValue: correctedValue,
                correctedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
            ))
        }
        return labels
    }

    func loadFacts(meetingID: UUID) throws -> [ScorecardFact] {
        try queryFacts(
            sql: "SELECT meeting_id, field, value, quote, speaker, timestamp_seconds, confidence, effective_at, updated_at, is_prior FROM facts WHERE meeting_id = ?",
            bindings: [meetingID.uuidString]
        )
    }

    func loadPriorFacts(prospectIdentityKey: String, excluding meetingID: UUID) throws -> [ScorecardFact] {
        let sql = """
        SELECT f.meeting_id, f.field, f.value, f.quote, f.speaker, f.timestamp_seconds,
               f.confidence, f.effective_at, f.updated_at, 1
        FROM facts f
        JOIN meetings m ON m.id = f.meeting_id
        WHERE m.prospect_identity_key = ? AND m.id != ?
          AND m.started_at = (
              SELECT MAX(m2.started_at) FROM meetings m2
              WHERE m2.prospect_identity_key = ? AND m2.id != ?
          )
        """
        return try queryFacts(
            sql: sql,
            bindings: [prospectIdentityKey, meetingID.uuidString, prospectIdentityKey, meetingID.uuidString]
        ).map { fact in
            var prior = fact
            prior.confidence = .prior
            prior.isPrior = true
            // Transcript timestamps restart at zero for every call. A prior call's
            // elapsed time must not make current-call evidence look artificially older.
            prior.timestampSeconds = 0
            return prior
        }
    }

    /// Loads meetings newest-first for the local call browser. Every whitespace-separated
    /// search term must match somewhere in the meeting name, firm, transcript, or facts.
    func loadCallHistory(search query: String = "") throws -> [CallHistorySummary] {
        let terms = query
            .split(whereSeparator: \Character.isWhitespace)
            .map(String.init)
            .filter { !$0.isEmpty }

        let searchClause: String
        var bindings: [Any?] = []
        if terms.isEmpty {
            searchClause = ""
        } else {
            let clause = """
            (m.title LIKE ? ESCAPE '\\' COLLATE NOCASE
             OR COALESCE(m.firm_name, '') LIKE ? ESCAPE '\\' COLLATE NOCASE
             OR COALESCE(m.prospect_display_name, '') LIKE ? ESCAPE '\\' COLLATE NOCASE
             OR COALESCE(m.prospect_email, '') LIKE ? ESCAPE '\\' COLLATE NOCASE
             OR COALESCE(m.prospect_identity_key, '') LIKE ? ESCAPE '\\' COLLATE NOCASE
             OR EXISTS (
                 SELECT 1 FROM transcript_segments search_ts
                 WHERE search_ts.meeting_id = m.id
                   AND (search_ts.text LIKE ? ESCAPE '\\' COLLATE NOCASE
                        OR search_ts.speaker LIKE ? ESCAPE '\\' COLLATE NOCASE)
             )
             OR EXISTS (
                 SELECT 1 FROM facts search_f
                 WHERE search_f.meeting_id = m.id
                   AND (search_f.value LIKE ? ESCAPE '\\' COLLATE NOCASE
                        OR search_f.quote LIKE ? ESCAPE '\\' COLLATE NOCASE)
             ))
            """
            searchClause = "WHERE " + Array(repeating: clause, count: terms.count).joined(separator: " AND ")
            for term in terms {
                let pattern = "%\(Self.escapeLikePattern(term))%"
                bindings.append(contentsOf: Array(repeating: pattern, count: 9))
            }
        }

        let sql = """
        SELECT m.id, m.title, m.firm_name, m.started_at, m.ended_at,
               (SELECT COUNT(*) FROM transcript_segments ts_count WHERE ts_count.meeting_id = m.id),
               (SELECT COUNT(*) FROM facts f_count WHERE f_count.meeting_id = m.id),
               COALESCE((
                   SELECT ts_preview.text FROM transcript_segments ts_preview
                   WHERE ts_preview.meeting_id = m.id
                   ORDER BY ts_preview.timestamp_seconds ASC, ts_preview.created_at ASC, ts_preview.id ASC
                   LIMIT 1
               ), ''), m.prospect_display_name, m.prospect_email
        FROM meetings m
        \(searchClause)
        ORDER BY m.started_at DESC, m.id DESC
        """

        lock.lock()
        defer { lock.unlock() }
        guard let db else { throw DatabaseError.open("Database is closed") }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)

        var meetings: [CallHistorySummary] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idText = textColumn(statement, 0),
                let id = UUID(uuidString: idText),
                let title = textColumn(statement, 1)
            else { continue }

            meetings.append(CallHistorySummary(
                id: id,
                title: title,
                firmName: textColumn(statement, 2),
                startedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 3)),
                endedAt: sqlite3_column_type(statement, 4) == SQLITE_NULL
                    ? nil
                    : Date(timeIntervalSince1970: sqlite3_column_double(statement, 4)),
                transcriptSegmentCount: Int(sqlite3_column_int64(statement, 5)),
                factCount: Int(sqlite3_column_int64(statement, 6)),
                transcriptPreview: textColumn(statement, 7) ?? "",
                prospectDisplayName: textColumn(statement, 8),
                prospectEmail: textColumn(statement, 9)
            ))
        }
        return meetings
    }

    /// Loads the complete locally stored transcript and current fact snapshot for one call.
    func loadCallHistoryDetail(meetingID: UUID) throws -> CallHistoryDetail? {
        lock.lock()
        defer { lock.unlock() }

        guard let meeting = try queryMeeting(id: meetingID) else { return nil }
        let segments = try queryTranscriptSegments(meetingID: meetingID)
        let facts = try queryFacts(
            sql: "SELECT meeting_id, field, value, quote, speaker, timestamp_seconds, confidence, effective_at, updated_at, is_prior FROM facts WHERE meeting_id = ?",
            bindings: [meetingID.uuidString]
        )
        let factOrder = Dictionary(uniqueKeysWithValues: ScorecardField.displayOrder.enumerated().map { ($1, $0) })
        return CallHistoryDetail(
            meeting: meeting,
            transcriptSegments: segments,
            facts: facts.sorted { (factOrder[$0.field] ?? .max) < (factOrder[$1.field] ?? .max) }
        )
    }

    func enqueueSync(_ envelope: SyncEnvelope) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let payload = try encoder.encode(envelope)
        guard let json = String(data: payload, encoding: .utf8) else { return }
        try execute(
            """
            INSERT OR IGNORE INTO sync_outbox
            (idempotency_key, meeting_id, destination, payload, status, created_at)
            VALUES (?, ?, 'notion', ?, 'awaiting_configuration', ?)
            """,
            bindings: [
                envelope.idempotencyKey,
                envelope.meeting.id.uuidString,
                json,
                envelope.createdAt.timeIntervalSince1970
            ]
        )
    }

    private func migrate() throws {
        try execute(
            """
            PRAGMA journal_mode = WAL;
            PRAGMA foreign_keys = ON;

            CREATE TABLE IF NOT EXISTS meetings (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                firm_name TEXT,
                prospect_identity_key TEXT,
                prospect_display_name TEXT,
                prospect_email TEXT,
                calendar_event_identifier TEXT,
                started_at REAL NOT NULL,
                ended_at REAL
            );

            CREATE TABLE IF NOT EXISTS prospects (
                identity_key TEXT PRIMARY KEY,
                display_name TEXT NOT NULL,
                primary_email TEXT NOT NULL,
                organization_domain TEXT,
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL
            );

            CREATE TABLE IF NOT EXISTS prospect_field_locks (
                prospect_identity_key TEXT NOT NULL REFERENCES prospects(identity_key) ON DELETE CASCADE,
                field TEXT NOT NULL,
                locked_at REAL NOT NULL,
                PRIMARY KEY (prospect_identity_key, field)
            );

            CREATE TABLE IF NOT EXISTS transcript_segments (
                id TEXT PRIMARY KEY,
                meeting_id TEXT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
                speaker TEXT NOT NULL,
                source TEXT NOT NULL,
                text TEXT NOT NULL,
                timestamp_seconds REAL NOT NULL,
                is_final INTEGER NOT NULL,
                created_at REAL NOT NULL
            );

            CREATE TABLE IF NOT EXISTS facts (
                meeting_id TEXT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
                field TEXT NOT NULL,
                value TEXT NOT NULL,
                quote TEXT NOT NULL,
                speaker TEXT NOT NULL,
                timestamp_seconds REAL NOT NULL,
                confidence TEXT NOT NULL,
                effective_at REAL NOT NULL,
                updated_at REAL NOT NULL,
                is_prior INTEGER NOT NULL DEFAULT 0,
                PRIMARY KEY (meeting_id, field)
            );

            CREATE TABLE IF NOT EXISTS extraction_decisions (
                id TEXT PRIMARY KEY,
                recorded_at REAL NOT NULL,
                meeting_id TEXT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
                rule_id TEXT NOT NULL,
                stage TEXT NOT NULL,
                outcome TEXT NOT NULL,
                field TEXT,
                proposed_value TEXT,
                previous_value TEXT,
                reason TEXT NOT NULL,
                quote TEXT,
                speaker TEXT,
                transcript_timestamp REAL
            );

            CREATE TABLE IF NOT EXISTS sync_outbox (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                idempotency_key TEXT UNIQUE NOT NULL,
                meeting_id TEXT NOT NULL,
                destination TEXT NOT NULL,
                payload TEXT NOT NULL,
                status TEXT NOT NULL,
                created_at REAL NOT NULL,
                completed_at REAL
            );

            CREATE TABLE IF NOT EXISTS fact_training_labels (
                meeting_id TEXT NOT NULL REFERENCES meetings(id) ON DELETE CASCADE,
                field TEXT NOT NULL,
                original_value TEXT,
                corrected_value TEXT NOT NULL,
                corrected_at REAL NOT NULL,
                PRIMARY KEY (meeting_id, field)
            );
            """
        )

        try addColumnIfMissing(table: "meetings", column: "prospect_identity_key", definition: "TEXT")
        try addColumnIfMissing(table: "meetings", column: "prospect_display_name", definition: "TEXT")
        try addColumnIfMissing(table: "meetings", column: "prospect_email", definition: "TEXT")
        try addColumnIfMissing(table: "meetings", column: "calendar_event_identifier", definition: "TEXT")
        try execute("CREATE INDEX IF NOT EXISTS meetings_prospect_identity_idx ON meetings(prospect_identity_key, started_at DESC)")
        try execute("CREATE INDEX IF NOT EXISTS extraction_decisions_meeting_idx ON extraction_decisions(meeting_id, recorded_at ASC)")
        try execute("CREATE INDEX IF NOT EXISTS fact_training_labels_meeting_idx ON fact_training_labels(meeting_id, corrected_at ASC)")
    }

    private func queryFacts(sql: String, bindings: [Any?]) throws -> [ScorecardFact] {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { throw DatabaseError.open("Database is closed") }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)

        var facts: [ScorecardFact] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let meetingIDText = textColumn(statement, 0),
                let meetingID = UUID(uuidString: meetingIDText),
                let fieldText = textColumn(statement, 1),
                let field = ScorecardField(rawValue: fieldText),
                let value = textColumn(statement, 2),
                let quote = textColumn(statement, 3),
                let speaker = textColumn(statement, 4),
                let confidenceText = textColumn(statement, 6),
                let confidence = FactConfidence(rawValue: confidenceText)
            else { continue }

            facts.append(ScorecardFact(
                meetingID: meetingID,
                field: field,
                value: value,
                quote: quote,
                speaker: speaker,
                timestampSeconds: sqlite3_column_double(statement, 5),
                confidence: confidence,
                effectiveAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 7)),
                updatedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 8)),
                isPrior: sqlite3_column_int(statement, 9) != 0
            ))
        }
        return facts
    }

    private func queryMeeting(id: UUID) throws -> MeetingRecord? {
        guard let db else { throw DatabaseError.open("Database is closed") }
        let sql = """
        SELECT id, title, firm_name, prospect_identity_key, prospect_display_name,
               prospect_email, calendar_event_identifier, started_at, ended_at
        FROM meetings WHERE id = ?
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        try bind([id.uuidString], to: statement)
        guard sqlite3_step(statement) == SQLITE_ROW,
              let idText = textColumn(statement, 0),
              let meetingID = UUID(uuidString: idText),
              let title = textColumn(statement, 1) else { return nil }

        return MeetingRecord(
            id: meetingID,
            title: title,
            firmName: textColumn(statement, 2),
            prospectIdentityKey: textColumn(statement, 3),
            prospectDisplayName: textColumn(statement, 4),
            prospectEmail: textColumn(statement, 5),
            calendarEventIdentifier: textColumn(statement, 6),
            startedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 7)),
            endedAt: sqlite3_column_type(statement, 8) == SQLITE_NULL
                ? nil
                : Date(timeIntervalSince1970: sqlite3_column_double(statement, 8))
        )
    }

    private func addColumnIfMissing(table: String, column: String, definition: String) throws {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { throw DatabaseError.open("Database is closed") }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "PRAGMA table_info(\(table))", -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }

        var exists = false
        while sqlite3_step(statement) == SQLITE_ROW {
            if textColumn(statement, 1) == column {
                exists = true
                break
            }
        }
        guard !exists else { return }
        try execute("ALTER TABLE \(table) ADD COLUMN \(column) \(definition)")
    }

    private func queryTranscriptSegments(meetingID: UUID) throws -> [TranscriptSegment] {
        guard let db else { throw DatabaseError.open("Database is closed") }
        let sql = """
        SELECT id, meeting_id, speaker, source, text, timestamp_seconds, is_final, created_at
        FROM transcript_segments
        WHERE meeting_id = ?
        ORDER BY timestamp_seconds ASC, created_at ASC, id ASC
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        try bind([meetingID.uuidString], to: statement)

        var segments: [TranscriptSegment] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idText = textColumn(statement, 0),
                let id = UUID(uuidString: idText),
                let meetingIDText = textColumn(statement, 1),
                let storedMeetingID = UUID(uuidString: meetingIDText),
                let speaker = textColumn(statement, 2),
                let sourceText = textColumn(statement, 3),
                let source = SpeakerSource(rawValue: sourceText),
                let text = textColumn(statement, 4)
            else { continue }

            segments.append(TranscriptSegment(
                id: id,
                meetingID: storedMeetingID,
                speaker: speaker,
                source: source,
                text: text,
                timestampSeconds: sqlite3_column_double(statement, 5),
                isFinal: sqlite3_column_int(statement, 6) != 0,
                createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 7))
            ))
        }
        return segments
    }

    private static func escapeLikePattern(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    private func execute(_ sql: String, bindings: [Any?] = []) throws {
        lock.lock()
        defer { lock.unlock() }
        guard let db else { throw DatabaseError.open("Database is closed") }

        if bindings.isEmpty {
            var errorMessage: UnsafeMutablePointer<CChar>?
            guard sqlite3_exec(db, sql, nil, nil, &errorMessage) == SQLITE_OK else {
                let message = errorMessage.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(db))
                sqlite3_free(errorMessage)
                throw DatabaseError.execute(message)
            }
            return
        }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepare(String(cString: sqlite3_errmsg(db)))
        }
        defer { sqlite3_finalize(statement) }
        try bind(bindings, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.execute(String(cString: sqlite3_errmsg(db)))
        }
    }

    private func bind(_ values: [Any?], to statement: OpaquePointer?) throws {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch value {
            case nil:
                result = sqlite3_bind_null(statement, index)
            case let value as String:
                result = sqlite3_bind_text(statement, index, value, -1, transient)
            case let value as Double:
                result = sqlite3_bind_double(statement, index, value)
            case let value as Int:
                result = sqlite3_bind_int64(statement, index, sqlite3_int64(value))
            default:
                result = sqlite3_bind_text(statement, index, String(describing: value!), -1, transient)
            }
            guard result == SQLITE_OK else {
                throw DatabaseError.execute("Could not bind SQLite parameter \(index)")
            }
        }
    }

    private func textColumn(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        guard let value = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: value)
    }
}
