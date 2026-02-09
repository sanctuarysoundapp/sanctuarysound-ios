// ============================================================================
// EQAnalyzerView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Real-time 1/3-octave frequency spectrum display (RTA).
//          Shows 31 vertical bars with peak-hold markers, color-coded by
//          level. Designed for use in a dark sound booth during soundcheck.
// ============================================================================

import SwiftUI


// MARK: - ─── EQ Analyzer View ────────────────────────────────────────────────

struct EQAnalyzerView: View {
    @StateObject private var analyzer = EQAnalyzer()
    @State private var showSnapshotName = false
    @State private var snapshotName = ""

    /// dB range for the display.
    private let dbRange: ClosedRange<Double> = -60...0
    private let dbRangeSpan: Double = 60.0

    var body: some View {
        ZStack {
            BoothColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ── RTA Display ──
                    rtaDisplay

                    // ── Controls ──
                    controlsSection

                    // ── Saved Snapshots ──
                    if !analyzer.savedSnapshots.isEmpty {
                        snapshotsSection
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("EQ Analyzer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .task {
            await analyzer.requestPermission()
        }
        .alert("Save Snapshot", isPresented: $showSnapshotName) {
            TextField("Snapshot name", text: $snapshotName)
            Button("Save") {
                analyzer.captureSnapshot(name: snapshotName)
                snapshotName = ""
            }
            Button("Cancel", role: .cancel) { snapshotName = "" }
        } message: {
            Text("Name this frequency capture for later reference.")
        }
    }


    // MARK: - ─── RTA Display ─────────────────────────────────────────────────

    private var rtaDisplay: some View {
        SectionCard(title: "Frequency Spectrum") {
            VStack(spacing: 4) {
                // ── Bar Chart ──
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let barWidth = max(2, (width - CGFloat(FrequencyBands.count - 1)) / CGFloat(FrequencyBands.count))
                    let spacing: CGFloat = 1

                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(0..<FrequencyBands.count, id: \.self) { index in
                            bandBar(
                                level: analyzer.bandLevels[index],
                                peak: analyzer.peakLevels[index],
                                height: height,
                                width: barWidth
                            )
                        }
                    }
                }
                .frame(height: 200)
                .padding(.horizontal, 4)

                // ── Frequency Labels ──
                frequencyLabels
            }

            // ── Level Info ──
            if analyzer.isRunning {
                HStack(spacing: 16) {
                    let maxLevel = analyzer.bandLevels.max() ?? FFTProcessor.noiseFloorDB
                    InfoBadge(label: "Peak Band", value: "\(Int(maxLevel)) dB")
                    let avgLevel = analyzer.bandLevels.reduce(0, +) / Double(FrequencyBands.count)
                    InfoBadge(label: "Average", value: "\(Int(avgLevel)) dB")
                }
            }
        }
    }

    private func bandBar(level: Double, peak: Double, height: CGFloat, width: CGFloat) -> some View {
        let normalizedLevel = max(0, min(1, (level - dbRange.lowerBound) / dbRangeSpan))
        let barHeight = CGFloat(normalizedLevel) * height
        let normalizedPeak = max(0, min(1, (peak - dbRange.lowerBound) / dbRangeSpan))
        let peakY = height - CGFloat(normalizedPeak) * height

        return ZStack(alignment: .bottom) {
            // Background track
            RoundedRectangle(cornerRadius: 1)
                .fill(BoothColors.surfaceElevated)
                .frame(width: width)

            // Level bar
            RoundedRectangle(cornerRadius: 1)
                .fill(barColor(for: level))
                .frame(width: width, height: max(1, barHeight))

            // Peak hold marker
            if peak > FFTProcessor.noiseFloorDB + 10 {
                Rectangle()
                    .fill(BoothColors.accentWarm)
                    .frame(width: width, height: 2)
                    .offset(y: -(height - peakY - height + barHeight) + (height - barHeight))
                    .offset(y: peakY - (height - barHeight))
            }
        }
    }

    private func barColor(for level: Double) -> Color {
        switch level {
        case _ where level > -10:
            return BoothColors.accentDanger   // Hot — red
        case _ where level > -20:
            return BoothColors.accentWarm     // Warm — amber
        default:
            return BoothColors.accent         // Normal — green
        }
    }

    private var frequencyLabels: some View {
        HStack(spacing: 0) {
            ForEach(0..<FrequencyBands.count, id: \.self) { index in
                if FrequencyBands.majorTickIndices.contains(index) {
                    Text(FrequencyBands.displayLabels[index])
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                        .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 4)
    }


    // MARK: - ─── Controls ────────────────────────────────────────────────────

    private var controlsSection: some View {
        SectionCard(title: "Controls") {
            HStack(spacing: 12) {
                // Start/Stop
                Button {
                    if analyzer.isRunning {
                        analyzer.stop()
                    } else {
                        analyzer.start()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: analyzer.isRunning ? "stop.fill" : "play.fill")
                        Text(analyzer.isRunning ? "Stop" : "Start")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(analyzer.isRunning ? BoothColors.accentDanger : BoothColors.background)
                    .background(analyzer.isRunning ? BoothColors.surfaceElevated : BoothColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!analyzer.permissionGranted)

                // Capture Snapshot
                Button {
                    showSnapshotName = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Capture")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(BoothColors.background)
                    .background(BoothColors.accentWarm)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!analyzer.isRunning)
                .opacity(analyzer.isRunning ? 1.0 : 0.4)
            }

            // Reset peaks button
            if analyzer.isRunning {
                Button {
                    analyzer.resetPeaks()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Peaks")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .foregroundStyle(BoothColors.textSecondary)
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if !analyzer.permissionGranted {
                Text("Microphone access is required. Grant permission in Settings.")
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.accentWarm)
            }
        }
    }


    // MARK: - ─── Snapshots ───────────────────────────────────────────────────

    private var snapshotsSection: some View {
        SectionCard(title: "Saved Captures (\(analyzer.savedSnapshots.count))") {
            ForEach(analyzer.savedSnapshots) { snapshot in
                snapshotRow(snapshot)
            }
        }
    }

    private func snapshotRow(_ snapshot: EQSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                Text(formatDate(snapshot.date))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(BoothColors.textSecondary)
            }
            Spacer()

            // Mini spectrum preview
            HStack(spacing: 1) {
                ForEach(Array(stride(from: 0, to: FrequencyBands.count, by: 3)), id: \.self) { index in
                    let level = snapshot.bandLevels[index]
                    let normalized = max(0, min(1, (level - dbRange.lowerBound) / dbRangeSpan))
                    RoundedRectangle(cornerRadius: 1)
                        .fill(barColor(for: level))
                        .frame(width: 3, height: max(2, CGFloat(normalized) * 24))
                }
            }
            .frame(height: 24)
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button(role: .destructive) {
                analyzer.deleteSnapshot(id: snapshot.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
