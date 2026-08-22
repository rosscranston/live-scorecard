import SwiftUI

/// A self-contained browser for the scorecard's SQLite history. The host keeps its
/// LOCAL DB button outside this view so the same button can open and close the browser.
struct CallHistoryBrowserView: View {
    @StateObject private var model: CallHistoryViewModel
    @State private var searchText = ""

    private let terminalGreen = Color(red: 0.33, green: 1.0, blue: 0.57)
    private let dim = Color.white.opacity(0.42)

    init(database: ScorecardDatabase) {
        _model = StateObject(wrappedValue: CallHistoryViewModel(database: database))
    }

    init(databasePath: String) {
        _model = StateObject(wrappedValue: CallHistoryViewModel(databasePath: databasePath))
    }

    var body: some View {
        Group {
            if let detail = model.selectedDetail {
                CallHistoryDetailView(
                    detail: detail,
                    errorMessage: model.errorMessage,
                    onBack: { model.closeDetail() },
                    onUpdateFact: { field, value in
                        Task { await model.updateFact(field: field, value: value) }
                    },
                    onUpdateEmail: { email in
                        Task { await model.updateIdentity(email: email) }
                    }
                )
            } else {
                VStack(spacing: 0) {
                    searchBar
                    Divider().overlay(Color.white.opacity(0.14))
                    historyList
                }
            }
        }
        .background(Color.black)
        .foregroundStyle(Color.white)
        .font(.system(size: 10, weight: .regular, design: .monospaced))
        .task(id: searchText) {
            do {
                try await Task.sleep(for: .milliseconds(160))
                await model.loadHistory(search: searchText)
            } catch {
                // A newer search term replaced this task.
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(terminalGreen)
            TextField("SEARCH CALLS", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(Color.white.opacity(0.9))
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(dim)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.035))
        .overlay {
            Rectangle().stroke(Color.white.opacity(0.13), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var historyList: some View {
        if model.isLoadingList && model.meetings.isEmpty {
            historyMessage("LOADING LOCAL CALLS...")
        } else if let error = model.errorMessage {
            historyMessage(error.uppercased(), isError: true)
        } else if model.meetings.isEmpty {
            historyMessage(searchText.isEmpty ? "NO SAVED CALLS" : "NO MATCHING CALLS")
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.meetings) { meeting in
                        Button {
                            Task { await model.open(meetingID: meeting.id) }
                        } label: {
                            CallHistoryRow(summary: meeting)
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isLoadingDetail)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if model.isLoadingList {
                    ProgressView()
                        .controlSize(.mini)
                        .padding(7)
                }
            }
        }
    }

    private func historyMessage(_ text: String, isError: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(text)
                .foregroundStyle(isError ? Color.red : dim)
                .fixedSize(horizontal: false, vertical: true)
            if isError {
                Button("RETRY") {
                    Task { await model.loadHistory(search: searchText) }
                }
                .buttonStyle(CallHistoryTerminalButtonStyle())
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(9)
    }
}

@MainActor
final class CallHistoryViewModel: ObservableObject {
    @Published private(set) var meetings: [CallHistorySummary] = []
    @Published private(set) var selectedDetail: CallHistoryDetail?
    @Published private(set) var isLoadingList = false
    @Published private(set) var isLoadingDetail = false
    @Published private(set) var errorMessage: String?

    private var database: ScorecardDatabase?
    private var requestedSearch = ""
    private var requestedMeetingID: UUID?

    init(database: ScorecardDatabase) {
        self.database = database
    }

    init(databasePath: String) {
        do {
            database = try ScorecardDatabase(url: URL(fileURLWithPath: databasePath))
        } catch {
            database = nil
            errorMessage = error.localizedDescription
        }
    }

    func loadHistory(search: String = "") async {
        guard let database else { return }
        requestedSearch = search
        isLoadingList = true
        errorMessage = nil
        do {
            let meetings = try await Task.detached(priority: .userInitiated) {
                try database.loadCallHistory(search: search)
            }.value
            guard requestedSearch == search else { return }
            self.meetings = meetings
        } catch {
            guard requestedSearch == search else { return }
            errorMessage = error.localizedDescription
        }
        if requestedSearch == search {
            isLoadingList = false
        }
    }

    func open(meetingID: UUID) async {
        guard let database else { return }
        requestedMeetingID = meetingID
        isLoadingDetail = true
        errorMessage = nil
        do {
            let detail = try await Task.detached(priority: .userInitiated) {
                try database.loadCallHistoryDetail(meetingID: meetingID)
            }.value
            guard requestedMeetingID == meetingID else { return }
            if let detail {
                selectedDetail = detail
            } else {
                errorMessage = "That call is no longer in the local database."
            }
        } catch {
            guard requestedMeetingID == meetingID else { return }
            errorMessage = error.localizedDescription
        }
        if requestedMeetingID == meetingID {
            isLoadingDetail = false
        }
    }

    func closeDetail() {
        requestedMeetingID = nil
        selectedDetail = nil
        isLoadingDetail = false
    }

    func updateFact(field: ScorecardField, value: String) async {
        guard let database, let detail = selectedDetail else { return }
        let meetingID = detail.meeting.id
        let originalValue = detail.facts.first(where: { $0.field == field })?.value
        let manualFact = FactReducer().manualFact(
            field: field,
            value: value,
            meetingID: meetingID
        )
        errorMessage = nil
        do {
            try await Task.detached(priority: .userInitiated) {
                try database.saveTrainingLabel(
                    meetingID: meetingID,
                    field: field,
                    originalValue: originalValue,
                    correctedValue: manualFact?.value ?? ""
                )
                if let manualFact {
                    try database.upsertFact(manualFact)
                    if field == .firmName {
                        try database.updateMeetingFirm(id: meetingID, firmName: manualFact.value)
                    }
                } else {
                    try database.deleteFact(meetingID: meetingID, field: field)
                }
            }.value
            await reloadDetail(meetingID: meetingID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateIdentity(email: String) async {
        guard let database, let detail = selectedDetail else { return }
        let knownName = detail.facts.first(where: { $0.field == .name })?.value
        guard let identity = CalendarProspectResolver.identity(email: email, displayName: knownName) else {
            errorMessage = "Enter one valid prospect email address."
            return
        }
        let meetingID = detail.meeting.id
        let existingFields = Set(detail.facts.map(\.field))
        errorMessage = nil
        do {
            try await Task.detached(priority: .userInitiated) {
                try database.updateMeetingIdentity(id: meetingID, identity: identity)
                let now = Date()
                if !existingFields.contains(.name),
                   identity.displayName.caseInsensitiveCompare(identity.primaryEmail) != .orderedSame {
                    try database.upsertFact(ScorecardFact(
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
                    ))
                }
                if !existingFields.contains(.firmName),
                   let organizationName = identity.inferredOrganizationName {
                    try database.upsertFact(ScorecardFact(
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
                    ))
                    try database.updateMeetingFirm(id: meetingID, firmName: organizationName)
                }
            }.value
            await reloadDetail(meetingID: meetingID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reloadDetail(meetingID: UUID) async {
        guard let database else { return }
        do {
            selectedDetail = try await Task.detached(priority: .userInitiated) {
                try database.loadCallHistoryDetail(meetingID: meetingID)
            }.value
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CallHistoryRow: View {
    let summary: CallHistorySummary

    private let green = Color(red: 0.33, green: 1.0, blue: 0.57)
    private let blue = Color(red: 0.26, green: 0.64, blue: 1.0)
    private let dim = Color.white.opacity(0.42)

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(summary.displayName.uppercased())
                    .foregroundStyle(green)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(summary.startedAt.formatted(date: .numeric, time: .shortened))
                    .foregroundStyle(dim)
                    .lineLimit(1)
            }
            HStack(spacing: 5) {
                Text(summary.endedAt == nil ? "OPEN" : durationText)
                    .foregroundStyle(summary.endedAt == nil ? Color.orange : blue)
                Text("\(summary.transcriptSegmentCount) LINES")
                Text("\(summary.factCount) FACTS")
            }
            .foregroundStyle(dim)
            if !summary.transcriptPreview.isEmpty {
                Text(summary.transcriptPreview)
                    .foregroundStyle(Color.white.opacity(0.64))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
        .background(Color.white.opacity(0.018))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
        }
    }

    private var durationText: String {
        guard let endedAt = summary.endedAt else { return "OPEN" }
        let total = max(0, Int(endedAt.timeIntervalSince(summary.startedAt)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct CallHistoryDetailView: View {
    let detail: CallHistoryDetail
    let errorMessage: String?
    let onBack: () -> Void
    let onUpdateFact: (ScorecardField, String) -> Void
    let onUpdateEmail: (String) -> Void

    @State private var expandedEvidence: Set<ScorecardField> = []
    @State private var emailDraft: String
    @FocusState private var focusedScorecardField: ScorecardField?

    private let green = Color(red: 0.33, green: 1.0, blue: 0.57)
    private let blue = Color(red: 0.26, green: 0.64, blue: 1.0)
    private let dim = Color.white.opacity(0.42)

    init(
        detail: CallHistoryDetail,
        errorMessage: String?,
        onBack: @escaping () -> Void,
        onUpdateFact: @escaping (ScorecardField, String) -> Void,
        onUpdateEmail: @escaping (String) -> Void
    ) {
        self.detail = detail
        self.errorMessage = errorMessage
        self.onBack = onBack
        self.onUpdateFact = onUpdateFact
        self.onUpdateEmail = onUpdateEmail
        _emailDraft = State(initialValue: detail.meeting.prospectEmail ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Button("< BACK") { onBack() }
                    .buttonStyle(CallHistoryTerminalButtonStyle())
                Text(displayName.uppercased())
                    .foregroundStyle(green)
                    .lineLimit(1)
                Spacer(minLength: 2)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.035))

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    metadata
                    factsSectionHeader
                    ForEach(ScorecardField.displayOrder) { field in
                        factRow(
                            field: field,
                            fact: detail.facts.first(where: { $0.field == field })
                        )
                    }

                    sectionHeader("TRANSCRIPT / \(detail.transcriptSegments.count)")
                    if detail.transcriptSegments.isEmpty {
                        emptyRow("NO TRANSCRIPT STORED")
                    } else {
                        ForEach(detail.transcriptSegments) { segment in
                            transcriptRow(segment)
                        }
                    }
                }
            }
        }
        .onChange(of: detail.meeting.prospectEmail) { _, email in
            emailDraft = email ?? ""
        }
    }

    private var displayName: String {
        let firm = detail.meeting.firmName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return firm.isEmpty ? detail.meeting.title : firm
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(detail.meeting.startedAt.formatted(date: .long, time: .shortened).uppercased())
                .foregroundStyle(Color.white.opacity(0.76))
            if let endedAt = detail.meeting.endedAt {
                Text("ENDED \(endedAt.formatted(date: .omitted, time: .shortened).uppercased())")
                    .foregroundStyle(dim)
            } else {
                Text("CALL NOT ENDED")
                    .foregroundStyle(Color.orange)
            }
            if let identity = detail.meeting.prospectDisplayName {
                Text("CAL ID  \(identity.uppercased())")
                    .foregroundStyle(blue)
            }
            HStack(spacing: 5) {
                Text("EMAIL")
                    .foregroundStyle(dim)
                TextField("prospect@firm.com", text: $emailDraft)
                    .textFieldStyle(.plain)
                    .foregroundStyle(blue)
                    .onSubmit { onUpdateEmail(emailDraft) }
                Button("SET") { onUpdateEmail(emailDraft) }
                    .buttonStyle(CallHistoryTerminalButtonStyle())
            }
            if let errorMessage {
                Text(errorMessage.uppercased())
                    .foregroundStyle(Color.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .foregroundStyle(green)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.06))
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
            }
    }

    private var factsSectionHeader: some View {
        HStack(spacing: 6) {
            Text("CAPTURED FACTS / \(detail.facts.count) OF \(ScorecardField.displayOrder.count)")
            Spacer(minLength: 4)
            Button(allEvidenceExpanded ? "COLLAPSE ALL" : "EXPAND ALL") {
                if allEvidenceExpanded {
                    expandedEvidence.removeAll()
                } else {
                    expandedEvidence = Set(detail.facts.compactMap { fact in
                        hasEvidence(fact) ? fact.field : nil
                    })
                }
            }
            .buttonStyle(CallHistoryTerminalButtonStyle())
        }
        .foregroundStyle(green)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.06))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }

    private var allEvidenceExpanded: Bool {
        let fieldsWithEvidence = Set(detail.facts.compactMap { fact in
            hasEvidence(fact) ? fact.field : nil
        })
        return !fieldsWithEvidence.isEmpty && fieldsWithEvidence.isSubset(of: expandedEvidence)
    }

    private func factRow(field: ScorecardField, fact: ScorecardFact?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(field.label)
                    .foregroundStyle(dim)
                    .frame(width: 88, alignment: .leading)
                Text(fact?.confidence.marker ?? " ")
                    .foregroundStyle(fact?.isPrior == true ? blue : green)
                    .frame(width: 8)
                PostCallFactEditor(
                    field: field,
                    value: fact?.value ?? "",
                    color: fact?.isPrior == true ? blue : Color.white,
                    focusedField: $focusedScorecardField,
                    onMove: { offset in moveFieldFocus(from: field, offset: offset) },
                    onCommit: { onUpdateFact(field, $0) }
                )
                Button {
                    if expandedEvidence.contains(field) {
                        expandedEvidence.remove(field)
                    } else {
                        expandedEvidence.insert(field)
                    }
                } label: {
                    Text(expandedEvidence.contains(field) ? "−" : "+")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .frame(width: 18, height: 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(fact.map { hasEvidence($0) } == true ? green : dim.opacity(0.45))
                .disabled(fact.map { hasEvidence($0) } != true)
                .help(expandedEvidence.contains(field) ? "Hide supporting evidence" : "Show supporting evidence")
            }
            if expandedEvidence.contains(field), let fact, hasEvidence(fact) {
                HStack(alignment: .top, spacing: 4) {
                    Text(formatTime(fact.timestampSeconds))
                    Text(fact.speaker)
                    Text("\"\(fact.quote)\"")
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
                .foregroundStyle(fact.isPrior ? blue.opacity(0.72) : dim)
                .padding(.leading, 101)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    private func hasEvidence(_ fact: ScorecardFact) -> Bool {
        !fact.quote.isEmpty &&
            fact.quote != "Manually entered" &&
            fact.quote != "Manually entered after call"
    }

    private func moveFieldFocus(from field: ScorecardField, offset: Int) {
        guard let index = ScorecardField.displayOrder.firstIndex(of: field) else { return }
        let destination = min(
            max(ScorecardField.displayOrder.startIndex, index + offset),
            ScorecardField.displayOrder.index(before: ScorecardField.displayOrder.endIndex)
        )
        focusedScorecardField = ScorecardField.displayOrder[destination]
    }

    private func transcriptRow(_ segment: TranscriptSegment) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Text(formatTime(segment.timestampSeconds))
                .foregroundStyle(dim)
                .frame(width: 34, alignment: .leading)
            Text(speakerText(segment))
                .foregroundStyle(speakerColor(segment.source))
                .frame(width: 12, alignment: .leading)
                .lineLimit(1)
            Text(segment.text)
                .foregroundStyle(Color.white.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.055)).frame(height: 1)
        }
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(dim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(9)
    }

    private func speakerText(_ segment: TranscriptSegment) -> String {
        switch segment.source {
        case .microphone: return "R"
        case .meetingAudio: return "P"
        case .circleback: return segment.speaker.uppercased()
        case .manual: return "M"
        }
    }

    private func speakerColor(_ source: SpeakerSource) -> Color {
        switch source {
        case .microphone: return green
        case .meetingAudio: return blue
        case .circleback: return .cyan
        case .manual: return .yellow
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct PostCallFactEditor: View {
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

private struct CallHistoryTerminalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let green = Color(red: 0.33, green: 1.0, blue: 0.57)
        configuration.label
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(green)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.black)
            .overlay {
                Rectangle().stroke(green.opacity(configuration.isPressed ? 0.6 : 1), lineWidth: 1)
            }
    }
}
