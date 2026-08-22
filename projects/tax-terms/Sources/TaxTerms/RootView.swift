import AppKit
import SwiftUI

enum RootPanel: String, CaseIterable {
    case dashboard
    case quiz
    case lists
    case admin
}

enum QuizLaunch: Equatable {
    case filter(QuizFilter)
    case list(UUID)
}

struct RootView: View {
    @ObservedObject var store: StudyStore
    @ObservedObject var windowController: FloatingWindowController

    @State private var panel: RootPanel = .dashboard
    @State private var quizLaunch: QuizLaunch = .filter(QuizFilter())

    private var palette: ThemePalette { ThemePalette(theme: store.settings.theme) }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                CompactDivider(palette: palette)
                content
                CompactDivider(palette: palette)
                footer
            }
            .background(palette.background)
            .foregroundStyle(palette.primary)

            if windowController.privacyCurtain {
                privacyCurtain
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .font(.system(size: 10, weight: .regular, design: .monospaced))
        .preferredColorScheme(store.settings.theme == .dark ? .dark : .light)
        .background(WindowAccessor(controller: windowController, settings: store.settings))
        .onAppear { store.beginAutomaticSync() }
        .onDisappear { store.saveNow() }
        .onReceive(NotificationCenter.default.publisher(for: .showDashboard)) { _ in panel = .dashboard }
        .onReceive(NotificationCenter.default.publisher(for: .showQuiz)) { _ in
            quizLaunch = .filter(QuizFilter())
            panel = .quiz
        }
        .onReceive(NotificationCenter.default.publisher(for: .showLists)) { _ in panel = .lists }
        .onReceive(NotificationCenter.default.publisher(for: .showAdmin)) { _ in panel = .admin }
        .onReceive(NotificationCenter.default.publisher(for: .syncTaxTerms)) { _ in
            Task { await store.syncNow() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleTaxTermsPrivacy)) { _ in
            windowController.togglePrivacyCurtain()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            if store.settings.autoCurtainWhenInactive { windowController.setPrivacyCurtain(true) }
        }
        .animation(.easeOut(duration: 0.12), value: windowController.privacyCurtain)
    }

    @ViewBuilder
    private var content: some View {
        switch panel {
        case .dashboard:
            DashboardView(
                store: store,
                startQuiz: { launch in quizLaunch = launch; panel = .quiz },
                openLists: { panel = .lists }
            )
        case .quiz:
            QuizView(store: store, launch: quizLaunch) { panel = .dashboard }
        case .lists:
            ListsView(store: store) { listID in quizLaunch = .list(listID); panel = .quiz }
        case .admin:
            AdminView(store: store, windowController: windowController)
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(syncColor)
                .frame(width: 6, height: 6)
                .help(store.syncState.label)
            Text("TAX TERMS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.green)
            Spacer(minLength: 2)
            ForEach(RootPanel.allCases, id: \.self) { item in
                Button(shortLabel(item)) { panel = item }
                    .buttonStyle(CompactOutlineButtonStyle(
                        accent: item == panel ? palette.green : palette.faint,
                        filled: item == panel
                    ))
                    .help(item.rawValue.uppercased())
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(palette.background)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Text(store.syncState.label)
                .foregroundStyle(syncColor)
            if let last = store.snapshot.lastSyncedAt {
                Text(last, style: .time).foregroundStyle(palette.faint)
            }
            Spacer()
            Text("\(store.totalCount) TERMS")
                .foregroundStyle(palette.secondary)
            Button("PRIVACY ⌃⌥0") { windowController.togglePrivacyCurtain() }
                .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
        }
        .font(.system(size: 7.5, weight: .medium, design: .monospaced))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(palette.surface)
    }

    private var privacyCurtain: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 7) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 28, weight: .light))
                Text("PRIVATE")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                Text("⌃⌥0 TO RESTORE")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.46))
            }
            .foregroundStyle(Color.white.opacity(0.86))
        }
        .onTapGesture { windowController.togglePrivacyCurtain() }
    }

    private var syncColor: Color {
        switch store.syncState {
        case .synced, .idle: return palette.green
        case .syncing: return palette.blue
        case .failed: return palette.red
        case .disconnected: return palette.orange
        }
    }

    private func shortLabel(_ panel: RootPanel) -> String {
        switch panel {
        case .dashboard: return "HOME"
        case .quiz: return "QUIZ"
        case .lists: return "LISTS"
        case .admin: return "ADMIN"
        }
    }
}
