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
            VStack(alignment: .leading, spacing: 8) {
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

                Divider()
                    .background(WatchColors.textMuted)

                // ── Stats ──
                statRow(label: "Peak", value: "\(Int(report.overallPeakDB)) dB")
                statRow(label: "Average", value: "\(Int(report.overallAverageDB)) dB")
                statRow(label: "Target", value: "\(Int(report.targetDB)) dB")
                statRow(label: "Breaches", value: "\(report.breachCount)")
                statRow(label: "Danger", value: "\(report.dangerCount)")
                statRow(label: "Duration", value: formatDuration(report.totalMonitoringSeconds))
                statRow(label: "Over %", value: String(format: "%.1f%%", report.breachPercentage))
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Report")
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(WatchColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(WatchColors.textPrimary)
        }
    }

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
