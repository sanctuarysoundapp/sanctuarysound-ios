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

    // ── Appearance ──

    var colorTheme: ColorThemeID = .darkBooth
}


// MARK: - ─── Color Theme ID ──────────────────────────────────────────────

/// Identifies which booth-friendly color theme to apply.
/// All themes are dark — designed for sound booth use during live services.
enum ColorThemeID: String, CaseIterable, Identifiable, Codable {
    case darkBooth    = "Dark Booth"
    case midnightBlue = "Midnight Blue"
    case warmAmber    = "Warm Amber"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .darkBooth:    return "circle.lefthalf.filled"
        case .midnightBlue: return "moon.stars.fill"
        case .warmAmber:    return "sun.dust.fill"
        }
    }

    var description: String {
        switch self {
        case .darkBooth:    return "Classic dark palette with green accents"
        case .midnightBlue: return "Blue-tinted dark palette for low-light booths"
        case .warmAmber:    return "Warm-tinted dark palette with amber glow"
        }
    }
}
