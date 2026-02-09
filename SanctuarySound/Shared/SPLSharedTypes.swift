// ============================================================================
// SPLSharedTypes.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Shared Model Layer (iOS + watchOS)
// Purpose: SPL-related types shared between the iPhone app and the Apple Watch
//          companion. Extracted from ServiceModels.swift so both targets can
//          compile these types without pulling the entire model layer.
// ============================================================================

import Foundation


// MARK: - ─── SPL Configuration ───────────────────────────────────────────────

/// User's preferred SPL target and flagging behavior.
struct SPLPreference: Codable {
    var targetDB: Double                // e.g., 90.0
    var flaggingMode: SPLFlaggingMode
    var calibrationOffset: Double?      // dBFS-to-SPL offset from calibration

    init(
        targetDB: Double = 90.0,
        flaggingMode: SPLFlaggingMode = .balanced,
        calibrationOffset: Double? = nil
    ) {
        self.targetDB = targetDB
        self.flaggingMode = flaggingMode
        self.calibrationOffset = calibrationOffset
    }

    /// Threshold above target that triggers a flag, based on mode.
    var flagThresholdDB: Double {
        flaggingMode.thresholdDB
    }
}

enum SPLFlaggingMode: String, CaseIterable, Identifiable, Codable {
    case strict     = "Strict"
    case balanced   = "Balanced"
    case variable   = "Variable"

    var id: String { rawValue }

    /// How many dB above target before flagging.
    var thresholdDB: Double {
        switch self {
        case .strict:   return 2.0
        case .balanced: return 5.0
        case .variable: return 8.0
        }
    }

    var description: String {
        switch self {
        case .strict:   return "Flag at +2 dB over target"
        case .balanced: return "Flag at +5 dB over target"
        case .variable: return "Flag at +8 dB over target"
        }
    }
}


// MARK: - ─── SPL Alert State ─────────────────────────────────────────────────

/// Represents the current SPL alert level relative to user preferences.
/// Used to drive haptics, visual pulse, and cross-tab alert banner.
enum SPLAlertState: Equatable {
    /// SPL is within the safe zone (at or below target).
    case safe
    /// SPL is over target but under the flag threshold (amber warning).
    case warning(currentDB: Int, overBy: Int)
    /// SPL exceeds the flag threshold — active alert (red danger).
    case alert(currentDB: Int, overBy: Int)

    var isActive: Bool {
        switch self {
        case .safe: return false
        case .warning, .alert: return true
        }
    }

    var isDanger: Bool {
        if case .alert = self { return true }
        return false
    }
}


// MARK: - ─── SPL Breach Log ──────────────────────────────────────────────────

/// A single recorded instance of the SPL exceeding the user's target.
struct SPLBreachEvent: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date
    let peakDB: Double          // Highest dB during this breach
    let targetDB: Double        // What the target was at time of breach
    let thresholdDB: Double     // What the flag threshold was

    init(
        startTime: Date,
        endTime: Date,
        peakDB: Double,
        targetDB: Double,
        thresholdDB: Double
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.peakDB = peakDB
        self.targetDB = targetDB
        self.thresholdDB = thresholdDB
    }

    /// Duration in seconds.
    var durationSeconds: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    /// How far over target the peak was.
    var overTargetDB: Double {
        peakDB - targetDB
    }

    /// Whether this breach exceeded the flag threshold (danger level).
    var wasDanger: Bool {
        peakDB > targetDB + thresholdDB
    }
}


/// Summary of SPL behavior across a monitoring session (one service).
struct SPLSessionReport: Codable, Identifiable {
    let id: UUID
    let date: Date
    let sessionStart: Date
    let sessionEnd: Date
    let targetDB: Double
    let flaggingMode: SPLFlaggingMode
    let breachEvents: [SPLBreachEvent]
    let overallPeakDB: Double
    let overallAverageDB: Double
    let totalMonitoringSeconds: TimeInterval

    init(
        date: Date = Date(),
        sessionStart: Date,
        sessionEnd: Date,
        targetDB: Double,
        flaggingMode: SPLFlaggingMode,
        breachEvents: [SPLBreachEvent],
        overallPeakDB: Double,
        overallAverageDB: Double,
        totalMonitoringSeconds: TimeInterval
    ) {
        self.id = UUID()
        self.date = date
        self.sessionStart = sessionStart
        self.sessionEnd = sessionEnd
        self.targetDB = targetDB
        self.flaggingMode = flaggingMode
        self.breachEvents = breachEvents
        self.overallPeakDB = overallPeakDB
        self.overallAverageDB = overallAverageDB
        self.totalMonitoringSeconds = totalMonitoringSeconds
    }

    /// Total number of breach events.
    var breachCount: Int { breachEvents.count }

    /// How many were danger-level breaches.
    var dangerCount: Int { breachEvents.filter(\.wasDanger).count }

    /// Total time spent over target.
    var totalBreachSeconds: TimeInterval {
        breachEvents.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Percentage of monitoring time spent over target.
    var breachPercentage: Double {
        guard totalMonitoringSeconds > 0 else { return 0 }
        return (totalBreachSeconds / totalMonitoringSeconds) * 100
    }

    /// Longest single breach event duration.
    var longestBreachSeconds: TimeInterval {
        breachEvents.map(\.durationSeconds).max() ?? 0
    }
}


// MARK: - ─── Localized Display Names ────────────────────────────────────────

extension SPLFlaggingMode {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}
