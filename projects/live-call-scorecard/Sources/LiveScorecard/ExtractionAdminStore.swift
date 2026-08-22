import Combine
import Foundation

final class ExtractionAdminRepository: @unchecked Sendable {
    static let shared = ExtractionAdminRepository()

    private let lock = NSLock()
    private let defaults: UserDefaults
    private let configurationKey: String
    private let maximumDecisionCount: Int
    private var storedConfiguration: ExtractionAdminConfiguration
    private var storedDecisions: [ExtractionDecision] = []
    private var decisionSink: (@Sendable (ExtractionDecision) -> Void)?

    init(
        defaults: UserDefaults = .standard,
        configurationKey: String = "live-scorecard.extraction-admin.configuration.v1",
        maximumDecisionCount: Int = 500
    ) {
        self.defaults = defaults
        self.configurationKey = configurationKey
        self.maximumDecisionCount = max(50, maximumDecisionCount)

        if let data = defaults.data(forKey: configurationKey),
           let decoded = try? JSONDecoder().decode(ExtractionAdminConfiguration.self, from: data) {
            storedConfiguration = decoded.sanitized()
        } else {
            storedConfiguration = .standard
        }
    }

    var configuration: ExtractionAdminConfiguration {
        lock.withLock { storedConfiguration }
    }

    var rules: [ExtractionAdminRule] {
        ExtractionRuleCatalog.ordered
    }

    func updateConfiguration(_ configuration: ExtractionAdminConfiguration) {
        let clean = configuration.sanitized()
        lock.withLock {
            storedConfiguration = clean
            persistLocked(clean)
        }
    }

    func setRule(_ ruleID: String, enabled: Bool) {
        guard ExtractionRuleCatalog.ordered.contains(where: { $0.id == ruleID && $0.isTunable }) else {
            return
        }
        lock.withLock {
            if enabled {
                storedConfiguration.disabledRuleIDs.remove(ruleID)
            } else {
                storedConfiguration.disabledRuleIDs.insert(ruleID)
            }
            persistLocked(storedConfiguration)
        }
    }

    func resetConfiguration() {
        updateConfiguration(.standard)
    }

    func record(_ decision: ExtractionDecision) {
        let sink = lock.withLock {
            storedDecisions.append(decision)
            if storedDecisions.count > maximumDecisionCount {
                storedDecisions.removeFirst(storedDecisions.count - maximumDecisionCount)
            }
            return decisionSink
        }
        sink?(decision)
    }

    func setDecisionSink(_ sink: (@Sendable (ExtractionDecision) -> Void)?) {
        lock.withLock {
            decisionSink = sink
        }
    }

    func recordLockedCandidate(
        _ candidate: FactCandidate,
        meetingID: UUID,
        previousValue: String?
    ) {
        record(ExtractionDecision(
            meetingID: meetingID,
            ruleID: ExtractionRuleCatalog.protectManual,
            stage: .replacement,
            outcome: .rejected,
            field: candidate.field,
            proposedValue: candidate.value,
            previousValue: previousValue,
            reason: "The field is locked in the scorecard, so the proposed value was ignored.",
            quote: candidate.quote,
            speaker: candidate.speaker,
            transcriptTimestamp: candidate.timestampSeconds
        ))
    }

    func decisions(meetingID: UUID? = nil) -> [ExtractionDecision] {
        lock.withLock {
            let selected = meetingID.map { id in
                storedDecisions.filter { $0.meetingID == id }
            } ?? storedDecisions
            return selected.reversed()
        }
    }

    func clearDecisions(meetingID: UUID? = nil) {
        lock.withLock {
            if let meetingID {
                storedDecisions.removeAll { $0.meetingID == meetingID }
            } else {
                storedDecisions.removeAll()
            }
        }
    }

    private func persistLocked(_ configuration: ExtractionAdminConfiguration) {
        guard let data = try? JSONEncoder().encode(configuration) else { return }
        defaults.set(data, forKey: configurationKey)
    }
}

@MainActor
final class ExtractionAdminViewModel: ObservableObject {
    @Published private(set) var rules: [ExtractionAdminRule]
    @Published var configuration: ExtractionAdminConfiguration
    @Published private(set) var decisions: [ExtractionDecision]

    private let repository: ExtractionAdminRepository
    private var selectedMeetingID: UUID?

    init(repository: ExtractionAdminRepository = .shared) {
        self.repository = repository
        rules = repository.rules
        configuration = repository.configuration
        decisions = repository.decisions()
    }

    func isEnabled(_ rule: ExtractionAdminRule) -> Bool {
        configuration.isEnabled(rule.id)
    }

    func setRule(_ rule: ExtractionAdminRule, enabled: Bool) {
        guard rule.isTunable else { return }
        repository.setRule(rule.id, enabled: enabled)
        reloadConfiguration()
    }

    func saveConfiguration() {
        repository.updateConfiguration(configuration)
        reloadConfiguration()
    }

    func resetConfiguration() {
        repository.resetConfiguration()
        reloadConfiguration()
    }

    func showDecisions(for meetingID: UUID?) {
        selectedMeetingID = meetingID
        refreshDecisions()
    }

    func refreshDecisions() {
        decisions = repository.decisions(meetingID: selectedMeetingID)
    }

    func clearDecisions() {
        repository.clearDecisions(meetingID: selectedMeetingID)
        refreshDecisions()
    }

    private func reloadConfiguration() {
        configuration = repository.configuration
    }
}
