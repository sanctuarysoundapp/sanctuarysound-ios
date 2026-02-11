// ============================================================================
// QAContent.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Data Layer
// Purpose: Data models for the Sound Engineer Q&A knowledge base. Defines
//          articles, categories, sections, and search-related types.
//          Content is bundled as JSON and loaded at runtime.
// ============================================================================

import Foundation


// MARK: - ─── Q&A Category ────────────────────────────────────────────────────

/// Categories for organizing Q&A articles.
enum QACategory: String, CaseIterable, Codable, Identifiable {
    case gainStaging        = "Gain Staging"
    case eq                 = "EQ Basics"
    case compression        = "Compression"
    case feedback           = "Feedback Control"
    case monitors           = "Monitor Mixing"
    case roomAcoustics      = "Room Acoustics"
    case vocals             = "Vocal Mixing"
    case instruments        = "Instrument Mixing"
    case mixerSetup         = "Mixer Setup"
    case troubleshooting    = "Troubleshooting"
    case advancedTechniques = "Advanced Techniques"

    var id: String { rawValue }

    /// SF Symbol icon for the category.
    var icon: String {
        switch self {
        case .gainStaging:        return "slider.vertical.3"
        case .eq:                 return "waveform"
        case .compression:        return "rectangle.compress.vertical"
        case .feedback:           return "speaker.wave.3.fill"
        case .monitors:           return "headphones"
        case .roomAcoustics:      return "building.2"
        case .vocals:             return "mic.fill"
        case .instruments:        return "guitars"
        case .mixerSetup:         return "slider.horizontal.3"
        case .troubleshooting:    return "wrench.and.screwdriver"
        case .advancedTechniques: return "graduationcap"
        }
    }

    /// Short description for the category card.
    var summary: String {
        switch self {
        case .gainStaging:        return "Setting levels, headroom, and signal flow"
        case .eq:                 return "Frequency shaping, cuts, boosts, and filters"
        case .compression:        return "Dynamic range control and leveling"
        case .feedback:           return "Preventing and eliminating feedback"
        case .monitors:           return "In-ear monitors and stage sound"
        case .roomAcoustics:      return "Room behavior, reverb, and treatment"
        case .vocals:             return "Mixing vocals for clarity and presence"
        case .instruments:        return "Drums, guitar, bass, and keys mixing"
        case .mixerSetup:         return "Console-specific setup and configuration"
        case .troubleshooting:    return "Diagnosing and fixing common problems"
        case .advancedTechniques: return "Deep techniques for experienced engineers"
        }
    }
}


// MARK: - ─── Q&A Article ─────────────────────────────────────────────────────

/// A single Q&A article in the knowledge base.
struct QAArticle: Codable, Identifiable {
    /// Slug-style identifier (e.g., "gain-staging-basics").
    let id: String
    let title: String
    let category: QACategory
    let difficulty: QADifficulty
    /// 1-2 sentence summary for list views.
    let summary: String
    /// Structured body content.
    let sections: [QASection]
    /// Search tags for discoverability.
    let tags: [String]
    /// IDs of related articles.
    let relatedArticles: [String]
    /// Console-specific tags (e.g., "avantis", "x32") for filtering.
    let consoleTags: [String]

    /// Backward-compatible initializer for articles without consoleTags.
    init(
        id: String,
        title: String,
        category: QACategory,
        difficulty: QADifficulty,
        summary: String,
        sections: [QASection],
        tags: [String],
        relatedArticles: [String],
        consoleTags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.difficulty = difficulty
        self.summary = summary
        self.sections = sections
        self.tags = tags
        self.relatedArticles = relatedArticles
        self.consoleTags = consoleTags
    }

    enum CodingKeys: String, CodingKey {
        case id, title, category, difficulty, summary, sections, tags, relatedArticles, consoleTags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(QACategory.self, forKey: .category)
        difficulty = try container.decode(QADifficulty.self, forKey: .difficulty)
        summary = try container.decode(String.self, forKey: .summary)
        sections = try container.decode([QASection].self, forKey: .sections)
        tags = try container.decode([String].self, forKey: .tags)
        relatedArticles = try container.decode([String].self, forKey: .relatedArticles)
        consoleTags = try container.decodeIfPresent([String].self, forKey: .consoleTags) ?? []
    }
}


// MARK: - ─── Q&A Section ─────────────────────────────────────────────────────

/// A section within a Q&A article body.
struct QASection: Codable {
    /// Optional heading for the section.
    let heading: String?
    /// Main body text.
    let content: String
    /// Optional callout tip.
    let tip: String?
}


// MARK: - ─── Q&A Difficulty ──────────────────────────────────────────────────

/// Difficulty level for Q&A articles, aligned with the app's experience levels.
enum QADifficulty: String, CaseIterable, Codable, Identifiable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"

    var id: String { rawValue }

    /// Badge color name for display.
    var badgeColorName: String {
        switch self {
        case .beginner:     return "accent"       // green
        case .intermediate: return "accentWarm"   // amber
        case .advanced:     return "accentDanger"  // red
        }
    }
}
