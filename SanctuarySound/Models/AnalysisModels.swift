// ============================================================================
// AnalysisModels.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Models
// Purpose: Mixer snapshot types (imported state) and delta analysis output
//          for comparing actual vs recommended settings.
// ============================================================================

import Foundation

// MARK: - ─── Mixer Snapshot (Imported State) ─────────────────────────────────

/// The actual state of a mixer channel as imported from CSV or TCP/MIDI.
/// Used for delta analysis against engine recommendations.
struct ChannelSnapshot: Codable, Identifiable {
    let id: UUID
    var channelNumber: Int              // Physical channel on the mixer (1-64)
    var name: String                    // Channel name from mixer
    var gainDB: Double?                 // Current preamp gain
    var faderDB: Double?                // Current fader position
    var hpfFrequency: Double?           // Current HPF setting (nil = bypassed)
    var hpfEnabled: Bool
    var eqBands: [SnapshotEQBand]       // Current EQ state
    var compThresholdDB: Double?        // Current compressor threshold
    var compRatio: Double?
    var compAttackMS: Double?
    var compReleaseMS: Double?
    var phantomPower: Bool
    var padEnabled: Bool

    init(
        id: UUID = UUID(),
        channelNumber: Int = 1,
        name: String = "",
        gainDB: Double? = nil,
        faderDB: Double? = nil,
        hpfFrequency: Double? = nil,
        hpfEnabled: Bool = false,
        eqBands: [SnapshotEQBand] = [],
        compThresholdDB: Double? = nil,
        compRatio: Double? = nil,
        compAttackMS: Double? = nil,
        compReleaseMS: Double? = nil,
        phantomPower: Bool = false,
        padEnabled: Bool = false
    ) {
        self.id = id
        self.channelNumber = channelNumber
        self.name = name
        self.gainDB = gainDB
        self.faderDB = faderDB
        self.hpfFrequency = hpfFrequency
        self.hpfEnabled = hpfEnabled
        self.eqBands = eqBands
        self.compThresholdDB = compThresholdDB
        self.compRatio = compRatio
        self.compAttackMS = compAttackMS
        self.compReleaseMS = compReleaseMS
        self.phantomPower = phantomPower
        self.padEnabled = padEnabled
    }
}

/// A single EQ band from the imported mixer state.
struct SnapshotEQBand: Codable, Identifiable {
    let id: UUID
    var frequency: Double
    var gainDB: Double
    var q: Double
    var enabled: Bool

    init(id: UUID = UUID(), frequency: Double = 1000, gainDB: Double = 0, q: Double = 1.0, enabled: Bool = true) {
        self.id = id
        self.frequency = frequency
        self.gainDB = gainDB
        self.q = q
        self.enabled = enabled
    }
}

/// A complete mixer snapshot — all channels at a point in time.
struct MixerSnapshot: Codable, Identifiable {
    let id: UUID
    var name: String                    // e.g., "Feb 8 — Pre-service"
    var importedAt: Date
    var mixer: MixerModel
    var channels: [ChannelSnapshot]

    init(
        id: UUID = UUID(),
        name: String = "Imported Snapshot",
        importedAt: Date = Date(),
        mixer: MixerModel = .allenHeathAvantis,
        channels: [ChannelSnapshot] = []
    ) {
        self.id = id
        self.name = name
        self.importedAt = importedAt
        self.mixer = mixer
        self.channels = channels
    }
}


// MARK: - ─── Delta Analysis Output ───────────────────────────────────────────

/// The result of comparing an imported mixer state against engine recommendations.
struct ChannelDelta: Identifiable {
    let id: UUID
    let channelName: String
    let channelNumber: Int
    let source: InputSource?            // Matched source (nil if unmatched)

    // ── Gain ──
    let actualGainDB: Double?
    let recommendedGainRange: ClosedRange<Double>?
    let gainStatus: DeltaStatus

    // ── Fader ──
    let actualFaderDB: Double?
    let recommendedFaderDB: Double?
    let faderStatus: DeltaStatus

    // ── HPF ──
    let actualHPF: Double?
    let recommendedHPF: Double?
    let hpfStatus: DeltaStatus

    // ── EQ ──
    let eqDeltas: [EQBandDelta]

    // ── Compression ──
    let compDelta: CompressorDelta?

    // ── Overall ──
    let overallScore: AnalysisScore
    let suggestions: [String]
}

/// Status of a single parameter comparison.
enum DeltaStatus: String {
    case optimal    = "Optimal"         // Within recommended range
    case close      = "Close"           // Within 3 dB of range
    case attention  = "Needs Attention" // More than 3 dB off
    case missing    = "No Data"         // Missing from import or recommendation

    var color: String {
        switch self {
        case .optimal:   return "accent"
        case .close:     return "accentWarm"
        case .attention: return "accentDanger"
        case .missing:   return "textMuted"
        }
    }
}

/// Delta for a single EQ band.
struct EQBandDelta: Identifiable {
    let id: UUID
    let frequency: Double
    let actualGainDB: Double
    let recommendedGainDB: Double
    let deltaDB: Double                 // actual - recommended
    let suggestion: String

    init(
        id: UUID = UUID(),
        frequency: Double,
        actualGainDB: Double,
        recommendedGainDB: Double,
        suggestion: String = ""
    ) {
        self.id = id
        self.frequency = frequency
        self.actualGainDB = actualGainDB
        self.recommendedGainDB = recommendedGainDB
        self.deltaDB = actualGainDB - recommendedGainDB
        self.suggestion = suggestion
    }
}

/// Delta for compressor settings.
struct CompressorDelta: Identifiable {
    let id: UUID
    let actualThreshold: Double?
    let recommendedThreshold: Double?
    let actualRatio: Double?
    let recommendedRatio: Double?
    let thresholdStatus: DeltaStatus
    let ratioStatus: DeltaStatus
    let suggestion: String

    init(
        id: UUID = UUID(),
        actualThreshold: Double? = nil,
        recommendedThreshold: Double? = nil,
        actualRatio: Double? = nil,
        recommendedRatio: Double? = nil,
        thresholdStatus: DeltaStatus = .missing,
        ratioStatus: DeltaStatus = .missing,
        suggestion: String = ""
    ) {
        self.id = id
        self.actualThreshold = actualThreshold
        self.recommendedThreshold = recommendedThreshold
        self.actualRatio = actualRatio
        self.recommendedRatio = recommendedRatio
        self.thresholdStatus = thresholdStatus
        self.ratioStatus = ratioStatus
        self.suggestion = suggestion
    }
}

/// Overall analysis score for a channel.
enum AnalysisScore: String, Codable {
    case excellent  = "Excellent"       // All params optimal
    case good       = "Good"            // Most params in range
    case fair       = "Fair"            // Some attention needed
    case poor       = "Needs Work"      // Multiple issues

    var emoji: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good:      return "checkmark.circle"
        case .fair:      return "exclamationmark.triangle"
        case .poor:      return "xmark.circle"
        }
    }
}

/// Complete analysis result for the whole mixer.
struct MixerAnalysis: Identifiable {
    let id: UUID
    let snapshot: MixerSnapshot
    let recommendation: MixerSettingRecommendation
    let channelDeltas: [ChannelDelta]
    let overallScore: AnalysisScore
    let splEstimate: SPLEstimate?
    let globalSuggestions: [String]
    let analyzedAt: Date

    init(
        id: UUID = UUID(),
        snapshot: MixerSnapshot,
        recommendation: MixerSettingRecommendation,
        channelDeltas: [ChannelDelta],
        overallScore: AnalysisScore = .good,
        splEstimate: SPLEstimate? = nil,
        globalSuggestions: [String] = [],
        analyzedAt: Date = Date()
    ) {
        self.id = id
        self.snapshot = snapshot
        self.recommendation = recommendation
        self.channelDeltas = channelDeltas
        self.overallScore = overallScore
        self.splEstimate = splEstimate
        self.globalSuggestions = globalSuggestions
        self.analyzedAt = analyzedAt
    }
}

/// Estimated SPL at the measurement point.
struct SPLEstimate {
    let estimatedPeakDB: Double         // Estimated peak SPL during loudest moment
    let targetDB: Double                // User's target
    let deltaDB: Double                 // estimated - target (positive = over)
    let flagged: Bool                   // Exceeds threshold for user's flagging mode
    let message: String
}


// MARK: - ─── Localized Display Names ────────────────────────────────────────

extension DeltaStatus {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension AnalysisScore {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}
