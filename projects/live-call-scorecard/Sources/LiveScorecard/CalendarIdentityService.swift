@preconcurrency import EventKit
import Foundation

struct ProspectIdentity: Codable, Equatable, Sendable {
    let key: String
    let displayName: String
    let primaryEmail: String
    let organizationDomain: String?

    var inferredOrganizationName: String? {
        organizationDomain.flatMap(CalendarProspectResolver.organizationName(from:))
    }
}

struct CalendarMeetingMatch: Equatable, Sendable {
    let eventIdentifier: String
    let eventTitle: String
    let startDate: Date
    let endDate: Date
    let identity: ProspectIdentity
}

enum CalendarIdentityLookup: Equatable, Sendable {
    case matched(CalendarMeetingMatch)
    case manuallyAssigned(ProspectIdentity)
    case unavailable(String)

    var compactLabel: String {
        switch self {
        case let .matched(match):
            return "ID \(match.identity.displayName)"
        case let .manuallyAssigned(identity):
            return "ID \(identity.displayName)"
        case .unavailable:
            return "NO CAL ID"
        }
    }

    var detail: String {
        switch self {
        case let .matched(match):
            return "CALENDAR MATCH: \(match.identity.displayName) / \(match.identity.primaryEmail)"
        case let .manuallyAssigned(identity):
            return "MANUAL ID: \(identity.displayName) / \(identity.primaryEmail)"
        case let .unavailable(reason):
            return "CALENDAR: \(reason) / PRIOR FACTS OFF"
        }
    }
}

struct CalendarAttendeeSnapshot: Equatable, Sendable {
    let name: String?
    let email: String
    let isCurrentUser: Bool
    let isDeclined: Bool
    let isPerson: Bool
}

struct CalendarEventSnapshot: Equatable, Sendable {
    let identifier: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let isCanceled: Bool
    let hasGoogleMeet: Bool
    let organizer: CalendarAttendeeSnapshot?
    let attendees: [CalendarAttendeeSnapshot]
}

enum CalendarProspectResolver {
    private static let internalDomains: Set<String> = ["cranston.ai"]
    private static let personalEmailDomains: Set<String> = [
        "aol.com", "fastmail.com", "gmail.com", "googlemail.com", "hey.com",
        "hotmail.com", "icloud.com", "live.com", "mac.com", "me.com", "msn.com",
        "outlook.com", "proton.me", "protonmail.com", "yahoo.com"
    ]

    static func resolve(
        events: [CalendarEventSnapshot],
        at now: Date,
        tolerance: TimeInterval = 10 * 60
    ) -> CalendarIdentityLookup {
        let candidates = events.filter { event in
            !event.isAllDay &&
            !event.isCanceled &&
            event.startDate <= now.addingTimeInterval(tolerance) &&
            event.endDate >= now.addingTimeInterval(-tolerance)
        }

        guard !candidates.isEmpty else {
            return .unavailable("NO ACTIVE EVENT")
        }

        let ranked = candidates.sorted { lhs, rhs in
            score(lhs, at: now) > score(rhs, at: now)
        }

        let resolvable = ranked.compactMap { event -> CalendarMeetingMatch? in
            guard let identity = identity(for: event) else { return nil }
            return CalendarMeetingMatch(
                eventIdentifier: event.identifier,
                eventTitle: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                identity: identity
            )
        }

        if let first = resolvable.first {
            let simultaneouslyActive = resolvable.filter {
                $0.startDate <= now && $0.endDate >= now
            }
            let distinctKeys = Set(simultaneouslyActive.map(\.identity.key))
            if distinctKeys.count > 1 {
                return .unavailable("MULTIPLE ACTIVE PROSPECT EVENTS")
            }
            return .matched(first)
        }

        return .unavailable("ACTIVE EVENT HAS NO UNIQUE EXTERNAL ATTENDEE")
    }

    static func identity(for event: CalendarEventSnapshot) -> ProspectIdentity? {
        var participants = event.attendees
        if let organizer = event.organizer {
            participants.insert(organizer, at: 0)
        }

        var seen = Set<String>()
        let external = participants.filter { participant in
            let email = normalizedEmail(participant.email)
            guard !email.isEmpty,
                  seen.insert(email).inserted,
                  participant.isPerson,
                  !participant.isCurrentUser,
                  !participant.isDeclined,
                  let domain = emailDomain(email),
                  !internalDomains.contains(domain)
            else { return false }
            return true
        }

        guard !external.isEmpty else { return nil }

        let businessDomains = Set(external.compactMap { participant -> String? in
            guard let domain = emailDomain(participant.email),
                  !personalEmailDomains.contains(domain) else { return nil }
            return domain
        })

        if businessDomains.count == 1, let domain = businessDomains.first {
            let participant = external.first(where: { emailDomain($0.email) == domain }) ?? external[0]
            let email = normalizedEmail(participant.email)
            let attendeeName = cleanedDisplayName(participant.name)
            return ProspectIdentity(
                key: "email:\(email)",
                displayName: attendeeName ?? inferredPersonName(from: email) ?? email,
                primaryEmail: email,
                organizationDomain: domain
            )
        }

        guard businessDomains.isEmpty, external.count == 1 else { return nil }
        let participant = external[0]
        let email = normalizedEmail(participant.email)
        let displayName = cleanedDisplayName(participant.name)
        return ProspectIdentity(
            key: "email:\(email)",
            displayName: displayName ?? inferredPersonName(from: email) ?? email,
            primaryEmail: email,
            organizationDomain: nil
        )
    }

    static func identity(email rawEmail: String, displayName: String? = nil) -> ProspectIdentity? {
        let email = normalizedEmail(rawEmail)
        guard let domain = emailDomain(email) else { return nil }
        let businessDomain = personalEmailDomains.contains(domain) ? nil : domain
        return ProspectIdentity(
            key: "email:\(email)",
            displayName: cleanedDisplayName(displayName) ?? inferredPersonName(from: email) ?? email,
            primaryEmail: email,
            organizationDomain: businessDomain
        )
    }

    static func organizationName(from rawDomain: String) -> String? {
        let labels = rawDomain.lowercased().split(separator: ".").map(String.init)
        guard labels.count >= 2 else { return nil }
        let compoundCountrySuffixes: Set<String> = ["co.uk", "com.au", "co.nz", "co.za"]
        let trailingPair = labels.suffix(2).joined(separator: ".")
        let organizationIndex = compoundCountrySuffixes.contains(trailingPair)
            ? labels.count - 3
            : labels.count - 2
        guard organizationIndex >= 0 else { return nil }

        var token = labels[organizationIndex]
            .replacingOccurrences(of: "_", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { return nil }

        let knownSuffixes = [
            "accounting", "advisory", "associates", "partners", "services",
            "financial", "consulting", "group", "cpa", "tax"
        ]
        if !token.contains("-"),
           let suffix = knownSuffixes.first(where: { token.count > $0.count && token.hasSuffix($0) }) {
            token.insert("-", at: token.index(token.endIndex, offsetBy: -suffix.count))
        }

        let words = token.split(separator: "-").map { word -> String in
            let lower = word.lowercased()
            if lower == "cpa" { return "CPA" }
            return lower.prefix(1).uppercased() + String(lower.dropFirst())
        }
        return words.isEmpty ? nil : words.joined(separator: " ")
    }

    private static func score(_ event: CalendarEventSnapshot, at now: Date) -> Int {
        var value = 0
        if event.startDate <= now && event.endDate >= now { value += 1_000 }
        if event.hasGoogleMeet { value += 200 }
        if identity(for: event) != nil { value += 100 }
        value -= min(99, Int(abs(event.startDate.timeIntervalSince(now)) / 60))
        return value
    }

    private static func cleanedDisplayName(_ value: String?) -> String? {
        let cleaned = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return cleaned.isEmpty ? nil : cleaned
    }

    private static func inferredPersonName(from email: String) -> String? {
        guard let local = normalizedEmail(email).split(separator: "@").first else { return nil }
        let roleAccounts: Set<String> = [
            "admin", "billing", "contact", "hello", "info", "office", "support", "team"
        ]
        let normalized = local.lowercased()
        guard !roleAccounts.contains(normalized),
              normalized.contains(".") || normalized.contains("-") || normalized.contains("_") else {
            return nil
        }
        let words = normalized
            .split(whereSeparator: { $0 == "." || $0 == "-" || $0 == "_" })
            .map { $0.prefix(1).uppercased() + String($0.dropFirst()) }
        return words.isEmpty ? nil : words.joined(separator: " ")
    }

    private static func normalizedEmail(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func emailDomain(_ email: String) -> String? {
        let parts = normalizedEmail(email).split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else { return nil }
        return String(parts[1])
    }
}

@MainActor
final class CalendarIdentityService: @unchecked Sendable {
    private final class SendableEventStore: @unchecked Sendable {
        let value = EKEventStore()
    }

    private let eventStore = SendableEventStore()
    private let queue = DispatchQueue(label: "ai.cranston.live-scorecard.calendar", qos: .userInitiated)

    func findCurrentProspect(at now: Date = Date()) async -> CalendarIdentityLookup {
        do {
            guard try await ensureCalendarAccess() else {
                return .unavailable("ACCESS DENIED")
            }
        } catch {
            return .unavailable("ACCESS ERROR: \(error.localizedDescription)")
        }

        let snapshots = await withCheckedContinuation { continuation in
            queue.async { [eventStore] in
                let start = now.addingTimeInterval(-8 * 60 * 60)
                let end = now.addingTimeInterval(8 * 60 * 60)
                let predicate = eventStore.value.predicateForEvents(withStart: start, end: end, calendars: nil)
                let events = eventStore.value.events(matching: predicate)
                continuation.resume(returning: events.map(Self.snapshot))
            }
        }
        return CalendarProspectResolver.resolve(events: snapshots, at: now)
    }

    private func ensureCalendarAccess() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess { return true }
        if status == .denied || status == .restricted { return false }
        return try await eventStore.value.requestFullAccessToEvents()
    }

    nonisolated private static func snapshot(_ event: EKEvent) -> CalendarEventSnapshot {
        let haystack = [event.url?.absoluteString, event.location, event.notes]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
        return CalendarEventSnapshot(
            identifier: event.eventIdentifier ?? UUID().uuidString,
            title: event.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? event.title!
                : "Calendar Meeting",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            isCanceled: event.status == .canceled,
            hasGoogleMeet: haystack.contains("meet.google.com"),
            organizer: event.organizer.map(attendeeSnapshot),
            attendees: (event.attendees ?? []).map(attendeeSnapshot)
        )
    }

    nonisolated private static func attendeeSnapshot(_ participant: EKParticipant) -> CalendarAttendeeSnapshot {
        CalendarAttendeeSnapshot(
            name: participant.name,
            email: email(from: participant.url),
            isCurrentUser: participant.isCurrentUser,
            isDeclined: participant.participantStatus == .declined,
            isPerson: participant.participantType == .person || participant.participantType == .unknown
        )
    }

    nonisolated private static func email(from url: URL) -> String {
        if url.scheme?.lowercased() == "mailto" {
            let raw = String(url.absoluteString.dropFirst("mailto:".count))
            let address = raw.split(separator: "?", maxSplits: 1).first.map(String.init) ?? raw
            return address.removingPercentEncoding ?? address
        }
        return url.absoluteString
    }
}
