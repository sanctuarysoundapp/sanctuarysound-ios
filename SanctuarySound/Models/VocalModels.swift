// ============================================================================
// VocalModels.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Models
// Purpose: Vocal profile types — range, style, mic type — driving EQ,
//          compression, and key-aware tuning decisions.
// ============================================================================

import Foundation

// MARK: - ─── Vocal Profile ────────────────────────────────────────────────

/// A detailed profile for any vocal input. This significantly affects EQ recommendations.
/// Range-based system: we care about the sound characteristics of the voice,
/// not the identity of the vocalist. Vocal range drives all frequency math.
struct VocalProfile: Codable, Identifiable {
    let id: UUID
    var range: VocalRange
    var style: VocalStyle
    var micType: MicType

    init(
        id: UUID = UUID(),
        range: VocalRange = .tenor,
        style: VocalStyle = .contemporary,
        micType: MicType = .dynamicCardioid
    ) {
        self.id = id
        self.range = range
        self.style = style
        self.micType = micType
    }

    /// Create from a saved vocalist
    init(from vocalist: SavedVocalist) {
        self.id = UUID()
        self.range = vocalist.range
        self.style = vocalist.style
        self.micType = vocalist.preferredMic
    }

    /// The fundamental frequency range for this voice type (Hz).
    /// Based purely on vocal range — the acoustic property that matters for EQ.
    var fundamentalRange: ClosedRange<Double> {
        switch range {
        case .soprano:      return 250...1050
        case .mezzoSoprano: return 200...850
        case .alto:         return 175...700
        case .tenor:        return 130...500
        case .baritone:     return 100...400
        case .bass:         return 80...330
        }
    }

    /// The "presence" frequency zone where intelligibility lives.
    var presenceZone: ClosedRange<Double> {
        switch range {
        case .soprano:      return 3000...6000
        case .mezzoSoprano: return 2800...5500
        case .alto:         return 2500...5000
        case .tenor:        return 2000...5000
        case .baritone:     return 1500...4000
        case .bass:         return 1200...3500
        }
    }

    /// Expected SPL at close-mic distance for this vocal range.
    /// Higher voices tend to produce more SPL at the mic due to projection angle.
    var expectedCloseMicSPL: Double {
        switch range {
        case .soprano:      return 108.0
        case .mezzoSoprano: return 106.0
        case .alto:         return 104.0
        case .tenor:        return 106.0
        case .baritone:     return 104.0
        case .bass:         return 102.0
        }
    }
}

enum VocalRange: String, CaseIterable, Identifiable, Codable {
    case soprano        = "Soprano"
    case mezzoSoprano   = "Mezzo-Soprano"
    case alto           = "Alto"
    case tenor          = "Tenor"
    case baritone       = "Baritone"
    case bass           = "Bass"

    var id: String { rawValue }

    /// Short label for compact UI badges
    var shortName: String {
        switch self {
        case .soprano:      return "Sop"
        case .mezzoSoprano: return "Mez"
        case .alto:         return "Alto"
        case .tenor:        return "Ten"
        case .baritone:     return "Bar"
        case .bass:         return "Bass"
        }
    }
}

enum VocalStyle: String, CaseIterable, Identifiable, Codable {
    case contemporary   = "Contemporary Worship"  // Bethel, Elevation, Hillsong
    case traditional    = "Traditional / Hymn"
    case gospel         = "Gospel"
    case choir          = "Choir Section"
    case spoken         = "Spoken Word / Preaching"

    var id: String { rawValue }

    /// Gospel singers tend to have extreme dynamic range.
    /// This factor is multiplied into the compressor threshold calculation.
    var dynamicRangeFactor: Double {
        switch self {
        case .contemporary:     return 1.0
        case .traditional:      return 0.8
        case .gospel:           return 1.4
        case .choir:            return 0.7
        case .spoken:           return 0.6
        }
    }
}

enum MicType: String, CaseIterable, Identifiable, Codable {
    case dynamicCardioid    = "Dynamic (SM58, e835)"
    case condenserCardioid  = "Condenser (KSM9, e965)"
    case condenserSDC       = "Small Diaphragm Condenser"
    case ribbon             = "Ribbon"
    case lavalier           = "Lavalier / Lapel"
    case headset            = "Headset"
    case shotgun            = "Shotgun"

    var id: String { rawValue }

    /// Sensitivity offset in dB. Dynamic mics need more gain; condensers need less.
    var sensitivityOffsetDB: Double {
        switch self {
        case .dynamicCardioid:      return 0.0    // Reference (SM58 baseline)
        case .condenserCardioid:    return -10.0   // ~10 dB hotter signal
        case .condenserSDC:         return -12.0
        case .ribbon:               return 5.0     // Lower output, needs more gain
        case .lavalier:             return -6.0
        case .headset:              return -8.0
        case .shotgun:              return -10.0
        }
    }

    /// Proximity effect severity (0.0 = none, 1.0 = severe).
    /// Affects low-frequency EQ recommendation.
    var proximityFactor: Double {
        switch self {
        case .dynamicCardioid:      return 0.8
        case .condenserCardioid:    return 0.6
        case .condenserSDC:         return 0.3
        case .ribbon:               return 0.9
        case .lavalier:             return 0.1
        case .headset:              return 0.2
        case .shotgun:              return 0.2
        }
    }
}


// MARK: - ─── Localized Display Names ────────────────────────────────────────

extension VocalRange {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension VocalStyle {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension MicType {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}
