// ============================================================================
// SPLReportExportView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Self-contained view designed for rendering as a shareable image
//          via ImageRenderer. Includes all report data with branding,
//          optimized for a fixed-width PNG. Uses grade/format helpers from
//          the SPLSessionReport extension (SPLReportFormatting).
// ============================================================================

import SwiftUI


// MARK: - ─── Report Export View (Image Renderer) ─────────────────────────────

/// A self-contained view designed for rendering as a shareable image via ImageRenderer.
/// Includes all report data with branding, optimized for a fixed-width PNG.
struct ReportExportView: View {
    let report: SPLSessionReport

    var body: some View {
        VStack(spacing: 16) {
            // ── Header ──
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SanctuarySound")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(BoothColors.accent)
                    Text("SPL Service Report")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(BoothColors.textSecondary)
                }
                Spacer()
                Text(report.formatSessionDate())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
            }
            .padding(.bottom, 4)

            // ── Grade Card ──
            VStack(spacing: 8) {
                Text(report.gradeEmoji)
                    .font(.system(size: 36))
                Text(report.gradeLabel)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(report.gradeColor)
                Text(report.gradeSummary)
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(report.gradeColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(report.gradeColor.opacity(0.2), lineWidth: 1)
            )

            // ── Stats Grid ──
            VStack(spacing: 8) {
                Text("SESSION SUMMARY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
                    .tracking(1)

                HStack(spacing: 8) {
                    exportStatBadge(label: "Duration", value: report.formatDuration(report.totalMonitoringSeconds))
                    exportStatBadge(label: "Target", value: "\(Int(report.targetDB)) dB", color: BoothColors.accent)
                    exportStatBadge(label: "Mode", value: report.flaggingMode.localizedName, color: BoothColors.accentWarm)
                }

                HStack(spacing: 8) {
                    exportStatBadge(
                        label: "Peak",
                        value: "\(Int(report.overallPeakDB)) dB",
                        color: report.overallPeakDB > report.targetDB ? BoothColors.accentDanger : BoothColors.accent
                    )
                    exportStatBadge(label: "Average", value: "\(Int(report.overallAverageDB)) dB")
                    exportStatBadge(
                        label: "Breaches",
                        value: "\(report.breachCount)",
                        color: report.breachCount > 0 ? BoothColors.accentWarm : BoothColors.accent
                    )
                }

                if report.breachCount > 0 {
                    HStack(spacing: 8) {
                        exportStatBadge(
                            label: "Over Target",
                            value: String(format: "%.0f%%", report.breachPercentage),
                            color: BoothColors.accentDanger
                        )
                        exportStatBadge(
                            label: "Longest",
                            value: report.formatDuration(report.longestBreachSeconds),
                            color: BoothColors.accentWarm
                        )
                        exportStatBadge(
                            label: "Danger",
                            value: "\(report.dangerCount)",
                            color: report.dangerCount > 0 ? BoothColors.accentDanger : BoothColors.accent
                        )
                    }
                }
            }

            // ── Breach Events (up to 8) ──
            if !report.breachEvents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("BREACH EVENTS (\(report.breachCount))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                        .tracking(1)

                    ForEach(Array(report.breachEvents.prefix(8))) { event in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(event.wasDanger ? BoothColors.accentDanger : BoothColors.accentWarm)
                                .frame(width: 6, height: 6)

                            Text(report.formatTime(event.startTime))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(BoothColors.textSecondary)
                                .frame(width: 65, alignment: .leading)

                            Text("Peak \(Int(event.peakDB)) dB")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(event.wasDanger ? BoothColors.accentDanger : BoothColors.accentWarm)

                            Spacer()

                            Text("+\(Int(event.overTargetDB)) dB · \(report.formatDuration(event.durationSeconds))")
                                .font(.system(size: 9))
                                .foregroundStyle(BoothColors.textMuted)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(BoothColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    if report.breachEvents.count > 8 {
                        Text("+ \(report.breachEvents.count - 8) more events")
                            .font(.system(size: 10))
                            .foregroundStyle(BoothColors.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }

            // ── Footer ──
            Text("Generated by SanctuarySound — Virtual Audio Director")
                .font(.system(size: 9))
                .foregroundStyle(BoothColors.textMuted)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 380)
        .background(BoothColors.background)
    }

    // ── Stat Badge ──
    private func exportStatBadge(
        label: String,
        value: String,
        color: Color = BoothColors.textPrimary
    ) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(BoothColors.textMuted)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
