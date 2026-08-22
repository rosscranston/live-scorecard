import XCTest
@testable import TaxTerms

final class ModelsTests: XCTestCase {
    func testSchedulerAgainCreatesShortReviewAndLapse() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let result = StudyScheduler.applying(.again, to: ReviewStats(), now: now)
        XCTAssertEqual(result.state, .needsReview)
        XCTAssertEqual(result.stats.lapseCount, 1)
        XCTAssertEqual(result.stats.reviewCount, 1)
        XCTAssertEqual(try XCTUnwrap(result.stats.dueAt).timeIntervalSince(now), 600, accuracy: 1)
    }

    func testSchedulerReviewExpandsInterval() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let stats = ReviewStats(intervalDays: 2, easeFactor: 2.5)
        let result = StudyScheduler.applying(.review, to: stats, now: now)
        XCTAssertEqual(result.state, .needsReview)
        XCTAssertEqual(result.stats.intervalDays, 5)
        XCTAssertEqual(try XCTUnwrap(result.stats.dueAt).timeIntervalSince(now), 5 * 86_400, accuracy: 1)
    }

    func testSchedulerMemorizedUsesMinimumSevenDays() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let result = StudyScheduler.applying(.memorized, to: ReviewStats(), now: now)
        XCTAssertEqual(result.state, .memorized)
        XCTAssertEqual(result.stats.intervalDays, 7)
    }

    func testQuizFilterSupportsAnyAndAllTagMatching() {
        let content = TermContent(term: "Form 1065", categories: ["Forms & Schedules", "Entity Types"])
        let card = TermCard(id: "1", notionURL: "", content: content, baseline: content)

        XCTAssertTrue(QuizFilter(tags: ["Entity Types"]).matches(card))
        XCTAssertTrue(QuizFilter(tags: ["Entity Types", "Software"], tagMatchMode: .any).matches(card))
        XCTAssertFalse(QuizFilter(tags: ["Entity Types", "Software"], tagMatchMode: .all).matches(card))
    }

    func testDueFilterExcludesMemorizedCardsWithoutAReviewDate() {
        let content = TermContent(term: "Basis", status: .memorized)
        let card = TermCard(id: "1", notionURL: "", content: content, baseline: content)
        XCTAssertFalse(QuizFilter(dueOnly: true).matches(card))
    }

    func testQuizFilterSearchesDefinitionAndTags() {
        let content = TermContent(term: "Basis", definition: "Investment in an asset", categories: ["Tax Concepts"])
        let card = TermCard(id: "1", notionURL: "", content: content, baseline: content)
        XCTAssertTrue(QuizFilter(search: "investment").matches(card))
        XCTAssertTrue(QuizFilter(search: "tax concepts").matches(card))
        XCTAssertFalse(QuizFilter(search: "software").matches(card))
    }

    func testSnapshotRoundTripsThroughJSON() throws {
        let content = TermContent(term: "Basis", status: .needsReview)
        let snapshot = StudySnapshot(cards: [
            TermCard(id: "abc", notionURL: "https://notion.so/abc", content: content, baseline: content)
        ])
        let data = try JSONEncoder.taxTerms.encode(snapshot)
        let decoded = try JSONDecoder.taxTerms.decode(StudySnapshot.self, from: data)
        XCTAssertEqual(decoded.cards.first?.id, snapshot.cards.first?.id)
        XCTAssertEqual(decoded.cards.first?.content, snapshot.cards.first?.content)
        XCTAssertEqual(decoded.settings, snapshot.settings)
    }
}
