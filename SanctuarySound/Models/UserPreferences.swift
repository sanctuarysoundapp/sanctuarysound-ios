// ============================================================================
// UserPreferences.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Model Layer
// Purpose: User-configurable defaults for mixer, band, room, and appearance.
//          Persisted via ServiceStore as JSON. All new services inherit these
//          defaults so volunteers don't have to re-enter common settings.
// ============================================================================

import Foundation


// MARK: - ─── User Preferences ─────────────────────────────────────────────

struct UserPreferences: Codable, Equatable {

    // ── Service Defaults ──

    var defaultMixer: MixerModel = .allenHeathAvantis
    var defaultExperienceLevel: ExperienceLevel = .intermediate
    var defaultBandComposition: BandComposition = .live
    var defaultDrumConfig: DrumConfiguration = .openStage
    var defaultRoomSize: RoomSize = .medium
    var defaultRoomSurface: RoomSurface = .mixed
    var defaultTargetSPL: Double = 90.0

    // ── PCO Import ──

    var preferredDrumTemplate: DrumKitTemplate = .standard5

    // ── Appearance ──

    var colorTheme: ColorThemeID = .darkBooth

    // ── Backward-Compatible Decoder ──

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultMixer = try container.decodeIfPresent(MixerModel.self, forKey: .defaultMixer) ?? .allenHeathAvantis
        defaultExperienceLevel = try container.decodeIfPresent(ExperienceLevel.self, forKey: .defaultExperienceLevel) ?? .intermediate
        defaultBandComposition = try container.decodeIfPresent(BandComposition.self, forKey: .defaultBandComposition) ?? .live
        defaultDrumConfig = try container.decodeIfPresent(DrumConfiguration.self, forKey: .defaultDrumConfig) ?? .openStage
        defaultRoomSize = try container.decodeIfPresent(RoomSize.self, forKey: .defaultRoomSize) ?? .medium
        defaultRoomSurface = try container.decodeIfPresent(RoomSurface.self, forKey: .defaultRoomSurface) ?? .mixed
        defaultTargetSPL = try container.decodeIfPresent(Double.self, forKey: .defaultTargetSPL) ?? 90.0
        preferredDrumTemplate = try container.decodeIfPresent(DrumKitTemplate.self, forKey: .preferredDrumTemplate) ?? .standard5
        colorTheme = try container.decodeIfPresent(ColorThemeID.self, forKey: .colorTheme) ?? .darkBooth
    }
}


// MARK: - ─── Color Theme ID ──────────────────────────────────────────────

/// Identifies which booth-friendly color theme to apply.
/// All themes are dark — designed for sound booth use during live services.
enum ColorThemeID: String, CaseIterable, Identifiable, Codable {
    case darkBooth    = "Dark Booth"
    case midnightBlue = "Midnight Blue"
    case warmAmber    = "Warm Amber"
    case forestCanopy = "Forest Canopy"
    case volcanic     = "Volcanic Wonder"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .darkBooth:    return String(localized: "Northern Lights")
        case .midnightBlue: return String(localized: "Ocean Depths")
        case .warmAmber:    return String(localized: "Arctic Serenity")
        case .forestCanopy: return String(localized: "Forest Canopy")
        case .volcanic:     return String(localized: "Volcanic Wonder")
        }
    }

    var icon: String {
        switch self {
        case .darkBooth:    return "sparkles"
        case .midnightBlue: return "water.waves"
        case .warmAmber:    return "snowflake"
        case .forestCanopy: return "leaf.fill"
        case .volcanic:     return "flame.fill"
        }
    }

    var localizedName: String {
        displayName
    }

    var description: String {
        switch self {
        case .darkBooth:    return "Classic dark palette with green accents"
        case .midnightBlue: return "Blue-tinted dark palette for low-light booths"
        case .warmAmber:    return "Deep purple-tinted palette — cool and calm"
        case .forestCanopy: return "Nature-inspired dark green palette"
        case .volcanic:     return "Dark charcoal with warm ember undertones"
        }
    }
}
