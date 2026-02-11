// ============================================================================
// MixerModel.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Models
// Purpose: Supported digital mixer models and their hardware-specific parameters.
// ============================================================================

import Foundation

// MARK: - ─── Mixer Ecosystem ──────────────────────────────────────────────

/// Supported digital mixer models and their hardware-specific parameters.
enum MixerModel: String, CaseIterable, Identifiable, Codable {
    case allenHeathAvantis = "Allen & Heath Avantis"
    case allenHeathSQ   = "Allen & Heath SQ"
    case allenHeathDLive = "Allen & Heath dLive"
    case behringerX32   = "Behringer X32"
    case midasM32       = "Midas M32"
    case yamahaTF       = "Yamaha TF Series"
    case yamahaCLQL     = "Yamaha CL/QL Series"
    case soundcraftSi   = "Soundcraft Si Series"
    case presonusSL     = "PreSonus StudioLive"

    var id: String { rawValue }

    /// Preamp gain range in dB (min, max).
    var gainRange: ClosedRange<Double> {
        switch self {
        case .allenHeathAvantis:                return 5...60
        case .allenHeathSQ, .allenHeathDLive:   return 0...60
        case .behringerX32, .midasM32:          return 0...60
        case .yamahaTF:                         return -6...66
        case .yamahaCLQL:                       return -6...66
        case .soundcraftSi:                     return -5...58
        case .presonusSL:                       return 0...60
        }
    }

    /// Fader scale range in dB (min represents -∞ in practice).
    var faderRange: ClosedRange<Double> {
        switch self {
        case .allenHeathAvantis:                return -120...10
        case .allenHeathSQ, .allenHeathDLive:   return -120...10
        case .behringerX32, .midasM32:          return -120...10
        case .yamahaTF:                         return -138...10
        case .yamahaCLQL:                       return -138...10
        case .soundcraftSi:                     return -120...10
        case .presonusSL:                       return -120...10
        }
    }

    /// Unity gain fader position in dB.
    var faderUnity: Double {
        return 0.0 // All supported consoles use 0 dB as unity
    }

    /// Number of parametric EQ bands available per channel.
    var eqBandCount: Int {
        switch self {
        case .allenHeathAvantis:                return 4
        case .allenHeathSQ:                     return 4
        case .allenHeathDLive:                  return 8
        case .behringerX32, .midasM32:          return 6
        case .yamahaTF:                         return 4
        case .yamahaCLQL:                       return 4
        case .soundcraftSi:                     return 4
        case .presonusSL:                       return 6
        }
    }

    /// Preamp gain (dB) needed to bring an SM58 at 94 dB SPL to the console's
    /// nominal operating level (-18 dBFS). This is mixer-specific because each
    /// console has a different internal reference level (0 dBFS-to-dBu alignment)
    /// and preamp topology.
    ///
    /// Calibrated values:
    /// - Avantis/dLive/SQ: 0 dBFS ≈ +18 dBu → need ~22 dB gain at 94 SPL
    /// - X32/M32: 0 dBFS ≈ +22 dBu → need ~28 dB gain at 94 SPL
    /// - Yamaha TF/CL/QL: 0 dBFS ≈ +24 dBu → need ~32 dB gain at 94 SPL
    /// - Others: conservative estimate ~30 dB
    var referenceGainAt94SPL: Double {
        switch self {
        case .allenHeathAvantis, .allenHeathSQ, .allenHeathDLive:
            return 22.0
        case .behringerX32, .midasM32:
            return 28.0
        case .yamahaTF, .yamahaCLQL:
            return 32.0
        case .soundcraftSi:
            return 30.0
        case .presonusSL:
            return 30.0
        }
    }

    /// Whether the console supports built-in compressor per channel.
    var hasChannelCompressor: Bool { true } // All modern digital consoles do

    /// Short display label for compact badges (e.g., InfoBadge).
    var shortName: String {
        switch self {
        case .allenHeathAvantis: return "Avantis"
        case .allenHeathSQ:     return "SQ"
        case .allenHeathDLive:  return "dLive"
        case .behringerX32:     return "X32"
        case .midasM32:         return "M32"
        case .yamahaTF:         return "TF"
        case .yamahaCLQL:       return "CL/QL"
        case .soundcraftSi:     return "Si"
        case .presonusSL:       return "SL"
        }
    }

    /// Display name for Settings picker cells (max 16 chars).
    var pickerDisplayName: String {
        switch self {
        case .allenHeathAvantis: return "A&H Avantis"
        case .allenHeathSQ:     return "A&H SQ"
        case .allenHeathDLive:  return "A&H dLive"
        case .behringerX32:     return "Behringer X32"
        case .midasM32:         return "Midas M32"
        case .yamahaTF:         return "Yamaha TF"
        case .yamahaCLQL:       return "Yamaha CL/QL"
        case .soundcraftSi:     return "Soundcraft Si"
        case .presonusSL:       return "PreSonus SL"
        }
    }
}


// MARK: - ─── Localized Display Names ────────────────────────────────────────

extension MixerModel {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}
