// ============================================================================
// AudioConstants.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Models
// Purpose: Central reference values for the entire audio engine.
// ============================================================================

import Foundation

// MARK: - ─── Core Constants ───────────────────────────────────────────────

/// Central reference values for the entire audio engine.
struct AudioConstants {
    /// Nominal operating level. All gain calculations target this.
    static let nominalLevelDBFS: Double = -18.0

    /// Maximum headroom above nominal before digital clip (0 dBFS).
    static let headroomDB: Double = 18.0

    /// Default High-Pass Filter frequency (Hz) when no specific recommendation applies.
    static let defaultHPF: Double = 80.0

    /// A4 tuning reference (Hz) — used for key-to-frequency conversion.
    static let a4Reference: Double = 440.0
}
