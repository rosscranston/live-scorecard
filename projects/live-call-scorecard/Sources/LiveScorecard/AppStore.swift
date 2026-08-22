import AVFoundation
import CoreGraphics
import Foundation
import Speech

enum CaptureStatus: Equatable {
    case idle
    case starting
    case listening
    case degraded(String)
    case ended

    var label: String {
        switch self {
        case .idle: return "IDLE"
        case .starting: return "STARTING"
        case .listening: return "LISTENING"
        case .degraded: return "MANUAL MODE"
        case .ended: return "ENDED"
        }
    }
}

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var currentMeeting: MeetingRecord?
    @Published private(set) var facts: [ScorecardField: ScorecardFact] = [:]
    @Published private(set) var transcriptSegments: [TranscriptSegment] = []
    @Published private(set) var recentSegments: [TranscriptSegment] = []
    @Published private(set) var livePartials: [SpeakerSource: String] = [:]
    @Published private(set) var livePartial: String?
    @Published private(set) var status: CaptureStatus = .idle
    @Published private(set) var lastError: String?
    @Published private(set) var microphoneDevices: [MicrophoneDeviceOption] = []
    @Published private(set) var selectedMicrophoneID: String?
    @Published private(set) var microphoneLevel: Double = 0
    @Published private(set) var microphoneHasReceivedBuffers = false
    @Published private(set) var lockedFields: Set<ScorecardField> = []
    @Published private(set) var latestAudioDiagnostic: AudioCaptureDiagnostic?
    @Published private(set) var calendarIdentityLookup: CalendarIdentityLookup = .unavailable("NOT CHECKED")
    @Published private(set) var lastEvaluationExportPath: String?

    private let database: ScorecardDatabase
    private let preferences: UserDefaults
    private let reducer = FactReducer()
    private let extractor = FactExtractionService()
    private let circlebackImporter = CirclebackImporter()
    private let calendarIdentityService = CalendarIdentityService()
    private let demoMode: Bool
    private var extractionTask: Task<Void, Never>?
    private var pendingExtraction: (meetingID: UUID, segments: [TranscriptSegment])?
    private var seenTranscriptKeys = Set<String>()
    private var loadedPriorIdentityKey: String?
    private let microphonePreferenceKey = "live-scorecard.microphone-device-id"

    private lazy var captureService = AudioCaptureService(
        onEvent: { [weak self] event in
            Task { @MainActor in
                self?.receive(event)
            }
        },
        onError: { [weak self] message in
            Task { @MainActor in
                self?.captureFailed(message)
            }
        },
        onMicrophoneLevel: { [weak self] level in
            Task { @MainActor in
                self?.microphoneLevel = level
                self?.microphoneHasReceivedBuffers = true
            }
        },
        onDiagnostic: { [weak self] diagnostic in
            Task { @MainActor in
                self?.latestAudioDiagnostic = diagnostic
            }
        }
    )

    init(demoMode: Bool = false, preferences: UserDefaults = .standard) {
        self.demoMode = demoMode
        self.preferences = preferences
        do {
            if demoMode {
                let demoURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("cranston-live-scorecard-demo.sqlite3")
                self.database = try ScorecardDatabase(url: demoURL)
            } else {
                self.database = try ScorecardDatabase()
            }
        } catch {
            fatalError("Unable to initialize local scorecard database: \(error.localizedDescription)")
        }

        let traceDatabase = self.database
        ExtractionAdminRepository.shared.setDecisionSink { decision in
            try? traceDatabase.saveExtractionDecision(decision)
        }

        refreshMicrophoneDevices()
        if demoMode {
            loadDemo()
        }
    }

    var isMeetingActive: Bool {
        currentMeeting?.endedAt == nil && currentMeeting != nil
    }

    var databasePath: String { database.url.path }

    var selectedMicrophoneName: String {
        microphoneDevices.first(where: { $0.id == selectedMicrophoneID })?.name ?? "NO INPUT"
    }

    var isProspectMicrophoneTestModeEnabled: Bool {
        ExtractionAdminRepository.shared.configuration.microphoneActsAsProspectForTesting
    }

    func isFactLocked(_ field: ScorecardField) -> Bool {
        lockedFields.contains(field)
    }

    func factLockHelp(_ field: ScorecardField) -> String {
        let action = isFactLocked(field) ? "Unlock" : "Lock"
        if let identity = currentMeeting?.prospectDisplayName {
            return "\(action) this answer for \(identity) and future meetings"
        }
        return "\(action) this answer for the current meeting"
    }

    func toggleFactLock(_ field: ScorecardField) {
        guard facts[field] != nil else { return }
        let isNowLocked: Bool
        if lockedFields.contains(field) {
            lockedFields.remove(field)
            isNowLocked = false
        } else {
            lockedFields.insert(field)
            isNowLocked = true
        }
        if let identityKey = currentMeeting?.prospectIdentityKey {
            do {
                try database.setProspectFieldLock(
                    prospectIdentityKey: identityKey,
                    field: field,
                    isLocked: isNowLocked
                )
            } catch {
                lastError = "Could not save the organization lock: \(error.localizedDescription)"
            }
        }
    }

    func refreshMicrophoneDevices() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone],
            mediaType: .audio,
            position: .unspecified
        )
        let defaultID = AVCaptureDevice.default(for: .audio)?.uniqueID
        microphoneDevices = discovery.devices.map { device in
            MicrophoneDeviceOption(
                id: device.uniqueID,
                name: device.localizedName,
                isSystemDefault: device.uniqueID == defaultID
            )
        }

        let savedID = preferences.string(forKey: microphonePreferenceKey)
        if let savedID, microphoneDevices.contains(where: { $0.id == savedID }) {
            selectedMicrophoneID = savedID
        } else if let defaultID, microphoneDevices.contains(where: { $0.id == defaultID }) {
            selectedMicrophoneID = defaultID
        } else {
            selectedMicrophoneID = microphoneDevices.first?.id
        }
    }

    func selectMicrophoneDevice(id: String) async {
        guard microphoneDevices.contains(where: { $0.id == id }) else { return }
        selectedMicrophoneID = id
        preferences.set(id, forKey: microphonePreferenceKey)
        microphoneLevel = 0
        microphoneHasReceivedBuffers = false
        latestAudioDiagnostic = nil

        guard isMeetingActive, status == .listening, !demoMode else {
            if demoMode {
                microphoneLevel = 0.46
                microphoneHasReceivedBuffers = true
            }
            return
        }

        do {
            try await captureService.updateMicrophoneDevice(id: id)
            lastError = nil
        } catch {
            lastError = "Microphone change failed: \(error.localizedDescription)"
        }
    }

    func startMeeting() async {
        guard !isMeetingActive, status != .starting else { return }
        status = .starting
        calendarIdentityLookup = .unavailable("CHECKING")
        let startedAt = Date()
        let lookup: CalendarIdentityLookup
        if demoMode {
            lookup = .unavailable("DEMO MODE")
        } else {
            lookup = await calendarIdentityService.findCurrentProspect(at: startedAt)
        }
        calendarIdentityLookup = lookup

        let calendarMatch: CalendarMeetingMatch?
        if case let .matched(match) = lookup {
            calendarMatch = match
        } else {
            calendarMatch = nil
        }
        let meeting = MeetingRecord(
            id: UUID(),
            title: calendarMatch?.eventTitle ?? "New Meeting",
            firmName: nil,
            prospectIdentityKey: calendarMatch?.identity.key,
            prospectDisplayName: calendarMatch?.identity.displayName,
            prospectEmail: calendarMatch?.identity.primaryEmail,
            calendarEventIdentifier: calendarMatch?.eventIdentifier,
            startedAt: startedAt,
            endedAt: nil
        )
        currentMeeting = meeting
        facts = [:]
        transcriptSegments = []
        recentSegments = []
        livePartials = [:]
        livePartial = nil
        seenTranscriptKeys = []
        loadedPriorIdentityKey = nil
        lastError = nil
        microphoneLevel = 0
        microphoneHasReceivedBuffers = false
        latestAudioDiagnostic = nil
        lockedFields = []
        lastEvaluationExportPath = nil

        do {
            if let identity = calendarMatch?.identity {
                try database.upsertProspect(identity)
            }
            try database.createMeeting(meeting)
            if let identityKey = meeting.prospectIdentityKey {
                lockedFields = try database.loadProspectFieldLocks(
                    prospectIdentityKey: identityKey
                )
            }
        } catch {
            captureFailed(error.localizedDescription)
            return
        }

        if let identityKey = meeting.prospectIdentityKey {
            loadPriorFactsIfNeeded(prospectIdentityKey: identityKey, meetingID: meeting.id)
        }
        if let identity = calendarMatch?.identity {
            seedIdentityFacts(from: identity, meetingID: meeting.id)
        }

        guard !demoMode else {
            status = .listening
            return
        }

        let authorization = await requestSpeechAuthorization()
        guard authorization == .authorized else {
            captureFailed(permissionMessage(for: "Speech Recognition"))
            return
        }

        guard await requestMicrophoneAuthorization() else {
            captureFailed(permissionMessage(for: "Microphone"))
            return
        }

        guard requestScreenCaptureAuthorization() else {
            captureFailed(permissionMessage(for: "Screen & System Audio Recording"))
            return
        }

        do {
            refreshMicrophoneDevices()
            try await captureService.start(microphoneDeviceID: selectedMicrophoneID)
            status = .listening
        } catch {
            captureFailed(error.localizedDescription)
        }
    }

    func endMeeting() async {
        guard var meeting = currentMeeting, meeting.endedAt == nil else { return }
        // Stop both recognizers first so shutdown cannot keep extending the extraction queue.
        await captureService.stop()
        await extractionTask?.value

        let endedAt = Date()
        meeting.endedAt = endedAt
        currentMeeting = meeting
        status = .ended
        microphoneLevel = 0
        microphoneHasReceivedBuffers = false
        latestAudioDiagnostic = nil

        do {
            try database.endMeeting(id: meeting.id, at: endedAt)
            let orderedFacts = ScorecardField.displayOrder.compactMap { facts[$0] }
            let envelope = SyncEnvelope(
                version: "1.0",
                idempotencyKey: "notion:live-scorecard:\(meeting.id.uuidString)",
                meeting: meeting,
                facts: orderedFacts,
                createdAt: endedAt
            )
            try database.enqueueSync(envelope)
            let decisions = try database.loadExtractionDecisions(meetingID: meeting.id)
            let exportURL = try EvaluationExporter.export(
                meeting: meeting,
                facts: orderedFacts,
                decisions: decisions,
                databaseURL: database.url
            )
            lastEvaluationExportPath = exportURL.path
        } catch {
            lastError = error.localizedDescription
        }
    }

    func updateManual(field: ScorecardField, value: String) {
        guard let meeting = currentMeeting else { return }
        let originalValue = facts[field]?.value
        let isPostCallCorrection = meeting.endedAt != nil
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            facts.removeValue(forKey: field)
            lockedFields.remove(field)
            try? database.deleteFact(meetingID: meeting.id, field: field)
            if isPostCallCorrection {
                try? database.saveTrainingLabel(
                    meetingID: meeting.id,
                    field: field,
                    originalValue: originalValue,
                    correctedValue: ""
                )
            }
            if let identityKey = meeting.prospectIdentityKey {
                try? database.setProspectFieldLock(
                    prospectIdentityKey: identityKey,
                    field: field,
                    isLocked: false
                )
            }
            return
        }

        guard let fact = reducer.manualFact(
            field: field,
            value: trimmed,
            meetingID: meeting.id
        ) else { return }
        facts[field] = fact
        try? database.upsertFact(fact)
        if isPostCallCorrection {
            try? database.saveTrainingLabel(
                meetingID: meeting.id,
                field: field,
                originalValue: originalValue,
                correctedValue: fact.value
            )
        }

        if field == .firmName {
            recordFirmName(fact.value, meetingID: meeting.id)
        }
        if field == .location {
            let updated = applyingWhileRespectingLocks([], meetingID: meeting.id)
            persistChanged(updated)
        }
    }

    func assignProspectEmail(_ rawEmail: String) {
        guard var meeting = currentMeeting else { return }
        let knownName = facts[.name]?.value
        guard let identity = CalendarProspectResolver.identity(
            email: rawEmail,
            displayName: knownName
        ) else {
            lastError = "Enter one valid prospect email address."
            return
        }

        do {
            try database.updateMeetingIdentity(id: meeting.id, identity: identity)
            meeting.prospectIdentityKey = identity.key
            meeting.prospectDisplayName = identity.displayName
            meeting.prospectEmail = identity.primaryEmail
            currentMeeting = meeting
            loadedPriorIdentityKey = nil
            lockedFields = try database.loadProspectFieldLocks(prospectIdentityKey: identity.key)
            loadPriorFactsIfNeeded(prospectIdentityKey: identity.key, meetingID: meeting.id)
            seedIdentityFacts(from: identity, meetingID: meeting.id)
            calendarIdentityLookup = .manuallyAssigned(identity)
            lastError = nil
        } catch {
            lastError = "Could not save prospect identity: \(error.localizedDescription)"
        }
    }

    func injectTranscript(
        text: String,
        source: SpeakerSource,
        timestampSeconds: Double,
        isFinal: Bool = true
    ) {
        receive(LiveTranscriptEvent(
            source: source,
            text: text,
            timestampSeconds: timestampSeconds,
            isFinal: isFinal
        ))
    }

    func importCirclebackFile(_ url: URL) async {
        guard let meeting = currentMeeting else {
            lastError = "Start or open a meeting before importing Circleback data."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let imported = try circlebackImporter.decode(data: data, meetingID: meeting.id)
            var fullTranscript = transcriptSegments
            var rolling = recentSegments
            for segment in imported {
                try database.saveSegment(segment)
                fullTranscript.append(segment)
                rolling.append(segment)
                rolling = Array(rolling.suffix(12))
                let candidates = await extractor.extract(from: fullTranscript.sorted {
                    $0.timestampSeconds < $1.timestampSeconds
                })
                apply(candidates, meetingID: meeting.id)
            }
            transcriptSegments = fullTranscript.sorted { $0.timestampSeconds < $1.timestampSeconds }
            recentSegments = rolling
            lastError = nil
        } catch {
            lastError = "Circleback import failed: \(error.localizedDescription)"
        }
    }

    private func receive(_ event: LiveTranscriptEvent) {
        guard let meeting = currentMeeting, meeting.endedAt == nil else { return }
        let trimmed = event.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let source = Self.transcriptSource(
            for: event.source,
            microphoneActsAsProspectForTesting: isProspectMicrophoneTestModeEnabled
        )

        guard event.isFinal else {
            livePartials[source] = trimmed
            refreshLivePartial()
            return
        }
        livePartials.removeValue(forKey: source)
        refreshLivePartial()

        let key = "\(source.rawValue)|\(Int(event.timestampSeconds * 10))|\(trimmed)"
        guard seenTranscriptKeys.insert(key).inserted else { return }

        let segment = TranscriptSegment(
            id: UUID(),
            meetingID: meeting.id,
            speaker: source.label,
            source: source,
            text: trimmed,
            timestampSeconds: event.timestampSeconds,
            isFinal: event.isFinal,
            createdAt: Date()
        )
        transcriptSegments.append(segment)
        transcriptSegments.sort { $0.timestampSeconds < $1.timestampSeconds }
        recentSegments.append(segment)
        recentSegments.sort { $0.timestampSeconds < $1.timestampSeconds }
        recentSegments = Array(recentSegments.suffix(12))
        try? database.saveSegment(segment)

        // Keep the UI buffer narrow, but let the extractor choose the largest
        // transcript suffix that fits Apple's real token window.
        queueExtraction(meetingID: meeting.id, segments: transcriptSegments)
    }

    nonisolated static func transcriptSource(
        for source: SpeakerSource,
        microphoneActsAsProspectForTesting: Bool
    ) -> SpeakerSource {
        if microphoneActsAsProspectForTesting, source == .microphone {
            return .meetingAudio
        }
        return source
    }

    private func refreshLivePartial() {
        let sourceOrder: [SpeakerSource] = [.meetingAudio, .microphone, .circleback, .manual]
        guard let source = sourceOrder.first(where: { livePartials[$0] != nil }),
              let text = livePartials[source] else {
            livePartial = nil
            return
        }
        livePartial = "\(source.label): \(text)"
    }

    private func queueExtraction(meetingID: UUID, segments: [TranscriptSegment]) {
        // Context extraction is slower than speech finalization. Keep the newest rolling
        // context while one request is running instead of serializing one model request for
        // every fragment. This preserves the latest evidence and bounds END latency.
        pendingExtraction = (meetingID, segments)
        guard extractionTask == nil else { return }

        extractionTask = Task { [weak self] in
            guard let self else { return }
            while let pending = self.pendingExtraction {
                self.pendingExtraction = nil
                let candidates = await self.extractor.extract(from: pending.segments)
                guard !Task.isCancelled else {
                    self.pendingExtraction = nil
                    self.extractionTask = nil
                    return
                }
                self.apply(candidates, meetingID: pending.meetingID)
            }
            self.extractionTask = nil
        }
    }

    private func apply(_ candidates: [FactCandidate], meetingID: UUID) {
        guard currentMeeting?.id == meetingID else { return }
        let updated = applyingWhileRespectingLocks(candidates, meetingID: meetingID)
        persistChanged(updated)

        if let firmName = updated[.firmName]?.value {
            recordFirmName(firmName, meetingID: meetingID)
        }
    }

    private func applyingWhileRespectingLocks(
        _ candidates: [FactCandidate],
        meetingID: UUID
    ) -> [ScorecardField: ScorecardFact] {
        let previous = facts
        let unlockedCandidates = candidates.filter { candidate in
            guard lockedFields.contains(candidate.field) else { return true }
            ExtractionAdminRepository.shared.recordLockedCandidate(
                candidate,
                meetingID: meetingID,
                previousValue: previous[candidate.field]?.value
            )
            return false
        }

        var updated = reducer.applying(unlockedCandidates, to: previous, meetingID: meetingID)
        for field in lockedFields {
            if updated[field] != previous[field] {
                ExtractionAdminRepository.shared.record(ExtractionDecision(
                    meetingID: meetingID,
                    ruleID: ExtractionRuleCatalog.protectManual,
                    stage: .replacement,
                    outcome: .rejected,
                    field: field,
                    proposedValue: updated[field]?.value,
                    previousValue: previous[field]?.value,
                    reason: "A calculated or inferred update was rejected because the field is locked in the scorecard."
                ))
            }
            if let existing = previous[field] {
                updated[field] = existing
            } else {
                updated.removeValue(forKey: field)
            }
        }
        return updated
    }

    private func persistChanged(_ updated: [ScorecardField: ScorecardFact]) {
        let old = facts
        facts = updated
        for (field, fact) in updated where old[field] != fact {
            try? database.upsertFact(fact)
        }
    }

    private func loadPriorFactsIfNeeded(prospectIdentityKey: String, meetingID: UUID) {
        guard !prospectIdentityKey.isEmpty,
              loadedPriorIdentityKey != prospectIdentityKey else { return }
        loadedPriorIdentityKey = prospectIdentityKey
        guard let priorFacts = try? database.loadPriorFacts(
            prospectIdentityKey: prospectIdentityKey,
            excluding: meetingID
        ) else { return }

        var merged = facts
        for prior in priorFacts where merged[prior.field] == nil {
            var copied = prior
            copied = ScorecardFact(
                meetingID: meetingID,
                field: copied.field,
                value: copied.value,
                quote: copied.quote,
                speaker: copied.speaker,
                timestampSeconds: copied.timestampSeconds,
                confidence: .prior,
                effectiveAt: copied.effectiveAt,
                updatedAt: Date(),
                isPrior: true
            )
            merged[copied.field] = copied
            try? database.upsertFact(copied)
        }
        facts = merged
    }

    private func recordFirmName(_ firmName: String, meetingID: UUID) {
        guard currentMeeting?.id == meetingID else { return }
        currentMeeting?.firmName = firmName
        if currentMeeting?.title == "New Meeting" {
            currentMeeting?.title = firmName
        }
        try? database.updateMeetingFirm(id: meetingID, firmName: firmName)
    }

    private func seedIdentityFacts(from identity: ProspectIdentity, meetingID: UUID) {
        guard currentMeeting?.id == meetingID else { return }
        let now = Date()

        if facts[.name] == nil,
           identity.displayName.caseInsensitiveCompare(identity.primaryEmail) != .orderedSame,
           identity.displayName.caseInsensitiveCompare(identity.organizationDomain ?? "") != .orderedSame {
            let fact = ScorecardFact(
                meetingID: meetingID,
                field: .name,
                value: identity.displayName,
                quote: "Calendar attendee: \(identity.displayName) <\(identity.primaryEmail)>",
                speaker: "CALENDAR",
                timestampSeconds: 0,
                confidence: .inferred,
                effectiveAt: now,
                updatedAt: now,
                isPrior: false
            )
            facts[.name] = fact
            try? database.upsertFact(fact)
            recordCalendarIdentityDecision(fact)
        }

        if facts[.firmName] == nil,
           let organizationName = identity.inferredOrganizationName {
            let fact = ScorecardFact(
                meetingID: meetingID,
                field: .firmName,
                value: organizationName,
                quote: "Calendar email domain: \(identity.organizationDomain ?? identity.primaryEmail)",
                speaker: "CALENDAR",
                timestampSeconds: 0,
                confidence: .inferred,
                effectiveAt: now,
                updatedAt: now,
                isPrior: false
            )
            facts[.firmName] = fact
            try? database.upsertFact(fact)
            recordFirmName(organizationName, meetingID: meetingID)
            recordCalendarIdentityDecision(fact)
        }
    }

    private func recordCalendarIdentityDecision(_ fact: ScorecardFact) {
        ExtractionAdminRepository.shared.record(ExtractionDecision(
            meetingID: fact.meetingID,
            ruleID: ExtractionRuleCatalog.calendarIdentity,
            stage: .inference,
            outcome: .inferred,
            field: fact.field,
            proposedValue: fact.value,
            reason: "The field was blank and calendar identity metadata supplied an editable seed.",
            quote: fact.quote,
            speaker: fact.speaker,
            transcriptTimestamp: fact.timestampSeconds
        ))
    }

    private func captureFailed(_ message: String) {
        let displayMessage: String
        if message.localizedCaseInsensitiveContains("tcc") ||
            message.localizedCaseInsensitiveContains("declined") ||
            message.localizedCaseInsensitiveContains("permission") {
            displayMessage = permissionMessage(for: "Screen & System Audio Recording, Microphone, and Speech Recognition")
        } else {
            displayMessage = message
        }
        lastError = displayMessage
        status = .degraded(displayMessage)
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func requestScreenCaptureAuthorization() -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        return CGRequestScreenCaptureAccess()
    }

    private func permissionMessage(for permission: String) -> String {
        "Grant \(permission) access in System Settings > Privacy & Security, then reopen Live Scorecard."
    }

    private func loadDemo() {
        let meeting = MeetingRecord(
            id: UUID(),
            title: "Anderson Tax Group",
            firmName: "Anderson Tax Group",
            prospectIdentityKey: "domain:andersontax.example",
            prospectDisplayName: "andersontax.example",
            prospectEmail: "owner@andersontax.example",
            calendarEventIdentifier: "demo-calendar-event",
            startedAt: Date().addingTimeInterval(-742),
            endedAt: nil
        )
        calendarIdentityLookup = .matched(CalendarMeetingMatch(
            eventIdentifier: "demo-calendar-event",
            eventTitle: meeting.title,
            startDate: meeting.startedAt,
            endDate: Date().addingTimeInterval(60 * 60),
            identity: ProspectIdentity(
                key: "domain:andersontax.example",
                displayName: "andersontax.example",
                primaryEmail: "owner@andersontax.example",
                organizationDomain: "andersontax.example"
            )
        ))
        currentMeeting = meeting
        status = .listening
        try? database.upsertProspect(ProspectIdentity(
            key: "domain:andersontax.example",
            displayName: "andersontax.example",
            primaryEmail: "owner@andersontax.example",
            organizationDomain: "andersontax.example"
        ))
        try? database.createMeeting(meeting)

        let demoCandidates: [FactCandidate] = [
            .init(field: .firmName, value: "Anderson Tax Group", quote: "We're Anderson Tax Group.", speaker: "PROSPECT", timestampSeconds: 18, confidence: .exact),
            .init(field: .location, value: "Austin, TX", quote: "We're based in Austin, Texas.", speaker: "PROSPECT", timestampSeconds: 31, confidence: .exact),
            .init(field: .totalReturns, value: "1250", quote: "We do about twelve fifty total returns.", speaker: "PROSPECT", timestampSeconds: 88, confidence: .approximate),
            .init(field: .personalReturns, value: "950", quote: "About nine hundred fifty are personal.", speaker: "PROSPECT", timestampSeconds: 94, confidence: .approximate),
            .init(field: .businessReturns, value: "300", quote: "Then roughly three hundred business returns.", speaker: "PROSPECT", timestampSeconds: 102, confidence: .approximate),
            .init(field: .primaryTaxSoftware, value: "Lacerte", quote: "We use Lacerte on desktop.", speaker: "PROSPECT", timestampSeconds: 147, confidence: .exact),
            .init(field: .taxSoftwareEnvironment, value: "Desktop", quote: "We use Lacerte on desktop.", speaker: "PROSPECT", timestampSeconds: 147, confidence: .exact),
            .init(field: .taxSoftwareHost, value: "Rightworks", quote: "Rightworks hosts it for us.", speaker: "PROSPECT", timestampSeconds: 161, confidence: .exact),
            .init(field: .clientPortal, value: "TaxDome", quote: "Clients upload everything through TaxDome.", speaker: "PROSPECT", timestampSeconds: 212, confidence: .exact),
            .init(field: .admins, value: "3", quote: "We have three admins.", speaker: "PROSPECT", timestampSeconds: 278, confidence: .exact),
            .init(field: .preparers, value: "8", quote: "There are eight preparers.", speaker: "PROSPECT", timestampSeconds: 282, confidence: .exact),
            .init(field: .reviewers, value: "4", quote: "Four people are doing review.", speaker: "PROSPECT", timestampSeconds: 286, confidence: .exact),
            .init(field: .cpas, value: "5", quote: "Five of us are CPAs.", speaker: "PROSPECT", timestampSeconds: 291, confidence: .exact),
            .init(field: .annualCommitment, value: "100", quote: "The annual commitment is one hundred returns.", speaker: "ROSS", timestampSeconds: 622, confidence: .exact)
        ]
        facts = reducer.applying(demoCandidates, to: [:], meetingID: meeting.id)

        // One prior value demonstrates the requested blue carry-forward treatment.
        if var practice = reducer.manualFact(field: .practiceManagement, value: "Karbon", meetingID: meeting.id) {
            practice.confidence = .prior
            practice.isPrior = true
            practice.quote = "Captured on prior call"
            facts[.practiceManagement] = practice
        }
        for fact in facts.values { try? database.upsertFact(fact) }

        var seenDemoLines = Set<String>()
        transcriptSegments = demoCandidates.compactMap { candidate in
            let key = "\(candidate.timestampSeconds)|\(candidate.speaker)|\(candidate.quote)"
            guard seenDemoLines.insert(key).inserted else { return nil }
            return TranscriptSegment(
                id: UUID(),
                meetingID: meeting.id,
                speaker: candidate.speaker,
                source: candidate.speaker == "ROSS" ? .microphone : .meetingAudio,
                text: candidate.quote,
                timestampSeconds: candidate.timestampSeconds,
                isFinal: true,
                createdAt: Date()
            )
        }
        .sorted { $0.timestampSeconds < $1.timestampSeconds }
        recentSegments = Array(transcriptSegments.suffix(12))
        microphoneLevel = 0.46
        microphoneHasReceivedBuffers = true
    }
}
