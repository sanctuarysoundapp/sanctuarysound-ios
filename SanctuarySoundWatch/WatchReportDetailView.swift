// ============================================================================
// WatchReportDetailView.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Detail view for a single SPL session report on the Watch.
// ============================================================================

import SwiftUI


// MARK: - ─── Watch Report Detail ────────────────────────────────────────────

struct WatchReportDetailView: View {
    let report: SPLSessionReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                // ── Header ──
                Text(report.date, style: .date)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(WatchColors.textPrimary)

                // ── Grade ──
                HStack {
                    Image(systemName: gradeIcon)
                        .foregroundStyle(gradeColor)
                    Text(gradeLabel)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(gradeColor)
                }

                // ── Breach Timeline Bar ──
                if report.totalMonitoringSeconds > 0 {
                    breachTimelineBar
                }

                // ── Stats ──
                coloredStatRow(label: "Peak", value: "\(Int(report.overallPeakDB)) dB", color: peakColor)
                coloredStatRow(label: "Average", value: "\(Int(report.overallAverageDB)) dB", color: averageColor)
                coloredStatRow(label: "Target", value: "\(Int(report.targetDB)) dB", color: WatchColors.textPrimary)
                coloredStatRow(label: "Breaches", value: "\(report.breachCount)", color: breachCountColor)
                coloredStatRow(label: "Danger", value: "\(report.dangerCount)", color: dangerColor)
                coloredStatRow(label: "Duration", value: formatDuration(report.totalMonitoringSeconds), color: WatchColors.textPrimary)
                coloredStatRow(label: "Over %", value: String(format: "%.1f%%", report.breachPercentage), color: overPercentColor)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Report")
    }


    // MARK: - ─── Colored Stat Row ─────────────────────────────────────────────

    private func coloredStatRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(WatchColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(WatchColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }


    // MARK: - ─── Breach Timeline Bar ──────────────────────────────────────────

    private var breachTimelineBar: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let totalSeconds = report.totalMonitoringSeconds

            ZStack(alignment: .leading) {
                // Full session background (safe = green)
                RoundedRectangle(cornerRadius: 3)
                    .fill(WatchColors.accent.opacity(0.3))
                    .frame(height: 6)

                // Breach segments overlaid
                ForEach(report.breachEvents) { breach in
                    let startFraction = max(0, min(1, breach.startTime.timeIntervalSince(report.sessionStart) / totalSeconds))
                    let durationFraction = max(0, min(1 - startFraction, breach.durationSeconds / totalSeconds))
                    let xOffset = startFraction * totalWidth
                    let segmentWidth = max(durationFraction * totalWidth, 2)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(breach.wasDanger ? WatchColors.accentDanger : WatchColors.accentWarm)
                        .frame(width: segmentWidth, height: 6)
                        .offset(x: xOffset)
                }
            }
        }
        .frame(height: 6)
        .padding(.vertical, 2)
    }


    // MARK: - ─── Color Logic ──────────────────────────────────────────────────

    private var peakColor: Color {
        let threshold = report.flaggingMode.thresholdDB
        if report.overallPeakDB > report.targetDB + threshold { return WatchColors.accentDanger }
        if report.overallPeakDB > report.targetDB { return WatchColors.accentWarm }
        return WatchColors.accent
    }

    private var averageColor: Color {
        if report.overallAverageDB > report.targetDB - 3 { return WatchColors.accentWarm }
        return WatchColors.accent
    }

    private var breachCountColor: Color {
        if report.breachCount == 0 { return WatchColors.accent }
        if report.breachCount <= 2 { return WatchColors.accentWarm }
        return WatchColors.accentDanger
    }

    private var dangerColor: Color {
        report.dangerCount > 0 ? WatchColors.accentDanger : WatchColors.accent
    }

    private var overPercentColor: Color {
        let pct = report.breachPercentage
        if pct < 5 { return WatchColors.accent }
        if pct < 15 { return WatchColors.accentWarm }
        return WatchColors.accentDanger
    }


    // MARK: - ─── Helpers ──────────────────────────────────────────────────────

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return "\(mins)m \(secs)s"
    }

    private var gradeLabel: String {
        let pct = report.breachPercentage
        if pct == 0 { return "Excellent" }
        if pct < 5 { return "Good" }
        if pct < 15 { return "Fair" }
        return "Needs Work"
    }

    private var gradeIcon: String {
        let pct = report.breachPercentage
        if pct == 0 { return "checkmark.circle.fill" }
        if pct < 5 { return "checkmark.circle" }
        if pct < 15 { return "exclamationmark.triangle" }
        return "xmark.circle"
    }

    private var gradeColor: Color {
        let pct = report.breachPercentage
        if pct < 5 { return WatchColors.accent }
        if pct < 15 { return WatchColors.accentWarm }
        return WatchColors.accentDanger
    }
}
