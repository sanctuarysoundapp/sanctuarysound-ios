// ============================================================================
// AppLogger.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Config / Infrastructure
// Purpose: Centralized logging for SanctuarySound using Apple's unified
//          logging system (OSLog). Each subsystem category maps to an
//          architectural layer so logs can be filtered in Console.app.
// Usage: Logger.persistence.error("Failed to save: \(error.localizedDescription)")
// ============================================================================

import OSLog

// MARK: - ─── App Logger Categories ────────────────────────────────────────

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.sanctuarysound.app"

    /// Persistence layer — JSON file reads/writes, migration
    static let persistence = Logger(subsystem: subsystem, category: "persistence")

    /// Network layer — PCO API, mixer TCP connections
    static let network = Logger(subsystem: subsystem, category: "network")

    /// Audio layer — SPL metering, EQ analysis, RT60 measurement
    static let audio = Logger(subsystem: subsystem, category: "audio")

    /// Engine layer — recommendation calculations, analysis
    static let engine = Logger(subsystem: subsystem, category: "engine")

    /// Connectivity — WatchConnectivity session management
    static let connectivity = Logger(subsystem: subsystem, category: "connectivity")
}
