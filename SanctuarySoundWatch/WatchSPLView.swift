// ============================================================================
// WatchSPLView.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Watch-face style dashboard with Activity Ring gauge and four
//          corner "complication" slots. Single-screen, no scrolling.
//          Digital Crown adjusts target SPL threshold in real-time.
// ============================================================================

import SwiftUI


// MARK: - ─── Watch SPL View ─────────────────────────────────────────────────

struct WatchSPLView: View {
    @ObservedObject var viewModel: WatchSPLViewModel
    @State private var isPulsing = false

    var body: some View {
        NavigationStack {
            ZStack {
                WatchColors.background
                    .ignoresSafeArea()

                dashboardContent
            }
            .focusable()
            .digitalCrownRotation(
                $viewModel.crownTargetDB,
                from: 70.0,
                through: 100.0,
                by: 1.0,
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: viewModel.crownTargetDB) { _, _ in
                viewModel.onCrownTargetChanged()
            }
        }
    }


    // MARK: - ─── Dashboard Layout ───────────────────────────────────────────

    private var dashboardContent: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // ── Radial Background Gradient ──
                RadialGradient(
                    colors: [WatchColors.surface.opacity(0.3), WatchColors.background],
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


    // MARK: - ─── Activity Ring Gauge ────────────────────────────────────────

    private func activityRingGauge(size: CGSize) -> some View {
        let ringDiameter = min(size.width, size.height) * 0.6
        let ringWidth: CGFloat = 10

        return NavigationLink {
            WatchReportsListView(reports: viewModel.reports)
        } label: {
            ZStack {
                // Background track ring
                Circle()
                    .stroke(
                        WatchColors.surface,
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .frame(width: ringDiameter, height: ringDiameter)

                // Filled arc — Activity Ring style with gradient
                Circle()
                    .trim(from: 0, to: min(viewModel.ringFillFraction, 1.0))
                    .stroke(
                        AngularGradient(
                            gradient: ringGradient,
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * min(viewModel.ringFillFraction, 1.0))
                        ),
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .frame(width: ringDiameter, height: ringDiameter)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.15), value: viewModel.currentDB)

                // Overshoot glow ring (when over target)
                if viewModel.ringFillFraction > 1.0 {
                    Circle()
                        .stroke(
                            WatchColors.accentDanger.opacity(0.3),
                            lineWidth: ringWidth + 4
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .blur(radius: 4)
                }

                // Center dB readout + session timer
                VStack(spacing: 0) {
                    Text("\(Int(viewModel.currentDB))")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(viewModel.ringColor)
                        .contentTransition(.numericText())
                        .scaleEffect(isPulsing ? 1.08 : 1.0)

                    Text("dB")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WatchColors.textSecondary)

                    // Session timer (visible only while running)
                    if viewModel.isRunning {
                        Text(viewModel.formattedElapsed)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(WatchColors.textMuted)
                            .padding(.top, 2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onChange(of: viewModel.alertStateCodable.rawValue) { _, newValue in
            isPulsing = newValue == "alert"
        }
        .animation(
            isPulsing
                ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                : .default,
            value: isPulsing
        )
    }

    /// Ring gradient based on alert state: solid green (safe), green→amber (warning), amber→red (alert).
    private var ringGradient: Gradient {
        switch viewModel.alertStateCodable.rawValue {
        case "alert":
            return Gradient(colors: [WatchColors.accentWarm, WatchColors.accentDanger])
        case "warning":
            return Gradient(colors: [WatchColors.accent, WatchColors.accentWarm])
        default:
            return Gradient(colors: [WatchColors.accent, WatchColors.accent])
        }
    }


    // MARK: - ─── Complication Slots ─────────────────────────────────────────

    /// Top-left: Peak dB reading
    private var complicationPeakDB: some View {
        VStack(spacing: 1) {
            Text("PEAK")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(WatchColors.textMuted)
            Text("\(Int(viewModel.peakDB))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(WatchColors.textPrimary)
                .contentTransition(.numericText())
        }
    }

    /// Top-right: Target dB (Crown-adjustable)
    private var complicationTargetDB: some View {
        VStack(spacing: 1) {
            Image(systemName: "crown.fill")
                .font(.system(size: 7))
                .foregroundStyle(WatchColors.accentWarm)
            Text("\(Int(viewModel.crownTargetDB))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(WatchColors.accentWarm)
                .contentTransition(.numericText())
        }
    }

    /// Bottom-left: Alert mode indicator
    private var complicationAlertMode: some View {
        VStack(spacing: 1) {
            Text("MODE")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(WatchColors.textMuted)
            Text(shortModeName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WatchColors.textPrimary)
        }
    }

    /// Bottom-right: Start/Stop button
    private var complicationStartStop: some View {
        Button {
            viewModel.toggleMonitoring()
        } label: {
            Image(systemName: viewModel.isRunning ? "stop.circle.fill" : "play.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(viewModel.isRunning ? WatchColors.accentDanger : WatchColors.accent)
        }
        .buttonStyle(.plain)
    }


    // MARK: - ─── Helpers ────────────────────────────────────────────────────

    /// Shortened mode name for compact complication display.
    private var shortModeName: String {
        switch viewModel.flaggingModeName {
        case "Balanced": return "BAL"
        case "Strict": return "STR"
        case "Variable": return "VAR"
        default: return String(viewModel.flaggingModeName.prefix(3)).uppercased()
        }
    }

    /// Tiny dot showing phone connection status.
    private var connectionDot: some View {
        Circle()
            .fill(viewModel.isPhoneReachable ? WatchColors.accent : WatchColors.textMuted)
            .frame(width: 4, height: 4)
    }
}


// MARK: - ─── Report Row ─────────────────────────────────────────────────────

struct WatchReportRow: View {
    let report: SPLSessionReport

    var body: some View {
        HStack(spacing: 6) {
            // ── Grade Icon ──
            Image(systemName: gradeIcon)
                .font(.system(size: 12))
                .foregroundStyle(gradeColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(report.date, style: .date)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WatchColors.textPrimary)
                HStack(spacing: 6) {
                    Text("Peak: \(Int(report.overallPeakDB))")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(WatchColors.textSecondary)
                    Text("Avg: \(Int(report.overallAverageDB))")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(WatchColors.textMuted)
                }
            }
            Spacer()
            Text("\(report.breachCount)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(breachCountColor)
        }
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

    private var breachCountColor: Color {
        if report.breachCount == 0 { return WatchColors.accent }
        if report.breachCount <= 2 { return WatchColors.accentWarm }
        return WatchColors.accentDanger
    }
}
