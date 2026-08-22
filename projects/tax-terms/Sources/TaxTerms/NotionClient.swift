import Foundation

struct RemoteTermRecord: Equatable {
    var id: String
    var notionURL: String
    var content: TermContent
    var lastEditedAt: Date?
}

struct NotionSchema: Equatable {
    var categoryOptions: [String]
    var propertyNames: Set<String>
}

enum NotionClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case http(status: Int, message: String)
    case malformedPage(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The Notion API URL could not be created."
        case .invalidResponse: return "Notion returned an invalid response."
        case .http(let status, let message): return "Notion \(status): \(message)"
        case .malformedPage(let detail): return "A Notion term could not be read: \(detail)"
        }
    }
}

final class NotionClient {
    static let apiVersion = "2026-03-11"

    private let token: String
    private let session: URLSession
    private let baseURL = URL(string: "https://api.notion.com/v1")!

    init(token: String, session: URLSession = .shared) {
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        self.session = session
    }

    func fetchSchema(dataSourceID: String) async throws -> NotionSchema {
        let json = try await request(path: "/data_sources/\(dataSourceID)", method: "GET")
        guard let properties = json["properties"] as? [String: Any] else {
            throw NotionClientError.invalidResponse
        }
        let category = properties["Category"] as? [String: Any]
        let multiSelect = category?["multi_select"] as? [String: Any]
        let options = (multiSelect?["options"] as? [[String: Any]] ?? [])
            .compactMap { $0["name"] as? String }
        return NotionSchema(
            categoryOptions: options.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending },
            propertyNames: Set(properties.keys)
        )
    }

    func fetchAllTerms(dataSourceID: String) async throws -> [RemoteTermRecord] {
        var records: [RemoteTermRecord] = []
        var cursor: String?

        repeat {
            var body: [String: Any] = [
                "page_size": 100,
                "sorts": [["property": "Term", "direction": "ascending"]]
            ]
            if let cursor { body["start_cursor"] = cursor }
            let json = try await request(
                path: "/data_sources/\(dataSourceID)/query",
                method: "POST",
                body: body
            )
            guard let results = json["results"] as? [[String: Any]] else {
                throw NotionClientError.invalidResponse
            }
            records.append(contentsOf: try results.map(Self.parsePage))
            let hasMore = json["has_more"] as? Bool ?? false
            cursor = hasMore ? json["next_cursor"] as? String : nil
        } while cursor != nil

        return records
    }

    func updatePage(_ card: TermCard, fields: Set<DirtyField>) async throws {
        guard !fields.isEmpty else { return }
        var properties: [String: Any] = [:]
        let content = card.content

        for field in fields {
            switch field {
            case .term:
                properties["Term"] = ["title": Self.richText(content.term)]
            case .definition:
                properties["Definition"] = ["rich_text": Self.richText(content.definition)]
            case .whyItMatters:
                properties["Why It Matters"] = ["rich_text": Self.richText(content.whyItMatters)]
            case .example:
                properties["Example in a Sentence"] = ["rich_text": Self.richText(content.example)]
            case .priority:
                let selectValue: Any = content.priority.isEmpty
                    ? NSNull()
                    : ["name": content.priority]
                properties["Priority"] = [
                    "select": selectValue
                ]
            case .categories:
                properties["Category"] = [
                    "multi_select": content.categories.sorted().map { ["name": $0] }
                ]
            case .status:
                properties["Status"] = ["status": ["name": content.status.notionStatus]]
            case .resources:
                properties["Resources"] = ["rich_text": Self.resourceRichText(content.resources)]
            case .studyNotes:
                properties["Study Notes"] = ["rich_text": Self.richText(content.studyNotes)]
            }
        }

        _ = try await request(
            path: "/pages/\(card.id)",
            method: "PATCH",
            body: ["properties": properties]
        )
    }

    private func request(
        path: String,
        method: String,
        body: [String: Any]? = nil,
        attempt: Int = 0
    ) async throws -> [String: Any] {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw NotionClientError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NotionClientError.invalidResponse
        }
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        if http.statusCode == 429, attempt < 5 {
            let retryAfter = Double(http.value(forHTTPHeaderField: "Retry-After") ?? "") ?? 1
            let delay = max(0.5, min(retryAfter, 30))
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            return try await self.request(path: path, method: method, body: body, attempt: attempt + 1)
        }
        if (500...599).contains(http.statusCode), attempt < 3 {
            let delay = pow(2, Double(attempt))
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            return try await self.request(path: path, method: method, body: body, attempt: attempt + 1)
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = json["message"] as? String
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown API error"
            throw NotionClientError.http(status: http.statusCode, message: message)
        }
        return json
    }

    static func parsePage(_ page: [String: Any]) throws -> RemoteTermRecord {
        guard let id = page["id"] as? String,
              let properties = page["properties"] as? [String: Any] else {
            throw NotionClientError.malformedPage("missing id or properties")
        }

        let content = TermContent(
            term: text(from: properties["Term"], arrayKey: "title"),
            definition: text(from: properties["Definition"]),
            whyItMatters: text(from: properties["Why It Matters"]),
            example: text(from: properties["Example in a Sentence"]),
            priority: selectName(from: properties["Priority"]),
            categories: multiSelectNames(from: properties["Category"]),
            status: StudyState.fromNotion(statusName(from: properties["Status"])),
            resources: resources(from: properties["Resources"]),
            studyNotes: text(from: properties["Study Notes"])
        )
        return RemoteTermRecord(
            id: id,
            notionURL: page["url"] as? String ?? "",
            content: content,
            lastEditedAt: parseDate(page["last_edited_time"] as? String)
        )
    }

    static func text(from property: Any?, arrayKey: String = "rich_text") -> String {
        guard let property = property as? [String: Any],
              let parts = property[arrayKey] as? [[String: Any]] else { return "" }
        return parts.compactMap { part in
            if let plain = part["plain_text"] as? String { return plain }
            return (part["text"] as? [String: Any])?["content"] as? String
        }.joined()
    }

    static func selectName(from property: Any?) -> String {
        guard let property = property as? [String: Any],
              let select = property["select"] as? [String: Any] else { return "" }
        return select["name"] as? String ?? ""
    }

    static func statusName(from property: Any?) -> String? {
        guard let property = property as? [String: Any],
              let status = property["status"] as? [String: Any] else { return nil }
        return status["name"] as? String
    }

    static func multiSelectNames(from property: Any?) -> [String] {
        guard let property = property as? [String: Any],
              let values = property["multi_select"] as? [[String: Any]] else { return [] }
        return values.compactMap { $0["name"] as? String }
    }

    static func resources(from property: Any?) -> [ResourceLink] {
        guard let property = property as? [String: Any],
              let values = property["rich_text"] as? [[String: Any]] else { return [] }

        var parsed: [ResourceLink] = []
        var plain = ""
        for value in values {
            let title = value["plain_text"] as? String
                ?? (value["text"] as? [String: Any])?["content"] as? String
                ?? ""
            plain += title
            let href = value["href"] as? String
                ?? ((value["text"] as? [String: Any])?["link"] as? [String: Any])?["url"] as? String
            if let href, !href.isEmpty {
                parsed.append(ResourceLink(
                    title: title.isEmpty ? href : title,
                    url: href,
                    kind: inferredKind(url: href),
                    timestampSeconds: timestamp(from: href)
                ))
            }
        }

        if parsed.isEmpty {
            parsed = markdownResources(in: plain)
        }

        var seen = Set<String>()
        return parsed.filter { seen.insert($0.url).inserted }
    }

    static func markdownResources(in text: String) -> [ResourceLink] {
        guard let regex = try? NSRegularExpression(pattern: #"\[([^\]]+)\]\((https?://[^\)]+)\)"#) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let titleRange = Range(match.range(at: 1), in: text),
                  let urlRange = Range(match.range(at: 2), in: text) else { return nil }
            let title = String(text[titleRange])
            let url = String(text[urlRange])
            return ResourceLink(
                title: title,
                url: url,
                kind: inferredKind(url: url),
                timestampSeconds: timestamp(from: url)
            )
        }
    }

    static func richText(_ value: String) -> [[String: Any]] {
        guard !value.isEmpty else { return [] }
        return value.chunked(maxCharacters: 1_900).map {
            ["type": "text", "text": ["content": $0]]
        }
    }

    static func resourceRichText(_ resources: [ResourceLink]) -> [[String: Any]] {
        var result: [[String: Any]] = []
        for (index, resource) in resources.enumerated() {
            if index > 0 {
                result.append(["type": "text", "text": ["content": " · "]])
            }
            let url = resource.destinationURL?.absoluteString ?? resource.url
            result.append([
                "type": "text",
                "text": [
                    "content": resource.title,
                    "link": ["url": url]
                ]
            ])
        }
        return result
    }

    private static func inferredKind(url: String) -> ResourceKind {
        let lower = url.lowercased()
        if lower.contains("youtube.com") || lower.contains("youtu.be") || lower.contains("vimeo.com") {
            return .video
        }
        if lower.contains("irs.gov") || lower.contains(".gov/") { return .official }
        return .reference
    }

    private static func timestamp(from url: String) -> Int? {
        guard let components = URLComponents(string: url),
              let raw = components.queryItems?.first(where: { $0.name == "t" })?.value else {
            return nil
        }
        if let seconds = Int(raw) { return seconds }
        if raw.hasSuffix("s"), let seconds = Int(raw.dropLast()) { return seconds }
        return nil
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}

enum SyncMergeEngine {
    struct Result {
        var card: TermCard
        var conflicts: [SyncConflict]
    }

    static func merge(local: TermCard, remote: RemoteTermRecord) -> Result {
        var merged = local
        var dirty = local.dirtyFields
        var conflicts: [SyncConflict] = []

        for field in DirtyField.allCases {
            let localValue = local.content.value(for: field)
            let remoteValue = remote.content.value(for: field)
            let baselineValue = local.baseline.value(for: field)

            if local.dirtyFields.contains(field) {
                if localValue == remoteValue {
                    dirty.remove(field)
                    merged.baseline.replace(field: field, from: remote.content)
                } else if remoteValue != baselineValue {
                    conflicts.append(SyncConflict(
                        cardID: local.id,
                        term: local.content.term,
                        field: field,
                        localValue: localValue,
                        remoteValue: remoteValue
                    ))
                }
            } else {
                merged.content.replace(field: field, from: remote.content)
                merged.baseline.replace(field: field, from: remote.content)
            }
        }

        merged.dirtyFields = dirty
        merged.notionURL = remote.notionURL
        merged.remoteLastEditedAt = remote.lastEditedAt
        return Result(card: merged, conflicts: conflicts)
    }
}

private extension String {
    func chunked(maxCharacters: Int) -> [String] {
        guard count > maxCharacters else { return [self] }
        var result: [String] = []
        var index = startIndex
        while index < endIndex {
            let end = self.index(index, offsetBy: maxCharacters, limitedBy: endIndex) ?? endIndex
            result.append(String(self[index..<end]))
            index = end
        }
        return result
    }
}
