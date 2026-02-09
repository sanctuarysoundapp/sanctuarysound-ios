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

                // Filled arc — Activity Ring style
                Circle()
                    .trim(from: 0, to: min(viewModel.ringFillFraction, 1.0))
                    .stroke(
                        viewModel.ringColor,
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

                // Center dB readout
                VStack(spacing: 0) {
                    Text("\(Int(viewModel.currentDB))")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(viewModel.ringColor)
                        .contentTransition(.numericText())

                    Text("dB")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(WatchColors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(report.date, style: .date)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(WatchColors.textPrimary)
                Text("Peak: \(Int(report.overallPeakDB)) dB")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(WatchColors.textSecondary)
            }
            Spacer()
            Text("\(report.breachCount)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(report.breachCount > 0 ? WatchColors.accentWarm : WatchColors.accent)
        }
    }
}
