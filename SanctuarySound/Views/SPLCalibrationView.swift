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
import UIKit

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

                    // Slider
                    Slider(
                        value: $splPreference.targetDB,
                        in: Self.splMin...Self.splMax,
                        step: 1
                    )
                    .tint(targetSliderColor)

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
            }
        }
        .alert("Calibrate SPL Meter", isPresented: $showCalibrationPrompt) {
            TextField("Reference SPL (dB)", text: $calibrationSPL)
                .keyboardType(.decimalPad)
            Button("Calibrate") {
                if let knownSPL = Double(calibrationSPL) {
                    let offset = splMeter.calculateCalibrationOffset(knownSPL: knownSPL)
                    splPreference = SPLPreference(
                        targetDB: splPreference.targetDB,
                        flaggingMode: splPreference.flaggingMode,
                        calibrationOffset: offset
                    )
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Play a steady tone and enter the SPL reading from your reference meter. The iPhone mic will be calibrated to match.")
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
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
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


// MARK: - ─── SPL Session Report View ─────────────────────────────────────────

/// Post-service report showing SPL behavior, breach events, and overall grade.
struct SPLSessionReportView: View {
    let report: SPLSessionReport
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Grade Card ──
                        gradeCard

                        // ── Summary Stats ──
                        summarySection

                        // ── Breach Timeline ──
                        if !report.breachEvents.isEmpty {
                            breachListSection
                        }

                        // ── Share Button ──
                        shareSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Service Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(BoothColors.accent)
                }
                ToolbarItem(placement: .primaryAction) {
                    if let image = renderedImage {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview(
                                "SPL Report — \(formatSessionDate(report.sessionStart))",
                                image: Image(uiImage: image)
                            )
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(BoothColors.accent)
                        }
                    } else {
                        Button {
                            renderReportImage()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(BoothColors.accent)
                        }
                    }
                }
            }
            .onAppear {
                renderReportImage()
            }
        }
    }

    // MARK: - Image Rendering

    /// Renders the report content as a shareable PNG image using ImageRenderer.
    private func renderReportImage() {
        guard !isRendering else { return }
        isRendering = true

        let reportContent = ReportExportView(report: report)

        Task { @MainActor in
            let renderer = ImageRenderer(content: reportContent)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                renderedImage = uiImage
            }
            isRendering = false
        }
    }


    // MARK: - Share Section

    private var shareSection: some View {
        VStack(spacing: 12) {
            if let image = renderedImage {
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview(
                        "SPL Report — \(formatSessionDate(report.sessionStart))",
                        image: Image(uiImage: image)
                    )
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Report as Image")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(BoothColors.background)
                    .background(BoothColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                Button {
                    renderReportImage()
                } label: {
                    HStack(spacing: 8) {
                        if isRendering {
                            ProgressView()
                                .tint(BoothColors.background)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "photo")
                        }
                        Text(isRendering ? "Rendering..." : "Prepare Shareable Image")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(BoothColors.textPrimary)
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isRendering)
            }

            Text("Exports the report as a shareable image — send via Messages, email, or save to Photos.")
                .font(.system(size: 10))
                .foregroundStyle(BoothColors.textMuted)
                .multilineTextAlignment(.center)
        }
    }


    // MARK: - Grade Card

    private var gradeCard: some View {
        VStack(spacing: 12) {
            Text(gradeEmoji)
                .font(.system(size: 48))

            Text(gradeLabel)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(gradeColor)

            Text(gradeSummary)
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)

            // Date/time
            Text(formatSessionDate(report.sessionStart))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(gradeColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(gradeColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var gradeLabel: String {
        if report.breachCount == 0 { return "Clean Service" }
        if report.dangerCount == 0 && report.breachPercentage < 10 { return "Good Control" }
        if report.breachPercentage < 20 { return "Needs Attention" }
        return "Over Target"
    }

    private var gradeEmoji: String {
        if report.breachCount == 0 { return "🟢" }
        if report.dangerCount == 0 && report.breachPercentage < 10 { return "🟡" }
        if report.breachPercentage < 20 { return "🟠" }
        return "🔴"
    }

    private var gradeColor: Color {
        if report.breachCount == 0 { return BoothColors.accent }
        if report.dangerCount == 0 && report.breachPercentage < 10 { return BoothColors.accentWarm }
        return BoothColors.accentDanger
    }

    private var gradeSummary: String {
        if report.breachCount == 0 {
            return "SPL stayed within target for the entire session."
        }
        let pct = String(format: "%.0f%%", report.breachPercentage)
        return "\(report.breachCount) breach\(report.breachCount == 1 ? "" : "es") over \(Int(report.targetDB)) dB target. Over target \(pct) of the time."
    }


    // MARK: - Summary Section

    private var summarySection: some View {
        SectionCard(title: "Session Summary") {
            // ── Row 1: Key stats ──
            HStack(spacing: 8) {
                ReportStatBadge(
                    label: "Duration",
                    value: formatDuration(report.totalMonitoringSeconds),
                    color: BoothColors.textPrimary
                )
                ReportStatBadge(
                    label: "Target",
                    value: "\(Int(report.targetDB)) dB",
                    color: BoothColors.accent
                )
                ReportStatBadge(
                    label: "Mode",
                    value: report.flaggingMode.localizedName,
                    color: BoothColors.accentWarm
                )
            }

            // ── Row 2: Levels ──
            HStack(spacing: 8) {
                ReportStatBadge(
                    label: "Peak",
                    value: "\(Int(report.overallPeakDB)) dB",
                    color: report.overallPeakDB > report.targetDB
                        ? BoothColors.accentDanger
                        : BoothColors.accent
                )
                ReportStatBadge(
                    label: "Average",
                    value: "\(Int(report.overallAverageDB)) dB",
                    color: BoothColors.textPrimary
                )
                ReportStatBadge(
                    label: "Breaches",
                    value: "\(report.breachCount)",
                    color: report.breachCount > 0
                        ? BoothColors.accentWarm
                        : BoothColors.accent
                )
            }

            // ── Row 3: Breach stats (if any) ──
            if report.breachCount > 0 {
                HStack(spacing: 8) {
                    ReportStatBadge(
                        label: "Over Target",
                        value: String(format: "%.0f%%", report.breachPercentage),
                        color: BoothColors.accentDanger
                    )
                    ReportStatBadge(
                        label: "Longest",
                        value: formatDuration(report.longestBreachSeconds),
                        color: BoothColors.accentWarm
                    )
                    ReportStatBadge(
                        label: "Danger",
                        value: "\(report.dangerCount)",
                        color: report.dangerCount > 0
                            ? BoothColors.accentDanger
                            : BoothColors.accent
                    )
                }
            }
        }
    }


    // MARK: - Breach List

    private var breachListSection: some View {
        SectionCard(title: "Breach Events (\(report.breachCount))") {
            ForEach(report.breachEvents) { event in
                HStack(spacing: 12) {
                    // Severity indicator
                    Circle()
                        .fill(event.wasDanger ? BoothColors.accentDanger : BoothColors.accentWarm)
                        .frame(width: 8, height: 8)

                    // Time
                    Text(formatTime(event.startTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(BoothColors.textSecondary)
                        .frame(width: 70, alignment: .leading)

                    // Peak
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Peak \(Int(event.peakDB)) dB")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(event.wasDanger ? BoothColors.accentDanger : BoothColors.accentWarm)
                        Text("+\(Int(event.overTargetDB)) dB over · \(formatDuration(event.durationSeconds))")
                            .font(.system(size: 10))
                            .foregroundStyle(BoothColors.textMuted)
                    }

                    Spacer()
                }
                .padding(8)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }


    // MARK: - Formatters

    private func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d · h:mm a"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter.string(from: date)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
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


// MARK: - ─── Report Stat Badge ───────────────────────────────────────────────

private struct ReportStatBadge: View {
    let label: String
    let value: String
    var color: Color = BoothColors.textPrimary

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(BoothColors.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}


// MARK: - ─── Report Export View (Image Renderer) ─────────────────────────────

/// A self-contained view designed for rendering as a shareable image via ImageRenderer.
/// Includes all report data with branding, optimized for a fixed-width PNG.
private struct ReportExportView: View {
    let report: SPLSessionReport

    // ── Grade Helpers ──
    private var gradeLabel: String {
        if report.breachCount == 0 { return "Clean Service" }
        if report.dangerCount == 0 && report.breachPercentage < 10 { return "Good Control" }
        if report.breachPercentage < 20 { return "Needs Attention" }
        return "Over Target"
    }

    private var gradeEmoji: String {
        if report.breachCount == 0 { return "🟢" }
        if report.dangerCount == 0 && report.breachPercentage < 10 { return "🟡" }
        if report.breachPercentage < 20 { return "🟠" }
        return "🔴"
    }

    private var gradeColor: Color {
        if report.breachCount == 0 { return BoothColors.accent }
        if report.dangerCount == 0 && report.breachPercentage < 10 { return BoothColors.accentWarm }
        return BoothColors.accentDanger
    }

    private var gradeSummary: String {
        if report.breachCount == 0 {
            return "SPL stayed within target for the entire session."
        }
        let pct = String(format: "%.0f%%", report.breachPercentage)
        return "\(report.breachCount) breach\(report.breachCount == 1 ? "" : "es") over \(Int(report.targetDB)) dB target. Over target \(pct) of the time."
    }

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
                Text(formatSessionDate(report.sessionStart))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
            }
            .padding(.bottom, 4)

            // ── Grade Card ──
            VStack(spacing: 8) {
                Text(gradeEmoji)
                    .font(.system(size: 36))
                Text(gradeLabel)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(gradeColor)
                Text(gradeSummary)
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(gradeColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(gradeColor.opacity(0.2), lineWidth: 1)
            )

            // ── Stats Grid ──
            VStack(spacing: 8) {
                Text("SESSION SUMMARY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
                    .tracking(1)

                HStack(spacing: 8) {
                    exportStatBadge(label: "Duration", value: formatDuration(report.totalMonitoringSeconds))
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
                            value: formatDuration(report.longestBreachSeconds),
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

                            Text(formatTime(event.startTime))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(BoothColors.textSecondary)
                                .frame(width: 65, alignment: .leading)

                            Text("Peak \(Int(event.peakDB)) dB")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(event.wasDanger ? BoothColors.accentDanger : BoothColors.accentWarm)

                            Spacer()

                            Text("+\(Int(event.overTargetDB)) dB · \(formatDuration(event.durationSeconds))")
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

    // ── Formatters ──
    private func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d · h:mm a"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter.string(from: date)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
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
