// ============================================================================
// DateFormatters.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Views/Components — Shared Utilities
// Purpose: Centralized static DateFormatter instances. DateFormatter init is
//          expensive (~20-30ms) — allocating in ForEach or row builders causes
//          visible jank on large lists. These statics are created once and
//          reused across the entire app.
// ============================================================================

import Foundation


// MARK: - ─── App Date Formatters ─────────────────────────────────────────────

enum AppDateFormatter {

    /// Short date for service rows: "Feb 9"
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    /// Full date for service detail: "Sunday, Feb 9, 2025"
    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f
    }()

    /// Medium date for input last-used: "Feb 9, 2025"
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    /// Date with time for snapshot names: "Feb 9, 3:30 PM"
    static let dateWithTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f
    }()

    /// Timestamp for EQ/RT60 snapshots: "3:30:15 PM"
    static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f
    }()

    /// ISO 8601 date-only for PCO date parsing: "2025-02-09"
    static let isoDateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
