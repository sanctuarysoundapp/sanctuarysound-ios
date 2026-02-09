// ============================================================================
// RecommendationModels.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Models
// Purpose: Engine output types — channel recommendations, EQ bands,
//          compressor settings, key warnings, and top-level results.
// ============================================================================

import Foundation

// MARK: - ─── Engine Output Models ─────────────────────────────────────────

/// The complete recommendation for a single channel.
struct ChannelRecommendation: Identifiable {
    let id: UUID
    let channel: InputChannel

    // ── Gain Staging ──
    let gainRangeDB: ClosedRange<Double>    // Recommended preamp gain range
    let faderStartDB: Double                 // Suggested fader position
    let headroomDB: Double                   // Available headroom at recommended gain

    // ── High-Pass Filter ──
    let hpfFrequency: Double?               // Recommended HPF (nil = bypass)

    // ── EQ Bands ──
    let eqBands: [EQRecommendation]         // Sorted by frequency, low to high

    // ── Dynamics ──
    let compressor: CompressorRecommendation?

    // ── Key-Aware Warnings ──
    let keyWarnings: [KeyWarning]

    // ── Contextual Notes ──
    let notes: [String]                     // Human-readable tips
}

/// A single EQ band recommendation.
struct EQRecommendation: Identifiable {
    let id: UUID
    var frequency: Double       // Center frequency (Hz)
    var gainDB: Double          // Boost (+) or cut (-) in dB
    var q: Double               // Bandwidth (Q factor)
    var type: EQBandType
    var reason: String          // e.g., "Reduce boxiness" or "Key of E buildup"

    init(
        id: UUID = UUID(),
        frequency: Double,
        gainDB: Double,
        q: Double = 2.0,
        type: EQBandType = .parametric,
        reason: String = ""
    ) {
        self.id = id
        self.frequency = frequency
        self.gainDB = gainDB
        self.q = q
        self.type = type
        self.reason = reason
    }
}

enum EQBandType: String, Codable {
    case lowShelf       = "Low Shelf"
    case highShelf      = "High Shelf"
    case parametric     = "Parametric (Bell)"
    case highPass       = "High-Pass"
    case lowPass        = "Low-Pass"
    case notch          = "Notch"
}

/// Compressor recommendation for a single channel.
struct CompressorRecommendation: Identifiable {
    let id: UUID
    var thresholdDB: Double     // Threshold in dBFS
    var ratio: Double           // e.g., 3.0 = 3:1
    var attackMS: Double        // Attack time in milliseconds
    var releaseMS: Double       // Release time in milliseconds
    var makeupGainDB: Double    // Makeup gain
    var reason: String

    init(
        id: UUID = UUID(),
        thresholdDB: Double,
        ratio: Double,
        attackMS: Double,
        releaseMS: Double,
        makeupGainDB: Double = 0.0,
        reason: String = ""
    ) {
        self.id = id
        self.thresholdDB = thresholdDB
        self.ratio = ratio
        self.attackMS = attackMS
        self.releaseMS = releaseMS
        self.makeupGainDB = makeupGainDB
        self.reason = reason
    }
}

/// A key-aware warning about potential frequency conflicts.
struct KeyWarning: Identifiable {
    let id: UUID
    let song: SetlistSong
    let conflictFrequency: Double
    let affectedSource: InputSource
    let severity: WarningSeverity
    let suggestion: String

    init(
        id: UUID = UUID(),
        song: SetlistSong,
        conflictFrequency: Double,
        affectedSource: InputSource,
        severity: WarningSeverity = .moderate,
        suggestion: String
    ) {
        self.id = id
        self.song = song
        self.conflictFrequency = conflictFrequency
        self.affectedSource = affectedSource
        self.severity = severity
        self.suggestion = suggestion
    }
}

enum WarningSeverity: String, Codable {
    case low        = "Info"
    case moderate   = "Watch"
    case high       = "Alert"
}

/// The top-level output from the SoundEngine for an entire service.
struct MixerSettingRecommendation: Identifiable {
    let id: UUID
    let service: WorshipService
    let channelRecommendations: [ChannelRecommendation]
    let globalNotes: [String]
    let generatedAt: Date

    init(
        id: UUID = UUID(),
        service: WorshipService,
        channelRecommendations: [ChannelRecommendation],
        globalNotes: [String] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.service = service
        self.channelRecommendations = channelRecommendations
        self.globalNotes = globalNotes
        self.generatedAt = generatedAt
    }
}


// MARK: - ─── Localized Display Names ────────────────────────────────────────

extension EQBandType {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension WarningSeverity {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}
