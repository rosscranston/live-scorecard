import SwiftUI

struct ExtractionAdminView: View {
    private enum Panel: String {
        case rules = "RULES"
        case trace = "TRACE"
    }

    @StateObject private var viewModel: ExtractionAdminViewModel
    @AppStorage(ScreenSharingVisibility.preferenceKey)
    private var isVisibleInScreenSharing = ScreenSharingVisibility.defaultValue
    @AppStorage(AppWindowTransparency.preferenceKey)
    private var appWindowTransparency = AppWindowTransparency.defaultValue
    @State private var panel: Panel = .rules
    @State private var expandedRules: Set<String> = []
    @State private var expandedDecisions: Set<UUID> = []
    @State private var primarySoftwareDraft = ""
    @State private var supportingSoftwareDraft = ""
    @State private var customInstructionsDraft = ""
    @State private var settingsSaved = false

    init(repository: ExtractionAdminRepository = .shared) {
        _viewModel = StateObject(wrappedValue: ExtractionAdminViewModel(repository: repository))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.blue.opacity(0.55))
            Group {
                switch panel {
                case .rules: rulesPanel
                case .trace: tracePanel
                }
            }
        }
        .font(.system(size: 10, weight: .regular, design: .monospaced))
        .foregroundStyle(Color(red: 0.42, green: 0.72, blue: 1))
        .background(Color.black)
        .onAppear {
            viewModel.refreshDecisions()
            loadEditableDrafts()
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Text("EXTRACTION ADMIN")
                .fontWeight(.semibold)
            Spacer(minLength: 4)
            panelButton(.rules)
            panelButton(.trace)
        }
        .padding(.horizontal, 8)
        .frame(height: 27)
    }

    private func panelButton(_ target: Panel) -> some View {
        Button(target.rawValue) {
            panel = target
            if target == .trace { viewModel.refreshDecisions() }
        }
        .buttonStyle(ExtractionAdminButtonStyle(isActive: panel == target))
    }

    private var rulesPanel: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                configurationControls
                sectionLabel("ORDERED PIPELINE")
                ForEach(ExtractionRuleStage.allCases, id: \.self) { stage in
                    stageHeader(stage)
                    ForEach(viewModel.rules.filter { $0.stage == stage }) { rule in
                        ruleRow(rule)
                    }
                }
                Button("RESET TO SAFE DEFAULTS") {
                    viewModel.resetConfiguration()
                    loadEditableDrafts()
                }
                .buttonStyle(ExtractionAdminButtonStyle(isActive: false))
                .padding(8)
            }
        }
    }

    private var configurationControls: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("DISPLAY PRIVACY")
            compactToggle(
                "SHOW IN SCREENSHARE + SCREENSHOTS",
                binding: $isVisibleInScreenSharing
            )
            Text(isVisibleInScreenSharing
                ? "VISIBLE TO WINDOW CAPTURE AND SCREENSHARING."
                : "HIDDEN FROM OTHER-PROCESS WINDOW CAPTURE.")
                .foregroundStyle(isVisibleInScreenSharing ? Color.blue : Color.gray)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 5) {
                Text("APP TRANSPARENCY")
                Spacer(minLength: 4)
                Text("\(Int((appWindowTransparency * 100).rounded()))%")
                    .foregroundStyle(Color.gray)
                    .frame(width: 30, alignment: .trailing)
            }
            Slider(
                value: $appWindowTransparency,
                in: 0...AppWindowTransparency.maximumValue,
                step: 0.05
            )
            .controlSize(.mini)
            .tint(Color(red: 0.42, green: 0.72, blue: 1))
            Text("0% = OPAQUE / 75% = MOST TRANSPARENT")
                .foregroundStyle(Color.gray)
                .fixedSize(horizontal: false, vertical: true)

            sectionLabel("DEBUG CAPTURE")
            compactToggle(
                "MICROPHONE → PROSPECT TEST MODE",
                binding: configurationBinding(\.microphoneActsAsProspectForTesting),
                warning: true
            )
            Text(viewModel.configuration.microphoneActsAsProspectForTesting
                ? "ON: WORDS SPOKEN INTO YOUR MICROPHONE ARE LABELED P / PROSPECT. TURN OFF BEFORE A REAL CALL."
                : "OFF: MICROPHONE IS ROSS; COMPUTER AUDIO IS PROSPECT.")
                .foregroundStyle(viewModel.configuration.microphoneActsAsProspectForTesting ? Color.orange : Color.gray)
                .fixedSize(horizontal: false, vertical: true)

            sectionLabel("TUNING")
            compactToggle("CONTEXT MODEL", binding: configurationBinding(\.languageModelEnabled))
            Text("TRANSCRIPT CONTEXT / AUTO-FIT TO APPLE TOKEN WINDOW")
                .foregroundStyle(Color.gray)
                .fixedSize(horizontal: false, vertical: true)
            numericControl(
                "OUTPUT TOKEN RESERVE",
                value: viewModel.configuration.responseTokenReserve,
                range: 512...1536
            ) { viewModel.configuration.responseTokenReserve = $0; viewModel.saveConfiguration() }
            numericControl(
                "MIN QUOTE CHARS",
                value: viewModel.configuration.minimumEvidenceQuoteCharacters,
                range: 2...80
            ) { viewModel.configuration.minimumEvidenceQuoteCharacters = $0; viewModel.saveConfiguration() }
            compactToggle("MODEL OVERRIDE", binding: configurationBinding(\.modelMayOverrideDeterministic), warning: true)

            sectionLabel("UPDATE GUARDS")
            compactToggle("PROTECT LOCKED", binding: configurationBinding(\.protectManualValues))
            compactToggle("REJECT OLDER", binding: configurationBinding(\.rejectOlderChangedValues))
            compactToggle("ESTIMATE > EXACT", binding: configurationBinding(\.approximateMayReplaceExact), warning: true)
            Text("Orange controls can make extraction less conservative.")
                .foregroundStyle(Color.orange.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            sectionLabel("SOFTWARE VOCABULARY")
            compactEditor(
                "PRIMARY TAX SOFTWARE / COMMA SEPARATED",
                text: $primarySoftwareDraft,
                height: 50
            )
            compactEditor(
                "SUPPORTING SOFTWARE / COMMA SEPARATED",
                text: $supportingSoftwareDraft,
                height: 50
            )
            Text("EVERY SUPPORTING NAME HEARD IN ONE SEGMENT IS SAVED AS A COMMA-SEPARATED LIST.")
                .foregroundStyle(Color.gray)
                .fixedSize(horizontal: false, vertical: true)

            sectionLabel("APPLE INTELLIGENCE RULES")
            compactEditor(
                "ADDITIONAL LOCAL MODEL INSTRUCTIONS",
                text: $customInstructionsDraft,
                height: 72
            )
            Button(settingsSaved ? "SAVED" : "SAVE VOCABULARY + AI RULES") {
                saveEditableDrafts()
            }
            .buttonStyle(ExtractionAdminButtonStyle(isActive: settingsSaved))

            sectionLabel("FIELD SPEAKER LOCKS")
            Text("P = PROSPECT / R = ROSS / E = EITHER. MANUAL EDITS ARE ALWAYS ALLOWED.")
                .foregroundStyle(Color.gray)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(ScorecardField.displayOrder) { field in
                sourcePolicyRow(field)
            }

            sectionLabel("FIELD UPDATE RULES")
            Text("LATEST = NEWER EVIDENCE / CONFIRM = DIRECT STATEMENT THEN CORRECTION / KEEP = MANUAL CHANGE ONLY")
                .foregroundStyle(Color.gray)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(ExtractionAdminConfiguration.configurableReplacementFields) { field in
                replacementPolicyRow(field)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }

    private func compactEditor(
        _ label: String,
        text: Binding<String>,
        height: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .foregroundStyle(Color.gray)
            TextEditor(text: text)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color(red: 0.42, green: 0.72, blue: 1))
                .scrollContentBackground(.hidden)
                .padding(3)
                .frame(height: height)
                .background(Color.white.opacity(0.035))
                .overlay(Rectangle().stroke(Color.blue.opacity(0.45), lineWidth: 1))
                .onChange(of: text.wrappedValue) { _, _ in settingsSaved = false }
        }
    }

    private func replacementPolicyRow(_ field: ScorecardField) -> some View {
        HStack(spacing: 4) {
            Text(field.label)
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: replacementPolicyBinding(field)) {
                ForEach(FieldReplacementPolicy.allCases, id: \.self) { policy in
                    Text(policy.compactLabel).tag(policy)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.mini)
            .frame(width: 82)
            .help(viewModel.configuration.replacementPolicy(for: field).explanation)
        }
        .frame(minHeight: 20)
    }

    private func sourcePolicyRow(_ field: ScorecardField) -> some View {
        let current = viewModel.configuration.sourcePolicy(for: field)
        return HStack(spacing: 4) {
            Text(field.label)
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 2) {
                ForEach(Array(FieldSourcePolicy.speakerChoices.enumerated()), id: \.element) { index, policy in
                    if index > 0 {
                        Text("|")
                            .foregroundStyle(Color.gray.opacity(0.7))
                    }
                    Button {
                        viewModel.configuration.setSourcePolicy(policy, for: field)
                        viewModel.saveConfiguration()
                    } label: {
                        Text(policy.shortLabel)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(red: 0.42, green: 0.72, blue: 1))
                            .frame(width: 18, height: 18)
                            .background(
                                current == policy
                                    ? Color(red: 0.42, green: 0.72, blue: 1).opacity(0.24)
                                    : Color.clear
                            )
                            .overlay(
                                Rectangle().stroke(
                                    Color(red: 0.42, green: 0.72, blue: 1)
                                        .opacity(current == policy ? 1 : 0.35),
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .help(policy.explanation)
                    .accessibilityLabel("(field.label): (policy.compactLabel)")
                }
            }
            .frame(width: 72, alignment: .trailing)
        }
        .frame(minHeight: 20)
    }

    private func replacementPolicyBinding(_ field: ScorecardField) -> Binding<FieldReplacementPolicy> {
        Binding(
            get: { viewModel.configuration.replacementPolicy(for: field) },
            set: { policy in
                viewModel.configuration.setReplacementPolicy(policy, for: field)
                viewModel.saveConfiguration()
            }
        )
    }

    private func loadEditableDrafts() {
        primarySoftwareDraft = viewModel.configuration.primaryTaxSoftwareCSV
        supportingSoftwareDraft = viewModel.configuration.supportingSoftwareCSV
        customInstructionsDraft = viewModel.configuration.customModelInstructions
        settingsSaved = false
    }

    private func saveEditableDrafts() {
        viewModel.configuration.primaryTaxSoftwareCSV = primarySoftwareDraft
        viewModel.configuration.supportingSoftwareCSV = supportingSoftwareDraft
        viewModel.configuration.customModelInstructions = customInstructionsDraft
        viewModel.saveConfiguration()
        loadEditableDrafts()
        settingsSaved = true
    }

    private func compactToggle(
        _ label: String,
        binding: Binding<Bool>,
        warning: Bool = false
    ) -> some View {
        Toggle(isOn: binding) {
            Text(label)
                .foregroundStyle(warning ? Color.orange : Color(red: 0.42, green: 0.72, blue: 1))
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
    }

    private func numericControl(
        _ label: String,
        value: Int,
        range: ClosedRange<Int>,
        update: @escaping (Int) -> Void
    ) -> some View {
        HStack(spacing: 4) {
            Text(label)
            Spacer(minLength: 3)
            Button("-") { update(max(range.lowerBound, value - 1)) }
                .buttonStyle(ExtractionAdminButtonStyle(isActive: false))
                .disabled(value <= range.lowerBound)
            Text("\(value)")
                .frame(minWidth: 22)
                .multilineTextAlignment(.center)
            Button("+") { update(min(range.upperBound, value + 1)) }
                .buttonStyle(ExtractionAdminButtonStyle(isActive: false))
                .disabled(value >= range.upperBound)
        }
        .frame(minHeight: 19)
    }

    private func stageHeader(_ stage: ExtractionRuleStage) -> some View {
        Text(stage.rawValue)
            .fontWeight(.bold)
            .foregroundStyle(stageColor(stage))
            .padding(.horizontal, 8)
            .padding(.top, 7)
            .padding(.bottom, 2)
    }

    private func ruleRow(_ rule: ExtractionAdminRule) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%03d", rule.order))
                    .foregroundStyle(Color.gray)
                if rule.isTunable {
                    Toggle("", isOn: Binding(
                        get: { viewModel.isEnabled(rule) },
                        set: { viewModel.setRule(rule, enabled: $0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.gray)
                        .frame(width: 22)
                }
                Button {
                    toggle(rule.id, in: &expandedRules)
                } label: {
                    HStack(spacing: 3) {
                        Text(rule.title.uppercased())
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 2)
                        Image(systemName: expandedRules.contains(rule.id) ? "minus" : "plus")
                            .font(.system(size: 8, weight: .bold))
                    }
                }
                .buttonStyle(.plain)
            }
            if expandedRules.contains(rule.id) {
                Text(rule.explanation)
                    .foregroundStyle(Color.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 28)
                Text(rule.id)
                    .foregroundStyle(Color.gray.opacity(0.65))
                    .padding(.leading, 28)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(rule.order.isMultiple(of: 20) ? 0.025 : 0))
    }

    private var tracePanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                Text("RECENT DECISIONS / \(viewModel.decisions.count)")
                Spacer(minLength: 3)
                Button("REFRESH") { viewModel.refreshDecisions() }
                    .buttonStyle(ExtractionAdminButtonStyle(isActive: false))
                Button("CLEAR") { viewModel.clearDecisions() }
                    .buttonStyle(ExtractionAdminButtonStyle(isActive: false))
            }
            .padding(8)

            if viewModel.decisions.isEmpty {
                VStack(spacing: 5) {
                    Text("NO DECISIONS RECORDED")
                    Text("Start a call or enter a manual value. The accepted and rejected candidates will appear here.")
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.decisions) { decision in
                            decisionRow(decision)
                        }
                    }
                }
            }
        }
    }

    private func decisionRow(_ decision: ExtractionDecision) -> some View {
        let expanded = expandedDecisions.contains(decision.id)
        return Button {
            toggle(decision.id, in: &expandedDecisions)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(decision.outcome.rawValue)
                        .fontWeight(.bold)
                        .foregroundStyle(outcomeColor(decision.outcome))
                    Spacer(minLength: 2)
                    Text(decision.field?.label ?? decision.stage.rawValue)
                        .foregroundStyle(Color.gray)
                    Image(systemName: expanded ? "minus" : "plus")
                        .font(.system(size: 8, weight: .bold))
                }
                if let proposed = decision.proposedValue {
                    HStack(spacing: 3) {
                        if let previous = decision.previousValue, previous != proposed {
                            Text(previous).strikethrough().foregroundStyle(Color.gray)
                            Text("→").foregroundStyle(Color.gray)
                        }
                        Text(proposed)
                            .foregroundStyle(Color.white)
                            .lineLimit(expanded ? nil : 1)
                    }
                }
                Text(decision.reason)
                    .foregroundStyle(Color.gray)
                    .lineLimit(expanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: expanded)
                if expanded {
                    Text(decision.ruleID)
                        .foregroundStyle(stageColor(decision.stage))
                    if let quote = decision.quote, !quote.isEmpty {
                        Text("\"\(quote)\"")
                            .foregroundStyle(Color.gray.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let seconds = decision.transcriptTimestamp {
                        Text("@ \(formatTime(seconds)) / \(decision.speaker ?? "UNKNOWN")")
                            .foregroundStyle(Color.gray.opacity(0.7))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    private func sectionLabel(_ value: String) -> some View {
        Text(value)
            .fontWeight(.bold)
            .foregroundStyle(Color.white.opacity(0.9))
            .padding(.top, 7)
            .padding(.bottom, 3)
    }

    private func configurationBinding(
        _ keyPath: WritableKeyPath<ExtractionAdminConfiguration, Bool>
    ) -> Binding<Bool> {
        Binding(
            get: { viewModel.configuration[keyPath: keyPath] },
            set: { value in
                viewModel.configuration[keyPath: keyPath] = value
                viewModel.saveConfiguration()
            }
        )
    }

    private func toggle<Element: Hashable>(_ element: Element, in set: inout Set<Element>) {
        if set.contains(element) {
            set.remove(element)
        } else {
            set.insert(element)
        }
    }

    private func stageColor(_ stage: ExtractionRuleStage) -> Color {
        switch stage {
        case .evidence: return .cyan
        case .deterministic: return .blue
        case .languageModel: return .purple
        case .replacement: return .orange
        case .inference: return .green
        }
    }

    private func outcomeColor(_ outcome: ExtractionDecisionOutcome) -> Color {
        switch outcome {
        case .accepted, .inferred: return .green
        case .replaced, .merged: return .blue
        case .rejected: return .orange
        case .unchanged, .unavailable: return .gray
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

private struct ExtractionAdminButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(isActive ? Color.black : Color(red: 0.42, green: 0.72, blue: 1))
            .padding(.horizontal, 5)
            .frame(minHeight: 18)
            .background(isActive ? Color(red: 0.42, green: 0.72, blue: 1) : Color.clear)
            .overlay(
                Rectangle().stroke(Color(red: 0.42, green: 0.72, blue: 1).opacity(0.75), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
