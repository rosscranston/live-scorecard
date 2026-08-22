import AVFoundation
import CoreMedia
import Foundation
import OSLog
import ScreenCaptureKit

enum AudioCaptureError: Error, LocalizedError {
    case noDisplay
    case noChrome
    case invalidAudioBuffer

    var errorDescription: String? {
        switch self {
        case .noDisplay: return "No Mac display was available for audio capture"
        case .noChrome: return "Google Chrome is not running"
        case .invalidAudioBuffer: return "macOS returned an invalid audio buffer"
        }
    }
}

final class AudioCaptureService: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    typealias EventHandler = @Sendable (LiveTranscriptEvent) -> Void
    typealias ErrorHandler = @Sendable (String) -> Void
    typealias MicrophoneLevelHandler = @Sendable (Double) -> Void
    typealias DiagnosticsHandler = @Sendable (AudioCaptureDiagnostic) -> Void

    private let onEvent: EventHandler
    private let onError: ErrorHandler
    private let onMicrophoneLevel: MicrophoneLevelHandler
    private let onDiagnostic: DiagnosticsHandler?
    private let logger = Logger(subsystem: "ai.cranston.live-scorecard", category: "AudioCapture")
    private let systemQueue = DispatchQueue(label: "ai.cranston.scorecard.system-audio", qos: .userInitiated)
    private let microphoneQueue = DispatchQueue(label: "ai.cranston.scorecard.microphone", qos: .userInitiated)

    private var stream: SCStream?
    private var configuration: SCStreamConfiguration?
    private var meetingChannel: SpeechChannel?
    private var microphoneChannel: SpeechChannel?
    private var lastMicrophoneLevelUpdate = Date.distantPast.timeIntervalSinceReferenceDate
    private var microphoneMonitor = MicrophoneSignalMonitor()
    private var selectedMicrophoneDeviceID: String?
    private var microphoneCaptureGeneration = 0
    private var reportedMicrophoneDecodeFailure = false

    init(
        onEvent: @escaping EventHandler,
        onError: @escaping ErrorHandler,
        onMicrophoneLevel: @escaping MicrophoneLevelHandler,
        onDiagnostic: DiagnosticsHandler? = nil
    ) {
        self.onEvent = onEvent
        self.onError = onError
        self.onMicrophoneLevel = onMicrophoneLevel
        self.onDiagnostic = onDiagnostic
        super.init()
    }

    func start(microphoneDeviceID: String?) async throws {
        guard stream == nil else { return }

        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        guard let display = content.displays.first else { throw AudioCaptureError.noDisplay }

        let chromeApps = content.applications.filter { application in
            application.bundleIdentifier == "com.google.Chrome"
        }
        let filter: SCContentFilter
        if chromeApps.isEmpty {
            let ownApps = content.applications.filter { application in
                application.bundleIdentifier == Bundle.main.bundleIdentifier
            }
            filter = SCContentFilter(
                display: display,
                excludingApplications: ownApps,
                exceptingWindows: []
            )
        } else {
            filter = SCContentFilter(
                display: display,
                including: chromeApps,
                exceptingWindows: []
            )
        }

        let microphoneFormat = Self.captureFormat(for: microphoneDeviceID)
        let configuration = SCStreamConfiguration()
        configuration.width = 2
        configuration.height = 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        configuration.queueDepth = 2
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        // External USB interfaces commonly reject the 16 kHz mono format that is ideal for
        // speech recognition. Capture in the device's active hardware format and let
        // SpeechChannel resample the owned, canonical mono buffers downstream.
        configuration.sampleRate = microphoneFormat.sampleRate
        configuration.channelCount = microphoneFormat.channelCount
        configuration.captureMicrophone = true
        configuration.microphoneCaptureDeviceID = microphoneDeviceID

        let meetingChannel = SpeechChannel(
            source: .meetingAudio,
            onEvent: onEvent,
            onError: onError
        )
        let microphoneChannel = SpeechChannel(
            source: .microphone,
            onEvent: onEvent,
            onError: onError
        )
        self.meetingChannel = meetingChannel
        self.microphoneChannel = microphoneChannel

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: systemQueue)
        try stream.addStreamOutput(self, type: .microphone, sampleHandlerQueue: microphoneQueue)
        self.stream = stream
        self.configuration = configuration
        selectedMicrophoneDeviceID = microphoneDeviceID
        resetMicrophoneDiagnostics()
        let configuredFormat = "\(microphoneFormat.sampleRate) Hz / \(microphoneFormat.channelCount) ch"
        emitDiagnostic(.captureConfigured(deviceID: microphoneDeviceID, format: configuredFormat))
        try await stream.startCapture()
        scheduleNoMicrophoneBufferCheck()
    }

    func updateMicrophoneDevice(id: String?) async throws {
        guard let stream, let configuration else { return }
        let microphoneFormat = Self.captureFormat(for: id)
        configuration.microphoneCaptureDeviceID = id
        configuration.sampleRate = microphoneFormat.sampleRate
        configuration.channelCount = microphoneFormat.channelCount
        selectedMicrophoneDeviceID = id
        try await stream.updateConfiguration(configuration)
        // Buffers can arrive while ScreenCaptureKit is applying a live device change.
        // Reset only after the update finishes so the next buffer reports the newly
        // selected device's actual decoded format instead of leaving CONFIGURED as
        // the last visible diagnostic.
        resetMicrophoneDiagnostics()
        let configuredFormat = "\(microphoneFormat.sampleRate) Hz / \(microphoneFormat.channelCount) ch"
        emitDiagnostic(.captureConfigured(deviceID: id, format: configuredFormat))
        scheduleNoMicrophoneBufferCheck()
    }

    func stop() async {
        if let stream {
            try? await stream.stopCapture()
        }
        await meetingChannel?.stop()
        await microphoneChannel?.stop()
        stream = nil
        configuration = nil
        meetingChannel = nil
        microphoneChannel = nil
        lastMicrophoneLevelUpdate = Date.distantPast.timeIntervalSinceReferenceDate
        selectedMicrophoneDeviceID = nil
        resetMicrophoneDiagnostics()
        onMicrophoneLevel(0)
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        onError("Audio capture stopped: \(error.localizedDescription)")
    }

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {
        guard sampleBuffer.isValid else {
            if outputType == .microphone {
                emitDiagnostic(.invalidMicrophoneBuffer(reason: "ScreenCaptureKit marked the sample buffer invalid"))
            }
            return
        }

        if outputType == .microphone {
            microphoneMonitor.recordRawBuffer()
        }

        let buffer: AVAudioPCMBuffer
        do {
            buffer = try AudioBufferCanonicalizer.makeCanonicalMonoBuffer(from: sampleBuffer)
        } catch {
            if outputType == .microphone, !reportedMicrophoneDecodeFailure {
                reportedMicrophoneDecodeFailure = true
                emitDiagnostic(.invalidMicrophoneBuffer(reason: error.localizedDescription))
            }
            return
        }

        switch outputType {
        case .audio:
            guard let meetingChannel else { return }
            Task { await meetingChannel.consume(buffer) }
        case .microphone:
            guard let microphoneChannel else { return }
            publishMicrophoneTelemetry(from: buffer)
            Task { await microphoneChannel.consume(buffer) }
        case .screen:
            break
        @unknown default:
            break
        }
    }

    private func publishMicrophoneTelemetry(from buffer: AVAudioPCMBuffer) {
        let now = Date.timeIntervalSinceReferenceDate
        let rms = AudioLevelMeter.rms(from: buffer)
        if let diagnostic = microphoneMonitor.recordDecodedBuffer(
            rms: rms,
            format: AudioBufferCanonicalizer.formatSummary(buffer.format),
            at: now
        ) {
            emitDiagnostic(diagnostic)
        }

        guard now - lastMicrophoneLevelUpdate >= 0.05 else { return }
        lastMicrophoneLevelUpdate = now
        onMicrophoneLevel(AudioLevelMeter.normalizedLevel(rms: rms))
    }

    private static func captureFormat(for deviceID: String?) -> CaptureDeviceFormat {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone],
            mediaType: .audio,
            position: .unspecified
        )
        let device: AVCaptureDevice?
        if let deviceID {
            device = discovery.devices.first { $0.uniqueID == deviceID }
        } else {
            device = AVCaptureDevice.default(for: .audio)
        }

        guard let description = device?.activeFormat.formatDescription,
              let streamDescription = description.audioStreamBasicDescription,
              streamDescription.mSampleRate > 0,
              streamDescription.mChannelsPerFrame > 0 else {
            // Core Audio's standard macOS hardware rate is a safer capture request than
            // the previous speech-optimized 16 kHz mono request for an unknown USB device.
            return CaptureDeviceFormat(sampleRate: 48_000, channelCount: 2)
        }
        return CaptureDeviceFormat(
            sampleRate: Int(streamDescription.mSampleRate.rounded()),
            channelCount: Int(streamDescription.mChannelsPerFrame)
        )
    }

    private func resetMicrophoneDiagnostics() {
        microphoneCaptureGeneration += 1
        microphoneMonitor = MicrophoneSignalMonitor()
        reportedMicrophoneDecodeFailure = false
    }

    private func scheduleNoMicrophoneBufferCheck() {
        let generation = microphoneCaptureGeneration
        microphoneQueue.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self,
                  self.stream != nil,
                  self.microphoneCaptureGeneration == generation,
                  self.microphoneMonitor.rawBufferCount == 0 else { return }
            self.emitDiagnostic(.noMicrophoneBuffers(deviceID: self.selectedMicrophoneDeviceID))
        }
    }

    private func emitDiagnostic(_ diagnostic: AudioCaptureDiagnostic) {
        switch diagnostic.severity {
        case .info:
            logger.info("\(diagnostic.description, privacy: .public)")
        case .warning:
            logger.warning("\(diagnostic.description, privacy: .public)")
        }
        onDiagnostic?(diagnostic)
    }
}

private struct CaptureDeviceFormat {
    let sampleRate: Int
    let channelCount: Int
}

enum AudioCaptureDiagnostic: Equatable, Sendable, CustomStringConvertible {
    enum Severity: Sendable {
        case info
        case warning
    }

    case captureConfigured(deviceID: String?, format: String)
    case microphoneFormatDetected(String)
    case noMicrophoneBuffers(deviceID: String?)
    case invalidMicrophoneBuffer(reason: String)
    case silentMicrophone(format: String)
    case microphoneSignalRestored

    var severity: Severity {
        switch self {
        case .captureConfigured, .microphoneFormatDetected, .microphoneSignalRestored:
            return .info
        case .noMicrophoneBuffers, .invalidMicrophoneBuffer, .silentMicrophone:
            return .warning
        }
    }

    var description: String {
        switch self {
        case let .captureConfigured(deviceID, format):
            return "Microphone capture configured: device=\(deviceID ?? "system default"), requested=\(format)"
        case let .microphoneFormatDetected(format):
            return "Microphone buffers detected: \(format)"
        case let .noMicrophoneBuffers(deviceID):
            return "No microphone buffers arrived within 3 seconds for device \(deviceID ?? "system default")"
        case let .invalidMicrophoneBuffer(reason):
            return "Microphone buffers arrived but could not be converted: \(reason)"
        case let .silentMicrophone(format):
            return "Microphone buffers are arriving but the selected input channel is silent: \(format)"
        case .microphoneSignalRestored:
            return "Microphone signal restored"
        }
    }
}

struct MicrophoneSignalMonitor {
    private(set) var rawBufferCount = 0
    private(set) var decodedBufferCount = 0
    private var firstSilentBufferTime: TimeInterval?
    private var reportedFormat = false
    private var reportedSilence = false

    mutating func recordRawBuffer() {
        rawBufferCount += 1
    }

    mutating func recordDecodedBuffer(
        rms: Double,
        format: String,
        at timestamp: TimeInterval
    ) -> AudioCaptureDiagnostic? {
        decodedBufferCount += 1

        if !reportedFormat {
            reportedFormat = true
            return .microphoneFormatDetected(format)
        }

        // -72 dBFS separates a genuinely silent USB route from ordinary room noise.
        let isSilent = !rms.isFinite || rms < 0.000_25
        if isSilent {
            if firstSilentBufferTime == nil {
                firstSilentBufferTime = timestamp
            }
            if !reportedSilence,
               let firstSilentBufferTime,
               timestamp - firstSilentBufferTime >= 3 {
                reportedSilence = true
                return .silentMicrophone(format: format)
            }
            return nil
        }

        firstSilentBufferTime = nil
        if reportedSilence {
            reportedSilence = false
            return .microphoneSignalRestored
        }
        return nil
    }
}

enum AudioBufferConversionError: Error, LocalizedError {
    case missingFormatDescription
    case unsupportedFormat(String)
    case emptyBuffer
    case conversionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingFormatDescription:
            return "the sample has no Core Audio format description"
        case let .unsupportedFormat(format):
            return "unsupported PCM format (\(format))"
        case .emptyBuffer:
            return "the sample contains no audio frames"
        case let .conversionFailed(reason):
            return "PCM conversion failed (\(reason))"
        }
    }
}

enum AudioBufferCanonicalizer {
    static func makeCanonicalMonoBuffer(from sampleBuffer: CMSampleBuffer) throws -> AVAudioPCMBuffer {
        guard let formatDescription = sampleBuffer.formatDescription else {
            throw AudioBufferConversionError.missingFormatDescription
        }
        let sourceFormat = AVAudioFormat(cmAudioFormatDescription: formatDescription)

        var result: AVAudioPCMBuffer?
        try sampleBuffer.withAudioBufferList { audioBufferList, _ in
            guard let borrowed = AVAudioPCMBuffer(
                pcmFormat: sourceFormat,
                bufferListNoCopy: audioBufferList.unsafePointer
            ) else {
                throw AudioBufferConversionError.unsupportedFormat(formatSummary(sourceFormat))
            }
            result = try makeCanonicalMonoBuffer(from: borrowed)
        }
        guard let result else { throw AudioBufferConversionError.emptyBuffer }
        return result
    }

    static func makeCanonicalMonoBuffer(from input: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        guard input.frameLength > 0 else { throw AudioBufferConversionError.emptyBuffer }
        guard let floatFormat = AVAudioFormat(
            standardFormatWithSampleRate: input.format.sampleRate,
            channels: input.format.channelCount
        ) else {
            throw AudioBufferConversionError.unsupportedFormat(formatSummary(input.format))
        }

        let floatBuffer = try convertedCopy(input, to: floatFormat)
        guard let channels = floatBuffer.floatChannelData,
              let monoFormat = AVAudioFormat(
                standardFormatWithSampleRate: floatBuffer.format.sampleRate,
                channels: 1
              ),
              let monoBuffer = AVAudioPCMBuffer(
                pcmFormat: monoFormat,
                frameCapacity: floatBuffer.frameLength
              ),
              let monoSamples = monoBuffer.floatChannelData?[0]
        else { throw AudioBufferConversionError.unsupportedFormat(formatSummary(floatBuffer.format)) }

        let frameCount = Int(floatBuffer.frameLength)
        let channelCount = Int(floatBuffer.format.channelCount)
        var loudestChannel = 0
        var loudestEnergy = -Double.infinity
        for channel in 0..<channelCount {
            var energy = 0.0
            for frame in 0..<frameCount {
                let sample = Double(channels[channel][frame])
                energy += sample * sample
            }
            if energy > loudestEnergy {
                loudestEnergy = energy
                loudestChannel = channel
            }
        }

        monoBuffer.frameLength = floatBuffer.frameLength
        memcpy(
            monoSamples,
            channels[loudestChannel],
            frameCount * MemoryLayout<Float>.size
        )
        return monoBuffer
    }

    static func formatSummary(_ format: AVAudioFormat) -> String {
        let commonFormat: String
        switch format.commonFormat {
        case .pcmFormatFloat32: commonFormat = "float32"
        case .pcmFormatFloat64: commonFormat = "float64"
        case .pcmFormatInt16: commonFormat = "int16"
        case .pcmFormatInt32: commonFormat = "int32"
        case .otherFormat: commonFormat = "other"
        @unknown default: commonFormat = "unknown"
        }
        return "\(Int(format.sampleRate)) Hz / \(format.channelCount) ch / \(commonFormat) / \(format.isInterleaved ? "interleaved" : "planar")"
    }

    private static func convertedCopy(
        _ input: AVAudioPCMBuffer,
        to outputFormat: AVAudioFormat
    ) throws -> AVAudioPCMBuffer {
        guard let converter = AVAudioConverter(from: input.format, to: outputFormat) else {
            throw AudioBufferConversionError.conversionFailed(
                "no converter from \(formatSummary(input.format)) to \(formatSummary(outputFormat))"
            )
        }
        let ratio = outputFormat.sampleRate / input.format.sampleRate
        let capacity = AVAudioFrameCount((Double(input.frameLength) * ratio).rounded(.up) + 16)
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
            throw AudioBufferConversionError.conversionFailed("could not allocate output buffer")
        }

        var supplied = false
        var conversionError: NSError?
        let status = converter.convert(to: output, error: &conversionError) { _, inputStatus in
            guard !supplied else {
                inputStatus.pointee = .endOfStream
                return nil
            }
            supplied = true
            inputStatus.pointee = .haveData
            return input
        }
        if let conversionError {
            throw AudioBufferConversionError.conversionFailed(conversionError.localizedDescription)
        }
        guard status == .haveData || status == .inputRanDry || status == .endOfStream,
              output.frameLength > 0 else {
            throw AudioBufferConversionError.conversionFailed("status \(status.rawValue), zero output frames")
        }
        return output
    }
}

enum AudioLevelMeter {
    static func normalizedLevel(from buffer: AVAudioPCMBuffer) -> Double {
        normalizedLevel(rms: rms(from: buffer))
    }

    static func rms(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData,
              buffer.frameLength > 0,
              buffer.format.channelCount > 0 else { return 0 }

        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        var sumOfSquares = 0.0
        var sampleCount = 0

        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameCount {
                let sample = Double(samples[frame])
                sumOfSquares += sample * sample
            }
            sampleCount += frameCount
        }

        guard sampleCount > 0 else { return 0 }
        return sqrt(sumOfSquares / Double(sampleCount))
    }

    static func normalizedLevel(rms: Double) -> Double {
        guard rms.isFinite, rms > 0 else { return 0 }
        let decibels = 20 * log10(max(rms, 0.000_001))
        return min(1, max(0, (decibels + 60) / 60))
    }
}
