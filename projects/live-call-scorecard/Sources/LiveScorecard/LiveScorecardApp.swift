import AppKit
import SwiftUI

@main
struct LiveScorecardApp: App {
    @StateObject private var store = AppStore(
        demoMode: CommandLine.arguments.contains("--demo")
    )

    var body: some Scene {
        WindowGroup("Live Scorecard") {
            ScorecardView(store: store)
                .frame(minWidth: 250, minHeight: 560)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 280, height: 900)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Meeting") {
                    Task { await store.startMeeting() }
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(store.isMeetingActive)

                Button("End Meeting") {
                    Task { await store.endMeeting() }
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(!store.isMeetingActive)

                Divider()

                Button("Import Circleback Transcript…") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.json]
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK, let url = panel.url {
                        Task { await store.importCirclebackFile(url) }
                    }
                }
                .disabled(store.currentMeeting == nil)
            }
        }
    }
}
