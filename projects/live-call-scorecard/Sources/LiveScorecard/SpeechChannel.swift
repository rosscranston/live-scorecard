@preconcurrency import AVFoundation
import CoreMedia
import Foundation
import Speech

struct LiveTranscriptEvent: Sendable {
    let source: SpeakerSource
    let text: String
    let timestampSeconds: Double
    let isFinal: Bool
}

actor SpeechChannel {
    typealias EventHandler = @Sendable (LiveTranscriptEvent) -> Void
    typealias ErrorHandler = @Sendable (String) -> Void

    private let source: SpeakerSource
    private let onEvent: EventHandler
    private let onError: ErrorHandler

    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var analyzerTask: Task<Void, Never>?
    private var resultsTask: Task<Void, Never>?
    private var targetFormat: AVAudioFormat?
    private var started = false

    init(source: SpeakerSource, onEvent: @escaping EventHandler, onError: @escaping ErrorHandler) {
        self.source = source
        self.onEvent = onEvent
        self.onError = onError
    }

    func consume(_ buffer: AVAudioPCMBuffer) async {
        do {
            if !started {
                try await start(naturalFormat: buffer.format)
            }
            guard let targetFormat,
                  let converted = try convert(buffer, to: targetFormat)
            else { return }
            inputContinuation?.yield(AnalyzerInput(buffer: converted))
        } catch {
            onError("\(source.label) transcription failed: \(error.localizedDescription)")
        }
    }

    func stop() async {
        inputContinuation?.finish()
        if let analyzer {
            try? await analyzer.finalizeAndFinishThroughEndOfInput()
        }
        analyzerTask?.cancel()
        resultsTask?.cancel()
        analyzerTask = nil
        resultsTask = nil
        inputContinuation = nil
        analyzer = nil
        transcriber = nil
        targetFormat = nil
        started = false
    }

    private func start(naturalFormat: AVAudioFormat) async throws {
        guard SpeechTranscriber.isAvailable else {
            throw NSError(
                domain: "LiveScorecard.Speech",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Live SpeechTranscriber is unavailable on this Mac"]
            )
        }
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) else {
            throw NSError(
                domain: "LiveScorecard.Speech",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "English speech transcription is unavailable"]
            )
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            preset: .timeIndexedProgressiveTranscription
        )
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }

        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber],
            considering: naturalFormat
        ) else {
            throw NSError(
                domain: "LiveScorecard.Speech",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No compatible speech audio format was found"]
            )
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        try await analyzer.prepareToAnalyze(in: format)
        let (stream, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)

        self.transcriber = transcriber
        self.analyzer = analyzer
        self.inputContinuation = continuation
        self.targetFormat = format
        self.started = true

        resultsTask = Task { [source, onEvent, onError] in
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { continue }
                    onEvent(LiveTranscriptEvent(
                        source: source,
                        text: text,
                        timestampSeconds: result.range.start.seconds,
                        isFinal: result.isFinal
                    ))
                }
            } catch is CancellationError {
                return
            } catch {
                onError("\(source.label) transcription results failed: \(error.localizedDescription)")
            }
        }

        analyzerTask = Task { [onError] in
            do {
                try await analyzer.start(inputSequence: stream)
            } catch is CancellationError {
                return
            } catch {
                onError("Speech analyzer stopped: \(error.localizedDescription)")
            }
        }
    }

    private func convert(_ input: AVAudioPCMBuffer, to outputFormat: AVAudioFormat) throws -> AVAudioPCMBuffer? {
        if input.format == outputFormat {
            return input
        }

        guard let converter = AVAudioConverter(from: input.format, to: outputFormat) else {
            return nil
        }
        let ratio = outputFormat.sampleRate / input.format.sampleRate
        let capacity = AVAudioFrameCount((Double(input.frameLength) * ratio).rounded(.up) + 16)
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
            return nil
        }

        var supplied = false
        var conversionError: NSError?
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            if supplied {
                inputStatus.pointee = .noDataNow
                return nil
            }
            supplied = true
            inputStatus.pointee = .haveData
            return input
        }
        if let conversionError { throw conversionError }
        guard status == .haveData || status == .inputRanDry, output.frameLength > 0 else {
            return nil
        }
        return output
    }
}
