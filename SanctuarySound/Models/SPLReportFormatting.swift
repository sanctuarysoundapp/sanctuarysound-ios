// ============================================================================
// SPLReportFormatting.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Model Extension
// Purpose: Computed grade properties and date/duration formatting for
//          SPLSessionReport. Extracted from SPLSessionReportView and
//          ReportExportView to eliminate duplication — both views now call
//          report.gradeLabel, report.gradeColor, etc.
// Note:    SPLSessionReport itself lives in Shared/SPLSharedTypes.swift
//          (multi-target). This extension is iOS-only because it imports
//          SwiftUI for Color.
// ============================================================================

import SwiftUI


// MARK: - ─── Grade Properties ─────────────────────────────────────────────────

extension SPLSessionReport {

    /// Human-readable grade label summarizing SPL behavior.
    var gradeLabel: String {
        if breachCount == 0 { return "Clean Service" }
        if dangerCount == 0 && breachPercentage < 10 { return "Good Control" }
        if breachPercentage < 20 { return "Needs Attention" }
        return "Over Target"
    }

    /// Colored circle emoji representing the grade tier.
    var gradeEmoji: String {
        if breachCount == 0 { return "\u{1F7E2}" }
        if dangerCount == 0 && breachPercentage < 10 { return "\u{1F7E1}" }
        if breachPercentage < 20 { return "\u{1F7E0}" }
        return "\u{1F534}" }

    /// SwiftUI color for the grade tier (green / amber / red).
    var gradeColor: Color {
        if breachCount == 0 { return BoothColors.accent }
        if dangerCount == 0 && breachPercentage < 10 { return BoothColors.accentWarm }
        return BoothColors.accentDanger
    }

    /// One-sentence summary of the session result.
    var gradeSummary: String {
        if breachCount == 0 {
            return "SPL stayed within target for the entire session."
        }
        let pct = String(format: "%.0f%%", breachPercentage)
        return "\(breachCount) breach\(breachCount == 1 ? "" : "es") over \(Int(targetDB)) dB target. Over target \(pct) of the time."
    }
}


// MARK: - ─── Formatters ───────────────────────────────────────────────────────

extension SPLSessionReport {

    /// Cached DateFormatter instances — created once, reused across all calls.
    private enum Formatters {
        static let sessionDate: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "EEEE, MMM d · h:mm a"
            return f
        }()

        static let time: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "h:mm:ss a"
            return f
        }()
    }

    /// Formats the session start date for display (e.g., "Sunday, Feb 9 · 10:30 AM").
    func formatSessionDate() -> String {
        Formatters.sessionDate.string(from: sessionStart)
    }

    /// Formats a timestamp to a short time string (e.g., "10:32:15 AM").
    func formatTime(_ date: Date) -> String {
        Formatters.time.string(from: date)
    }

    /// Formats a duration in seconds to a compact string (e.g., "45s", "3m 12s", "1h 5m").
    func formatDuration(_ seconds: TimeInterval) -> String {
        let secs = Int(seconds)
        if secs < 60 { return "\(secs)s" }
        let minutes = secs / 60
        let remainingSecs = secs % 60
        if minutes < 60 { return "\(minutes)m \(remainingSecs)s" }
        let hours = minutes / 60
        let remainingMins = minutes % 60
        return "\(hours)h \(remainingMins)m"
    }
}
