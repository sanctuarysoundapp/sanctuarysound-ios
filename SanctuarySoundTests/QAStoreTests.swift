// ============================================================================
// QAStoreTests.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Unit Tests
// Purpose: Verify QAStore filtering, searching, console tag filtering,
//          content integrity, and backward compatibility.
// ============================================================================

import XCTest
@testable import SanctuarySound


@MainActor
final class QAStoreTests: XCTestCase {

    private var store: QAStore!

    override func setUp() {
        super.setUp()
        store = QAStore()
        store.loadContent()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }


    // MARK: - ─── Content Integrity ────────────────────────────────────────────

    func testArticleCountMinimum() {
        XCTAssertGreaterThanOrEqual(
            store.articles.count, 40,
            "Knowledge base should have at least 40 articles, found \(store.articles.count)"
        )
    }

    func testAllArticleIDsUnique() {
        let ids = store.articles.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "Article IDs must be unique")
    }

    func testNewCategoriesExist() {
        let categories = Set(store.articles.map { $0.category })
        XCTAssertTrue(categories.contains(.mixerSetup), "Missing .mixerSetup category articles")
        XCTAssertTrue(categories.contains(.troubleshooting), "Missing .troubleshooting category articles")
        XCTAssertTrue(categories.contains(.advancedTechniques), "Missing .advancedTechniques category articles")
    }

    func testAllCategoriesHaveArticles() {
        for category in QACategory.allCases {
            let count = store.articleCount(for: category)
            XCTAssertGreaterThan(count, 0, "\(category.rawValue) should have at least 1 article")
        }
    }


    // MARK: - ─── Category Filtering ──────────────────────────────────────────

    func testFilterByCategory() {
        store.selectedCategory = .gainStaging
        let results = store.filteredArticles
        XCTAssertFalse(results.isEmpty, "Gain Staging should have articles")
        XCTAssertTrue(results.allSatisfy { $0.category == .gainStaging })
    }

    func testFilterByDifficulty() {
        store.selectedDifficulty = .beginner
        let results = store.filteredArticles
        XCTAssertFalse(results.isEmpty, "Should have beginner articles")
        XCTAssertTrue(results.allSatisfy { $0.difficulty == .beginner })
    }


    // MARK: - ─── Console Tag Filtering ───────────────────────────────────────

    func testFilterByConsoleTag() {
        store.selectedConsoleTags = ["avantis"]
        let results = store.filteredArticles
        XCTAssertFalse(results.isEmpty, "Should have Avantis-tagged articles")
        XCTAssertTrue(results.allSatisfy { $0.consoleTags.contains("avantis") })
    }

    func testCompositeFiltering() {
        store.selectedCategory = .mixerSetup
        store.selectedDifficulty = .beginner
        let results = store.filteredArticles
        XCTAssertTrue(results.allSatisfy {
            $0.category == .mixerSetup && $0.difficulty == .beginner
        })
    }

    func testAvailableConsoleTags() {
        let tags = store.availableConsoleTags
        XCTAssertFalse(tags.isEmpty, "Should have console tags")
        // Tags should be sorted
        XCTAssertEqual(tags, tags.sorted(), "Console tags should be sorted alphabetically")
    }


    // MARK: - ─── Search ─────────────────────────────────────────────────────

    func testSearchIncludesConsoleTags() {
        store.searchQuery = "avantis"
        let results = store.filteredArticles
        XCTAssertFalse(results.isEmpty, "Search for 'avantis' should find tagged articles")
    }

    func testSearchByTitle() {
        store.searchQuery = "gain staging"
        let results = store.filteredArticles
        XCTAssertFalse(results.isEmpty, "Search for 'gain staging' should find articles")
    }


    // MARK: - ─── Filter State ────────────────────────────────────────────────

    func testHasActiveFilters() {
        XCTAssertFalse(store.hasActiveFilters, "No filters should be active initially")

        store.selectedCategory = .eq
        XCTAssertTrue(store.hasActiveFilters, "Category filter should be active")

        store.clearAllFilters()
        XCTAssertFalse(store.hasActiveFilters, "Filters should be cleared")
        XCTAssertTrue(store.searchQuery.isEmpty)
        XCTAssertNil(store.selectedCategory)
        XCTAssertNil(store.selectedDifficulty)
        XCTAssertTrue(store.selectedConsoleTags.isEmpty)
    }


    // MARK: - ─── Related Articles ───────────────────────────────────────────

    func testRelatedArticlesResolution() {
        guard let article = store.articles.first(where: { !$0.relatedArticles.isEmpty }) else {
            XCTFail("Should have at least one article with related articles")
            return
        }
        let related = store.relatedArticles(for: article)
        XCTAssertFalse(related.isEmpty, "Related articles should resolve to actual articles")
    }


    // MARK: - ─── Backward Compatibility ──────────────────────────────────────

    func testBackwardCompatibleDecoding() throws {
        // JSON without consoleTags field should decode with empty array
        let json = """
        {
            "id": "test-article",
            "title": "Test",
            "category": "Gain Staging",
            "difficulty": "Beginner",
            "summary": "Test summary",
            "sections": [],
            "tags": ["test"],
            "relatedArticles": []
        }
        """
        let data = json.data(using: .utf8)!
        let article = try JSONDecoder().decode(QAArticle.self, from: data)
        XCTAssertEqual(article.consoleTags, [], "Missing consoleTags should default to empty array")
    }
}
