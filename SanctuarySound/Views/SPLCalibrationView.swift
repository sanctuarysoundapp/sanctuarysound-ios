// ============================================================================
// SPLCalibrationView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Real-time SPL monitoring using the iPhone mic and calibration
//          workflow for setting the dBFS-to-SPL offset. Also provides
//          SPL preference configuration (target dB, flagging mode).
// ============================================================================

import SwiftUI

// MARK: - ─── SPL Calibration View ───────────────────────────────────────────

struct SPLCalibrationView: View {
    @ObservedObject var store: ServiceStore
    @ObservedObject var splMeter: SPLMeter
    @Binding var splPreference: SPLPreference
    var onSave: (SPLPreference) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var calibrationSPL: String = ""
    @State private var showCalibrationPrompt = false
    @State private var isPulsing = false
    @State private var hapticTrigger = false
    @State private var showSessionReport = false
    @State private var latestReport: SPLSessionReport?
    @State private var showCalibrationError = false

    // Valid SPL range for calibration references (40 dB near-silence to 130 dB pain threshold)
    private static let calibrationRange: ClosedRange<Double> = 40...130

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Live SPL Meter ──
                        liveMetrSection

                        // ── SPL Target Preference ──
                        targetSection

                        // ── Alert Mode ──
                        flaggingSection

                        // ── Calibration ──
                        calibrationSection

                        // ── Past Reports ──
                        if !store.savedReports.isEmpty {
                            pastReportsSection
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("SPL Monitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        if splMeter.isRunning {
                            store.stopMonitoringAndSaveReport()
                        }
                        onSave(splPreference)
                        dismiss()
                    }
                    .foregroundStyle(BoothColors.accent)
                }
            }
            .onAppear {
                splMeter.updateAlertThresholds(preference: splPreference)
                Task { await splMeter.requestPermission() }
            }
            .onDisappear {
                if splMeter.isRunning {
                    store.stopMonitoringAndSaveReport()
                }
            }
            .onChange(of: splMeter.alertState) { _, newState in
                // Trigger haptic on state transitions to warning/alert
                if newState.isActive {
                    hapticTrigger.toggle()
                }
                // Drive pulse animation
                withAnimation(
                    newState.isDanger
                        ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                        : .default
                ) {
                    isPulsing = newState.isDanger
                }
            }
            .sensoryFeedback(.warning, trigger: hapticTrigger)
            .sheet(isPresented: $showSessionReport) {
                if let report = latestReport {
                    SPLSessionReportView(report: report)
                }
            }
        }
    }


    // MARK: - Live Meter Section

    private var liveMetrSection: some View {
        SectionCard(title: "Live SPL") {
            HStack(spacing: 12) {
                // Current reading
                VStack(spacing: 4) {
                    Text("CURRENT")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                    Text("\(Int(splMeter.currentDB))")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(currentColor)
                    Text("dB SPL")
                        .font(.system(size: 9))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(currentColor.opacity(isPulsing ? 0.25 : 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isPulsing ? BoothColors.accentDanger : Color.clear,
                            lineWidth: 2
                        )
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current sound level \(Int(splMeter.currentDB)) dB SPL")
                .accessibilityValue("\(Int(splMeter.currentDB))")

                VStack(spacing: 12) {
                    // Peak
                    VStack(spacing: 2) {
                        Text("PEAK")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.textMuted)
                        Text("\(Int(splMeter.peakDB))")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(peakColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(peakColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Peak level \(Int(splMeter.peakDB)) dB")
                    .accessibilityValue("\(Int(splMeter.peakDB))")

                    // Average
                    VStack(spacing: 2) {
                        Text("AVG")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.textMuted)
                        Text("\(Int(splMeter.averageDB))")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Average level \(Int(splMeter.averageDB)) dB")
                    .accessibilityValue("\(Int(splMeter.averageDB))")
                }
            }

            // ── SPL Bar ──
            SPLBar(
                currentDB: splMeter.currentDB,
                targetDB: splPreference.targetDB,
                thresholdDB: splPreference.flagThresholdDB
            )

            // Controls
            HStack(spacing: 12) {
                Button {
                    if splMeter.isRunning {
                        if let report = store.stopMonitoringAndSaveReport() {
                            latestReport = report
                            showSessionReport = true
                        }
                    } else {
                        splMeter.start()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: splMeter.isRunning ? "stop.fill" : "mic.fill")
                        Text(splMeter.isRunning ? "Stop & Report" : "Start Listening")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(BoothColors.background)
                    .background(splMeter.isRunning ? BoothColors.accentDanger : BoothColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel(splMeter.isRunning ? "Stop monitoring and generate report" : "Start SPL monitoring")
                .accessibilityHint(splMeter.isRunning ? "Stops measurement and shows a session report" : "Begins measuring sound pressure level using the iPhone microphone")

                Button {
                    splMeter.resetPeak()
                } label: {
                    Text("Reset Peak")
                        .font(.system(size: 13, weight: .medium))
                        .frame(height: 44)
                        .padding(.horizontal, 16)
                        .foregroundStyle(BoothColors.textSecondary)
                        .background(BoothColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel("Reset peak level")
            }

            // ── Breach counter (live) ──
            if splMeter.isRunning && !splMeter.breachEvents.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(BoothColors.accentWarm)
                    Text("\(splMeter.breachEvents.count) breach\(splMeter.breachEvents.count == 1 ? "" : "es") logged this session")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }

            if !splMeter.permissionGranted {
                Text("Microphone access required. Grant permission in Settings.")
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.accentWarm)
            }
        }
    }


    // MARK: - Target Section

    private static let splMin: Double = 70
    private static let splMax: Double = 100

    private var targetSection: some View {
        SectionCard(title: "SPL Target") {
            VStack(spacing: 16) {
                // ── Large dB readout ──
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(splPreference.targetDB))")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textPrimary)
                        .contentTransition(.numericText())
                    Text("dB")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("SPL target \(Int(splPreference.targetDB)) dB")
                .accessibilityValue("\(Int(splPreference.targetDB))")

                // ── Stepper buttons with slider ──
                HStack(spacing: 12) {
                    // Minus button
                    Button {
                        adjustTarget(by: -1)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                splPreference.targetDB <= Self.splMin
                                    ? BoothColors.textMuted
                                    : BoothColors.accent
                            )
                    }
                    .disabled(splPreference.targetDB <= Self.splMin)
                    .accessibilityLabel("Decrease target SPL")

                    // Slider
                    Slider(
                        value: $splPreference.targetDB,
                        in: Self.splMin...Self.splMax,
                        step: 1
                    )
                    .tint(targetSliderColor)
                    .accessibilityLabel("SPL target slider")
                    .accessibilityValue("\(Int(splPreference.targetDB)) dB, \(targetDescription)")

                    // Plus button
                    Button {
                        adjustTarget(by: 1)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(
                                splPreference.targetDB >= Self.splMax
                                    ? BoothColors.textMuted
                                    : BoothColors.accent
                            )
                    }
                    .disabled(splPreference.targetDB >= Self.splMax)
                    .accessibilityLabel("Increase target SPL")
                }

                // ── Range labels ──
                HStack {
                    Text("\(Int(Self.splMin)) dB")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                    Spacer()
                    Text(targetDescription)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(targetDescriptionColor)
                    Spacer()
                    Text("\(Int(Self.splMax)) dB")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                }
            }

            Text("Preferred maximum SPL during the loudest moments of worship.")
                .font(.system(size: 11))
                .foregroundStyle(BoothColors.textMuted)
        }
    }

    private func adjustTarget(by amount: Double) {
        let newValue = splPreference.targetDB + amount
        let clamped = min(Self.splMax, max(Self.splMin, newValue))
        splPreference = SPLPreference(
            targetDB: clamped,
            flaggingMode: splPreference.flaggingMode,
            calibrationOffset: splPreference.calibrationOffset
        )
    }

    private var targetDescription: String {
        let db = splPreference.targetDB
        if db <= 75 { return "Quiet — Spoken Word" }
        if db <= 82 { return "Conversational" }
        if db <= 88 { return "Moderate Worship" }
        if db <= 93 { return "Energetic Worship" }
        return "Full Band — Loud"
    }

    private var targetDescriptionColor: Color {
        let db = splPreference.targetDB
        if db <= 82 { return BoothColors.accent }
        if db <= 93 { return BoothColors.accentWarm }
        return BoothColors.accentDanger
    }

    private var targetSliderColor: Color {
        let db = splPreference.targetDB
        if db <= 85 { return BoothColors.accent }
        if db <= 93 { return BoothColors.accentWarm }
        return BoothColors.accentDanger
    }


    // MARK: - Flagging Section

    private var flaggingSection: some View {
        SectionCard(title: "Alert Mode") {
            Picker("Alert Mode", selection: $splPreference.flaggingMode) {
                ForEach(SPLFlaggingMode.allCases) { mode in
                    Text(mode.localizedName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("SPL alert mode")

            Text(splPreference.flaggingMode.description)
                .font(.system(size: 11))
                .foregroundStyle(BoothColors.textSecondary)

            // ── Alert behavior description ──
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.accentWarm)
                    Text("Haptic tap when threshold is breached")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textSecondary)
                }
                HStack(spacing: 6) {
                    Image(systemName: "light.beacon.max")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.accentDanger)
                    Text("Visual pulse + alert banner on all tabs")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .padding(.top, 4)
        }
    }


    // MARK: - Calibration Section

    private var calibrationSection: some View {
        SectionCard(title: "Calibration") {
            VStack(alignment: .leading, spacing: 8) {
                Text("If you have a reference SPL meter, you can calibrate the iPhone mic for more accurate readings.")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)

                if let offset = splPreference.calibrationOffset {
                    HStack {
                        Text("Current calibration offset:")
                            .font(.system(size: 12))
                            .foregroundStyle(BoothColors.textSecondary)
                        Spacer()
                        Text(String(format: "%+.1f dB", offset))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.accent)
                    }
                }

                Button {
                    showCalibrationPrompt = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tuningfork")
                        Text("Calibrate")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(BoothColors.accentWarm)
                    .background(BoothColors.accentWarm.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel("Calibrate SPL meter")
                .accessibilityHint("Lets you enter a reference SPL reading to calibrate the iPhone microphone")
            }
        }
        .alert("Calibrate SPL Meter", isPresented: $showCalibrationPrompt) {
            TextField("Reference SPL (dB)", text: $calibrationSPL)
                .keyboardType(.decimalPad)
            Button("Calibrate") {
                if let knownSPL = Double(calibrationSPL),
                   Self.calibrationRange.contains(knownSPL) {
                    let offset = splMeter.calculateCalibrationOffset(knownSPL: knownSPL)
                    splPreference = SPLPreference(
                        targetDB: splPreference.targetDB,
                        flaggingMode: splPreference.flaggingMode,
                        calibrationOffset: offset
                    )
                } else {
                    showCalibrationError = true
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Play a steady tone and enter the SPL reading from your reference meter. The iPhone mic will be calibrated to match.")
        }
        .alert("Invalid SPL Reference", isPresented: $showCalibrationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Enter a value between 40 and 130 dB. This is the valid range for real-world SPL calibration references.")
        }
    }


    // MARK: - Past Reports Section

    private var pastReportsSection: some View {
        SectionCard(title: "Service Reports (\(store.savedReports.count))") {
            ForEach(store.savedReports.prefix(5)) { report in
                HStack(spacing: 10) {
                    // ── Report Card (tappable to open) ──
                    Button {
                        latestReport = report
                        showSessionReport = true
                    } label: {
                        HStack(spacing: 12) {
                            // Grade indicator
                            Circle()
                                .fill(reportGradeColor(report))
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatReportDate(report.date))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(BoothColors.textPrimary)
                                Text("\(report.breachCount) breaches · Peak \(Int(report.overallPeakDB)) dB · \(formatDuration(report.totalMonitoringSeconds))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(BoothColors.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(BoothColors.textMuted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(BoothColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("SPL report from \(formatReportDate(report.date)), \(report.breachCount) breaches, peak \(Int(report.overallPeakDB)) dB")
                    .accessibilityHint("Tap to view full report")

                    // ── Delete Button (outside the card) ──
                    Button(role: .destructive) {
                        withAnimation { store.deleteReport(id: report.id) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(BoothColors.accentDanger.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(BoothColors.accentDanger.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete report from \(formatReportDate(report.date))")
                }
                .contextMenu {
                    Button(role: .destructive) {
                        withAnimation { store.deleteReport(id: report.id) }
                    } label: {
                        Label("Delete Report", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func reportGradeColor(_ report: SPLSessionReport) -> Color {
        if report.breachCount == 0 { return BoothColors.accent }
        if report.dangerCount == 0 { return BoothColors.accentWarm }
        return BoothColors.accentDanger
    }

    private func formatReportDate(_ date: Date) -> String {
        AppDateFormatter.dateWithTime.string(from: date)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        if minutes < 1 { return "\(Int(seconds))s" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let remainingMins = minutes % 60
        return "\(hours)h \(remainingMins)m"
    }


    // MARK: - Color Helpers

    private var currentColor: Color {
        if splMeter.currentDB > splPreference.targetDB + splPreference.flagThresholdDB {
            return BoothColors.accentDanger
        }
        if splMeter.currentDB > splPreference.targetDB {
            return BoothColors.accentWarm
        }
        return BoothColors.accent
    }

    private var peakColor: Color {
        if splMeter.peakDB > splPreference.targetDB + splPreference.flagThresholdDB {
            return BoothColors.accentDanger
        }
        if splMeter.peakDB > splPreference.targetDB {
            return BoothColors.accentWarm
        }
        return BoothColors.accent
    }
}


// MARK: - ─── SPL Bar (Visual Meter) ─────────────────────────────────────────

private struct SPLBar: View {
    let currentDB: Double
    let targetDB: Double
    let thresholdDB: Double

    private let minDB: Double = 40
    private let maxDB: Double = 110

    private func normalized(_ db: Double) -> Double {
        max(0, min(1, (db - minDB) / (maxDB - minDB)))
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let targetPos = width * normalized(targetDB)
            let thresholdPos = width * normalized(targetDB + thresholdDB)
            let currentPos = width * normalized(currentDB)

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(BoothColors.surfaceElevated)
                    .frame(height: 12)

                // Green zone (safe)
                RoundedRectangle(cornerRadius: 4)
                    .fill(BoothColors.accent.opacity(0.3))
                    .frame(width: targetPos, height: 12)

                // Amber zone (over target, under threshold)
                RoundedRectangle(cornerRadius: 0)
                    .fill(BoothColors.accentWarm.opacity(0.3))
                    .frame(width: max(0, thresholdPos - targetPos), height: 12)
                    .offset(x: targetPos)

                // Current level indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(currentDB > targetDB + thresholdDB
                          ? BoothColors.accentDanger
                          : currentDB > targetDB
                            ? BoothColors.accentWarm
                            : BoothColors.accent)
                    .frame(width: max(4, currentPos), height: 12)

                // Target line
                Rectangle()
                    .fill(BoothColors.textPrimary)
                    .frame(width: 2, height: 18)
                    .offset(x: targetPos - 1)
            }
        }
        .frame(height: 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("SPL level bar, current \(Int(currentDB)) dB, target \(Int(targetDB)) dB")
        .accessibilityValue("\(Int(currentDB)) of \(Int(targetDB)) dB")

        // dB scale labels
        HStack {
            Text("\(Int(minDB))")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
            Spacer()
            Text("\(Int(targetDB)) target")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textSecondary)
            Spacer()
            Text("\(Int(maxDB))")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
        }
    }
}
