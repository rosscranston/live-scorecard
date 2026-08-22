import Foundation

enum TimeZoneResolution: Equatable, Sendable {
    case resolved(identifier: String)
    case ambiguous
    case unknown
}

struct TimeZoneResolver: Sendable {
    private let cityZones: [String: String] = [
        "los angeles": "America/Los_Angeles",
        "san francisco": "America/Los_Angeles",
        "san diego": "America/Los_Angeles",
        "seattle": "America/Los_Angeles",
        "portland": "America/Los_Angeles",
        "phoenix": "America/Phoenix",
        "denver": "America/Denver",
        "salt lake city": "America/Denver",
        "albuquerque": "America/Denver",
        "chicago": "America/Chicago",
        "dallas": "America/Chicago",
        "houston": "America/Chicago",
        "austin": "America/Chicago",
        "nashville": "America/Chicago",
        "memphis": "America/Chicago",
        "new orleans": "America/Chicago",
        "new york": "America/New_York",
        "boston": "America/New_York",
        "philadelphia": "America/New_York",
        "washington dc": "America/New_York",
        "atlanta": "America/New_York",
        "miami": "America/New_York",
        "orlando": "America/New_York",
        "tampa": "America/New_York",
        "indianapolis": "America/Indiana/Indianapolis",
        "honolulu": "Pacific/Honolulu",
        "anchorage": "America/Anchorage"
    ]

    private let stateZones: [String: String] = [
        "california": "America/Los_Angeles", "ca": "America/Los_Angeles",
        "washington": "America/Los_Angeles", "wa": "America/Los_Angeles",
        "oregon": "America/Los_Angeles", "or": "America/Los_Angeles",
        "nevada": "America/Los_Angeles", "nv": "America/Los_Angeles",
        "arizona": "America/Phoenix", "az": "America/Phoenix",
        "colorado": "America/Denver", "co": "America/Denver",
        "utah": "America/Denver", "ut": "America/Denver",
        "new mexico": "America/Denver", "nm": "America/Denver",
        "montana": "America/Denver", "mt": "America/Denver",
        "wyoming": "America/Denver", "wy": "America/Denver",
        "texas": "America/Chicago", "tx": "America/Chicago",
        "illinois": "America/Chicago", "il": "America/Chicago",
        "minnesota": "America/Chicago", "mn": "America/Chicago",
        "wisconsin": "America/Chicago", "wi": "America/Chicago",
        "missouri": "America/Chicago", "mo": "America/Chicago",
        "louisiana": "America/Chicago", "la": "America/Chicago",
        "alabama": "America/Chicago", "al": "America/Chicago",
        "mississippi": "America/Chicago", "ms": "America/Chicago",
        "oklahoma": "America/Chicago", "ok": "America/Chicago",
        "kansas": "America/Chicago", "ks": "America/Chicago",
        "nebraska": "America/Chicago", "ne": "America/Chicago",
        "new york": "America/New_York", "ny": "America/New_York",
        "massachusetts": "America/New_York", "ma": "America/New_York",
        "pennsylvania": "America/New_York", "pa": "America/New_York",
        "new jersey": "America/New_York", "nj": "America/New_York",
        "virginia": "America/New_York", "va": "America/New_York",
        "north carolina": "America/New_York", "nc": "America/New_York",
        "south carolina": "America/New_York", "sc": "America/New_York",
        "georgia": "America/New_York", "ga": "America/New_York",
        "ohio": "America/New_York", "oh": "America/New_York",
        "michigan": "America/Detroit", "mi": "America/Detroit",
        "maryland": "America/New_York", "md": "America/New_York",
        "connecticut": "America/New_York", "ct": "America/New_York",
        "hawaii": "Pacific/Honolulu", "hi": "Pacific/Honolulu",
        "alaska": "America/Anchorage", "ak": "America/Anchorage"
    ]

    private let ambiguousStates: Set<String> = [
        "florida", "fl", "tennessee", "tn", "kentucky", "ky",
        "indiana", "in", "idaho", "id", "north dakota", "nd",
        "south dakota", "sd"
    ]

    func resolve(_ location: String) -> TimeZoneResolution {
        let normalized = normalize(location)
        guard !normalized.isEmpty else { return .unknown }

        for (city, zone) in cityZones where normalized.contains(city) {
            return .resolved(identifier: zone)
        }

        let components = normalized
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        for component in components.reversed() {
            if ambiguousStates.contains(component) {
                return .ambiguous
            }
            if let zone = stateZones[component] {
                return .resolved(identifier: zone)
            }
        }

        if ambiguousStates.contains(normalized) {
            return .ambiguous
        }
        if let zone = stateZones[normalized] {
            return .resolved(identifier: zone)
        }
        return .unknown
    }

    private func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
