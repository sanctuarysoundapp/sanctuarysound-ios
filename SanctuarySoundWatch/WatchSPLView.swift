// ============================================================================
// WatchSPLView.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Main watch interface showing a circular gauge for real-time SPL,
//          start/stop controls, alert mode display, and recent reports.
// ============================================================================

import SwiftUI


// MARK: - ─── Watch SPL View ─────────────────────────────────────────────────

struct WatchSPLView: View {
    @ObservedObject var viewModel: WatchSPLViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // ── Live Gauge ──
                    splGauge

                    // ── Controls ──
                    controlsSection

                    // ── Reports ──
                    reportsSection
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("SPL")
            .navigationBarTitleDisplayMode(.inline)
        }
    }


    // MARK: - Live Gauge

    private var splGauge: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(WatchColors.surface, lineWidth: 8)
                    .frame(width: 120, height: 120)

                // Colored gauge ring
                Circle()
                    .trim(from: 0, to: gaugeProgress)
                    .stroke(
                        gaugeColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.15), value: viewModel.currentDB)

                // dB readout
                VStack(spacing: 2) {
                    Text("\(Int(viewModel.currentDB))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(gaugeColor)
                        .contentTransition(.numericText())

                    Text("dB")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WatchColors.textSecondary)
                }
            }

            // Peak / Average badges
            HStack(spacing: 12) {
                badge(label: "PEAK", value: "\(Int(viewModel.peakDB))")
                badge(label: "AVG", value: "\(Int(viewModel.averageDB))")
            }

            // Connection status
            connectionIndicator
        }
    }

    private func badge(label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(WatchColors.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(WatchColors.textPrimary)
        }
    }

    private var connectionIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(viewModel.isPhoneReachable ? WatchColors.accent : WatchColors.textMuted)
                .frame(width: 6, height: 6)
            Text(viewModel.isPhoneReachable ? "Connected" : "Disconnected")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WatchColors.textSecondary)
        }
    }


    // MARK: - Controls

    private var controlsSection: some View {
        VStack(spacing: 8) {
            // Start / Stop button
            Button {
                viewModel.toggleMonitoring()
            } label: {
                HStack {
                    Image(systemName: viewModel.isRunning ? "stop.fill" : "play.fill")
                    Text(viewModel.isRunning ? "Stop" : "Start")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .tint(viewModel.isRunning ? WatchColors.accentDanger : WatchColors.accent)

            // Alert mode + target
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TARGET")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(WatchColors.textMuted)
                    Text("\(Int(viewModel.targetDB)) dB")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(WatchColors.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("MODE")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(WatchColors.textMuted)
                    Text(viewModel.flaggingModeName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WatchColors.textPrimary)
                }
            }
            .padding(.horizontal, 8)
        }
    }


    // MARK: - Reports

    private var reportsSection: some View {
        Group {
            if !viewModel.reports.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RECENT REPORTS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(WatchColors.textMuted)
                        .padding(.horizontal, 4)

                    ForEach(viewModel.reports.prefix(3)) { report in
                        NavigationLink {
                            WatchReportDetailView(report: report)
                        } label: {
                            WatchReportRow(report: report)
                        }
                    }

                    if viewModel.reports.count > 3 {
                        NavigationLink("View All") {
                            WatchReportsListView(reports: viewModel.reports)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(WatchColors.accent)
                    }
                }
            }
        }
    }


    // MARK: - Helpers

    private var gaugeProgress: CGFloat {
        let clamped = min(max(viewModel.currentDB, 40), 110)
        return (clamped - 40) / 70.0
    }

    private var gaugeColor: Color {
        switch viewModel.alertStateCodable.rawValue {
        case "alert":
            return WatchColors.accentDanger
        case "warning":
            return WatchColors.accentWarm
        default:
            return WatchColors.accent
        }
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
