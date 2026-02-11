// ============================================================================
// QABrowserView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Browse and search the Sound Engineer Q&A knowledge base.
//          Category grid, search bar, filter chips, article list.
//          100% offline — all content bundled with the app.
// ============================================================================

import SwiftUI


// MARK: - ─── QA Browser View ─────────────────────────────────────────────────

struct QABrowserView: View {
    @StateObject private var store = QAStore()

    var body: some View {
        ZStack {
            BoothColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ── Search ──
                    searchBar

                    // ── Filter Chips ──
                    filterChipsBar

                    if store.searchQuery.isEmpty && !store.hasActiveFilters {
                        // ── Category Grid ──
                        categoryGrid

                        // ── Getting Started ──
                        gettingStartedSection
                    } else {
                        // ── Results ──
                        resultsSection
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Sound Engineer Q&A")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear {
            store.loadContent()
        }
    }


    // MARK: - ─── Search Bar ──────────────────────────────────────────────────

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textMuted)

            TextField("Search articles...", text: $store.searchQuery)
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textPrimary)
                .textFieldStyle(.plain)

            if !store.searchQuery.isEmpty {
                Button {
                    store.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(BoothColors.textMuted)
                }
            }
        }
        .padding(12)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }


    // MARK: - ─── Filter Chips ────────────────────────────────────────────────

    private var filterChipsBar: some View {
        VStack(spacing: 8) {
            // Difficulty chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QADifficulty.allCases) { difficulty in
                        filterChip(
                            label: difficulty.rawValue,
                            isActive: store.selectedDifficulty == difficulty,
                            color: difficultyColor(difficulty)
                        ) {
                            if store.selectedDifficulty == difficulty {
                                store.selectedDifficulty = nil
                            } else {
                                store.selectedDifficulty = difficulty
                            }
                        }
                    }

                    // Console tag chips
                    if !store.availableConsoleTags.isEmpty {
                        Divider()
                            .frame(height: 20)
                            .overlay(BoothColors.divider)

                        ForEach(store.availableConsoleTags, id: \.self) { tag in
                            filterChip(
                                label: tag.uppercased(),
                                isActive: store.selectedConsoleTags.contains(tag),
                                color: BoothColors.accentWarm
                            ) {
                                if store.selectedConsoleTags.contains(tag) {
                                    store.selectedConsoleTags.remove(tag)
                                } else {
                                    store.selectedConsoleTags.insert(tag)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            // Clear All button
            if store.hasActiveFilters {
                Button {
                    store.clearAllFilters()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                        Text("Clear All Filters")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(BoothColors.accentDanger)
                }
            }
        }
    }

    private func filterChip(
        label: String,
        isActive: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(isActive ? BoothColors.background : color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? color : color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }


    // MARK: - ─── Category Grid ───────────────────────────────────────────────

    private var categoryGrid: some View {
        SectionCard(title: "Categories (\(store.articles.count) articles)") {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(QACategory.allCases) { category in
                    categoryCard(category)
                }
            }
        }
    }

    private func categoryCard(_ category: QACategory) -> some View {
        Button {
            store.selectedCategory = category
        } label: {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(BoothColors.accent)

                Text(category.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BoothColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("\(store.articleCount(for: category))")
                    .font(.system(size: 10))
                    .foregroundStyle(BoothColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }


    // MARK: - ─── Getting Started ─────────────────────────────────────────────

    private var gettingStartedSection: some View {
        SectionCard(title: "Getting Started") {
            let beginnerArticles = store.articles.filter { $0.difficulty == .beginner }.prefix(4)

            if beginnerArticles.isEmpty {
                Text("Loading content...")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(beginnerArticles)) { article in
                    NavigationLink {
                        QAArticleDetailView(article: article, store: store)
                    } label: {
                        articleRow(article)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }


    // MARK: - ─── Results ─────────────────────────────────────────────────────

    private var resultsSection: some View {
        VStack(spacing: 12) {
            // Category header with back button
            if let category = store.selectedCategory {
                HStack {
                    Button {
                        store.selectedCategory = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12))
                            Text("All Categories")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(BoothColors.accent)
                    }
                    Spacer()
                }

                SectionCard(title: "\(category.rawValue) (\(store.filteredArticles.count))") {
                    articleList
                }
            } else {
                // Search or filter results
                SectionCard(title: "Results (\(store.filteredArticles.count))") {
                    articleList
                }
            }
        }
    }

    private var articleList: some View {
        Group {
            if store.filteredArticles.isEmpty {
                emptyResults
            } else {
                ForEach(store.filteredArticles) { article in
                    NavigationLink {
                        QAArticleDetailView(article: article, store: store)
                    } label: {
                        articleRow(article)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(BoothColors.textMuted)
            Text("No articles found")
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }


    // MARK: - ─── Article Row ─────────────────────────────────────────────────

    private func articleRow(_ article: QAArticle) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(article.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BoothColors.textPrimary)
                        .lineLimit(2)

                    difficultyBadge(article.difficulty)
                }

                Text(article.summary)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
                    .lineLimit(2)

                // Console tags on article row
                if !article.consoleTags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(article.consoleTags.prefix(3), id: \.self) { tag in
                            Text(tag.uppercased())
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(BoothColors.accentWarm)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(BoothColors.accentWarm.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(BoothColors.textMuted)
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func difficultyBadge(_ difficulty: QADifficulty) -> some View {
        let color = difficultyColor(difficulty)

        return Text(difficulty.rawValue)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func difficultyColor(_ difficulty: QADifficulty) -> Color {
        switch difficulty {
        case .beginner:     return BoothColors.accent
        case .intermediate: return BoothColors.accentWarm
        case .advanced:     return BoothColors.accentDanger
        }
    }
}
