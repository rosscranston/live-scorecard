import SwiftUI

struct NotepadRootView: View {
    private enum Panel {
        case note
        case admin
    }

    @ObservedObject var store: NoteStore
    @ObservedObject var windowController: FloatingWindowController
    @ObservedObject var gitSync: GitSyncService
    @State private var panel: Panel = .note

    private let terminalGreen = Color(red: 0.33, green: 1.0, blue: 0.57)
    private let adminBlue = Color(red: 0.42, green: 0.72, blue: 1.0)
    private let dim = Color.white.opacity(0.42)

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.16))

            if panel == .note {
                editor
            } else {
                AdminPanel(
                    controller: windowController,
                    store: store,
                    gitSync: gitSync
                )
            }

            Divider().overlay(Color.white.opacity(0.16))
            footer
        }
        .background(Color.black)
        .foregroundStyle(Color.white)
        .font(.system(size: 10, weight: .regular, design: .monospaced))
        .background(WindowAccessor(controller: windowController))
        .onAppear { gitSync.start() }
        .onDisappear { store.saveNow() }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(saveIndicatorColor)
                .frame(width: 6, height: 6)
                .help(store.saveState.label)
            Text("Private Notepad")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(terminalGreen)
            Spacer(minLength: 4)
            Button(panel == .admin ? "NOTE" : "ADMIN") {
                panel = panel == .admin ? .note : .admin
            }
            .buttonStyle(CompactHeaderButtonStyle(
                accent: panel == .admin ? adminBlue : terminalGreen,
                isActive: panel == .admin
            ))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: Binding(
                get: { store.text },
                set: { store.updateFromEditor($0) }
            ))
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.92))
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)

            if store.text.isEmpty {
                Text("TYPE PRIVATE CALL NOTES…")
                    .foregroundStyle(dim)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 11)
                    .allowsHitTesting(false)
            }
        }
        .background(Color.black)
    }

    private var footer: some View {
        HStack(spacing: 7) {
            Text(store.dayLabel)
                .foregroundStyle(terminalGreen)
            Text("30M GIT")
                .foregroundStyle(dim)
            Spacer()
            Text("L \(store.lineCount) / W \(store.wordCount) / C \(store.characterCount)")
                .foregroundStyle(dim)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.04))
        .help(store.documentURL.path)
    }

    private var saveIndicatorColor: Color {
        store.saveState == .saved ? terminalGreen : .yellow
    }
}

private struct AdminPanel: View {
    @ObservedObject var controller: FloatingWindowController
    @ObservedObject var store: NoteStore
    @ObservedObject var gitSync: GitSyncService

    private let blue = Color(red: 0.42, green: 0.72, blue: 1.0)
    private let green = Color(red: 0.33, green: 1.0, blue: 0.57)
    private let dim = Color.white.opacity(0.42)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                sectionLabel("WINDOW OPACITY")
                HStack(spacing: 5) {
                    Text("TRANSPARENCY")
                    Spacer(minLength: 4)
                    Text("\(Int((controller.transparency * 100).rounded()))%")
                        .foregroundStyle(Color.gray)
                        .frame(width: 34, alignment: .trailing)
                }
                Slider(
                    value: Binding(
                        get: { controller.transparency },
                        set: { controller.setTransparency($0) }
                    ),
                    in: 0...WindowTransparency.maximumValue,
                    step: 0.05
                )
                .controlSize(.mini)
                .tint(blue)
                Text("0% = OPAQUE / 75% = MOST TRANSPARENT")
                    .foregroundStyle(dim)

                sectionLabel("SNAP POSITION")
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(WindowPosition.gridOrder) { position in
                        Button {
                            controller.snap(to: position)
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: position.symbolName)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(position.shortcutLabel)
                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            }
                            .frame(maxWidth: .infinity, minHeight: 35)
                        }
                        .buttonStyle(AdminPositionButtonStyle(
                            isActive: controller.currentPosition == position
                        ))
                        .help("\(position.label) / \(position.shortcutLabel)")
                    }
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(controller.globalShortcutsAvailable ? green : Color.orange)
                        .frame(width: 5, height: 5)
                    Text(controller.globalShortcutsAvailable
                         ? "GLOBAL SHORTCUTS ACTIVE"
                         : "ONE OR MORE SHORTCUTS UNAVAILABLE")
                        .foregroundStyle(controller.globalShortcutsAvailable ? green : Color.orange)
                }
                Text("⌃⌥1–9 FOLLOW THE GRID ABOVE AND WORK WHILE ANOTHER APP IS ACTIVE.")
                    .foregroundStyle(dim)
                    .fixedSize(horizontal: false, vertical: true)

                sectionLabel("TIMESTAMPED DAILY LOG")
                settingsRow("INACTIVITY BREAK", value: "10 SEC")
                settingsRow("CURRENT DOCUMENT", value: "\(store.dayLabel).md")
                Text("TIMESTAMPS ARE HIDDEN IN THE EDITOR. EVERY SAVED NOTE LINE AND TYPING BURST AFTER 10 SECONDS OF INACTIVITY KEEPS ITS [HH:MM:SS] TIME IN THE DAILY FILE.")
                    .foregroundStyle(dim)
                    .fixedSize(horizontal: false, vertical: true)

                sectionLabel("GITHUB SYNC")
                settingsRow("REPOSITORY", value: "PRIVATE")
                settingsRow("INTERVAL", value: "30 MIN")
                settingsRow("STATUS", value: gitSync.state.label)
                if let nextSyncAt = gitSync.nextSyncAt {
                    settingsRow("NEXT", value: formatClock(nextSyncAt))
                }
                if let detail = gitSync.state.detail {
                    Text(detail)
                        .foregroundStyle(syncStatusColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button("SYNC NOW") {
                    store.saveNow()
                    gitSync.syncNow()
                }
                .buttonStyle(AdminTextButtonStyle())

                sectionLabel("SCREENSHARE PRIVACY")
                privacyRow("SEPARATE FLOATING WINDOW", state: "ON")
                privacyRow("ALWAYS ON TOP / ALL SPACES", state: "ON")
                privacyRow("LEGACY CAPTURE-OPT-OUT HINT", state: "ON*")
                Text("REQUIRED: SHARE A SINGLE BROWSER OR APP WINDOW. DO NOT SHARE ENTIRE SCREEN OR DISPLAY. MACOS DOES NOT OFFER A GUARANTEED FLAG THAT HIDES AN ARBITRARY WINDOW FROM EVERY FULL-DISPLAY CAPTURE TOOL.")
                    .foregroundStyle(Color.orange)
                    .fixedSize(horizontal: false, vertical: true)

                sectionLabel("STORAGE")
                Text(store.notesDirectoryURL.path)
                    .foregroundStyle(dim)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                Button("RESET LAYOUT") {
                    controller.resetLayout()
                }
                .buttonStyle(AdminTextButtonStyle())
                .padding(.top, 4)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
        }
        .foregroundStyle(blue)
        .background(Color.black)
    }

    private func sectionLabel(_ value: String) -> some View {
        Text(value)
            .fontWeight(.bold)
            .foregroundStyle(Color.white.opacity(0.9))
            .padding(.top, 6)
            .padding(.bottom, 1)
    }

    private func privacyRow(_ label: String, state: String) -> some View {
        settingsRow(label, value: state, valueColor: green)
    }

    private func settingsRow(
        _ label: String,
        value: String,
        valueColor: Color? = nil
    ) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .foregroundStyle(dim)
            Spacer(minLength: 4)
            Text(value)
                .fontWeight(.bold)
                .foregroundStyle(valueColor ?? blue)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    private var syncStatusColor: Color {
        switch gitSync.state {
        case .failed: return .orange
        case .synced: return green
        case .waiting, .syncing: return dim
        }
    }

    private func formatClock(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

private struct CompactHeaderButtonStyle: ButtonStyle {
    let accent: Color
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(isActive ? Color.black : accent)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(isActive ? accent : Color.clear)
            .overlay {
                Rectangle().stroke(accent, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

private struct AdminPositionButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        let blue = Color(red: 0.42, green: 0.72, blue: 1.0)
        return configuration.label
            .foregroundStyle(isActive ? Color.black : blue)
            .background(isActive ? blue : Color.clear)
            .overlay {
                Rectangle().stroke(blue.opacity(0.8), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

private struct AdminTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let blue = Color(red: 0.42, green: 0.72, blue: 1.0)
        return configuration.label
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(blue)
            .padding(.horizontal, 6)
            .frame(minHeight: 20)
            .overlay {
                Rectangle().stroke(blue.opacity(0.8), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
