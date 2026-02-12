// ============================================================================
// WatchScreenshotPreviews.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Debug Utility
// Purpose: iOS-compilable replica views for Watch app and Widget complication
//          screenshots. Rendered via ImageRenderer in unit tests to produce
//          App Store screenshot PNGs without requiring watchOS UI tests.
//
// SYNC WARNING: These views replicate the visual layout of:
//   - WatchSPLView.swift          (307 lines — dashboard, ring gauge, corners)
//   - WatchReportsListView.swift  (40 lines — report list with rows)
//   - WatchReportDetailView.swift (167 lines — grade, colored stats, timeline)
//   - WatchComplicationProvider.swift (155 lines — circular, corner, rectangular)
//   - WatchColors.swift           (121 lines — Dark Booth theme colors)
//   If the source Watch files change, update these replicas to match.
// ============================================================================

#if DEBUG

import SwiftUI


// MARK: - ─── Screenshot Colors ─────────────────────────────────────────────

/// Static color values matching the WatchColors "Dark Booth" (Northern Lights) theme.
/// No @AppStorage dependency — safe for iOS-side ImageRenderer usage.
enum ScreenshotColors {

    // ── Shared Accent Colors (identical across all themes) ──

    static let accent       = Color(red: 0.30, green: 0.75, blue: 0.55)
    static let accentWarm   = Color(red: 0.95, green: 0.65, blue: 0.20)
    static let accentDanger = Color(red: 0.95, green: 0.30, blue: 0.25)

    // ── Dark Booth Theme Colors ──

    static let background      = Color(red: 0.06, green: 0.06, blue: 0.08)
    static let surface         = Color(red: 0.10, green: 0.10, blue: 0.13)
    static let surfaceElevated = Color(red: 0.14, green: 0.14, blue: 0.18)
    static let textPrimary     = Color(red: 0.92, green: 0.92, blue: 0.94)
    static let textSecondary   = Color(red: 0.55, green: 0.55, blue: 0.60)
    static let textMuted       = Color(red: 0.35, green: 0.35, blue: 0.40)
}


// MARK: - ─── Watch Dashboard Preview ───────────────────────────────────────

/// Replica of WatchSPLView.dashboardContent for screenshot rendering.
/// Takes plain parameters instead of a ViewModel dependency.
struct WatchDashboardPreview: View {
    let currentDB: Double
    let peakDB: Double
    let targetDB: Double
    let alertState: String      // "safe", "warning", "alert"
    let isRunning: Bool
    let flaggingMode: String    // "BAL", "STR", "VAR"
    let isPhoneReachable: Bool
    let sessionElapsed: TimeInterval

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                ScreenshotColors.background
                    .ignoresSafeArea()

                // ── Radial Background Gradient ──
                RadialGradient(
                    colors: [ScreenshotColors.surface.opacity(0.3), ScreenshotColors.background],
                    center: .center,
                    startRadius: 0,
                    endRadius: min(size.width, size.height) * 0.5
                )
                .ignoresSafeArea()

                // ── Central Activity Ring Gauge ──
                activityRingGauge(size: size)
                    .position(x: size.width / 2, y: size.height / 2)

                // ── Top-Left: Peak dB ──
                complicationPeakDB
                    .position(x: 28, y: 24)

                // ── Top-Right: Target dB (Crown) ──
                complicationTargetDB
                    .position(x: size.width - 28, y: 24)

                // ── Bottom-Left: Alert Mode ──
                complicationAlertMode
                    .position(x: 28, y: size.height - 24)

                // ── Bottom-Right: Start/Stop ──
                complicationStartStop
                    .position(x: size.width - 28, y: size.height - 24)

                // ── Connection indicator ──
                connectionDot
                    .position(x: size.width / 2, y: size.height - 8)
            }
        }
    }

    // MARK: - Activity Ring Gauge

    private func activityRingGauge(size: CGSize) -> some View {
        let ringDiameter = min(size.width, size.height) * 0.6
        let ringWidth: CGFloat = 10

        return ZStack {
            // Background track ring
            Circle()
                .stroke(
                    ScreenshotColors.surface,
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: ringDiameter, height: ringDiameter)

            // Filled arc — Activity Ring style with gradient
            Circle()
                .trim(from: 0, to: min(ringFillFraction, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: ringGradient,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * min(ringFillFraction, 1.0))
                    ),
                    style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                )
                .frame(width: ringDiameter, height: ringDiameter)
                .rotationEffect(.degrees(-90))

            // Overshoot glow ring (when over target)
            if ringFillFraction > 1.0 {
                Circle()
                    .stroke(
                        ScreenshotColors.accentDanger.opacity(0.3),
                        lineWidth: ringWidth + 4
                    )
                    .frame(width: ringDiameter, height: ringDiameter)
                    .blur(radius: 4)
            }

            // Center dB readout + session timer
            VStack(spacing: 0) {
                Text("\(Int(currentDB))")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(ringColor)
                    // Static pulse for alert screenshots (1.08x scale)
                    .scaleEffect(alertState == "alert" ? 1.08 : 1.0)

                Text("dB")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(ScreenshotColors.textSecondary)

                // Session timer (visible only while running)
                if isRunning && sessionElapsed > 0 {
                    Text(formattedElapsed)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(ScreenshotColors.textMuted)
                        .padding(.top, 2)
                }
            }
        }
    }

    // MARK: - Complication Slots

    private var complicationPeakDB: some View {
        VStack(spacing: 1) {
            Text("PEAK")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(ScreenshotColors.textMuted)
            Text("\(Int(peakDB))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(ScreenshotColors.textPrimary)
        }
    }

    private var complicationTargetDB: some View {
        VStack(spacing: 1) {
            Image(systemName: "crown.fill")
                .font(.system(size: 7))
                .foregroundStyle(ScreenshotColors.accentWarm)
            Text("\(Int(targetDB))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(ScreenshotColors.accentWarm)
        }
    }

    private var complicationAlertMode: some View {
        VStack(spacing: 1) {
            Text("MODE")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(ScreenshotColors.textMuted)
            Text(flaggingMode)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ScreenshotColors.textPrimary)
        }
    }

    private var complicationStartStop: some View {
        Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
            .font(.system(size: 24))
            .foregroundStyle(isRunning ? ScreenshotColors.accentDanger : ScreenshotColors.accent)
    }

    private var connectionDot: some View {
        Circle()
            .fill(isPhoneReachable ? ScreenshotColors.accent : ScreenshotColors.textMuted)
            .frame(width: 4, height: 4)
    }

    // MARK: - Computed Properties

    /// Replicates WatchSPLViewModel.ringFillFraction exactly.
    /// 0.0 at 40 dB floor, 1.0 at target dB. Can exceed 1.0 when over target,
    /// capped at (range + 20) / range to prevent unbounded overshoot.
    private var ringFillFraction: CGFloat {
        let floor = 40.0
        let range = max(targetDB - floor, 1.0)
        return min(max(currentDB - floor, 0), range + 20) / range
    }

    /// Replicates WatchSPLView ring color logic
    private var ringColor: Color {
        switch alertState {
        case "alert":   return ScreenshotColors.accentDanger
        case "warning": return ScreenshotColors.accentWarm
        default:        return ScreenshotColors.accent
        }
    }

    /// Ring gradient based on alert state: solid green (safe), green→amber (warning), amber→red (alert).
    private var ringGradient: Gradient {
        switch alertState {
        case "alert":
            return Gradient(colors: [ScreenshotColors.accentWarm, ScreenshotColors.accentDanger])
        case "warning":
            return Gradient(colors: [ScreenshotColors.accent, ScreenshotColors.accentWarm])
        default:
            return Gradient(colors: [ScreenshotColors.accent, ScreenshotColors.accent])
        }
    }

    /// Formatted elapsed time matching WatchSPLViewModel.formattedElapsed.
    private var formattedElapsed: String {
        let total = max(0, Int(sessionElapsed))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}


// MARK: - ─── Watch Report List Preview ─────────────────────────────────────

/// Replica of WatchReportsListView + WatchReportRow for screenshot rendering.
/// NOTE: Uses VStack instead of ScrollView — ImageRenderer cannot measure
/// ScrollView content (collapses to zero height, producing black screenshots).
struct WatchReportListPreview: View {
    let reports: [SPLSessionReport]

    var body: some View {
        ZStack {
            ScreenshotColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation title area
                Text("Reports")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(ScreenshotColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // Report rows (VStack, not ScrollView)
                VStack(spacing: 4) {
                    ForEach(reports) { report in
                        reportRow(report)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(ScreenshotColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 8)

                Spacer()
            }
        }
    }

    private func reportRow(_ report: SPLSessionReport) -> some View {
        HStack(spacing: 6) {
            // ── Grade Icon ──
            Image(systemName: gradeIcon(for: report))
                .font(.system(size: 12))
                .foregroundStyle(gradeColor(for: report))

            VStack(alignment: .leading, spacing: 2) {
                Text(report.date, style: .date)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ScreenshotColors.textPrimary)
                HStack(spacing: 6) {
                    Text("Peak: \(Int(report.overallPeakDB))")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(ScreenshotColors.textSecondary)
                    Text("Avg: \(Int(report.overallAverageDB))")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(ScreenshotColors.textMuted)
                }
            }
            Spacer()
            Text("\(report.breachCount)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(breachCountColor(for: report))
        }
    }

    private func gradeIcon(for report: SPLSessionReport) -> String {
        let pct = report.breachPercentage
        if pct == 0 { return "checkmark.circle.fill" }
        if pct < 5 { return "checkmark.circle" }
        if pct < 15 { return "exclamationmark.triangle" }
        return "xmark.circle"
    }

    private func gradeColor(for report: SPLSessionReport) -> Color {
        let pct = report.breachPercentage
        if pct < 5 { return ScreenshotColors.accent }
        if pct < 15 { return ScreenshotColors.accentWarm }
        return ScreenshotColors.accentDanger
    }

    private func breachCountColor(for report: SPLSessionReport) -> Color {
        if report.breachCount == 0 { return ScreenshotColors.accent }
        if report.breachCount <= 2 { return ScreenshotColors.accentWarm }
        return ScreenshotColors.accentDanger
    }
}


// MARK: - ─── Watch Report Detail Preview ───────────────────────────────────

/// Replica of WatchReportDetailView for screenshot rendering.
/// NOTE: Uses VStack instead of ScrollView — ImageRenderer cannot measure
/// ScrollView content (collapses to zero height, producing black screenshots).
struct WatchReportDetailPreview: View {
    let report: SPLSessionReport

    var body: some View {
        ZStack {
            ScreenshotColors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 6) {
                // ── Navigation title ──
                Text("Report")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(ScreenshotColors.textPrimary)

                // ── Header ──
                Text(report.date, style: .date)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(ScreenshotColors.textPrimary)

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
                coloredStatRow(label: "Target", value: "\(Int(report.targetDB)) dB", color: ScreenshotColors.textPrimary)
                coloredStatRow(label: "Breaches", value: "\(report.breachCount)", color: breachCountColor)
                coloredStatRow(label: "Danger", value: "\(report.dangerCount)", color: dangerColor)
                coloredStatRow(label: "Duration", value: formatDuration(report.totalMonitoringSeconds), color: ScreenshotColors.textPrimary)
                coloredStatRow(label: "Over %", value: String(format: "%.1f%%", report.breachPercentage), color: overPercentColor)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
    }


    // MARK: - Colored Stat Row

    private func coloredStatRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ScreenshotColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(ScreenshotColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }


    // MARK: - Breach Timeline Bar

    private var breachTimelineBar: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let totalSeconds = report.totalMonitoringSeconds

            ZStack(alignment: .leading) {
                // Full session background (safe = green)
                RoundedRectangle(cornerRadius: 3)
                    .fill(ScreenshotColors.accent.opacity(0.3))
                    .frame(height: 6)

                // Breach segments overlaid
                ForEach(report.breachEvents) { breach in
                    let startFraction = max(0, min(1, breach.startTime.timeIntervalSince(report.sessionStart) / totalSeconds))
                    let durationFraction = max(0, min(1 - startFraction, breach.durationSeconds / totalSeconds))
                    let xOffset = startFraction * totalWidth
                    let segmentWidth = max(durationFraction * totalWidth, 2)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(breach.wasDanger ? ScreenshotColors.accentDanger : ScreenshotColors.accentWarm)
                        .frame(width: segmentWidth, height: 6)
                        .offset(x: xOffset)
                }
            }
        }
        .frame(height: 6)
        .padding(.vertical, 2)
    }


    // MARK: - Color Logic

    private var peakColor: Color {
        let threshold = report.flaggingMode.thresholdDB
        if report.overallPeakDB > report.targetDB + threshold { return ScreenshotColors.accentDanger }
        if report.overallPeakDB > report.targetDB { return ScreenshotColors.accentWarm }
        return ScreenshotColors.accent
    }

    private var averageColor: Color {
        if report.overallAverageDB > report.targetDB - 3 { return ScreenshotColors.accentWarm }
        return ScreenshotColors.accent
    }

    private var breachCountColor: Color {
        if report.breachCount == 0 { return ScreenshotColors.accent }
        if report.breachCount <= 2 { return ScreenshotColors.accentWarm }
        return ScreenshotColors.accentDanger
    }

    private var dangerColor: Color {
        report.dangerCount > 0 ? ScreenshotColors.accentDanger : ScreenshotColors.accent
    }

    private var overPercentColor: Color {
        let pct = report.breachPercentage
        if pct < 5 { return ScreenshotColors.accent }
        if pct < 15 { return ScreenshotColors.accentWarm }
        return ScreenshotColors.accentDanger
    }


    // MARK: - Helpers

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
        if pct < 5 { return ScreenshotColors.accent }
        if pct < 15 { return ScreenshotColors.accentWarm }
        return ScreenshotColors.accentDanger
    }
}


// MARK: - ─── Complication Entry ────────────────────────────────────────────

/// Lightweight replica of SPLComplicationEntry without WidgetKit dependency.
struct ScreenshotComplicationEntry {
    let currentDB: Int
    let alertState: String      // "safe", "warning", "alert"
    let targetDB: Int
    let isRunning: Bool
}


// MARK: - ─── Widget Circular Preview ───────────────────────────────────────

/// Replica of SPLCircularView using iOS-compatible gauge style.
/// NOTE: The actual WatchComplicationProvider uses `.gaugeStyle(.circular)` which is
/// watchOS-only. We use `.accessoryCircular` (iOS 16+) as the closest equivalent.
/// Visual output is nearly identical for App Store marketing purposes.
struct WidgetCircularPreview: View {
    let entry: ScreenshotComplicationEntry

    var body: some View {
        Gauge(value: Double(entry.currentDB), in: 40...110) {
            Text("dB")
                .font(.system(size: 8))
        } currentValueLabel: {
            Text("\(entry.currentDB)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(gaugeColor)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(gaugeGradient)
    }

    private var gaugeColor: Color {
        switch entry.alertState {
        case "alert":   return .red
        case "warning": return .orange
        default:        return .green
        }
    }

    private var gaugeGradient: Gradient {
        Gradient(colors: [.green, .yellow, .orange, .red])
    }
}


// MARK: - ─── Widget Corner Preview ─────────────────────────────────────────

/// Replica of SPLCornerView.
struct WidgetCornerPreview: View {
    let entry: ScreenshotComplicationEntry

    var body: some View {
        Text("\(entry.currentDB)")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(entry.isRunning ? .green : .gray)
    }
}


// MARK: - ─── Widget Rectangular Preview ────────────────────────────────────

/// Replica of SPLRectangularView.
struct WidgetRectangularPreview: View {
    let entry: ScreenshotComplicationEntry

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.isRunning ? "waveform" : "waveform.slash")
                .font(.system(size: 14))
                .foregroundStyle(entry.isRunning ? .green : .gray)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(entry.currentDB) dB")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("Target: \(entry.targetDB)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#endif
