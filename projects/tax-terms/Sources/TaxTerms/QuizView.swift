import AppKit
import SwiftUI

struct QuizView: View {
    @ObservedObject var store: StudyStore
    let launch: QuizLaunch
    let exitQuiz: () -> Void

    @State private var queue: [String] = []
    @State private var index = 0
    @State private var revealed = false
    @State private var sessionRatings: [StudyRating: Int] = [:]
    @State private var keyMonitor: LocalKeyMonitor?
    @State private var selectedCard: CardSheetSelection?

    private var palette: ThemePalette { ThemePalette(theme: store.settings.theme) }
    private var currentCard: TermCard? {
        guard queue.indices.contains(index) else { return nil }
        return store.card(id: queue[index])
    }

    var body: some View {
        VStack(spacing: 0) {
            quizHeader
            CompactDivider(palette: palette)
            if queue.isEmpty {
                emptyState
            } else if index >= queue.count {
                summary
            } else if let card = currentCard {
                cardView(card)
            }
        }
        .background(palette.background)
        .onAppear {
            buildQueue()
            let monitor = LocalKeyMonitor()
            monitor.start { event in handle(event) }
            keyMonitor = monitor
        }
        .onDisappear {
            keyMonitor?.stop()
            keyMonitor = nil
        }
        .onChange(of: launch) { _, _ in buildQueue() }
        .sheet(item: $selectedCard) { selection in
            TermEditorView(store: store, cardID: selection.id)
        }
    }

    private var quizHeader: some View {
        HStack(spacing: 6) {
            Button("← HOME") { exitQuiz() }
                .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
            Text(index < queue.count ? "\(index + 1)/\(queue.count)" : "DONE")
                .foregroundStyle(palette.secondary)
            Spacer()
            Text("1 AGAIN · 2 REVIEW · 3 MEMORIZED")
                .font(.system(size: 6.8, design: .monospaced))
                .foregroundStyle(palette.faint)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
    }

    private func cardView(_ card: TermCard) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if revealed {
                    back(card)
                } else {
                    front(card)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CompactDivider(palette: palette)
            if revealed {
                ratingBar(card)
            } else {
                HStack(spacing: 6) {
                    Button("SPACE — REVEAL") { revealed = true }
                        .buttonStyle(CompactOutlineButtonStyle(accent: palette.green, filled: true))
                    Spacer()
                    Button("EDIT") { selectedCard = CardSheetSelection(id: card.id) }
                        .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
                }
                .padding(7)
            }
        }
    }

    private func front(_ card: TermCard) -> some View {
        VStack(spacing: 12) {
            Spacer()
            StateBadge(state: card.content.status, palette: palette)
            Text(card.content.term)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.primary)
                .padding(.horizontal, 18)
            if !card.content.categories.isEmpty {
                FlowLayout(spacing: 3) {
                    ForEach(card.content.categories, id: \.self) { tag in
                        TagChip(text: tag, selected: false, palette: palette)
                    }
                }
                .frame(maxWidth: 280)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { revealed = true }
    }

    private func back(_ card: TermCard) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(card.content.term)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.green)
                    Spacer()
                    Button("EDIT") { selectedCard = CardSheetSelection(id: card.id) }
                        .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
                }
                if store.settings.visibleBackFields.contains(.definition) {
                    backField("DEFINITION", card.content.definition)
                }
                if store.settings.visibleBackFields.contains(.whyItMatters) {
                    backField("WHY IT MATTERS", card.content.whyItMatters)
                }
                if store.settings.visibleBackFields.contains(.example) {
                    backField("EXAMPLE", card.content.example)
                }
                if store.settings.visibleBackFields.contains(.priority), !card.content.priority.isEmpty {
                    backField("PRIORITY", card.content.priority)
                }
                if store.settings.visibleBackFields.contains(.categories) {
                    FlowLayout(spacing: 3) {
                        ForEach(card.content.categories, id: \.self) { tag in
                            TagChip(text: tag, selected: false, palette: palette)
                        }
                    }
                }
                if store.settings.visibleBackFields.contains(.resources), !card.content.resources.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        fieldLabel("RESOURCES")
                        ForEach(card.content.resources) { resource in
                            if let url = resource.destinationURL {
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Image(systemName: resource.kind == .video ? "play.rectangle" : "link")
                                        Text(resource.title).lineLimit(2)
                                    }
                                    .font(.system(size: 8.5, design: .monospaced))
                                    .foregroundStyle(palette.blue)
                                }
                            }
                        }
                    }
                }
                if store.settings.visibleBackFields.contains(.studyNotes) {
                    VStack(alignment: .leading, spacing: 3) {
                        fieldLabel("NOTES — AUTOSAVES + SYNCS")
                        TextEditor(text: Binding(
                            get: { store.card(id: card.id)?.content.studyNotes ?? "" },
                            set: { store.updateNotes(cardID: card.id, notes: $0) }
                        ))
                        .font(.system(size: 9, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(3)
                        .frame(minHeight: 66)
                        .background(palette.surface)
                        .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
                    }
                }
            }
            .padding(9)
        }
    }

    private func backField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            fieldLabel(label)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(value.isEmpty ? palette.faint : palette.primary)
                .textSelection(.enabled)
        }
    }

    private func fieldLabel(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 7, weight: .bold, design: .monospaced))
            .foregroundStyle(palette.faint)
    }

    private func ratingBar(_ card: TermCard) -> some View {
        HStack(spacing: 5) {
            ratingButton("1 AGAIN", .again, palette.red, card)
            ratingButton("2 REVIEW", .review, palette.orange, card)
            ratingButton("3 MEMORIZED", .memorized, palette.green, card)
        }
        .padding(7)
    }

    private func ratingButton(_ label: String, _ rating: StudyRating, _ color: Color, _ card: TermCard) -> some View {
        Button(label) { rate(rating, card: card) }
            .buttonStyle(CompactOutlineButtonStyle(accent: color, filled: rating == .memorized))
            .frame(maxWidth: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "rectangle.stack.badge.minus")
                .font(.system(size: 24))
                .foregroundStyle(palette.faint)
            Text("NO TERMS MATCH THIS QUIZ")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
            Button("BACK") { exitQuiz() }
                .buttonStyle(CompactOutlineButtonStyle(accent: palette.green))
            Spacer()
        }
    }

    private var summary: some View {
        VStack(spacing: 11) {
            Spacer()
            Text("SESSION COMPLETE")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.green)
            HStack(spacing: 0) {
                StatCell(value: sessionRatings[.again, default: 0], label: "AGAIN", color: palette.red, palette: palette)
                StatCell(value: sessionRatings[.review, default: 0], label: "REVIEW", color: palette.orange, palette: palette)
                StatCell(value: sessionRatings[.memorized, default: 0], label: "MEMORIZED", color: palette.green, palette: palette)
            }
            .frame(maxWidth: 280)
            HStack(spacing: 5) {
                Button("QUIZ AGAIN") { buildQueue() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.green, filled: true))
                Button("HOME") { exitQuiz() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
            }
            Spacer()
        }
    }

    private func buildQueue() {
        let cards: [TermCard]
        switch launch {
        case .filter(let filter): cards = store.cards(matching: filter)
        case .list(let id):
            cards = store.lists.first(where: { $0.id == id }).map(store.cards(in:)) ?? []
        }
        queue = cards.map(\.id)
        if store.settings.shuffleQuiz { queue.shuffle() }
        index = 0
        revealed = false
        sessionRatings = [:]
    }

    private func rate(_ rating: StudyRating, card: TermCard) {
        store.record(rating, for: card.id)
        sessionRatings[rating, default: 0] += 1
        index += 1
        revealed = false
    }

    private func handle(_ event: NSEvent) -> NSEvent? {
        if NSApp.keyWindow?.firstResponder is NSTextView { return event }
        guard index < queue.count, let card = currentCard else { return event }
        switch event.keyCode {
        case 49: revealed = true; return nil // space
        case 18 where revealed: rate(.again, card: card); return nil
        case 19 where revealed: rate(.review, card: card); return nil
        case 20 where revealed: rate(.memorized, card: card); return nil
        case 123 where index > 0: index -= 1; revealed = false; return nil
        case 124 where index < queue.count - 1: index += 1; revealed = false; return nil
        default: return event
        }
    }
}

final class LocalKeyMonitor {
    private var monitor: Any?

    func start(handler: @escaping (NSEvent) -> NSEvent?) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: handler)
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    deinit { stop() }
}
