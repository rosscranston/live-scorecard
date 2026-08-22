import AVFoundation
import XCTest
@testable import LiveScorecard

final class AudioCaptureCompatibilityTests: XCTestCase {
    func testCanonicalMonoUsesTheActiveStereoChannel() throws {
        let format = try XCTUnwrap(AVAudioFormat(
            standardFormatWithSampleRate: 48_000,
            channels: 2
        ))
        let input = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4))
        input.frameLength = 4
        let channels = try XCTUnwrap(input.floatChannelData)
        for frame in 0..<4 {
            channels[0][frame] = 0
            channels[1][frame] = 0.25
        }

        let output = try AudioBufferCanonicalizer.makeCanonicalMonoBuffer(from: input)

        XCTAssertEqual(output.format.sampleRate, 48_000)
        XCTAssertEqual(output.format.channelCount, 1)
        XCTAssertEqual(output.frameLength, 4)
        let samples = try XCTUnwrap(output.floatChannelData?[0])
        for frame in 0..<4 {
            XCTAssertEqual(samples[frame], 0.25, accuracy: 0.000_1)
        }
    }

    func testCanonicalMonoConvertsInterleavedIntegerUSBPCM() throws {
        let format = try XCTUnwrap(AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 48_000,
            channels: 2,
            interleaved: true
        ))
        let input = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4))
        input.frameLength = 4
        let buffers = UnsafeMutableAudioBufferListPointer(input.mutableAudioBufferList)
        let samples = try XCTUnwrap(buffers[0].mData?.assumingMemoryBound(to: Int16.self))
        for frame in 0..<4 {
            samples[(frame * 2)] = 0
            samples[(frame * 2) + 1] = 16_384
        }

        let output = try AudioBufferCanonicalizer.makeCanonicalMonoBuffer(from: input)

        XCTAssertEqual(output.format.commonFormat, .pcmFormatFloat32)
        XCTAssertFalse(output.format.isInterleaved)
        XCTAssertEqual(output.format.channelCount, 1)
        let outputSamples = try XCTUnwrap(output.floatChannelData?[0])
        for frame in 0..<4 {
            XCTAssertEqual(outputSamples[frame], 0.5, accuracy: 0.001)
        }
    }

    func testSignalMonitorDistinguishesBuffersSilenceAndRecovery() {
        var monitor = MicrophoneSignalMonitor()
        monitor.recordRawBuffer()

        XCTAssertEqual(monitor.rawBufferCount, 1)
        XCTAssertEqual(
            monitor.recordDecodedBuffer(rms: 0, format: "48 kHz stereo", at: 0),
            .microphoneFormatDetected("48 kHz stereo")
        )
        XCTAssertNil(monitor.recordDecodedBuffer(rms: 0, format: "48 kHz stereo", at: 1))
        XCTAssertEqual(
            monitor.recordDecodedBuffer(rms: 0, format: "48 kHz stereo", at: 4),
            .silentMicrophone(format: "48 kHz stereo")
        )
        XCTAssertEqual(
            monitor.recordDecodedBuffer(rms: 0.05, format: "48 kHz stereo", at: 5),
            .microphoneSignalRestored
        )
        XCTAssertEqual(monitor.decodedBufferCount, 4)
    }
}
