// ============================================================================
// QAStore.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Store Layer
// Purpose: Loads and manages the Sound Engineer Q&A knowledge base.
//          Reads bundled JSON content, provides search and filtering,
//          and publishes results for the QABrowserView.
// ============================================================================

import Foundation


// MARK: - ─── QA Store ────────────────────────────────────────────────────────

/// Manages the Q&A knowledge base — loading, searching, and filtering articles.
@MainActor
final class QAStore: ObservableObject {

    // ── Published State ──
    @Published private(set) var articles: [QAArticle] = []
    @Published var searchQuery: String = ""
    @Published var selectedCategory: QACategory?
    @Published var selectedDifficulty: QADifficulty?
    @Published var selectedConsoleTags: Set<String> = []

    /// Filtered articles based on current search/filter state.
    var filteredArticles: [QAArticle] {
        var results = articles

        // Filter by category
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        // Filter by difficulty
        if let difficulty = selectedDifficulty {
            results = results.filter { $0.difficulty == difficulty }
        }

        // Filter by console tags
        if !selectedConsoleTags.isEmpty {
            results = results.filter { article in
                !article.consoleTags.isEmpty
                && !selectedConsoleTags.isDisjoint(with: article.consoleTags)
            }
        }

        // Search
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            results = results.filter { article in
                article.title.lowercased().contains(query)
                || article.summary.lowercased().contains(query)
                || article.tags.contains { $0.lowercased().contains(query) }
                || article.consoleTags.contains { $0.lowercased().contains(query) }
                || article.sections.contains { section in
                    section.content.lowercased().contains(query)
                    || (section.heading?.lowercased().contains(query) ?? false)
                }
            }
        }

        return results
    }

    /// Whether any filter is currently active.
    var hasActiveFilters: Bool {
        selectedCategory != nil
        || selectedDifficulty != nil
        || !selectedConsoleTags.isEmpty
    }

    /// Sorted unique console tags from all articles.
    var availableConsoleTags: [String] {
        let allTags = articles.flatMap { $0.consoleTags }
        return Array(Set(allTags)).sorted()
    }

    /// Articles grouped by category (for browse view).
    var articlesByCategory: [QACategory: [QAArticle]] {
        Dictionary(grouping: articles, by: { $0.category })
    }

    /// Count of articles per category.
    func articleCount(for category: QACategory) -> Int {
        articles.filter { $0.category == category }.count
    }

    /// Find related articles for a given article.
    func relatedArticles(for article: QAArticle) -> [QAArticle] {
        article.relatedArticles.compactMap { relatedID in
            articles.first { $0.id == relatedID }
        }
    }

    /// Clear all filters and search query.
    func clearAllFilters() {
        searchQuery = ""
        selectedCategory = nil
        selectedDifficulty = nil
        selectedConsoleTags = []
    }


    // MARK: - ─── Loading ─────────────────────────────────────────────────────

    /// Load articles from the bundled JSON file. Skips reload if already populated.
    func loadContent() {
        guard articles.isEmpty else { return }

        guard let url = Bundle.main.url(forResource: "qa_content", withExtension: "json") else {
            // If no JSON file, load built-in content
            articles = QABuiltInContent.allArticles
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([QAArticle].self, from: data)
            articles = decoded
        } catch {
            // Fallback to built-in content
            articles = QABuiltInContent.allArticles
        }
    }
}
