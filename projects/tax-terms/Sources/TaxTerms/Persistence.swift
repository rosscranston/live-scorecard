import CryptoKit
import Foundation

protocol SnapshotPersisting {
    func load() throws -> StudySnapshot
    func save(_ snapshot: StudySnapshot) throws
}

enum PersistenceError: LocalizedError {
    case missingCombinedRepresentation

    var errorDescription: String? {
        "The encrypted study database could not be encoded."
    }
}

final class EncryptedSnapshotStore: SnapshotPersisting {
    static let encryptionKeyAccount = "study-database-key"

    let fileURL: URL
    private let keychain: KeychainStore
    private let fileManager: FileManager

    init(
        fileURL: URL = AppPaths.studyDatabaseURL(),
        keychain: KeychainStore = .shared,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.keychain = keychain
        self.fileManager = fileManager
    }

    func load() throws -> StudySnapshot {
        guard fileManager.fileExists(atPath: fileURL.path) else { return StudySnapshot() }
        let encrypted = try Data(contentsOf: fileURL)
        let sealed = try AES.GCM.SealedBox(combined: encrypted)
        let data = try AES.GCM.open(sealed, using: try encryptionKey())
        return try JSONDecoder.taxTerms.decode(StudySnapshot.self, from: data)
    }

    func save(_ snapshot: StudySnapshot) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder.taxTerms.encode(snapshot)
        let sealed = try AES.GCM.seal(data, using: try encryptionKey())
        guard let combined = sealed.combined else {
            throw PersistenceError.missingCombinedRepresentation
        }
        try combined.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    private func encryptionKey() throws -> SymmetricKey {
        if let existing = try keychain.read(account: Self.encryptionKeyAccount) {
            return SymmetricKey(data: existing)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        try keychain.write(data, account: Self.encryptionKeyAccount)
        return key
    }
}

enum AppPaths {
    static func applicationSupportDirectory(
        fileManager: FileManager = .default
    ) -> URL {
        let base = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base.appendingPathComponent("Tax Terms", isDirectory: true)
    }

    static func studyDatabaseURL(fileManager: FileManager = .default) -> URL {
        applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("study-data.enc", isDirectory: false)
    }

    static func exportURL(fileManager: FileManager = .default) -> URL {
        applicationSupportDirectory(fileManager: fileManager)
            .appendingPathComponent("Tax Terms Export.json", isDirectory: false)
    }
}

extension JSONEncoder {
    static var taxTerms: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var taxTerms: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
