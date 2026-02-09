// ============================================================================
// QABrowserView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Browse and search the Sound Engineer Q&A knowledge base.
//          Category grid, search bar, article list, and article detail view.
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

                    if store.searchQuery.isEmpty && store.selectedCategory == nil {
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


    // MARK: - ─── Category Grid ───────────────────────────────────────────────

    private var categoryGrid: some View {
        SectionCard(title: "Categories") {
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

                Text("\(store.articleCount(for: category)) articles")
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
            } else {
                // Search results
                SectionCard(title: "Results (\(store.filteredArticles.count))") {
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
        let color: Color = {
            switch difficulty {
            case .beginner:     return BoothColors.accent
            case .intermediate: return BoothColors.accentWarm
            case .advanced:     return BoothColors.accentDanger
            }
        }()

        return Text(difficulty.rawValue)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}


// MARK: - ─── Article Detail View ─────────────────────────────────────────────

struct QAArticleDetailView: View {
    let article: QAArticle
    let store: QAStore

    var body: some View {
        ZStack {
            BoothColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // ── Header ──
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(article.category.rawValue)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(BoothColors.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BoothColors.accent.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 3))

                            difficultyBadge(article.difficulty)
                        }

                        Text(article.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(BoothColors.textPrimary)

                        Text(article.summary)
                            .font(.system(size: 14))
                            .foregroundStyle(BoothColors.textSecondary)
                            .lineSpacing(2)
                    }

                    Divider()
                        .overlay(BoothColors.divider)

                    // ── Sections ──
                    ForEach(Array(article.sections.enumerated()), id: \.offset) { _, section in
                        sectionView(section)
                    }

                    // ── Related Articles ──
                    let related = store.relatedArticles(for: article)
                    if !related.isEmpty {
                        Divider()
                            .overlay(BoothColors.divider)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("RELATED")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(BoothColors.textMuted)
                                .tracking(1)

                            ForEach(related) { relatedArticle in
                                NavigationLink {
                                    QAArticleDetailView(article: relatedArticle, store: store)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: relatedArticle.category.icon)
                                            .font(.system(size: 12))
                                            .foregroundStyle(BoothColors.accent)

                                        Text(relatedArticle.title)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(BoothColors.textPrimary)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10))
                                            .foregroundStyle(BoothColors.textMuted)
                                    }
                                    .padding(10)
                                    .background(BoothColors.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func sectionView(_ section: QASection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let heading = section.heading {
                Text(heading)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BoothColors.textPrimary)
            }

            Text(section.content)
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textPrimary)
                .lineSpacing(3)

            if let tip = section.tip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.accentWarm)
                        .padding(.top, 2)

                    Text(tip)
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.textSecondary)
                        .lineSpacing(2)
                }
                .padding(10)
                .background(BoothColors.accentWarm.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func difficultyBadge(_ difficulty: QADifficulty) -> some View {
        let color: Color = {
            switch difficulty {
            case .beginner:     return BoothColors.accent
            case .intermediate: return BoothColors.accentWarm
            case .advanced:     return BoothColors.accentDanger
            }
        }()

        return Text(difficulty.rawValue)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
