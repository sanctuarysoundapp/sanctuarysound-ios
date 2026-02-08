// ============================================================================
// AnalysisView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Displays delta analysis between imported mixer state and engine
//          recommendations. Shows per-channel comparison with color-coded
//          status indicators and actionable suggestions.
// ============================================================================

import SwiftUI

// MARK: - ─── Analysis View ───────────────────────────────────────────────────

struct AnalysisView: View {
    let analysis: MixerAnalysis
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // ── Overall Score ──
                        OverallScoreCard(analysis: analysis)

                        // ── SPL Estimate ──
                        if let spl = analysis.splEstimate {
                            SPLEstimateCard(estimate: spl)
                        }

                        // ── Global Suggestions ──
                        if !analysis.globalSuggestions.isEmpty {
                            SectionCard(title: "Suggestions") {
                                ForEach(Array(analysis.globalSuggestions.enumerated()), id: \.offset) { _, suggestion in
                                    Text(suggestion)
                                        .font(.system(size: 13))
                                        .foregroundStyle(BoothColors.textPrimary)
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(BoothColors.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }

                        // ── Channel Deltas ──
                        ForEach(analysis.channelDeltas) { delta in
                            ChannelDeltaCard(delta: delta)
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Mix Analysis")
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


// MARK: - ─── Overall Score Card ──────────────────────────────────────────────

private struct OverallScoreCard: View {
    let analysis: MixerAnalysis

    private var scoreColor: Color {
        switch analysis.overallScore {
        case .excellent: return BoothColors.accent
        case .good:      return BoothColors.accent
        case .fair:      return BoothColors.accentWarm
        case .poor:      return BoothColors.accentDanger
        }
    }

    var body: some View {
        SectionCard(title: "Analysis Result") {
            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: analysis.overallScore.emoji)
                        .font(.system(size: 36))
                        .foregroundStyle(scoreColor)

                    Text(analysis.overallScore.rawValue)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(scoreColor)
                }
                .frame(width: 100)

                VStack(alignment: .leading, spacing: 6) {
                    let total = analysis.channelDeltas.count
                    let optimal = analysis.channelDeltas.filter { $0.overallScore == .excellent || $0.overallScore == .good }.count
                    let attention = analysis.channelDeltas.filter { $0.overallScore == .poor }.count

                    StatusRow(label: "Channels analyzed", value: "\(total)", color: BoothColors.textPrimary)
                    StatusRow(label: "Looking good", value: "\(optimal)", color: BoothColors.accent)
                    if attention > 0 {
                        StatusRow(label: "Need attention", value: "\(attention)", color: BoothColors.accentDanger)
                    }
                }
            }
        }
    }
}

private struct StatusRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}


// MARK: - ─── SPL Estimate Card ───────────────────────────────────────────────

private struct SPLEstimateCard: View {
    let estimate: SPLEstimate

    private var color: Color {
        if estimate.flagged { return BoothColors.accentDanger }
        if estimate.deltaDB > 0 { return BoothColors.accentWarm }
        return BoothColors.accent
    }

    var body: some View {
        SectionCard(title: "SPL Estimate") {
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("PEAK")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                    Text("\(Int(estimate.estimatedPeakDB))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                    Text("dB SPL")
                        .font(.system(size: 9))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(spacing: 4) {
                    Text("TARGET")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                    Text("\(Int(estimate.targetDB))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textPrimary)
                    Text("dB SPL")
                        .font(.system(size: 9))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(spacing: 4) {
                    Text("DELTA")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                    Text(estimate.deltaDB >= 0 ? "+\(Int(estimate.deltaDB))" : "\(Int(estimate.deltaDB))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                    Text("dB")
                        .font(.system(size: 9))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(color.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text(estimate.message)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}


// MARK: - ─── Channel Delta Card ──────────────────────────────────────────────

private struct ChannelDeltaCard: View {
    let delta: ChannelDelta
    @State private var isExpanded = false

    private var scoreColor: Color {
        switch delta.overallScore {
        case .excellent: return BoothColors.accent
        case .good:      return BoothColors.accent
        case .fair:      return BoothColors.accentWarm
        case .poor:      return BoothColors.accentDanger
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ──
            HStack(spacing: 12) {
                Image(systemName: delta.overallScore.emoji)
                    .font(.system(size: 16))
                    .foregroundStyle(scoreColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ch \(delta.channelNumber): \(delta.channelName)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BoothColors.textPrimary)

                    if let source = delta.source {
                        Text(source.rawValue)
                            .font(.system(size: 11))
                            .foregroundStyle(BoothColors.textSecondary)
                    }
                }

                Spacer()

                Text(delta.overallScore.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(scoreColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(scoreColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textMuted)
            }
            .padding(16)

            // ── Status Indicators (always visible) ──
            HStack(spacing: 6) {
                DeltaStatusPill(label: "GAIN", status: delta.gainStatus)
                DeltaStatusPill(label: "FADER", status: delta.faderStatus)
                DeltaStatusPill(label: "HPF", status: delta.hpfStatus)
                if delta.compDelta != nil {
                    DeltaStatusPill(label: "COMP", status: delta.compDelta?.ratioStatus ?? .missing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, isExpanded ? 12 : 16)

            // ── Expanded Detail ──
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    // Gain detail
                    if let actual = delta.actualGainDB, let range = delta.recommendedGainRange {
                        DeltaRow(
                            param: "Gain",
                            actual: "\(Int(actual)) dB",
                            recommended: "\(Int(range.lowerBound))–\(Int(range.upperBound)) dB",
                            status: delta.gainStatus
                        )
                    }

                    // Fader detail
                    if let actual = delta.actualFaderDB, let rec = delta.recommendedFaderDB {
                        DeltaRow(
                            param: "Fader",
                            actual: String(format: "%+.0f dB", actual),
                            recommended: String(format: "%+.0f dB", rec),
                            status: delta.faderStatus
                        )
                    }

                    // HPF detail
                    if delta.recommendedHPF != nil || delta.actualHPF != nil {
                        DeltaRow(
                            param: "HPF",
                            actual: delta.actualHPF.map { "\(Int($0)) Hz" } ?? "Off",
                            recommended: delta.recommendedHPF.map { "\(Int($0)) Hz" } ?? "N/A",
                            status: delta.hpfStatus
                        )
                    }

                    // Compressor detail
                    if let comp = delta.compDelta {
                        VStack(alignment: .leading, spacing: 4) {
                            if let actRatio = comp.actualRatio, let recRatio = comp.recommendedRatio {
                                DeltaRow(
                                    param: "Comp Ratio",
                                    actual: String(format: "%.0f:1", actRatio),
                                    recommended: String(format: "%.0f:1", recRatio),
                                    status: comp.ratioStatus
                                )
                            }
                            if let actThresh = comp.actualThreshold, let recThresh = comp.recommendedThreshold {
                                DeltaRow(
                                    param: "Comp Threshold",
                                    actual: String(format: "%.0f dB", actThresh),
                                    recommended: String(format: "%.0f dB", recThresh),
                                    status: comp.thresholdStatus
                                )
                            }
                        }
                    }

                    // EQ deltas
                    if !delta.eqDeltas.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EQ ANALYSIS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(BoothColors.textMuted)
                                .tracking(1)

                            ForEach(delta.eqDeltas) { eq in
                                EQDeltaRow(eqDelta: eq)
                            }
                        }
                    }

                    // Suggestions
                    if !delta.suggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SUGGESTIONS")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(BoothColors.accentWarm)
                                .tracking(1)

                            ForEach(Array(delta.suggestions.enumerated()), id: \.offset) { _, suggestion in
                                Text(suggestion)
                                    .font(.system(size: 11))
                                    .foregroundStyle(BoothColors.textSecondary)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(BoothColors.accentWarm.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
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
}


// MARK: - ─── Delta UI Components ─────────────────────────────────────────────

private struct DeltaStatusPill: View {
    let label: String
    let status: DeltaStatus

    private var color: Color {
        switch status {
        case .optimal:   return BoothColors.accent
        case .close:     return BoothColors.accentWarm
        case .attention: return BoothColors.accentDanger
        case .missing:   return BoothColors.textMuted
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct DeltaRow: View {
    let param: String
    let actual: String
    let recommended: String
    let status: DeltaStatus

    private var statusColor: Color {
        switch status {
        case .optimal:   return BoothColors.accent
        case .close:     return BoothColors.accentWarm
        case .attention: return BoothColors.accentDanger
        case .missing:   return BoothColors.textMuted
        }
    }

    var body: some View {
        HStack {
            Text(param)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(BoothColors.textSecondary)
                .frame(width: 90, alignment: .leading)

            Text(actual)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(statusColor)
                .frame(width: 70, alignment: .trailing)

            Image(systemName: "arrow.right")
                .font(.system(size: 9))
                .foregroundStyle(BoothColors.textMuted)

            Text(recommended)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(BoothColors.textPrimary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct EQDeltaRow: View {
    let eqDelta: EQBandDelta

    private var color: Color {
        if abs(eqDelta.deltaDB) <= 1.5 { return BoothColors.accent }
        if abs(eqDelta.deltaDB) <= 3.0 { return BoothColors.accentWarm }
        return BoothColors.accentDanger
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(eqDelta.frequency >= 1000
                 ? String(format: "%.1fk", eqDelta.frequency / 1000)
                 : "\(Int(eqDelta.frequency)) Hz")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(BoothColors.textPrimary)
                .frame(width: 50, alignment: .leading)

            Text(String(format: "%+.1f", eqDelta.actualGainDB))
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 40, alignment: .trailing)

            Image(systemName: "arrow.right")
                .font(.system(size: 8))
                .foregroundStyle(BoothColors.textMuted)

            Text(String(format: "%+.1f", eqDelta.recommendedGainDB))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(BoothColors.textPrimary)
                .frame(width: 40, alignment: .trailing)

            Text(String(format: "%+.1f", eqDelta.deltaDB))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
