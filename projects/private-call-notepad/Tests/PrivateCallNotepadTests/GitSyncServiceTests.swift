import Foundation
import XCTest
@testable import PrivateCallNotepad

final class GitSyncServiceTests: XCTestCase {
    func testSynchronizerCommitsAndPushesOnlyNotesDirectory() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let repository = root.appendingPathComponent("working", isDirectory: true)
        let remote = root.appendingPathComponent("remote.git", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        try runGit(["init", "--bare", remote.path], in: root)
        try runGit(["init"], in: repository)
        try runGit(["config", "user.name", "Private Notepad Tests"], in: repository)
        try runGit(["config", "user.email", "private-notepad-tests@example.com"], in: repository)
        try runGit(["branch", "-M", "main"], in: repository)

        let readme = repository.appendingPathComponent("README.md")
        try "private notes".write(to: readme, atomically: true, encoding: .utf8)
        try runGit(["add", "--", "README.md"], in: repository)
        try runGit(["commit", "-m", "Initialize"], in: repository)
        try runGit(["remote", "add", "origin", remote.path], in: repository)
        try runGit(["push", "-u", "origin", "main"], in: repository)

        let notesDirectory = repository.appendingPathComponent("notes", isDirectory: true)
        try FileManager.default.createDirectory(at: notesDirectory, withIntermediateDirectories: true)
        try "# 2026-08-21\n\n[09:30:00] Test".write(
            to: notesDirectory.appendingPathComponent("2026-08-21.md"),
            atomically: true,
            encoding: .utf8
        )
        try "do not stage".write(
            to: repository.appendingPathComponent("unrelated.txt"),
            atomically: true,
            encoding: .utf8
        )

        let result = try GitNotesSynchronizer.synchronize(
            repositoryURL: repository,
            at: ISO8601DateFormatter().date(from: "2026-08-21T09:30:00Z")!
        )

        XCTAssertTrue(result.committedChanges)
        XCTAssertEqual(try gitOutput(["status", "--short"], in: repository), "?? unrelated.txt")
        XCTAssertTrue(
            try gitOutput(["log", "-1", "--pretty=%s"], in: repository)
                .hasPrefix("Sync notes 2026-08-21")
        )
    }

    private func runGit(_ arguments: [String], in directory: URL) throws {
        _ = try gitOutput(arguments, in: directory)
    }

    private func gitOutput(_ arguments: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = directory
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()

        let output = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let error = String(
            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "GitSyncServiceTests",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: error]
            )
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
