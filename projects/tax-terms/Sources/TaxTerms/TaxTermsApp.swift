import SwiftUI

extension Notification.Name {
    static let showDashboard = Notification.Name("TaxTerms.showDashboard")
    static let showQuiz = Notification.Name("TaxTerms.showQuiz")
    static let showLists = Notification.Name("TaxTerms.showLists")
    static let showAdmin = Notification.Name("TaxTerms.showAdmin")
    static let syncTaxTerms = Notification.Name("TaxTerms.sync")
    static let toggleTaxTermsPrivacy = Notification.Name("TaxTerms.privacy")
}

@main
struct TaxTermsApp: App {
    @StateObject private var store = StudyStore()
    @StateObject private var windowController = FloatingWindowController()

    var body: some Scene {
        WindowGroup("Tax Terms") {
            RootView(store: store, windowController: windowController)
                .frame(minWidth: 340, minHeight: 320)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 400)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Study") {
                Button("Dashboard") { post(.showDashboard) }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Start Quiz") { post(.showQuiz) }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Lists") { post(.showLists) }
                    .keyboardShortcut("3", modifiers: .command)
                Button("Admin") { post(.showAdmin) }
                    .keyboardShortcut(",", modifiers: .command)
                Divider()
                Button("Sync Now") { post(.syncTaxTerms) }
                    .keyboardShortcut("s", modifiers: .command)
                Button("Privacy Curtain") { post(.toggleTaxTermsPrivacy) }
                    .keyboardShortcut("0", modifiers: [.control, .option])
            }
        }
    }

    private func post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: nil)
    }
}
