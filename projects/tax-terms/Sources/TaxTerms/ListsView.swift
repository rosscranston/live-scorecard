import SwiftUI

struct ListsView: View {
    @ObservedObject var store: StudyStore
    let startQuiz: (UUID) -> Void

    @State private var selectedListID: UUID?
    @State private var showingNewList = false
    @State private var editingList: SavedQuizList?
    @State private var showingMembers = false
    @State private var selectedCard: CardSheetSelection?

    private var palette: ThemePalette { ThemePalette(theme: store.settings.theme) }
    private var selectedList: SavedQuizList? {
        guard let selectedListID else { return nil }
        return store.lists.first { $0.id == selectedListID }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            CompactDivider(palette: palette)
            if let list = selectedList {
                listDetail(list)
            } else {
                emptyState
            }
        }
        .background(palette.background)
        .onAppear {
            if selectedListID == nil { selectedListID = store.lists.first?.id }
        }
        .onChange(of: store.lists.map(\.id)) { _, ids in
            if let selectedListID, !ids.contains(selectedListID) { self.selectedListID = ids.first }
        }
        .sheet(isPresented: $showingNewList) {
            SaveListView(store: store, initialFilter: QuizFilter(), initialKind: .smart)
        }
        .sheet(item: $editingList) { list in
            SaveListView(store: store, editing: list)
        }
        .sheet(isPresented: $showingMembers) {
            if let list = selectedList { ManualListMembersView(store: store, list: list) }
        }
        .sheet(item: $selectedCard) { selection in
            TermEditorView(store: store, cardID: selection.id)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 6) {
            Menu {
                ForEach(store.lists) { list in
                    Button(list.name) { selectedListID = list.id }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedList?.name.uppercased() ?? "SELECT LIST")
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.primary)
            }
            .menuStyle(.borderlessButton)
            Spacer()
            Button("NEW") { showingNewList = true }
                .buttonStyle(CompactOutlineButtonStyle(accent: palette.green))
            if selectedList != nil {
                Button("EDIT") { editingList = selectedList }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.blue))
            }
        }
        .padding(7)
    }

    private func listDetail(_ list: SavedQuizList) -> some View {
        let cards = store.cards(in: list)
        return VStack(spacing: 0) {
            HStack(spacing: 7) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(list.kind.label)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.faint)
                    Text("\(cards.count) TERMS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(palette.green)
                }
                Spacer()
                if list.kind == .manual {
                    Button("MEMBERS") { showingMembers = true }
                        .buttonStyle(CompactOutlineButtonStyle(accent: palette.blue))
                }
                Button("QUIZ") { startQuiz(list.id) }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.green, filled: true))
                    .disabled(cards.isEmpty)
            }
            .padding(7)
            CompactDivider(palette: palette)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(cards) { card in
                        Button { selectedCard = CardSheetSelection(id: card.id) } label: {
                            TermCompactRow(card: card, palette: palette)
                        }
                        .buttonStyle(BareRowButtonStyle())
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 9) {
            Spacer()
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 26))
                .foregroundStyle(palette.faint)
            Text("CREATE A SMART OR MANUAL QUIZ LIST")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(palette.secondary)
            Button("NEW LIST") { showingNewList = true }
                .buttonStyle(CompactOutlineButtonStyle(accent: palette.green, filled: true))
            Spacer()
        }
    }
}

struct SaveListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: StudyStore

    @State private var list: SavedQuizList
    private var isEditing: Bool

    private var palette: ThemePalette { ThemePalette(theme: store.settings.theme) }

    init(store: StudyStore, initialFilter: QuizFilter, initialKind: QuizListKind) {
        self.store = store
        _list = State(initialValue: SavedQuizList(name: "", kind: initialKind, filter: initialFilter))
        isEditing = false
    }

    init(store: StudyStore, editing: SavedQuizList) {
        self.store = store
        _list = State(initialValue: editing)
        isEditing = true
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "EDIT LIST" : "NEW LIST")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.green)
                Spacer()
                Button("CANCEL") { dismiss() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
            }
            .padding(9)
            CompactDivider(palette: palette)
            ScrollView {
                VStack(alignment: .leading, spacing: 9) {
                    SectionLabel("Name", palette: palette)
                    TextField("E.G. CORE SOFTWARE", text: $list.name)
                        .textFieldStyle(.plain)
                        .padding(7)
                        .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
                    SectionLabel("Type", palette: palette)
                    Picker("Type", selection: $list.kind) {
                        ForEach(QuizListKind.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if list.kind == .smart {
                        SectionLabel("Live filters", palette: palette)
                        FilterControls(filter: $list.filter, store: store)
                        Text("SMART LISTS UPDATE AUTOMATICALLY WHEN TERMS OR TAGS CHANGE.")
                            .font(.system(size: 7.5, design: .monospaced))
                            .foregroundStyle(palette.faint)
                    } else {
                        Text("SAVE THE LIST, THEN USE MEMBERS TO CHOOSE TERMS.")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(palette.secondary)
                    }
                }
                .padding(9)
            }
            CompactDivider(palette: palette)
            HStack {
                if isEditing {
                    Button("DELETE") { store.deleteList(id: list.id); dismiss() }
                        .buttonStyle(CompactOutlineButtonStyle(accent: palette.red))
                }
                Spacer()
                Button("SAVE") {
                    list.name = list.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.upsertList(list)
                    dismiss()
                }
                .buttonStyle(CompactOutlineButtonStyle(accent: palette.green, filled: true))
                .disabled(list.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(9)
        }
        .frame(minWidth: 360, minHeight: 360)
        .background(palette.background)
        .foregroundStyle(palette.primary)
    }
}

struct ManualListMembersView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: StudyStore
    let list: SavedQuizList
    @State private var search = ""

    private var palette: ThemePalette { ThemePalette(theme: store.settings.theme) }
    private var current: SavedQuizList? { store.lists.first { $0.id == list.id } }
    private var filteredCards: [TermCard] {
        guard !search.isEmpty else { return store.cards }
        return store.cards.filter {
            $0.content.term.range(of: search, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("MEMBERS · \(list.name.uppercased())")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.green)
                Spacer()
                Button("DONE") { dismiss() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.green))
            }
            .padding(8)
            CompactDivider(palette: palette)
            TextField("SEARCH TERMS…", text: $search)
                .textFieldStyle(.plain)
                .padding(7)
                .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
                .padding(7)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredCards) { card in
                        Button { store.toggle(cardID: card.id, inManualList: list.id) } label: {
                            HStack {
                                Image(systemName: current?.cardIDs.contains(card.id) == true ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(current?.cardIDs.contains(card.id) == true ? palette.green : palette.faint)
                                Text(card.content.term).lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .frame(minHeight: 27)
                            .overlay(alignment: .bottom) { Rectangle().fill(palette.border).frame(height: 1) }
                        }
                        .buttonStyle(BareRowButtonStyle())
                    }
                }
            }
        }
        .frame(minWidth: 380, minHeight: 430)
        .background(palette.background)
        .foregroundStyle(palette.primary)
    }
}
