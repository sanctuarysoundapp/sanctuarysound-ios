// ============================================================================
// WatchConnectivityDTO.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Shared DTO Layer (iOS + watchOS)
// Purpose: Data transfer objects and constants for WatchConnectivity messages
//          between the iPhone and Apple Watch companion app.
// ============================================================================

import Foundation


// MARK: - ─── Message Keys ────────────────────────────────────────────────────

/// Constants for WCSession message dictionary keys.
enum WCMessageKey {
    // ── SPL Snapshot (sendMessage, ~10Hz) ──
    static let messageType = "messageType"
    static let splCurrent = "splCurrent"
    static let splPeak = "splPeak"
    static let splAverage = "splAverage"
    static let alertState = "alertState"
    static let alertCurrentDB = "alertCurrentDB"
    static let alertOverBy = "alertOverBy"
    static let isRunning = "isRunning"
    static let timestamp = "timestamp"

    // ── Commands (Watch → iPhone) ──
    static let command = "command"
    static let commandStart = "start"
    static let commandStop = "stop"

    // ── Message Types ──
    static let typeSPLSnapshot = "splSnapshot"
    static let typeCommand = "command"
    static let typePreferenceUpdate = "preferenceUpdate"

    // ── Application Context Keys (preferences) ──
    static let targetDB = "targetDB"
    static let flaggingMode = "flaggingMode"
    static let themeID = "themeID"
    static let calibrationOffset = "calibrationOffset"

    // ── User Info Transfer Keys (reports) ──
    static let reportData = "reportData"
}


// MARK: - ─── SPL Snapshot ────────────────────────────────────────────────────

/// A lightweight snapshot of SPL state sent from iPhone to Watch at ~10Hz.
struct SPLSnapshot: Codable {
    let currentDB: Double
    let peakDB: Double
    let averageDB: Double
    let alertState: SPLAlertStateCodable
    let isRunning: Bool
    let timestamp: Date

    init(
        currentDB: Double,
        peakDB: Double,
        averageDB: Double,
        alertState: SPLAlertStateCodable,
        isRunning: Bool,
        timestamp: Date = Date()
    ) {
        self.currentDB = currentDB
        self.peakDB = peakDB
        self.averageDB = averageDB
        self.alertState = alertState
        self.isRunning = isRunning
        self.timestamp = timestamp
    }

    /// Converts to a WCSession-compatible dictionary for sendMessage().
    func toDictionary() -> [String: Any] {
        [
            WCMessageKey.messageType: WCMessageKey.typeSPLSnapshot,
            WCMessageKey.splCurrent: currentDB,
            WCMessageKey.splPeak: peakDB,
            WCMessageKey.splAverage: averageDB,
            WCMessageKey.alertState: alertState.rawValue,
            WCMessageKey.alertCurrentDB: alertState.currentDB ?? 0,
            WCMessageKey.alertOverBy: alertState.overBy ?? 0,
            WCMessageKey.isRunning: isRunning,
            WCMessageKey.timestamp: timestamp.timeIntervalSince1970
        ]
    }

    /// Reconstructs from a WCSession message dictionary.
    static func from(dictionary dict: [String: Any]) -> SPLSnapshot? {
        guard
            let current = dict[WCMessageKey.splCurrent] as? Double,
            let peak = dict[WCMessageKey.splPeak] as? Double,
            let average = dict[WCMessageKey.splAverage] as? Double,
            let alertRaw = dict[WCMessageKey.alertState] as? String,
            let isRunning = dict[WCMessageKey.isRunning] as? Bool,
            let timestampInterval = dict[WCMessageKey.timestamp] as? TimeInterval
        else { return nil }

        let alertCurrentDB = dict[WCMessageKey.alertCurrentDB] as? Int
        let alertOverBy = dict[WCMessageKey.alertOverBy] as? Int
        let alertState = SPLAlertStateCodable(
            rawValue: alertRaw,
            currentDB: alertCurrentDB,
            overBy: alertOverBy
        )

        return SPLSnapshot(
            currentDB: current,
            peakDB: peak,
            averageDB: average,
            alertState: alertState,
            isRunning: isRunning,
            timestamp: Date(timeIntervalSince1970: timestampInterval)
        )
    }
}


// MARK: - ─── SPL Alert State (Codable Wrapper) ──────────────────────────────

/// Codable wrapper for `SPLAlertState` to support WCSession serialization.
/// The original `SPLAlertState` enum has associated values, making automatic
/// Codable conformance impossible. This wrapper flattens the enum into
/// a raw string + optional associated values.
struct SPLAlertStateCodable: Codable, Equatable {
    let rawValue: String
    let currentDB: Int?
    let overBy: Int?

    /// Safe state constant.
    static let safe = SPLAlertStateCodable(rawValue: "safe", currentDB: nil, overBy: nil)

    init(rawValue: String, currentDB: Int?, overBy: Int?) {
        self.rawValue = rawValue
        self.currentDB = currentDB
        self.overBy = overBy
    }

    /// Convert from the real SPLAlertState enum.
    init(from state: SPLAlertState) {
        switch state {
        case .safe:
            self.rawValue = "safe"
            self.currentDB = nil
            self.overBy = nil
        case .warning(let db, let over):
            self.rawValue = "warning"
            self.currentDB = db
            self.overBy = over
        case .alert(let db, let over):
            self.rawValue = "alert"
            self.currentDB = db
            self.overBy = over
        }
    }

    /// Convert back to the real SPLAlertState enum.
    func toAlertState() -> SPLAlertState {
        switch rawValue {
        case "warning":
            return .warning(currentDB: currentDB ?? 0, overBy: overBy ?? 0)
        case "alert":
            return .alert(currentDB: currentDB ?? 0, overBy: overBy ?? 0)
        default:
            return .safe
        }
    }

    var isActive: Bool {
        rawValue != "safe"
    }

    var isDanger: Bool {
        rawValue == "alert"
    }
}
