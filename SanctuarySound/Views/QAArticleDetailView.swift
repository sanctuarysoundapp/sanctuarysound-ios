// ============================================================================
// QAArticleDetailView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Detail view for a single Q&A article, showing sections, tips,
//          console tags, and related articles with navigation.
// ============================================================================

import SwiftUI


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
                    articleHeader

                    Divider()
                        .overlay(BoothColors.divider)

                    // ── Sections ──
                    ForEach(Array(article.sections.enumerated()), id: \.offset) { _, section in
                        sectionView(section)
                    }

                    // ── Related Articles ──
                    relatedArticlesSection
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }


    // MARK: - ─── Header ──────────────────────────────────────────────────────

    private var articleHeader: some View {
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

            // Console tags
            if !article.consoleTags.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 10))
                        .foregroundStyle(BoothColors.textMuted)
                    ForEach(article.consoleTags, id: \.self) { tag in
                        Text(tag.uppercased())
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.accentWarm)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(BoothColors.accentWarm.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
            }
        }
    }


    // MARK: - ─── Section Content ─────────────────────────────────────────────

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


    // MARK: - ─── Related Articles ────────────────────────────────────────────

    private var relatedArticlesSection: some View {
        let related = store.relatedArticles(for: article)

        return Group {
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
    }


    // MARK: - ─── Difficulty Badge ────────────────────────────────────────────

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
