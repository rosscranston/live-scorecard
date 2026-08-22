import Foundation

struct CirclebackWebhookPayload: Decodable, Sendable {
    struct TranscriptItem: Decodable, Sendable {
        let speaker: String
        let text: String
        let timestamp: Double
    }

    let id: String
    let name: String
    let createdAt: String?
    let transcript: [TranscriptItem]
}

enum CirclebackImportError: Error, LocalizedError {
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .emptyTranscript: return "The Circleback export did not contain transcript segments"
        }
    }
}

struct CirclebackImporter: Sendable {
    func decode(data: Data, meetingID: UUID) throws -> [TranscriptSegment] {
        let payload = try JSONDecoder().decode(CirclebackWebhookPayload.self, from: data)
        guard !payload.transcript.isEmpty else { throw CirclebackImportError.emptyTranscript }

        return payload.transcript
            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { $0.timestamp < $1.timestamp }
            .map { item in
                TranscriptSegment(
                    id: UUID(),
                    meetingID: meetingID,
                    speaker: item.speaker,
                    source: .circleback,
                    text: item.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    timestampSeconds: item.timestamp,
                    isFinal: true,
                    createdAt: Date()
                )
            }
    }
}
