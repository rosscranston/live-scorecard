import Foundation
import XCTest
@testable import PrivateCallNotepad

@MainActor
final class NoteStoreTests: XCTestCase {
    func testFirstTypingBurstHidesTimestampAndContinuousTypingKeepsOriginalStoredTime() throws {
        let fixture = makeFixture()
        defer { fixture.cleanup() }

        fixture.store.updateFromEditor("Client", at: fixture.start)
        fixture.store.updateFromEditor(
            fixture.store.text + " concern",
            at: fixture.start.addingTimeInterval(4)
        )

        fixture.store.saveNow()

        XCTAssertEqual(fixture.store.text, "Client concern")
        XCTAssertEqual(
            try contents(of: fixture.store.documentURL),
            "# 2026-08-21\n\n[09:30:00] Client concern"
        )
    }

    func testTypingAfterMoreThanTenSecondsStartsNewHiddenTimestampedLine() throws {
        let fixture = makeFixture()
        defer { fixture.cleanup() }

        fixture.store.updateFromEditor("First note", at: fixture.start)
        fixture.store.updateFromEditor(
            fixture.store.text + "Second note",
            at: fixture.start.addingTimeInterval(11)
        )

        fixture.store.saveNow()

        XCTAssertEqual(fixture.store.text, "First note\nSecond note")
        XCTAssertEqual(
            try contents(of: fixture.store.documentURL),
            "# 2026-08-21\n\n[09:30:00] First note\n[09:30:11] Second note"
        )
    }

    func testEveryNewTypedLineReceivesHiddenStoredTimestamp() throws {
        let fixture = makeFixture()
        defer { fixture.cleanup() }

        fixture.store.updateFromEditor("First", at: fixture.start)
        fixture.store.updateFromEditor(
            fixture.store.text + "\n",
            at: fixture.start.addingTimeInterval(1)
        )
        fixture.store.updateFromEditor(
            fixture.store.text + "Second",
            at: fixture.start.addingTimeInterval(2)
        )

        fixture.store.saveNow()

        XCTAssertEqual(fixture.store.text, "First\nSecond")
        XCTAssertEqual(
            try contents(of: fixture.store.documentURL),
            "# 2026-08-21\n\n[09:30:00] First\n[09:30:02] Second"
        )
    }

    func testInsertedOrPastedLinesGetStoredTimestampsButStayPlainInEditor() throws {
        let fixture = makeFixture()
        defer { fixture.cleanup() }

        fixture.store.updateFromEditor("Existing", at: fixture.start)
        fixture.store.updateFromEditor(
            "Inserted\n" + fixture.store.text,
            at: fixture.start.addingTimeInterval(5)
        )

        fixture.store.saveNow()

        XCTAssertEqual(fixture.store.text, "Inserted\nExisting")
        XCTAssertEqual(
            try contents(of: fixture.store.documentURL),
            "# 2026-08-21\n\n[09:30:05] Inserted\n[09:30:00] Existing"
        )
    }

    func testDailyMarkdownDocumentRoundTrips() throws {
        let fixture = makeFixture()
        defer { fixture.cleanup() }

        fixture.store.updateFromEditor("Client concern", at: fixture.start)
        fixture.store.saveNow()

        let fileContents = try String(contentsOf: fixture.store.documentURL, encoding: .utf8)
        XCTAssertEqual(fileContents, "# 2026-08-21\n\n[09:30:00] Client concern")

        let reader = NoteStore(
            repositoryURL: fixture.repositoryURL,
            legacyDocumentURL: nil,
            calendar: fixture.calendar,
            nowProvider: { fixture.start }
        )
        XCTAssertEqual(reader.text, "Client concern")
        XCTAssertEqual(reader.saveState, .saved)

        reader.updateFromEditor("Client issue", at: fixture.start.addingTimeInterval(5))
        reader.saveNow()
        XCTAssertEqual(reader.text, "Client issue")
        XCTAssertEqual(
            try contents(of: reader.documentURL),
            "# 2026-08-21\n\n[09:30:00] Client issue"
        )
    }

    func testFirstEditAfterMidnightRotatesToNewDailyDocument() throws {
        let fixture = makeFixture()
        defer { fixture.cleanup() }

        fixture.store.updateFromEditor("Day one", at: fixture.start)
        let nextDay = date("2026-08-22T00:00:01Z")
        fixture.store.updateFromEditor(fixture.store.text + "Day two", at: nextDay)
        fixture.store.saveNow()

        let dayOne = fixture.repositoryURL.appendingPathComponent("notes/2026-08-21.md")
        let dayTwo = fixture.repositoryURL.appendingPathComponent("notes/2026-08-22.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dayOne.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dayTwo.path))
        XCTAssertEqual(fixture.store.text, "Day two")
        XCTAssertEqual(
            try contents(of: dayTwo),
            "# 2026-08-22\n\n[00:00:01] Day two"
        )
    }

    func testLegacyPlainTextIsMigratedWithoutDeletingSource() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let repository = directory.appendingPathComponent("repo", isDirectory: true)
        let legacy = directory.appendingPathComponent("Current Note.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "Old line\nAnother line".write(to: legacy, atomically: true, encoding: .utf8)
        let start = date("2026-08-21T09:30:00Z")
        try FileManager.default.setAttributes([.modificationDate: start], ofItemAtPath: legacy.path)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = NoteStore(
            repositoryURL: repository,
            legacyDocumentURL: legacy,
            calendar: utcCalendar,
            nowProvider: { start }
        )

        XCTAssertEqual(store.text, "Old line\nAnother line")
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacy.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.documentURL.path))
        XCTAssertEqual(
            try contents(of: store.documentURL),
            "# 2026-08-21\n\n[09:30:00] Old line\n[09:30:00] Another line"
        )
    }

    func testEmptyNoteHasZeroCounts() {
        let fixture = makeFixture()
        defer { fixture.cleanup() }

        XCTAssertEqual(fixture.store.lineCount, 0)
        XCTAssertEqual(fixture.store.wordCount, 0)
        XCTAssertEqual(fixture.store.characterCount, 0)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func makeFixture() -> Fixture {
        let repository = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let start = date("2026-08-21T09:30:00Z")
        let calendar = utcCalendar
        let store = NoteStore(
            repositoryURL: repository,
            legacyDocumentURL: nil,
            calendar: calendar,
            nowProvider: { start }
        )
        return Fixture(
            repositoryURL: repository,
            start: start,
            calendar: calendar,
            store: store
        )
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private func contents(of url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    private struct Fixture {
        let repositoryURL: URL
        let start: Date
        let calendar: Calendar
        let store: NoteStore

        func cleanup() {
            try? FileManager.default.removeItem(at: repositoryURL)
        }
    }
}
