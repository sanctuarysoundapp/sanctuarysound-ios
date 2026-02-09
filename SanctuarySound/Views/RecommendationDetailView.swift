// ============================================================================
// RecommendationDetailView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Displays the SoundEngine output — per-channel gain, EQ,
//          compression, HPF, key warnings, and global notes.
// Design: Dark booth-optimized UI with channel cards and visual indicators.
// ============================================================================

import SwiftUI

// MARK: - ─── Main Recommendation View ────────────────────────────────────────

struct RecommendationDetailView: View {
    let recommendation: MixerSettingRecommendation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // ── Header Summary ──
                        RecommendationHeader(recommendation: recommendation)

                        // ── Global Notes ──
                        if !recommendation.globalNotes.isEmpty {
                            GlobalNotesCard(notes: recommendation.globalNotes)
                        }

                        // ── Channel Cards ──
                        ForEach(recommendation.channelRecommendations) { channelRec in
                            ChannelRecommendationCard(
                                channelRec: channelRec,
                                detailLevel: recommendation.service.detailLevel
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Mix Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(BoothColors.accent)
                }
            }
        }
    }
}


// MARK: - ─── Header Summary ──────────────────────────────────────────────────

private struct RecommendationHeader: View {
    let recommendation: MixerSettingRecommendation

    private var service: WorshipService { recommendation.service }

    var body: some View {
        SectionCard(title: "Service Overview") {
            HStack(spacing: 12) {
                InfoBadge(label: "Console", value: service.mixer.shortName)
                InfoBadge(label: "Channels", value: "\(recommendation.channelRecommendations.count)")
                InfoBadge(label: "Songs", value: "\(service.setlist.count)")
                InfoBadge(label: "Level", value: service.detailLevel.shortName)
            }

            HStack(spacing: 12) {
                InfoBadge(label: "RT60", value: String(format: "%.1fs", service.room.effectiveRT60))
                InfoBadge(label: "Drums", value: service.drumConfig.localizedName.components(separatedBy: " ").first ?? "")
                InfoBadge(
                    label: "Room",
                    value: service.room.hasLowEndProblem ? "Boomy" : "OK",
                    color: service.room.hasLowEndProblem ? BoothColors.accentWarm : BoothColors.accent
                )
            }
        }
    }
}


// MARK: - ─── Global Notes Card ───────────────────────────────────────────────

private struct GlobalNotesCard: View {
    let notes: [String]

    var body: some View {
        SectionCard(title: "Global Notes") {
            ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                Text(note)
                    .font(.system(size: 13))
                    .foregroundStyle(BoothColors.textPrimary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}


// MARK: - ─── Channel Recommendation Card ─────────────────────────────────────

private struct ChannelRecommendationCard: View {
    let channelRec: ChannelRecommendation
    let detailLevel: DetailLevel

    @State private var isExpanded: Bool = false

    private var channel: InputChannel { channelRec.channel }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Channel Header (always visible) ──
            channelHeader

            // ── Gain & Fader (always visible) ──
            gainFaderSection

            // ── Expandable Detail ──
            if isExpanded {
                VStack(spacing: 12) {
                    // HPF
                    if detailLevel.showsHPF, let hpf = channelRec.hpfFrequency {
                        hpfSection(hpf: hpf)
                    }

                    // EQ
                    if detailLevel.showsEQ, !channelRec.eqBands.isEmpty {
                        eqSection
                    }

                    // Compression
                    if detailLevel.showsCompression, let comp = channelRec.compressor {
                        compressorSection(comp: comp)
                    }

                    // Key Warnings
                    if !channelRec.keyWarnings.isEmpty {
                        keyWarningsSection
                    }

                    // Notes
                    if !channelRec.notes.isEmpty {
                        notesSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(BoothColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
    }

    // ── Channel Header ──
    private var channelHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: channel.source.category.systemIcon)
                .font(.system(size: 16))
                .foregroundStyle(BoothColors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BoothColors.textPrimary)

                Text(channel.source.localizedName)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
            }

            Spacer()

            // Line/Mic badge
            if channel.source.isLineLevel {
                Text("LINE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accentWarm)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BoothColors.accentWarm.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Text("MIC")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BoothColors.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(BoothColors.textMuted)
        }
        .padding(16)
    }

    // ── Gain & Fader Section ──
    private var gainFaderSection: some View {
        HStack(spacing: 8) {
            // Gain range
            GainRangeIndicator(
                range: channelRec.gainRangeDB,
                label: "GAIN"
            )

            // Fader start
            VStack(spacing: 4) {
                Text("FADER")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
                    .tracking(1)

                Text(formatDB(channelRec.faderStartDB))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.textPrimary)

                Text("dB start")
                    .font(.system(size: 9))
                    .foregroundStyle(BoothColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Headroom
            VStack(spacing: 4) {
                Text("HEADROOM")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
                    .tracking(1)

                Text(formatDB(channelRec.headroomDB))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(headroomColor(channelRec.headroomDB))

                Text("dB safe")
                    .font(.system(size: 9))
                    .foregroundStyle(BoothColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, isExpanded ? 12 : 16)
    }

    // ── HPF Section ──
    private func hpfSection(hpf: Double) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.accentWarm)

            Text("HPF")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textSecondary)

            Spacer()

            Text("\(Int(hpf)) Hz")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.accentWarm)
        }
        .padding(12)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // ── EQ Section ──
    private var eqSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EQ BANDS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
                .tracking(1)

            ForEach(channelRec.eqBands) { band in
                EQBandRow(band: band)
            }
        }
    }

    // ── Compressor Section ──
    private func compressorSection(comp: CompressorRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("COMPRESSOR")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
                .tracking(1)

            VStack(spacing: 10) {
                // ── Parameter grid — 2 rows of 2 for readability ──
                HStack(spacing: 8) {
                    CompressorBadge(label: "Threshold", value: "\(formatDB(comp.thresholdDB)) dB")
                    CompressorBadge(label: "Ratio", value: String(format: "%.0f:1", comp.ratio))
                }
                HStack(spacing: 8) {
                    CompressorBadge(label: "Attack", value: String(format: "%.0f ms", comp.attackMS))
                    CompressorBadge(label: "Release", value: String(format: "%.0f ms", comp.releaseMS))
                }

                if comp.makeupGainDB > 0 {
                    HStack {
                        Text("Makeup Gain")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BoothColors.textSecondary)
                        Spacer()
                        Text("+\(String(format: "%.1f", comp.makeupGainDB)) dB")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.accentWarm)
                    }
                    .padding(.horizontal, 4)
                }

                if !comp.reason.isEmpty {
                    Text(comp.reason)
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // ── Key Warnings Section ──
    private var keyWarningsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KEY WARNINGS")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.accentWarm)
                .tracking(1)

            ForEach(channelRec.keyWarnings) { warning in
                KeyWarningRow(warning: warning)
            }
        }
    }

    // ── Notes Section ──
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
                .tracking(1)

            ForEach(Array(channelRec.notes.enumerated()), id: \.offset) { _, note in
                Text(note)
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // ── Helpers ──

    private func headroomColor(_ dB: Double) -> Color {
        if dB >= 12 { return BoothColors.accent }
        if dB >= 6 { return BoothColors.accentWarm }
        return BoothColors.accentDanger
    }
}


// MARK: - ─── Gain Range Indicator ────────────────────────────────────────────

private struct GainRangeIndicator: View {
    let range: ClosedRange<Double>
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
                .tracking(1)

            Text("\(Int(range.lowerBound))–\(Int(range.upperBound))")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.accent)

            Text("dB range")
                .font(.system(size: 9))
                .foregroundStyle(BoothColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(BoothColors.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


// MARK: - ─── EQ Band Row ─────────────────────────────────────────────────────

private struct EQBandRow: View {
    let band: EQRecommendation

    private var isBoost: Bool { band.gainDB > 0 }
    private var color: Color { isBoost ? BoothColors.accentWarm : BoothColors.accent }
    private var actionLabel: String { isBoost ? "BOOST" : "CUT" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ── Top row: Freq, Q, action label, gain value ──
            HStack(spacing: 10) {
                // Frequency
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatFrequency(band.frequency))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textPrimary)

                    Text("Q: \(String(format: "%.1f", band.q))")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(BoothColors.textSecondary)
                }

                Spacer()

                // CUT / BOOST label
                Text(actionLabel)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                // Gain value
                Text("\(formatDB(band.gainDB)) dB")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }

            // ── Gain bar ──
            GainBar(gainDB: band.gainDB, color: color)

            // ── Reason ──
            if !band.reason.isEmpty {
                Text(band.reason)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


// MARK: - ─── Gain Bar (Visual EQ Indicator) ──────────────────────────────────

private struct GainBar: View {
    let gainDB: Double
    let color: Color

    private var normalizedWidth: Double {
        min(abs(gainDB) / 8.0, 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: gainDB >= 0 ? .leading : .trailing) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(BoothColors.divider)
                    .frame(height: 6)

                // Center line
                Rectangle()
                    .fill(BoothColors.textMuted)
                    .frame(width: 1, height: 10)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                // Gain indicator
                if gainDB >= 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: (geo.size.width / 2) * normalizedWidth, height: 6)
                        .offset(x: geo.size.width / 2)
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: (geo.size.width / 2) * normalizedWidth, height: 6)
                        .offset(x: (geo.size.width / 2) * (1.0 - normalizedWidth))
                }
            }
        }
        .frame(height: 10)
    }
}


// MARK: - ─── Compressor Badge ────────────────────────────────────────────────

private struct CompressorBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(BoothColors.textSecondary)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(BoothColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}


// MARK: - ─── Key Warning Row ─────────────────────────────────────────────────

private struct KeyWarningRow: View {
    let warning: KeyWarning

    private var severityColor: Color {
        switch warning.severity {
        case .low: return BoothColors.textSecondary
        case .moderate: return BoothColors.accentWarm
        case .high: return BoothColors.accentDanger
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(warning.song.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BoothColors.textPrimary)

                    Text("Key: \(warning.song.key.localizedName)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(severityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(severityColor.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))

                    Text("\(Int(warning.conflictFrequency)) Hz")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                }

                Text(warning.suggestion)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(severityColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


// MARK: - ─── Formatting Helpers ──────────────────────────────────────────────

private func formatDB(_ value: Double) -> String {
    let sign = value >= 0 ? "+" : ""
    return "\(sign)\(String(format: "%.1f", value))"
}

private func formatFrequency(_ hz: Double) -> String {
    if hz >= 1000 {
        return String(format: "%.1fk", hz / 1000)
    }
    return "\(Int(hz))"
}
