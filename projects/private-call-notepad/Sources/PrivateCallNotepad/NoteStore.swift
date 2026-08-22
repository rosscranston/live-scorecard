import Foundation

enum NotesRepositoryPaths {
    static func defaultRepositoryURL(bundle: Bundle = .main) -> URL {
        if let configured = bundle.object(forInfoDictionaryKey: "PrivateNotesRepositoryPath") as? String,
           !configured.isEmpty {
            return URL(fileURLWithPath: configured, isDirectory: true)
        }

        return URL(
            fileURLWithPath: "/Users/rossegates/Documents/ChatGPT/ai-os-cranston/private-notes",
            isDirectory: true
        )
    }

    static func defaultLegacyDocumentURL(fileManager: FileManager = .default) -> URL {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return applicationSupport
            .appendingPathComponent("Cranston Private Notepad", isDirectory: true)
            .appendingPathComponent("Current Note.txt", isDirectory: false)
    }
}

enum TimestampedNoteEditing {
    static let inactivityThreshold: TimeInterval = 10

    struct Line: Equatable {
        var timestamp: String?
        var content: String
    }

    static func parsingStoredText(_ text: String, fallbackTimestamp: String) -> [Line] {
        plainLines(in: text).map { line in
            guard let prefix = timestampPrefix(in: line) else {
                return Line(
                    timestamp: line.isEmpty ? nil : fallbackTimestamp,
                    content: line
                )
            }

            return Line(
                timestamp: String(prefix.dropFirst().dropLast(2)),
                content: String(line.dropFirst(prefix.count))
            )
        }
    }

    static func displayedText(from lines: [Line]) -> String {
        lines.map(\.content).joined(separator: "\n")
    }

    static func storedText(from lines: [Line], fallbackTimestamp: String) -> String {
        lines.map { line in
            guard !line.content.isEmpty else { return "" }
            return "[\(line.timestamp ?? fallbackTimestamp)] \(line.content)"
        }
        .joined(separator: "\n")
    }

    static func reconciling(
        previous: [Line],
        with displayedText: String,
        timestamp: String
    ) -> [Line] {
        let newContents = plainLines(in: displayedText)
        guard !newContents.isEmpty else { return [] }

        let oldContents = previous.map(\.content)
        var prefixCount = 0
        while prefixCount < oldContents.count,
              prefixCount < newContents.count,
              oldContents[prefixCount] == newContents[prefixCount] {
            prefixCount += 1
        }

        var suffixCount = 0
        while suffixCount < oldContents.count - prefixCount,
              suffixCount < newContents.count - prefixCount,
              oldContents[oldContents.count - suffixCount - 1]
                == newContents[newContents.count - suffixCount - 1] {
            suffixCount += 1
        }

        let oldMiddleEnd = oldContents.count - suffixCount
        let newMiddleEnd = newContents.count - suffixCount
        let oldMiddle = Array(previous[prefixCount..<oldMiddleEnd])
        let newMiddle = Array(newContents[prefixCount..<newMiddleEnd])

        var result = Array(previous.prefix(prefixCount))
        for (index, content) in newMiddle.enumerated() {
            let prior = index < oldMiddle.count ? oldMiddle[index] : nil
            let lineTimestamp: String?
            if content.isEmpty {
                lineTimestamp = nil
            } else if let prior, !prior.content.isEmpty {
                lineTimestamp = prior.timestamp ?? timestamp
            } else {
                lineTimestamp = timestamp
            }
            result.append(Line(timestamp: lineTimestamp, content: content))
        }

        if suffixCount > 0 {
            result.append(contentsOf: previous.suffix(suffixCount))
        }
        return result
    }

    private static func plainLines(in text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        return text.components(separatedBy: "\n")
    }

    private static func timestampPrefix(in line: String) -> Substring? {
        let prefix = Array(line.prefix(11))
        guard prefix.count == 11,
              prefix[0] == "["
            && prefix[1].isNumber
            && prefix[2].isNumber
            && prefix[3] == ":"
            && prefix[4].isNumber
            && prefix[5].isNumber
            && prefix[6] == ":"
            && prefix[7].isNumber
            && prefix[8].isNumber
            && prefix[9] == "]"
            && prefix[10] == " " else { return nil }
        return line.prefix(11)
    }
}

@MainActor
final class NoteStore: ObservableObject {
    enum SaveState: Equatable {
        case saved
        case saving
        case failed(String)

        var label: String {
            switch self {
            case .saved: return "AUTOSAVED"
            case .saving: return "UNSAVED"
            case .failed: return "SAVE FAILED"
            }
        }
    }

    @Published private(set) var text = ""
    @Published private(set) var saveState: SaveState = .saved
    @Published private(set) var documentURL: URL

    let repositoryURL: URL
    let notesDirectoryURL: URL

    private let fileManager: FileManager
    private let calendar: Calendar
    private let nowProvider: () -> Date
    private let legacyDocumentURL: URL?
    private var currentDayKey: String
    private var lastTypingActivityAt: Date?
    private var pendingSave: DispatchWorkItem?
    private var lines: [TimestampedNoteEditing.Line] = []

    init(
        repositoryURL: URL = NotesRepositoryPaths.defaultRepositoryURL(),
        legacyDocumentURL: URL? = NotesRepositoryPaths.defaultLegacyDocumentURL(),
        fileManager: FileManager = .default,
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.repositoryURL = repositoryURL
        notesDirectoryURL = repositoryURL.appendingPathComponent("notes", isDirectory: true)
        self.legacyDocumentURL = legacyDocumentURL
        self.fileManager = fileManager
        self.calendar = calendar
        self.nowProvider = nowProvider

        let now = nowProvider()
        currentDayKey = Self.dayKey(for: now, calendar: calendar)
        documentURL = notesDirectoryURL.appendingPathComponent("\(currentDayKey).md")
        loadCurrentDay(migratingLegacyIfNeeded: true)
    }

    var wordCount: Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
    }

    var characterCount: Int {
        text.count
    }

    var lineCount: Int {
        text.split(separator: "\n", omittingEmptySubsequences: true).count
    }

    var dayLabel: String {
        currentDayKey
    }

    func updateFromEditor(_ candidate: String, at suppliedDate: Date? = nil) {
        let now = suppliedDate ?? nowProvider()
        let priorText = text
        let appendedText = candidate.hasPrefix(priorText)
            ? String(candidate.dropFirst(priorText.count))
            : nil

        rotateDayIfNeeded(at: now)

        let timestamp = Self.timeKey(for: now, calendar: calendar)
        let startsNewSession = lastTypingActivityAt.map {
            now.timeIntervalSince($0) > TimestampedNoteEditing.inactivityThreshold
        } ?? true

        var updatedDisplay = candidate
        if let appendedText {
            updatedDisplay = text
            if startsNewSession,
               !updatedDisplay.isEmpty,
               !updatedDisplay.hasSuffix("\n"),
               !appendedText.isEmpty,
               appendedText.first != "\n" {
                updatedDisplay.append("\n")
            }
            updatedDisplay.append(appendedText)
        }

        lines = TimestampedNoteEditing.reconciling(
            previous: lines,
            with: updatedDisplay,
            timestamp: timestamp
        )
        text = TimestampedNoteEditing.displayedText(from: lines)
        lastTypingActivityAt = now
        scheduleSave()
    }

    func saveNow() {
        pendingSave?.cancel()
        pendingSave = nil
        saveState = .saving

        do {
            try fileManager.createDirectory(
                at: notesDirectoryURL,
                withIntermediateDirectories: true
            )
            let fallbackTimestamp = Self.timeKey(for: nowProvider(), calendar: calendar)
            let timestampedBody = TimestampedNoteEditing.storedText(
                from: lines,
                fallbackTimestamp: fallbackTimestamp
            )
            let contents = "# \(currentDayKey)\n\n\(timestampedBody)"
            try contents.write(to: documentURL, atomically: true, encoding: .utf8)
            saveState = .saved
        } catch {
            saveState = .failed(error.localizedDescription)
        }
    }

    private func rotateDayIfNeeded(at date: Date) {
        let newDayKey = Self.dayKey(for: date, calendar: calendar)
        guard newDayKey != currentDayKey else { return }

        saveNow()
        currentDayKey = newDayKey
        documentURL = notesDirectoryURL.appendingPathComponent("\(newDayKey).md")
        lastTypingActivityAt = nil
        loadCurrentDay(migratingLegacyIfNeeded: false)
    }

    private func loadCurrentDay(migratingLegacyIfNeeded: Bool) {
        if fileManager.fileExists(atPath: documentURL.path) {
            do {
                let contents = try String(contentsOf: documentURL, encoding: .utf8)
                let body = Self.body(from: contents, dayKey: currentDayKey)
                let attributes = try? fileManager.attributesOfItem(atPath: documentURL.path)
                let fallbackDate = attributes?[.modificationDate] as? Date ?? nowProvider()
                let fallbackTimestamp = Self.timeKey(for: fallbackDate, calendar: calendar)
                lines = TimestampedNoteEditing.parsingStoredText(
                    body,
                    fallbackTimestamp: fallbackTimestamp
                )
                text = TimestampedNoteEditing.displayedText(from: lines)
                saveState = .saved
                if TimestampedNoteEditing.storedText(
                    from: lines,
                    fallbackTimestamp: fallbackTimestamp
                ) != body {
                    saveNow()
                }
                return
            } catch {
                lines = []
                text = ""
                saveState = .failed(error.localizedDescription)
                return
            }
        }

        guard migratingLegacyIfNeeded,
              let legacyDocumentURL,
              fileManager.fileExists(atPath: legacyDocumentURL.path),
              let legacyText = try? String(contentsOf: legacyDocumentURL, encoding: .utf8),
              !legacyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            lines = []
            text = ""
            saveState = .saved
            return
        }

        let attributes = try? fileManager.attributesOfItem(atPath: legacyDocumentURL.path)
        let migrationDate = attributes?[.modificationDate] as? Date ?? nowProvider()
        lines = TimestampedNoteEditing.parsingStoredText(
            legacyText,
            fallbackTimestamp: Self.timeKey(for: migrationDate, calendar: calendar)
        )
        text = TimestampedNoteEditing.displayedText(from: lines)
        saveNow()
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        saveState = .saving

        let workItem = DispatchWorkItem { [weak self] in
            self?.saveNow()
        }
        pendingSave = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private static func body(from fileContents: String, dayKey: String) -> String {
        let header = "# \(dayKey)\n\n"
        guard fileContents.hasPrefix(header) else { return fileContents }
        return String(fileContents.dropFirst(header.count))
    }

    private static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    private static func timeKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        return String(
            format: "%02d:%02d:%02d",
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0
        )
    }
}
