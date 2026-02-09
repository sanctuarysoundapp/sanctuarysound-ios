// ============================================================================
// ToolsView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Tools tab — utility features including SPL Meter, with future
//          expansion for EQ Analyzer, Room Acoustics, and AI Q&A.
// ============================================================================

import SwiftUI


// MARK: - ─── Tools View ──────────────────────────────────────────────────────

struct ToolsView: View {
    @ObservedObject var store: ServiceStore
    @Binding var splPreference: SPLPreference

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── SPL Meter ──
                        splMeterCard

                        // ── Future Tools ──
                        futureToolsSection

                        // ── SPL Reports ──
                        splReportsSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }


    // MARK: - SPL Meter Card

    private var splMeterCard: some View {
        NavigationLink {
            SPLCalibrationView(
                store: store,
                splPreference: $splPreference,
                onSave: { pref in store.updateSPLPreference(pref) }
            )
        } label: {
            toolCard(
                title: "SPL Meter",
                icon: "speaker.wave.2.fill",
                description: "Monitor sound levels in real-time with calibration, alerts, and session reports.",
                accentColor: BoothColors.accent,
                isActive: store.splMeter.isRunning,
                enabled: true
            )
        }
        .buttonStyle(.plain)
    }


    // MARK: - Future Tools

    private var futureToolsSection: some View {
        SectionCard(title: "Coming Soon") {
            toolCard(
                title: "EQ Analyzer",
                icon: "waveform",
                description: "Real-time frequency spectrum display for room and mix analysis.",
                accentColor: BoothColors.accentWarm,
                isActive: false,
                enabled: false
            )

            toolCard(
                title: "Room Acoustics",
                icon: "building.2",
                description: "Measure RT60 reverb time using your iPhone mic.",
                accentColor: BoothColors.accentWarm,
                isActive: false,
                enabled: false
            )

            toolCard(
                title: "Sound Engineer Q&A",
                icon: "questionmark.bubble",
                description: "Audio engineering knowledge base for mixing questions.",
                accentColor: BoothColors.accentWarm,
                isActive: false,
                enabled: false
            )
        }
    }


    // MARK: - SPL Reports

    private var splReportsSection: some View {
        SectionCard(title: "SPL Reports (\(store.savedReports.count))") {
            if store.savedReports.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.text.clipboard")
                        .font(.system(size: 28))
                        .foregroundStyle(BoothColors.textMuted)
                    Text("No session reports yet. Start monitoring with the SPL Meter.")
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(store.savedReports.prefix(5)) { report in
                    reportRow(report)
                }
            }
        }
    }

    private func reportRow(_ report: SPLSessionReport) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(report.sessionStart))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                HStack(spacing: 6) {
                    Text("Avg: \(Int(report.overallAverageDB)) dB")
                    Text("\u{00B7}")
                    Text("Peak: \(Int(report.overallPeakDB)) dB")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(BoothColors.textSecondary)
            }
            Spacer()
            Text(gradeLabel(for: report))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(gradeColorForReport(report))
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }


    // MARK: - Tool Card Component

    private func toolCard(
        title: String,
        icon: String,
        description: String,
        accentColor: Color,
        isActive: Bool,
        enabled: Bool
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(enabled ? 0.15 : 0.05))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(enabled ? accentColor : BoothColors.textMuted)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(enabled ? BoothColors.textPrimary : BoothColors.textMuted)
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(BoothColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(enabled ? BoothColors.textSecondary : BoothColors.textMuted)
                    .lineLimit(2)
            }

            Spacer()

            if enabled {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textMuted)
            }
        }
        .padding(12)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .opacity(enabled ? 1.0 : 0.6)
    }


    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func gradeLabel(for report: SPLSessionReport) -> String {
        if report.breachCount == 0 { return "Clean" }
        if report.dangerCount == 0 && report.breachPercentage < 10 { return "Good" }
        if report.breachPercentage < 20 { return "Fair" }
        return "Over"
    }

    private func gradeColorForReport(_ report: SPLSessionReport) -> Color {
        if report.breachCount == 0 { return BoothColors.accent }
        if report.dangerCount == 0 && report.breachPercentage < 10 { return BoothColors.accentWarm }
        return BoothColors.accentDanger
    }
}
