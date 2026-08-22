import SwiftUI

struct TermEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: StudyStore
    let cardID: String

    @State private var draft = TermContent()
    @State private var newTag = ""
    @State private var loaded = false

    private var palette: ThemePalette { ThemePalette(theme: store.settings.theme) }
    private var card: TermCard? { store.card(id: cardID) }

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            CompactDivider(palette: palette)
            ScrollView {
                VStack(alignment: .leading, spacing: 9) {
                    textField("TERM", text: $draft.term, singleLine: true)
                    HStack(spacing: 6) {
                        VStack(alignment: .leading, spacing: 3) {
                            fieldLabel("PRIORITY")
                            Picker("Priority", selection: $draft.priority) {
                                Text("NONE").tag("")
                                ForEach(["Core", "Useful", "Advanced"], id: \.self) { Text($0.uppercased()).tag($0) }
                            }
                            .labelsHidden()
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            fieldLabel("STUDY STATE")
                            Picker("State", selection: $draft.status) {
                                ForEach(StudyState.allCases) { Text($0.label).tag($0) }
                            }
                            .labelsHidden()
                        }
                    }
                    tagsEditor
                    textField("DEFINITION", text: $draft.definition)
                    textField("WHY IT MATTERS", text: $draft.whyItMatters)
                    textField("EXAMPLE IN A SENTENCE", text: $draft.example)
                    resourcesEditor
                    textField("FREEFORM STUDY NOTES", text: $draft.studyNotes, minHeight: 110)
                    manualLists
                }
                .padding(9)
            }
            CompactDivider(palette: palette)
            HStack(spacing: 6) {
                if let url = URL(string: card?.notionURL ?? ""), !url.absoluteString.isEmpty {
                    Link("OPEN NOTION", destination: url)
                        .buttonStyle(CompactOutlineButtonStyle(accent: palette.blue))
                }
                Spacer()
                Button("CANCEL") { dismiss() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.faint))
                Button("SAVE + SYNC") { saveAndDismiss() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.green, filled: true))
            }
            .padding(9)
        }
        .frame(minWidth: 440, minHeight: 560)
        .background(palette.background)
        .foregroundStyle(palette.primary)
        .onAppear {
            guard !loaded, let card else { return }
            draft = card.content
            loaded = true
        }
    }

    private var editorHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("EDIT TERM")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(palette.green)
                Text("LOCAL EDITS AUTOSAVE AND PUSH TO NOTION")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(palette.faint)
            }
            Spacer()
            StateBadge(state: draft.status, palette: palette)
        }
        .padding(9)
    }

    private var tagsEditor: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("TAGS · NEW TAGS ARE CREATED IN NOTION")
            FlowLayout(spacing: 4) {
                ForEach(Array(Set(store.categoryOptions + draft.categories)).sorted(), id: \.self) { tag in
                    Button { toggleTag(tag) } label: {
                        TagChip(text: tag, selected: draft.categories.contains(tag), palette: palette)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 5) {
                TextField("NEW TAG", text: $newTag)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
                    .onSubmit(addTag)
                Button("ADD") { addTag() }
                    .buttonStyle(CompactOutlineButtonStyle(accent: palette.blue))
            }
        }
    }

    private var resourcesEditor: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                fieldLabel("RESOURCES · VIDEOS SUPPORT EXACT TIMESTAMPS")
                Spacer()
                Button("+ RESOURCE") {
                    draft.resources.append(ResourceLink(title: "", url: "", kind: .reference))
                }
                .buttonStyle(CompactOutlineButtonStyle(accent: palette.blue))
            }
            ForEach(Array(draft.resources.indices), id: \.self) { index in
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        TextField("TITLE", text: $draft.resources[index].title)
                            .textFieldStyle(.plain)
                        Picker("Kind", selection: $draft.resources[index].kind) {
                            ForEach(ResourceKind.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
                        }
                        .labelsHidden()
                        .frame(width: 92)
                        Button("×") { draft.resources.remove(at: index) }
                            .buttonStyle(CompactOutlineButtonStyle(accent: palette.red))
                    }
                    TextField("HTTPS://…", text: $draft.resources[index].url)
                        .textFieldStyle(.plain)
                    if draft.resources[index].kind == .video {
                        HStack {
                            Text("TIMESTAMP SEC").foregroundStyle(palette.faint)
                            TextField("0", value: $draft.resources[index].timestampSeconds, format: .number)
                                .textFieldStyle(.plain)
                        }
                    }
                }
                .padding(6)
                .background(palette.surface)
                .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
            }
        }
    }

    private var manualLists: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("MANUAL LIST MEMBERSHIP")
            let manual = store.lists.filter { $0.kind == .manual }
            if manual.isEmpty {
                Text("NO MANUAL LISTS YET")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(palette.faint)
            } else {
                FlowLayout(spacing: 4) {
                    ForEach(manual) { list in
                        Button { store.toggle(cardID: cardID, inManualList: list.id) } label: {
                            TagChip(
                                text: list.name,
                                selected: store.lists.first(where: { $0.id == list.id })?.cardIDs.contains(cardID) == true,
                                palette: palette
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func textField(
        _ label: String,
        text: Binding<String>,
        singleLine: Bool = false,
        minHeight: CGFloat = 72
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            fieldLabel(label)
            if singleLine {
                TextField(label, text: text)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
            } else {
                TextEditor(text: text)
                    .font(.system(size: 9, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(3)
                    .frame(minHeight: minHeight)
                    .background(palette.surface)
                    .overlay { Rectangle().stroke(palette.border, lineWidth: 1) }
            }
        }
    }

    private func fieldLabel(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
            .foregroundStyle(palette.faint)
    }

    private func toggleTag(_ tag: String) {
        if draft.categories.contains(tag) {
            draft.categories.removeAll { $0 == tag }
        } else {
            draft.categories.append(tag)
        }
    }

    private func addTag() {
        let value = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if !draft.categories.contains(value) { draft.categories.append(value) }
        newTag = ""
    }

    private func saveAndDismiss() {
        draft.categories = Array(Set(draft.categories)).sorted()
        draft.resources.removeAll {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || $0.url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        store.replaceContent(cardID: cardID, with: draft)
        dismiss()
    }
}
