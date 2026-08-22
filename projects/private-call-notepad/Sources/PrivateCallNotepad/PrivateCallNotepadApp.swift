import SwiftUI

@main
struct PrivateCallNotepadApp: App {
    @StateObject private var noteStore: NoteStore
    @StateObject private var windowController: FloatingWindowController
    @StateObject private var gitSync: GitSyncService

    init() {
        let repositoryURL = NotesRepositoryPaths.defaultRepositoryURL()
        _noteStore = StateObject(wrappedValue: NoteStore(repositoryURL: repositoryURL))
        _windowController = StateObject(wrappedValue: FloatingWindowController())
        _gitSync = StateObject(wrappedValue: GitSyncService(repositoryURL: repositoryURL))
    }

    var body: some Scene {
        WindowGroup("Private Call Notepad") {
            NotepadRootView(
                store: noteStore,
                windowController: windowController,
                gitSync: gitSync
            )
            .frame(minWidth: 280, minHeight: 360)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 320, height: 660)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
