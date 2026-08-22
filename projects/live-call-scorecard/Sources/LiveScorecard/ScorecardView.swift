import AppKit
import SwiftUI

struct ScorecardView: View {
    @ObservedObject var store: AppStore
    @AppStorage(ScreenSharingVisibility.preferenceKey)
    private var isVisibleInScreenSharing = ScreenSharingVisibility.defaultValue
    @AppStorage(AppWindowTransparency.preferenceKey)
    private var appWindowTransparency = AppWindowTransparency.defaultValue
    @State private var viewMode: TerminalViewMode = .scorecard
    @State private var showSettingsPanel = false
    @State private var expandedQuotes: Set<ScorecardField> = []
    @State private var prospectEmailDraft = ""
    @FocusState private var focusedScorecardField: ScorecardField?

    private let terminalGreen = Color(red: 0.33, green: 1.0, blue: 0.57)
    private let priorBlue = Color(red: 0.26, green: 0.64, blue: 1.0)
    private let dim = Color.white.opacity(0.42)

    var body: some View {
        VStack(spacing: 0) {
            header
            statusBar
            Divider().overlay(Color.white.opacity(0.16))
            if viewMode == .words {
                transcriptConsole
            } else if viewMode == .history {
                CallHistoryBrowserView(databasePath: store.databasePath)
                Divider().overlay(Color.white.opacity(0.16))
                footer
            } else if viewMode == .admin {
                ExtractionAdminView()
                Divider().overlay(Color.white.opacity(0.16))
                footer
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if store.currentMeeting != nil {
                            prospectEmailRow
                        }
                        ForEach(ScorecardField.displayOrder) { field in
                            factRow(field)
                        }
                    }
                }
                Divider().overlay(Color.white.opacity(0.16))
                transcriptTail
                footer
            }
        }
        .background(Color.black)
        .foregroundStyle(Color.white)
        .font(.system(size: 10, weight: .regular, design: .monospaced))
        .background(WindowConfigurator(
            isVisibleInScreenSharing: isVisibleInScreenSharing,
            transparency: appWindowTransparency
        ))
        .onChange(of: store.currentMeeting?.id) { _, _ in
            expandedQuotes = []
            prospectEmailDraft = store.currentMeeting?.prospectEmail ?? ""
        }
        .onChange(of: store.currentMeeting?.prospectEmail) { _, email in
            prospectEmailDraft = email ?? ""
        }
        .onChange(of: store.isMeetingActive) { _, isActive in
            if isActive {
                viewMode = .scorecard
                showSettingsPanel = false
            } else if viewMode == .words {
                viewMode = .scorecard
                showSettingsPanel = false
            }
        }
    }

    private var prospectEmailRow: some View {
        HStack(spacing: 5) {
            Text("EMAIL")
                .foregroundStyle(dim)
                .frame(width: 92, alignment: .leading)
            Text("@")
                .foregroundStyle(priorBlue)
                .frame(width: 8, alignment: .center)
            TextField("prospect@firm.com", text: $prospectEmailDraft)
                .textFieldStyle(.plain)
                .foregroundStyle(priorBlue)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .onSubmit { store.assignProspectEmail(prospectEmailDraft) }
            Button("SET") {
                store.assignProspectEmail(prospectEmailDraft)
            }
            .buttonStyle(TerminalFooterButtonStyle(isActive: false))
            .help("Tie this meeting and future prior facts to this exact email address")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(priorBlue.opacity(0.055))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text("CRANSTON / LIVE SCORECARD")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(terminalGreen)
                Text(headerSubtitle)
                    .lineLimit(1)
                    .foregroundStyle(dim)
            }
            Spacer(minLength: 4)
            if store.isMeetingActive {
                Button(viewMode == .words ? "CARD" : "WORDS") {
                    if viewMode == .words {
                        showSettingsPanel = false
                        viewMode = .scorecard
                    } else {
                        viewMode = .words
                    }
                }
                .buttonStyle(TerminalModeButtonStyle(isActive: viewMode == .words))
                .help(viewMode == .words ? "Return to the scorecard" : "Show the live raw transcript")
            }
            Button(store.isMeetingActive ? "END" : "NEW MEETING") {
                Task {
                    if store.isMeetingActive {
                        await store.endMeeting()
                    } else {
                        await store.startMeeting()
                    }
                }
            }
            .buttonStyle(TerminalButtonStyle(isDestructive: store.isMeetingActive))
            .keyboardShortcut(store.isMeetingActive ? "e" : "n", modifiers: .command)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }

    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 5, height: 5)
            Text(statusLabel)
                .foregroundStyle(statusColor)
            if let meeting = store.currentMeeting {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(elapsed(from: meeting.startedAt, to: meeting.endedAt ?? context.date))
                        .foregroundStyle(dim)
                }
            }
            if store.isMeetingActive && store.isProspectMicrophoneTestModeEnabled {
                Text("DEBUG MIC=P")
                    .foregroundStyle(Color.orange)
                    .fontWeight(.bold)
            }
            Spacer()
            Text(statusRightLabel)
                .foregroundStyle(statusRightColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .help(store.calendarIdentityLookup.detail)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
    }

    private func factRow(_ field: ScorecardField) -> some View {
        let fact = store.facts[field]
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(field.label)
                    .foregroundStyle(dim)
                    .frame(width: 92, alignment: .leading)
                Text(fact?.confidence.marker ?? " ")
                    .foregroundStyle(markerColor(fact?.confidence))
                    .frame(width: 8, alignment: .center)
                EditableFactValue(
                    field: field,
                    value: fact?.value ?? "",
                    color: fact?.isPrior == true ? priorBlue : Color.white,
                    focusedField: $focusedScorecardField,
                    onMove: { offset in moveFieldFocus(from: field, offset: offset) },
                    onCommit: { store.updateManual(field: field, value: $0) }
                )
                Button {
                    toggleQuote(field)
                } label: {
                    Text(expandedQuotes.contains(field) ? "−" : "+")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .frame(width: 18, height: 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(fact == nil ? dim.opacity(0.45) : terminalGreen)
                .disabled(fact == nil || fact?.quote == "Manually entered")
                .help(expandedQuotes.contains(field) ? "Hide supporting quote" : "Show supporting quote")

                Button {
                    store.toggleFactLock(field)
                } label: {
                    Image(systemName: store.isFactLocked(field) ? "lock.fill" : "lock.open")
                        .frame(width: 11, height: 11)
                }
                .buttonStyle(.plain)
                .foregroundStyle(store.isFactLocked(field) ? terminalGreen : dim)
                .disabled(fact == nil)
                .help(store.factLockHelp(field))
            }

            if expandedQuotes.contains(field),
               let fact,
               !fact.quote.isEmpty,
               fact.quote != "Manually entered" {
                HStack(spacing: 4) {
                    Text(formatTime(fact.timestampSeconds))
                    Text(fact.speaker)
                    Text("\"\(fact.quote)\"")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .foregroundStyle(fact.isPrior ? priorBlue.opacity(0.72) : dim)
                .padding(.leading, 105)
                .help(fact.quote)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, fact == nil ? 5 : 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground(field))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)
        }
    }

    private var transcriptTail: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("TRANSCRIPT / LAST FINAL")
                .foregroundStyle(dim)
            if let segment = store.recentSegments.last(where: { $0.isFinal }) {
                Text("\(segment.source.label): \(segment.text)")
                    .foregroundStyle(Color.white.opacity(0.74))
                    .lineLimit(2)
            } else if let partial = store.livePartial {
                Text(partial)
                    .foregroundStyle(Color.white.opacity(0.58))
                    .lineLimit(2)
            } else {
                Text("Waiting for speech...")
                    .foregroundStyle(dim)
            }
            if let error = store.lastError {
                Text(error)
                    .foregroundStyle(Color(red: 1.0, green: 0.43, blue: 0.38))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
    }

    private var transcriptConsole: some View {
        GeometryReader { geometry in
            let footerHeight: CGFloat = 27
            let dividerHeight: CGFloat = showSettingsPanel ? 2 : 1
            let contentHeight = max(0, geometry.size.height - footerHeight - dividerHeight)
            let transcriptHeight = showSettingsPanel ? floor(contentHeight / 2) : contentHeight

            VStack(spacing: 0) {
                transcriptScroll
                    .frame(height: transcriptHeight)

                if showSettingsPanel {
                    Divider().overlay(Color.white.opacity(0.16))
                    settingsPanel
                        .frame(height: contentHeight - transcriptHeight)
                }

                Divider().overlay(Color.white.opacity(0.16))
                transcriptFooter
                    .frame(height: footerHeight)
            }
        }
    }

    private var transcriptScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if let error = store.lastError {
                        Text(error)
                            .foregroundStyle(Color(red: 1.0, green: 0.43, blue: 0.38))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 8)
                    }

                    if store.transcriptSegments.isEmpty && store.livePartials.isEmpty {
                        Text("Waiting for captured words...")
                            .foregroundStyle(dim)
                            .padding(.vertical, 4)
                    }

                    ForEach(store.transcriptSegments) { segment in
                        transcriptRow(
                            id: segment.id.uuidString,
                            timestamp: formatTime(segment.timestampSeconds),
                            speaker: transcriptSpeaker(for: segment),
                            source: segment.source,
                            text: segment.text,
                            isPartial: false
                        )
                    }

                    ForEach(livePartialSources, id: \.self) { source in
                        if let text = store.livePartials[source] {
                            transcriptRow(
                                id: "partial-\(source.rawValue)",
                                timestamp: "LIVE",
                                speaker: transcriptSpeaker(for: source),
                                source: source,
                                text: text,
                                isPartial: true
                            )
                        }
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("transcript-bottom")
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
            }
            .onAppear { scrollTranscriptToBottom(proxy) }
            .onChange(of: transcriptScrollSignature) { _, _ in
                scrollTranscriptToBottom(proxy)
            }
        }
    }

    private var transcriptFooter: some View {
        HStack(spacing: 7) {
            Text("RAW CAPTURE")
                .foregroundStyle(terminalGreen)
            Button(showSettingsPanel ? "CLOSE" : "SETTINGS") {
                showSettingsPanel.toggle()
                if showSettingsPanel {
                    store.refreshMicrophoneDevices()
                }
            }
            .buttonStyle(TerminalFooterButtonStyle(isActive: showSettingsPanel))
            .help(showSettingsPanel ? "Close audio settings" : "Open audio settings")
            Spacer(minLength: 4)
            Text(showSettingsPanel ? "AUDIO / LIVE" : "FINAL + LIVE PARTIAL")
                .foregroundStyle(dim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 9)
        .background(Color.white.opacity(0.04))
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("SETTINGS / AUDIO INPUT")
                    .foregroundStyle(terminalGreen)
                Spacer()
                Button("REFRESH") {
                    store.refreshMicrophoneDevices()
                }
                .buttonStyle(TerminalFooterButtonStyle(isActive: false))
            }

            Text("MICROPHONE")
                .foregroundStyle(dim)

            if store.microphoneDevices.isEmpty {
                Text("NO AUDIO INPUTS FOUND")
                    .foregroundStyle(Color(red: 1.0, green: 0.43, blue: 0.38))
            } else {
                Picker("", selection: microphoneSelection) {
                    ForEach(store.microphoneDevices) { device in
                        Text(device.displayName.uppercased())
                            .tag(device.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 6) {
                Text("INPUT LEVEL")
                    .foregroundStyle(dim)
                    .lineLimit(1)
                    .frame(width: 72, alignment: .leading)
                audioLevelBar
                Text("\(Int((store.microphoneLevel * 100).rounded()))")
                    .foregroundStyle(terminalGreen)
                    .frame(width: 20, alignment: .trailing)
                Text(microphoneStatusText)
                    .foregroundStyle(microphoneStatusColor)
                    .frame(width: 43, alignment: .trailing)
            }

            Text(store.isMeetingActive && store.status == .listening
                 ? "SELECTION APPLIES LIVE"
                 : "SELECTION USED NEXT START")
                .foregroundStyle(dim)

            if let diagnostic = store.latestAudioDiagnostic {
                Text(diagnostic.description.uppercased())
                    .foregroundStyle(audioDiagnosticColor(diagnostic))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }

            Divider().overlay(Color.white.opacity(0.12))

            VStack(alignment: .leading, spacing: 3) {
                Text("CALENDAR IDENTITY")
                    .foregroundStyle(dim)
                Text(store.calendarIdentityLookup.detail)
                    .foregroundStyle(calendarIdentityColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }

            Divider().overlay(Color.white.opacity(0.12))

            VStack(alignment: .leading, spacing: 3) {
                Text("FUTURE SETTINGS")
                    .foregroundStyle(dim)
                Text("ADDITIONAL CONTROLS RESERVED")
                    .foregroundStyle(Color.white.opacity(0.24))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.025))
    }

    private var microphoneSelection: Binding<String> {
        Binding(
            get: { store.selectedMicrophoneID ?? "" },
            set: { id in
                Task { await store.selectMicrophoneDevice(id: id) }
            }
        )
    }

    private var audioLevelBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                Rectangle()
                    .fill(microphoneStatusColor)
                    .frame(width: geometry.size.width * min(1, max(0, store.microphoneLevel)))
            }
        }
        .frame(height: 7)
        .overlay {
            Rectangle().stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
    }

    private var microphoneStatusText: String {
        guard store.isMeetingActive else { return "IDLE" }
        guard store.status == .listening else { return "OFF" }
        guard store.microphoneHasReceivedBuffers else { return "NO DATA" }
        return store.microphoneLevel < 0.02 ? "SILENT" : "SIGNAL"
    }

    private var microphoneStatusColor: Color {
        switch microphoneStatusText {
        case "SIGNAL": return terminalGreen
        case "SILENT", "NO DATA", "OFF": return Color.orange
        default: return dim
        }
    }

    private func audioDiagnosticColor(_ diagnostic: AudioCaptureDiagnostic) -> Color {
        switch diagnostic.severity {
        case .info: return dim
        case .warning: return Color.orange
        }
    }

    private func transcriptRow(
        id: String,
        timestamp: String,
        speaker: String,
        source: SpeakerSource,
        text: String,
        isPartial: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Text(timestamp)
                .foregroundStyle(dim)
                .frame(width: 34, alignment: .leading)
            Text(speaker)
                .foregroundStyle(transcriptSpeakerColor(source, speaker: speaker))
                .frame(width: 10, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(text + (isPartial ? " …" : ""))
                .foregroundStyle(Color.white.opacity(isPartial ? 0.58 : 0.84))
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
        .id(id)
    }

    private var livePartialSources: [SpeakerSource] {
        [.meetingAudio, .microphone, .circleback, .manual]
    }

    private var transcriptScrollSignature: String {
        let lastFinalID = store.transcriptSegments.last?.id.uuidString ?? "none"
        let partials = livePartialSources.compactMap { source in
            store.livePartials[source].map { "\(source.rawValue):\($0)" }
        }
        return ([String(store.transcriptSegments.count), lastFinalID] + partials).joined(separator: "|")
    }

    private func transcriptSpeaker(for segment: TranscriptSegment) -> String {
        switch segment.source {
        case .microphone: return "R"
        case .meetingAudio: return "P"
        case .circleback:
            return segment.speaker.localizedCaseInsensitiveContains("ross") ? "R" : "P"
        case .manual: return "M"
        }
    }

    private func transcriptSpeaker(for source: SpeakerSource) -> String {
        switch source {
        case .microphone: return "R"
        case .meetingAudio: return "P"
        case .circleback: return "C"
        case .manual: return "M"
        }
    }

    private func transcriptSpeakerColor(_ source: SpeakerSource, speaker: String) -> Color {
        switch source {
        case .microphone: return terminalGreen
        case .meetingAudio: return priorBlue
        case .circleback: return speaker == "R" ? terminalGreen : priorBlue
        case .manual: return .yellow
        }
    }

    private func scrollTranscriptToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo("transcript-bottom", anchor: .bottom)
        }
    }

    private var footer: some View {
        HStack(spacing: 7) {
            Button("LOCAL DB") {
                guard !store.isMeetingActive else { return }
                viewMode = viewMode == .history ? .scorecard : .history
            }
            .buttonStyle(TerminalFooterButtonStyle(isActive: viewMode == .history))
            .disabled(store.isMeetingActive)
            .help(store.isMeetingActive ? "End the meeting before browsing saved calls" : "Open or close saved calls")

            Button("ADMIN") {
                guard !store.isMeetingActive else { return }
                viewMode = viewMode == .admin ? .scorecard : .admin
            }
            .buttonStyle(TerminalFooterButtonStyle(isActive: viewMode == .admin))
            .disabled(store.isMeetingActive)
            .help("Inspect and tune extraction rules")

            Spacer()
            Text("= exact  ~ approx  + calc  < prior")
                .foregroundStyle(dim)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.04))
        .help(store.databasePath)
    }

    private var headerSubtitle: String {
        switch viewMode {
        case .history: return "LOCAL CALL HISTORY"
        case .admin: return "EXTRACTION ADMIN"
        case .scorecard, .words:
            return store.currentMeeting?.title.uppercased() ?? "NO ACTIVE MEETING"
        }
    }

    private var statusLabel: String {
        switch viewMode {
        case .history: return "HISTORY"
        case .admin: return "RULES"
        case .scorecard, .words: return store.status.label
        }
    }

    private var statusRightLabel: String {
        if viewMode == .words { return "RAW / LIVE" }
        if store.isMeetingActive { return store.calendarIdentityLookup.compactLabel.uppercased() }
        return "CMD N / CMD E"
    }

    private var statusRightColor: Color {
        guard store.isMeetingActive, viewMode != .words else { return dim }
        return calendarIdentityColor
    }

    private var calendarIdentityColor: Color {
        switch store.calendarIdentityLookup {
        case .matched, .manuallyAssigned: return priorBlue
        case .unavailable: return Color.orange
        }
    }

    private var statusColor: Color {
        switch store.status {
        case .listening: return terminalGreen
        case .starting: return Color.yellow
        case .degraded: return Color.orange
        case .ended: return priorBlue
        case .idle: return dim
        }
    }

    private func markerColor(_ confidence: FactConfidence?) -> Color {
        switch confidence {
        case .approximate: return .yellow
        case .inferred: return .cyan
        case .conflict: return .red
        case .manual: return terminalGreen
        case .prior: return priorBlue
        case .exact: return terminalGreen
        case nil: return dim
        }
    }

    private func rowBackground(_ field: ScorecardField) -> Color {
        switch field {
        case .totalReturns, .primaryTaxSoftware, .annualCommitment, .pilotCommitment:
            return Color.white.opacity(0.035)
        default:
            return .clear
        }
    }

    private func elapsed(from start: Date, to end: Date) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(start)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func toggleQuote(_ field: ScorecardField) {
        if expandedQuotes.contains(field) {
            expandedQuotes.remove(field)
        } else {
            expandedQuotes.insert(field)
        }
    }

    private func moveFieldFocus(from field: ScorecardField, offset: Int) {
        guard let index = ScorecardField.displayOrder.firstIndex(of: field) else { return }
        let destination = min(
            max(ScorecardField.displayOrder.startIndex, index + offset),
            ScorecardField.displayOrder.index(before: ScorecardField.displayOrder.endIndex)
        )
        focusedScorecardField = ScorecardField.displayOrder[destination]
    }
}

private enum TerminalViewMode {
    case scorecard
    case words
    case history
    case admin
}

private struct EditableFactValue: View {
    let field: ScorecardField
    let value: String
    let color: Color
    let focusedField: FocusState<ScorecardField?>.Binding
    let onMove: (Int) -> Void
    let onCommit: (String) -> Void

    @State private var draft: String
    @State private var lastCommittedValue: String

    init(
        field: ScorecardField,
        value: String,
        color: Color,
        focusedField: FocusState<ScorecardField?>.Binding,
        onMove: @escaping (Int) -> Void,
        onCommit: @escaping (String) -> Void
    ) {
        self.field = field
        self.value = value
        self.color = color
        self.focusedField = focusedField
        self.onMove = onMove
        self.onCommit = onCommit
        _draft = State(initialValue: value)
        _lastCommittedValue = State(initialValue: value)
    }

    var body: some View {
        TextField("—", text: $draft)
            .textFieldStyle(.plain)
            .foregroundStyle(color)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .lineLimit(1)
            .focused(focusedField, equals: field)
            .onSubmit { commit() }
            .onKeyPress(.upArrow) {
                commit()
                onMove(-1)
                return .handled
            }
            .onKeyPress(.downArrow) {
                commit()
                onMove(1)
                return .handled
            }
            .onChange(of: value) { _, newValue in
                lastCommittedValue = newValue
                if focusedField.wrappedValue != field { draft = newValue }
            }
            .onChange(of: focusedField.wrappedValue) { oldField, newField in
                if oldField == field && newField != field { commit() }
            }
    }

    private func commit() {
        guard draft != lastCommittedValue else { return }
        lastCommittedValue = draft
        onCommit(draft)
    }
}

private struct TerminalButtonStyle: ButtonStyle {
    let isDestructive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(isDestructive ? Color.black : Color.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                (isDestructive ? Color(red: 1.0, green: 0.43, blue: 0.38) : Color(red: 0.33, green: 1.0, blue: 0.57))
                    .opacity(configuration.isPressed ? 0.65 : 1)
            )
            .clipShape(Rectangle())
    }
}

private struct TerminalModeButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        let green = Color(red: 0.33, green: 1.0, blue: 0.57)
        return configuration.label
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(isActive ? Color.black : green)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(isActive ? green.opacity(configuration.isPressed ? 0.65 : 1) : Color.clear)
            .overlay {
                Rectangle()
                    .stroke(green.opacity(configuration.isPressed ? 0.65 : 1), lineWidth: 1)
            }
    }
}

private struct TerminalFooterButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        let green = Color(red: 0.33, green: 1.0, blue: 0.57)
        return configuration.label
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(isActive ? Color.black : green)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(isActive ? green.opacity(configuration.isPressed ? 0.65 : 1) : Color.clear)
            .overlay {
                Rectangle()
                    .stroke(green.opacity(configuration.isPressed ? 0.65 : 1), lineWidth: 1)
            }
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    let isVisibleInScreenSharing: Bool
    let transparency: Double

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window, let screen = window.screen ?? NSScreen.main else { return }
        let visible = screen.visibleFrame
        let width = max(260, floor(visible.width / 6))
        let frame = NSRect(x: visible.minX, y: visible.minY, width: width, height: visible.height)
        if abs(window.frame.width - width) > 1 || abs(window.frame.minX - visible.minX) > 1 {
            window.setFrame(frame, display: true)
        }
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .black
        window.minSize = NSSize(width: 250, height: 560)
        ScreenSharingVisibility.apply(to: window, isVisible: isVisibleInScreenSharing)
        AppWindowTransparency.apply(to: window, transparency: transparency)
    }
}
