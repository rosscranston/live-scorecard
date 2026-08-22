import XCTest
@testable import TaxTerms

final class SyncTests: XCTestCase {
    func testDirtyLocalFieldWinsWhenRemoteHasNotChanged() {
        let baseline = TermContent(term: "Basis", definition: "Old")
        var localContent = baseline
        localContent.definition = "Local"
        let local = TermCard(
            id: "1",
            notionURL: "",
            content: localContent,
            baseline: baseline,
            dirtyFields: [.definition]
        )
        let remote = RemoteTermRecord(id: "1", notionURL: "u", content: baseline)
        let result = SyncMergeEngine.merge(local: local, remote: remote)
        XCTAssertEqual(result.card.content.definition, "Local")
        XCTAssertTrue(result.card.dirtyFields.contains(.definition))
        XCTAssertTrue(result.conflicts.isEmpty)
    }

    func testConflictKeepsLocalValueAndRecordsEvidence() {
        let baseline = TermContent(term: "Basis", definition: "Old")
        var localContent = baseline
        localContent.definition = "Local"
        var remoteContent = baseline
        remoteContent.definition = "Remote"
        let local = TermCard(
            id: "1",
            notionURL: "",
            content: localContent,
            baseline: baseline,
            dirtyFields: [.definition]
        )
        let result = SyncMergeEngine.merge(
            local: local,
            remote: RemoteTermRecord(id: "1", notionURL: "u", content: remoteContent)
        )
        XCTAssertEqual(result.card.content.definition, "Local")
        XCTAssertEqual(result.conflicts.count, 1)
        XCTAssertEqual(result.conflicts.first?.remoteValue, "Remote")
    }

    func testCleanLocalFieldAcceptsRemoteValue() {
        let baseline = TermContent(term: "Basis", definition: "Old")
        var remoteContent = baseline
        remoteContent.definition = "Remote"
        let local = TermCard(id: "1", notionURL: "", content: baseline, baseline: baseline)
        let result = SyncMergeEngine.merge(
            local: local,
            remote: RemoteTermRecord(id: "1", notionURL: "u", content: remoteContent)
        )
        XCTAssertEqual(result.card.content.definition, "Remote")
        XCTAssertEqual(result.card.baseline.definition, "Remote")
    }

    func testMatchingDirtyValueClearsDirtyField() {
        let baseline = TermContent(term: "Basis", definition: "Old")
        var changed = baseline
        changed.definition = "Same"
        let local = TermCard(
            id: "1",
            notionURL: "",
            content: changed,
            baseline: baseline,
            dirtyFields: [.definition]
        )
        let result = SyncMergeEngine.merge(
            local: local,
            remote: RemoteTermRecord(id: "1", notionURL: "u", content: changed)
        )
        XCTAssertFalse(result.card.dirtyFields.contains(.definition))
    }

    func testParsesMarkdownResourceLinksAndTimestamp() {
        let text = "[IRS guide](https://www.irs.gov/example) · [Video — 2:05](https://www.youtube.com/watch?v=abc&t=125s)"
        let links = NotionClient.markdownResources(in: text)
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links[0].kind, .official)
        XCTAssertEqual(links[1].kind, .video)
        XCTAssertEqual(links[1].timestampSeconds, 125)
    }

    func testParsesNotionPageProperties() throws {
        let page: [String: Any] = [
            "id": "page-1",
            "url": "https://notion.so/page-1",
            "last_edited_time": "2026-08-21T20:00:00.000Z",
            "properties": [
                "Term": ["title": [["plain_text": "Form 1065"]]],
                "Definition": ["rich_text": [["plain_text": "Partnership return"]]],
                "Why It Matters": ["rich_text": []],
                "Example in a Sentence": ["rich_text": []],
                "Priority": ["select": ["name": "Core"]],
                "Category": ["multi_select": [["name": "Forms & Schedules"]]],
                "Status": ["status": ["name": "Done"]],
                "Resources": ["rich_text": [[
                    "plain_text": "IRS Form 1065",
                    "href": "https://www.irs.gov/forms-pubs/about-form-1065"
                ]]],
                "Study Notes": ["rich_text": [["plain_text": "Remember K-1s"]]]
            ]
        ]
        let parsed = try NotionClient.parsePage(page)
        XCTAssertEqual(parsed.content.term, "Form 1065")
        XCTAssertEqual(parsed.content.status, .memorized)
        XCTAssertEqual(parsed.content.resources.first?.kind, .official)
        XCTAssertEqual(parsed.content.studyNotes, "Remember K-1s")
    }

    func testBundledResourceCatalogDecodesEntriesWithoutStoredUUIDs() {
        let library = ResourceLibrary.bundled
        let links = library.resources(for: "Blue J")
        XCTAssertEqual(library.termCount, 177)
        XCTAssertEqual(links?.count, 2)
        XCTAssertEqual(links?.first?.kind, .official)
        XCTAssertNotNil(links?.first?.id)
    }
}
