import Foundation

struct TranscriptContextWindow: Sendable {
    let segments: [TranscriptSegment]
    let prompt: String
    let promptTokenCount: Int
    let promptTokenBudget: Int
    let usedExactTokenCount: Bool
}

enum TranscriptContextSelector {
    static func select(
        from segments: [TranscriptSegment],
        promptTokenBudget: Int,
        usedExactTokenCount: Bool,
        render: (TranscriptSegment) -> String,
        countTokens: (String) async throws -> Int
    ) async throws -> TranscriptContextWindow {
        guard !segments.isEmpty, promptTokenBudget > 0 else {
            return TranscriptContextWindow(
                segments: [],
                prompt: "",
                promptTokenCount: 0,
                promptTokenBudget: max(0, promptTokenBudget),
                usedExactTokenCount: usedExactTokenCount
            )
        }

        func prompt(for count: Int) -> String {
            segments.suffix(count).map(render).joined(separator: "\n")
        }

        var lower = 0
        var upper = segments.count
        var selectedPrompt = ""
        var selectedTokenCount = 0

        // Token count is monotonic as older transcript lines are prepended, so a
        // binary search finds the largest suffix with only O(log n) measurements.
        while lower < upper {
            let candidateCount = (lower + upper + 1) / 2
            let candidatePrompt = prompt(for: candidateCount)
            let candidateTokens = try await countTokens(candidatePrompt)
            if candidateTokens <= promptTokenBudget {
                lower = candidateCount
                selectedPrompt = candidatePrompt
                selectedTokenCount = candidateTokens
            } else {
                upper = candidateCount - 1
            }
        }

        if lower > 0, selectedPrompt.isEmpty {
            selectedPrompt = prompt(for: lower)
            selectedTokenCount = try await countTokens(selectedPrompt)
        }

        return TranscriptContextWindow(
            segments: Array(segments.suffix(lower)),
            prompt: selectedPrompt,
            promptTokenCount: selectedTokenCount,
            promptTokenBudget: promptTokenBudget,
            usedExactTokenCount: usedExactTokenCount
        )
    }
}
