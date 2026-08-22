import AppKit
import SwiftUI

struct AdminView: View {
    @ObservedObject var store: StudyStore
    @ObservedObject var windowController: FloatingWindowController

    @State private var token = ""
    @State private var tokenMessage: String?
    @State private var exportMessage: String?

    private var palette: ThemePalette { ThemePalette(theme: store.settings.theme) }
    private let grid = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                appearance
                backFields
                windowControls
                notionConnection
                syncDetails
                keyboardShortcuts
                privacy
                dataControls
            }
            .padding(8)
        }
        .background(palette.background)
        .foregroundStyle(palette.primary)
    }

    private var appearance: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionLabel("Appearance", palette: palette)
            Picker("Theme", selection: settingBinding(\.theme)) {
                ForEach(AppTheme.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            HStack {
                Text("SHUFFLE QUIZ").foregroundStyle(palette.secondary)
                Spacer()
                Toggle("", isOn: settingBinding(\.shuffleQuiz)).labelsHidden().controlSize(.small)
            }
            .settingsRow(palette)
        }
    }

    private var backFields: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel("Card back fields", palette: palette)
            ForEach(BackField.allCases) { field in
                HStack {
                    Text(field.label).foregroundStyle(palette.secondary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { store.settings.visibleBackFields.contains(field) },
                        set: { enabled in
                            store.updateSettings {
                                if enabled { $0.visibleBackFields.insert(field) }
                                else { $0.visibleBackFields.remove(field) }
                            }
                        }
                    ))
                    .labelsHidden()
                    .controlSize(.small)
                }
                .settingsRow(palette)
            }
        }
    }

    private var windowControls: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionLabel("Window", palette: palette)
            HStack {
                Text("TRANSPARENCY").foregroundStyle(palette.secondary)
                Slider(value: Binding(
                    get: { store.settings.transparency },
                    set: { value in store.updateSettings { $0.transparency = value } }
                ), in: 0...0.60, step: 0.05)
                .controlSize(.mini)
                .tint(palette.blue)
                Text("\(Int(store.settings.transparency * 100))%")
                    .foregroundStyle(palette.blue)
                    .frame(width: 28, alignment: .trailing)
            }
            .settingsRow(palette)
            toggleRow("ALWAYS ON TOP", binding: settingBinding(\.alwaysOnTop))
            toggleRow("AUTO CURTAIN WHEN INACTIVE", binding: settingBinding(\.autoCurtainWhenInactive))
            LazyVGrid(columns: grid, spacing: 4) {
                ForEach(WindowPosition.gridOrder) { position in
                    Button {
                        windowController.snap(to: position)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: position.symbolName)
                            Text(position.shortcutLabel)
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(CompactOutlineButtonStyle(
                        accent: palette.blue,
                        filled: windowController.currentPosition == position
                    ))
                    .help(position.label)
                }
            }
            HStack {
                Text("DEFAULT: 25% WIDTH × 40% HEIGHT · TOP RIGHT")
                    .font(.system(size: 7.2, design: .monospaced))
                    .foregroundStyle(palette.faint)
                Spacer()
                Button("RESET") { windowController.resetLayout() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
            }
        }
    }

    private var notionConnection: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionLabel("Notion connection", palette: palette)
            Text(store.hasNotionToken ? "TOKEN STORED IN MACOS KEYCHAIN" : "NO TOKEN STORED")
                .foregroundStyle(store.hasNotionToken ? palette.green : palette.orange)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
            VStack(alignment: .leading, spacing: 3) {
                instruction("1", "Ask a workspace owner to create an internal Notion integration if you cannot.")
                instruction("2", "Give it Read content and Update content capabilities.")
                instruction("3", "Open the Terms database · ••• · Connections · add the integration.")
                instruction("4", "Paste the integration token below. It never enters the source code.")
            }
            Link("OPEN NOTION INTEGRATION GUIDE ↗", destination: URL(string: "https://developers.notion.com/guides/get-started/create-a-notion-integration")!)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.blue)
            SecureField(store.hasNotionToken ? "PASTE A NEW TOKEN TO REPLACE" : "PASTE NOTION TOKEN", text: $token)
                .textFieldStyle(.plain)
                .padding(7)
                .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
            HStack(spacing: 5) {
                Button("SAVE + TEST + SYNC") { connect() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.green, filled: true))
                    .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if store.hasNotionToken {
                    Button("REMOVE TOKEN") {
                        do { try store.removeNotionToken(); tokenMessage = "TOKEN REMOVED" }
                        catch { tokenMessage = error.localizedDescription }
                    }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.red))
                }
            }
            if let tokenMessage {
                Text(tokenMessage)
                    .font(.system(size: 7.5, design: .monospaced))
                    .foregroundStyle(palette.orange)
                    .textSelection(.enabled)
            }
        }
    }

    private var syncDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel("Sync", palette: palette)
            settingsValue("STATUS", store.syncState.label, color: syncColor)
            settingsValue("INTERVAL", "\(store.settings.syncIntervalMinutes) MIN", color: palette.blue)
            settingsValue("DATA SOURCE", store.settings.dataSourceID, color: palette.faint)
            if let date = store.snapshot.lastSyncedAt {
                settingsValue("LAST SUCCESS", date.formatted(date: .abbreviated, time: .standard), color: palette.green)
            }
            Button("SYNC NOW ⌘S") { Task { await store.syncNow() } }
                .buttonStyle(CompactOutlineButtonStyle(accent: palette.blue))
                .disabled(!store.hasNotionToken || store.syncState == .syncing)
            if case .failed(let message) = store.syncState {
                Text(message)
                    .foregroundStyle(palette.red)
                    .font(.system(size: 7.5, design: .monospaced))
                    .textSelection(.enabled)
            }
            if !store.conflicts.isEmpty {
                Text("\(store.conflicts.count) SYNC CONFLICTS · LOCAL VALUE KEPT")
                    .foregroundStyle(palette.orange)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                ForEach(store.conflicts.suffix(5)) { conflict in
                    Text("\(conflict.term) · \(conflict.field.rawValue)")
                        .foregroundStyle(palette.secondary)
                        .font(.system(size: 7.5, design: .monospaced))
                }
                Button("CLEAR CONFLICT LOG") { store.clearConflicts() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
            }
        }
    }

    private var keyboardShortcuts: some View {
        VStack(alignment: .leading, spacing: 3) {
            SectionLabel("Keyboard shortcuts", palette: palette)
            shortcut("⌘1 / ⌘2 / ⌘3 / ⌘,", "HOME / QUIZ / LISTS / ADMIN")
            shortcut("SPACE", "REVEAL CARD")
            shortcut("1 / 2 / 3", "AGAIN / REVIEW / MEMORIZED")
            shortcut("← / →", "PREVIOUS / NEXT")
            shortcut("⌘S", "SYNC NOW")
            shortcut("⌃⌥1–9", "SNAP WINDOW")
            shortcut("⌃⌥0", "PRIVACY CURTAIN")
            settingsValue(
                "GLOBAL SHORTCUTS",
                windowController.globalShortcutsAvailable ? "ACTIVE" : "ONE OR MORE UNAVAILABLE",
                color: windowController.globalShortcutsAvailable ? palette.green : palette.orange
            )
        }
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel("Screenshare privacy", palette: palette)
            settingsValue("FLOATING WINDOW", "ON", color: palette.green)
            settingsValue("LEGACY CAPTURE HINT", "ON · BEST EFFORT", color: palette.orange)
            settingsValue("PRIVACY CURTAIN", "⌃⌥0", color: palette.green)
            Text("MACOS DOES NOT PROVIDE A PUBLIC API THAT GUARANTEES HIDING AN ARBITRARY APP FROM WHOLE-DISPLAY SCREENSHOTS. SHARE A SINGLE BROWSER OR APP WINDOW, NOT THE ENTIRE DISPLAY.")
                .foregroundStyle(palette.orange)
                .font(.system(size: 7.4, weight: .medium, design: .monospaced))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var dataControls: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel("Storage", palette: palette)
            Text(AppPaths.studyDatabaseURL().path)
                .font(.system(size: 7.2, design: .monospaced))
                .foregroundStyle(palette.faint)
                .textSelection(.enabled)
            Text("LOCAL DATABASE: AES-256-GCM ENCRYPTED · KEY: MACOS KEYCHAIN")
                .font(.system(size: 7.2, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.green)
            Button("EXPORT PLAINTEXT JSON") {
                do {
                    let url = try store.exportPlaintextCopy()
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    exportMessage = "EXPORTED: \(url.path)"
                } catch {
                    exportMessage = error.localizedDescription
                }
            }
            .buttonStyle(CompactOutlineButtonStyle(accent: palette.orange))
            if let exportMessage {
                Text(exportMessage)
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(palette.faint)
                    .textSelection(.enabled)
            }
            if let error = store.persistenceError {
                Text("LOCAL SAVE ERROR: \(error)")
                    .font(.system(size: 7.5, design: .monospaced))
                    .foregroundStyle(palette.red)
            }
        }
    }

    private func connect() {
        do {
            try store.saveNotionToken(token)
            token = ""
            tokenMessage = "TOKEN SAVED · TESTING CONNECTION"
            Task { await store.syncNow() }
        } catch {
            tokenMessage = error.localizedDescription
        }
    }

    private func instruction(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 5) {
            Text(number).foregroundStyle(palette.green).fontWeight(.bold)
            Text(text).foregroundStyle(palette.secondary)
        }
        .font(.system(size: 7.6, design: .monospaced))
    }

    private func toggleRow(_ label: String, binding: Binding<Bool>) -> some View {
        HStack {
            Text(label).foregroundStyle(palette.secondary)
            Spacer()
            Toggle("", isOn: binding).labelsHidden().controlSize(.small)
        }
        .settingsRow(palette)
    }

    private func shortcut(_ keys: String, _ action: String) -> some View {
        HStack {
            Text(keys).foregroundStyle(palette.blue).fontWeight(.bold)
            Spacer()
            Text(action).foregroundStyle(palette.secondary)
        }
        .settingsRow(palette)
    }

    private func settingsValue(_ label: String, _ value: String, color: Color) -> some View {
        HStack {
            Text(label).foregroundStyle(palette.secondary)
            Spacer(minLength: 5)
            Text(value).foregroundStyle(color).fontWeight(.bold).lineLimit(1)
        }
        .settingsRow(palette)
    }

    private var syncColor: Color {
        switch store.syncState {
        case .synced, .idle: return palette.green
        case .syncing: return palette.blue
        case .failed: return palette.red
        case .disconnected: return palette.orange
        }
    }

    private func settingBinding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { store.settings[keyPath: keyPath] },
            set: { newValue in store.updateSettings { $0[keyPath: keyPath] = newValue } }
        )
    }
}

private extension View {
    func settingsRow(_ palette: ThemePalette) -> some View {
        self
            .font(.system(size: 8, design: .monospaced))
            .padding(.vertical, 3)
            .overlay(alignment: .bottom) { Rectangle().fill(palette.border).frame(height: 1) }
    }
}
