import XCTest
@testable import LiveScorecard

@MainActor
final class AppStoreTests: XCTestCase {
    func testProspectMicrophoneDebugModeMapsMicrophoneToProspect() {
        XCTAssertEqual(
            AppStore.transcriptSource(
                for: .microphone,
                microphoneActsAsProspectForTesting: true
            ),
            .meetingAudio
        )
        XCTAssertEqual(
            AppStore.transcriptSource(
                for: .microphone,
                microphoneActsAsProspectForTesting: false
            ),
            .microphone
        )
        XCTAssertEqual(
            AppStore.transcriptSource(
                for: .meetingAudio,
                microphoneActsAsProspectForTesting: true
            ),
            .meetingAudio
        )
    }

    func testVolatileTranscriptDoesNotSuppressMatchingFinalSegment() async {
        let store = AppStore(demoMode: true)
        await store.endMeeting()
        await store.startMeeting()

        store.injectTranscript(
            text: "We file 900 returns.",
            source: .meetingAudio,
            timestampSeconds: 12,
            isFinal: false
        )
        XCTAssertEqual(store.livePartial, "PROSPECT: We file 900 returns.")
        XCTAssertEqual(store.livePartials[.meetingAudio], "We file 900 returns.")
        XCTAssertTrue(store.transcriptSegments.isEmpty)
        XCTAssertTrue(store.recentSegments.isEmpty)

        store.injectTranscript(
            text: "We file 900 returns.",
            source: .meetingAudio,
            timestampSeconds: 12,
            isFinal: true
        )

        XCTAssertNil(store.livePartial)
        XCTAssertTrue(store.livePartials.isEmpty)
        XCTAssertEqual(store.transcriptSegments.count, 1)
        XCTAssertEqual(store.recentSegments.count, 1)
        XCTAssertTrue(store.recentSegments[0].isFinal)
    }

    func testLivePartialsRemainSeparateForEachAudioChannel() async {
        let store = AppStore(demoMode: true)
        await store.endMeeting()
        await store.startMeeting()

        store.injectTranscript(
            text: "We use Lacerte.",
            source: .meetingAudio,
            timestampSeconds: 4,
            isFinal: false
        )
        store.injectTranscript(
            text: "You use Lacerte.",
            source: .microphone,
            timestampSeconds: 5,
            isFinal: false
        )

        XCTAssertEqual(store.livePartials[.meetingAudio], "We use Lacerte.")
        XCTAssertEqual(store.livePartials[.microphone], "You use Lacerte.")

        store.injectTranscript(
            text: "We use Lacerte.",
            source: .meetingAudio,
            timestampSeconds: 4,
            isFinal: true
        )

        XCTAssertNil(store.livePartials[.meetingAudio])
        XCTAssertEqual(store.livePartials[.microphone], "You use Lacerte.")
        XCTAssertEqual(store.livePartial, "ROSS: You use Lacerte.")
        XCTAssertEqual(store.transcriptSegments.map(\.text), ["We use Lacerte."])
    }

    func testLockedFactRejectsLaterTranscriptUpdate() async {
        ExtractionAdminRepository.shared.clearDecisions()
        let store = AppStore(demoMode: true)
        let meetingID = store.currentMeeting?.id
        store.updateManual(field: .totalReturns, value: "800")
        store.toggleFactLock(.totalReturns)

        store.injectTranscript(
            text: "Actually, we file 999 total returns.",
            source: .meetingAudio,
            timestampSeconds: 800,
            isFinal: true
        )
        await store.endMeeting()

        XCTAssertTrue(store.isFactLocked(.totalReturns))
        XCTAssertEqual(store.facts[.totalReturns]?.value, "800")
        XCTAssertTrue(ExtractionAdminRepository.shared.decisions(meetingID: meetingID).contains {
            $0.field == .totalReturns &&
            $0.outcome == .rejected &&
            $0.reason.localizedCaseInsensitiveContains("locked in the scorecard")
        })
    }

    func testNewMeetingClearsFactLocks() async {
        let store = AppStore(demoMode: true)
        store.toggleFactLock(.totalReturns)
        XCTAssertTrue(store.isFactLocked(.totalReturns))

        await store.endMeeting()
        await store.startMeeting()

        XCTAssertFalse(store.isFactLocked(.totalReturns))
    }

    func testManualEmailAssignmentSeedsExactProspectIdentity() async {
        let store = AppStore(demoMode: true)
        await store.endMeeting()
        await store.startMeeting()

        store.assignProspectEmail("carry.jones@greenfieldtax.com")

        XCTAssertEqual(store.currentMeeting?.prospectIdentityKey, "email:carry.jones@greenfieldtax.com")
        XCTAssertEqual(store.currentMeeting?.prospectEmail, "carry.jones@greenfieldtax.com")
        XCTAssertEqual(store.facts[.name]?.value, "Carry Jones")
        XCTAssertEqual(store.facts[.firmName]?.value, "Greenfield Tax")
    }

    func testPostCallManualCorrectionCreatesTrainingLabel() async throws {
        let store = AppStore(demoMode: true)
        await store.endMeeting()
        await store.startMeeting()
        let meetingID = try XCTUnwrap(store.currentMeeting?.id)
        store.updateManual(field: .name, value: "Gary")
        await store.endMeeting()

        store.updateManual(field: .name, value: "Carry")

        let database = try ScorecardDatabase(url: URL(fileURLWithPath: store.databasePath))
        let label = try XCTUnwrap(database.loadTrainingLabels(meetingID: meetingID).first {
            $0.field == .name
        })
        XCTAssertEqual(label.originalValue, "Gary")
        XCTAssertEqual(label.correctedValue, "Carry")
    }
}
