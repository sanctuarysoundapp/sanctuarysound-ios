// ============================================================================
// RT60MeasurementView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Guided RT60 measurement wizard. Walks the volunteer through a
//          clap test — measuring ambient noise, detecting the impulse, and
//          calculating reverberation time. Displays results with room
//          classification and actionable mixing advice.
// ============================================================================

import SwiftUI


// MARK: - ─── RT60 Measurement View ──────────────────────────────────────────

struct RT60MeasurementView: View {
    @StateObject private var analyzer = RT60Analyzer()

    var body: some View {
        ZStack {
            BoothColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ── Phase-Based Content ──
                    phaseContent

                    // ── Past Measurements ──
                    if !analyzer.savedMeasurements.isEmpty {
                        measurementsSection
                    }
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Room Acoustics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .task {
            await analyzer.requestPermission()
        }
    }


    // MARK: - ─── Phase Content ───────────────────────────────────────────────

    @ViewBuilder
    private var phaseContent: some View {
        switch analyzer.phase {
        case .idle:
            idlePhase
        case .measuringNoiseFloor:
            noiseFloorPhase
        case .listeningForImpulse:
            listeningPhase
        case .recordingDecay:
            recordingPhase
        case .processing:
            processingPhase
        case .result(let measurement):
            resultPhase(measurement)
        case .failed(let reason):
            failedPhase(reason)
        }
    }


    // MARK: - Idle

    private var idlePhase: some View {
        SectionCard(title: "Measure Your Room") {
            VStack(spacing: 16) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 48))
                    .foregroundStyle(BoothColors.accent)
                    .frame(maxWidth: .infinity)

                Text("Measure the reverberation time (RT60) of your room using a clap test. This tells you how long sound takes to decay, which affects your mixing decisions.")
                    .font(.system(size: 13))
                    .foregroundStyle(BoothColors.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(number: "1", text: "Find a quiet moment (no music, minimal talking)")
                    instructionRow(number: "2", text: "Hold your phone at mix position")
                    instructionRow(number: "3", text: "When prompted, clap once — loud and sharp")
                    instructionRow(number: "4", text: "Stay quiet while the decay is recorded")
                }
                .padding(.vertical, 8)

                Button {
                    analyzer.startMeasurement()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Begin Measurement")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(BoothColors.background)
                    .background(BoothColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!analyzer.permissionGranted)

                if !analyzer.permissionGranted {
                    Text("Microphone access is required. Grant permission in Settings.")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.accentWarm)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.accent)
                .frame(width: 20, height: 20)
                .background(BoothColors.accent.opacity(0.15))
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textPrimary)
        }
    }


    // MARK: - Noise Floor

    private var noiseFloorPhase: some View {
        SectionCard(title: "Measuring Ambient Noise") {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(BoothColors.accent)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity)
                    .padding()

                Text("Sampling the noise floor...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)

                Text("Stay quiet. Measuring ambient noise level for reference.")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)
                    .multilineTextAlignment(.center)

                cancelButton
            }
        }
    }


    // MARK: - Listening

    private var listeningPhase: some View {
        SectionCard(title: "Ready") {
            VStack(spacing: 16) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(BoothColors.accentWarm)
                    .frame(maxWidth: .infinity)
                    .symbolEffect(.pulse)

                Text("CLAP NOW!")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundStyle(BoothColors.accentWarm)
                    .tracking(2)

                Text("One loud, sharp clap. Then stay quiet while the room decays.")
                    .font(.system(size: 13))
                    .foregroundStyle(BoothColors.textSecondary)
                    .multilineTextAlignment(.center)

                cancelButton
            }
        }
    }


    // MARK: - Recording Decay

    private var recordingPhase: some View {
        SectionCard(title: "Clap Detected") {
            VStack(spacing: 16) {
                Image(systemName: "waveform")
                    .font(.system(size: 48))
                    .foregroundStyle(BoothColors.accent)
                    .frame(maxWidth: .infinity)
                    .symbolEffect(.variableColor)

                Text("Recording decay...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)

                Text("Stay quiet. Listening to the room reverb die away.")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)
                    .multilineTextAlignment(.center)

                ProgressView()
                    .tint(BoothColors.accent)

                cancelButton
            }
        }
    }


    // MARK: - Processing

    private var processingPhase: some View {
        SectionCard(title: "Analyzing") {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(BoothColors.accent)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity)
                    .padding()

                Text("Processing impulse response...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
            }
        }
    }


    // MARK: - Result

    private func resultPhase(_ measurement: RT60Measurement) -> some View {
        VStack(spacing: 20) {
            SectionCard(title: "Result") {
                VStack(spacing: 16) {
                    // Big RT60 number
                    VStack(spacing: 4) {
                        Text(String(format: "%.2f", measurement.rt60Seconds))
                            .font(.system(size: 56, weight: .black, design: .monospaced))
                            .foregroundStyle(BoothColors.accent)

                        Text("seconds (RT60)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    // Classification
                    HStack(spacing: 8) {
                        Text(measurement.roomClassification)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(classificationColor(measurement.roomClassification))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(classificationColor(measurement.roomClassification).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        if !measurement.isReliable {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                Text("Low SNR")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(BoothColors.accentWarm)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(BoothColors.accentWarm.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    // Stats
                    HStack(spacing: 16) {
                        InfoBadge(label: "Noise Floor", value: "\(Int(measurement.noiseFloorDB)) dB")
                        InfoBadge(label: "SNR", value: "\(Int(measurement.snrDB)) dB")
                    }
                }
            }

            // Advice
            SectionCard(title: "Mixing Advice") {
                Text(RT60Calculator.advice(for: measurement.rt60Seconds))
                    .font(.system(size: 13))
                    .foregroundStyle(BoothColors.textPrimary)
                    .lineSpacing(3)
            }

            // Actions
            SectionCard(title: "Actions") {
                Button {
                    analyzer.reset()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Measure Again")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(BoothColors.background)
                    .background(BoothColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private func classificationColor(_ classification: String) -> Color {
        switch classification {
        case "Very Dry", "Dry":
            return BoothColors.accent
        case "Moderate":
            return BoothColors.accentWarm
        default:
            return BoothColors.accentDanger
        }
    }


    // MARK: - Failed

    private func failedPhase(_ reason: String) -> some View {
        SectionCard(title: "Measurement Failed") {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(BoothColors.accentWarm)
                    .frame(maxWidth: .infinity)

                Text(reason)
                    .font(.system(size: 13))
                    .foregroundStyle(BoothColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    analyzer.reset()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Try Again")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(BoothColors.background)
                    .background(BoothColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }


    // MARK: - ─── Saved Measurements ──────────────────────────────────────────

    private var measurementsSection: some View {
        SectionCard(title: "Past Measurements (\(analyzer.savedMeasurements.count))") {
            ForEach(analyzer.savedMeasurements) { measurement in
                measurementRow(measurement)
            }
        }
    }

    private func measurementRow(_ measurement: RT60Measurement) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(String(format: "%.2fs", measurement.rt60Seconds))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textPrimary)

                    Text(measurement.roomClassification)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(classificationColor(measurement.roomClassification))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(classificationColor(measurement.roomClassification).opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    if !measurement.isReliable {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(BoothColors.accentWarm)
                    }
                }

                Text(formatDate(measurement.date))
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
            }
            Spacer()
            Text("SNR: \(Int(measurement.snrDB)) dB")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button(role: .destructive) {
                analyzer.deleteMeasurement(id: measurement.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }


    // MARK: - ─── Helpers ─────────────────────────────────────────────────────

    private var cancelButton: some View {
        Button {
            analyzer.cancelMeasurement()
        } label: {
            Text("Cancel")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BoothColors.textSecondary)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
