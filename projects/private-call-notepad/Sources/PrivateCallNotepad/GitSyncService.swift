import Foundation

struct GitSyncResult: Equatable, Sendable {
    let committedChanges: Bool
    let detail: String
}

enum GitNotesSynchronizer {
    static func synchronize(repositoryURL: URL, at date: Date = Date()) throws -> GitSyncResult {
        guard FileManager.default.fileExists(
            atPath: repositoryURL.appendingPathComponent(".git", isDirectory: true).path
        ) else {
            throw GitSyncError("NOTES REPOSITORY IS NOT INITIALIZED")
        }

        try runGit(["add", "--", "notes"], in: repositoryURL)
        let diff = try runGit(
            ["diff", "--cached", "--quiet", "--", "notes"],
            in: repositoryURL,
            acceptedExitCodes: [0, 1]
        )

        let committedChanges = diff.exitCode == 1
        if committedChanges {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            try runGit(
                ["commit", "-m", "Sync notes \(formatter.string(from: date))"],
                in: repositoryURL
            )
        }

        try runGit(["push", "origin", "main"], in: repositoryURL)
        return GitSyncResult(
            committedChanges: committedChanges,
            detail: committedChanges ? "NOTES COMMITTED + PUSHED" : "REMOTE CURRENT / NO CHANGES"
        )
    }

    @discardableResult
    private static func runGit(
        _ arguments: [String],
        in repositoryURL: URL,
        acceptedExitCodes: Set<Int32> = [0]
    ) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = arguments
        process.currentDirectoryURL = repositoryURL

        var environment = ProcessInfo.processInfo.environment
        environment["LC_ALL"] = "C"
        process.environment = environment

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let error = String(
            data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let result = CommandResult(
            exitCode: process.terminationStatus,
            output: output,
            error: error
        )

        guard acceptedExitCodes.contains(result.exitCode) else {
            let detail = [result.error, result.output]
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw GitSyncError(detail.isEmpty ? "GIT COMMAND FAILED" : detail)
        }
        return result
    }

    private struct CommandResult {
        let exitCode: Int32
        let output: String
        let error: String
    }

    private struct GitSyncError: LocalizedError {
        let message: String

        init(_ message: String) {
            self.message = message
        }

        var errorDescription: String? { message }
    }
}

@MainActor
final class GitSyncService: ObservableObject {
    enum State: Equatable {
        case waiting
        case syncing
        case synced(String)
        case failed(String)

        var label: String {
            switch self {
            case .waiting: return "WAITING"
            case .syncing: return "SYNCING"
            case .synced: return "SYNCED"
            case .failed: return "SYNC FAILED"
            }
        }

        var detail: String? {
            switch self {
            case .synced(let detail), .failed(let detail): return detail
            case .waiting, .syncing: return nil
            }
        }
    }

    static let defaultInterval: TimeInterval = 30 * 60

    @Published private(set) var state: State = .waiting
    @Published private(set) var lastSyncAt: Date?
    @Published private(set) var nextSyncAt: Date?

    let repositoryURL: URL
    let interval: TimeInterval

    private var timer: Timer?
    private var isSyncing = false

    init(
        repositoryURL: URL,
        interval: TimeInterval = 30 * 60
    ) {
        self.repositoryURL = repositoryURL
        self.interval = interval
    }

    func start() {
        guard timer == nil else { return }
        scheduleNextSync()
    }

    func syncNow() {
        guard !isSyncing else { return }
        isSyncing = true
        state = .syncing

        let repositoryURL = repositoryURL
        Task {
            do {
                let result = try await Task.detached(priority: .utility) {
                    try GitNotesSynchronizer.synchronize(repositoryURL: repositoryURL)
                }.value
                lastSyncAt = Date()
                state = .synced(result.detail)
            } catch {
                state = .failed(Self.compact(error.localizedDescription))
            }
            isSyncing = false
            scheduleNextSync()
        }
    }

    private func scheduleNextSync() {
        timer?.invalidate()
        nextSyncAt = Date().addingTimeInterval(interval)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.syncNow()
            }
        }
    }

    private static func compact(_ value: String) -> String {
        let singleLine = value
            .split(whereSeparator: { $0.isNewline })
            .joined(separator: " ")
        return String(singleLine.prefix(240)).uppercased()
    }
}
