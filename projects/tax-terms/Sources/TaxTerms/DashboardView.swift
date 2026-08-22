import SwiftUI

struct CardSheetSelection: Identifiable {
    let id: String
}

struct DashboardView: View {
    @ObservedObject var store: StudyStore
    let startQuiz: (QuizLaunch) -> Void
    let openLists: () -> Void

    @State private var filter = QuizFilter()
    @State private var selectedCard: CardSheetSelection?
    @State private var showingSaveList = false

    private var palette: ThemePalette { ThemePalette(theme: store.settings.theme) }
    private var matchingCards: [TermCard] { store.cards(matching: filter) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 7) {
                stats
                quickStart
                FilterControls(filter: $filter, store: store)
                HStack(spacing: 5) {
                    Button("START \(matchingCards.count)") { startQuiz(.filter(filter)) }
                        .buttonStyle(CompactOutlineButtonStyle(accent: palette.green, filled: true))
                        .disabled(matchingCards.isEmpty)
                    Button("SAVE SMART LIST") { showingSaveList = true }
                        .buttonStyle(CompactOutlineButtonStyle(accent: palette.blue))
                    Spacer()
                    if filter != QuizFilter() {
                        Button("CLEAR") { filter = QuizFilter() }
                            .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
                    }
                }
                savedLists
                termBrowser
            }
            .padding(7)
        }
        .background(palette.background)
        .sheet(item: $selectedCard) { selection in
            TermEditorView(store: store, cardID: selection.id)
        }
        .sheet(isPresented: $showingSaveList) {
            SaveListView(store: store, initialFilter: filter, initialKind: .smart)
        }
    }

    private var stats: some View {
        PanelBox(palette: palette) {
            HStack(spacing: 0) {
                StatCell(value: store.totalCount, label: "TOTAL", color: palette.primary, palette: palette)
                StatCell(value: store.dueCount, label: "DUE", color: palette.orange, palette: palette)
                StatCell(value: store.reviewCount, label: "REVIEW", color: palette.blue, palette: palette)
                StatCell(value: store.memorizedCount, label: "MEMORIZED", color: palette.green, palette: palette)
            }
        }
    }

    private var quickStart: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionLabel("Quick start", palette: palette)
            HStack(spacing: 4) {
                quickButton("ALL", filter: QuizFilter())
                quickButton("SOFTWARE", filter: QuizFilter(tags: ["Software"]))
                quickButton("FORMS", filter: QuizFilter(tags: ["Forms & Schedules"]))
                quickButton("DUE", filter: QuizFilter(dueOnly: true))
            }
        }
    }

    private func quickButton(_ label: String, filter: QuizFilter) -> some View {
        Button(label) { startQuiz(.filter(filter)) }
            .buttonStyle(CompactOutlineButtonStyle(accent: palette.green))
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var savedLists: some View {
        if !store.lists.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    SectionLabel("Saved lists", palette: palette)
                    Spacer()
                    Button("MANAGE") { openLists() }
                        .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
                }
                ForEach(store.lists.prefix(4)) { list in
                    Button {
                        startQuiz(.list(list.id))
                    } label: {
                        HStack(spacing: 6) {
                            Text(list.name.uppercased())
                                .fontWeight(.semibold)
                                .foregroundStyle(palette.primary)
                                .lineLimit(1)
                            Text(list.kind.label).foregroundStyle(palette.faint)
                            Spacer()
                            Text("\(store.cards(in: list).count)").foregroundStyle(palette.green)
                            Image(systemName: "play.fill").foregroundStyle(palette.green)
                        }
                        .font(.system(size: 8.5, design: .monospaced))
                        .padding(.horizontal, 7)
                        .frame(minHeight: 24)
                        .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
                    }
                    .buttonStyle(BareRowButtonStyle())
                }
            }
        }
    }

    private var termBrowser: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                SectionLabel("Terms", palette: palette)
                Spacer()
                Text("\(matchingCards.count)").foregroundStyle(palette.faint)
            }
            LazyVStack(spacing: 0) {
                ForEach(matchingCards) { card in
                    Button { selectedCard = CardSheetSelection(id: card.id) } label: {
                        TermCompactRow(card: card, palette: palette)
                    }
                    .buttonStyle(BareRowButtonStyle())
                }
            }
            .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
        }
    }
}

struct TermCompactRow: View {
    let card: TermCard
    let palette: ThemePalette

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(stateColor)
                .frame(width: 5, height: 5)
            VStack(alignment: .leading, spacing: 1) {
                Text(card.content.term)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                Text(card.content.categories.joined(separator: " · ").uppercased())
                    .font(.system(size: 6.8, design: .monospaced))
                    .foregroundStyle(palette.faint)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if !card.content.priority.isEmpty {
                Text(card.content.priority.uppercased())
                    .font(.system(size: 6.8, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(palette.faint)
        }
        .padding(.horizontal, 7)
        .frame(minHeight: 29)
        .overlay(alignment: .bottom) { Rectangle().fill(palette.border).frame(height: 1) }
    }

    private var stateColor: Color {
        switch card.content.status {
        case .notStarted: return palette.faint
        case .needsReview: return palette.orange
        case .memorized: return palette.green
        }
    }
}

struct FilterControls: View {
    @Binding var filter: QuizFilter
    @ObservedObject var store: StudyStore

    private var palette: ThemePalette { ThemePalette(theme: store.settings.theme) }

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass").foregroundStyle(palette.faint)
                TextField("SEARCH TERMS…", text: $filter.search)
                    .textFieldStyle(.plain)
                    .font(.system(size: 9, design: .monospaced))
            }
            .padding(.horizontal, 7)
            .frame(height: 26)
            .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }

            HStack(spacing: 4) {
                Menu {
                    Picker("Match", selection: $filter.tagMatchMode) {
                        ForEach(TagMatchMode.allCases) { Text($0.label).tag($0) }
                    }
                    Divider()
                    ForEach(store.categoryOptions, id: \.self) { tag in
                        Button {
                            toggle(tag, in: &filter.tags)
                        } label: {
                            Label(tag, systemImage: filter.tags.contains(tag) ? "checkmark" : "plus")
                        }
                    }
                } label: {
                    Text(filter.tags.isEmpty ? "TAGS" : "TAGS \(filter.tags.count)")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Menu {
                    ForEach(["Core", "Useful", "Advanced"], id: \.self) { priority in
                        Button { toggle(priority, in: &filter.priorities) } label: {
                            Label(priority, systemImage: filter.priorities.contains(priority) ? "checkmark" : "plus")
                        }
                    }
                } label: {
                    Text(filter.priorities.isEmpty ? "PRIORITY" : "PRIORITY \(filter.priorities.count)")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Spacer(minLength: 0)
                Button("DUE") { filter.dueOnly.toggle() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.orange, filled: filter.dueOnly))
            }

            HStack(spacing: 4) {
                ForEach(StudyState.allCases) { state in
                    Button(state.label) { toggle(state, in: &filter.states) }
                        .buttonStyle(CompactOutlineButtonStyle(
                            accent: state == .memorized ? palette.green : state == .needsReview ? palette.orange : palette.faint,
                            filled: filter.states.contains(state)
                        ))
                }
            }
        }
    }

    private func toggle<T: Hashable>(_ value: T, in set: inout Set<T>) {
        if set.contains(value) { set.remove(value) } else { set.insert(value) }
    }
}
