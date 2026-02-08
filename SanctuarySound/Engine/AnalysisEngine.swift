// ============================================================================
// AnalysisEngine.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Business Logic Layer
// Purpose: Compares an imported MixerSnapshot against engine-generated
//          recommendations, producing a per-channel delta analysis with
//          actionable suggestions and SPL estimates.
// ============================================================================

import Foundation

// MARK: - ─── Analysis Engine ─────────────────────────────────────────────────

/// Compares actual mixer state against ideal recommendations.
/// Produces a `MixerAnalysis` with per-channel deltas and suggestions.
final class AnalysisEngine {

    // MARK: - Public API

    /// Perform a complete delta analysis.
    ///
    /// - Parameters:
    ///   - snapshot: The imported mixer state.
    ///   - recommendation: The engine-generated ideal settings.
    ///   - channelMapping: Maps snapshot channel numbers to InputSource types.
    ///   - splPreference: User's SPL target and flagging mode.
    /// - Returns: A `MixerAnalysis` result.
    func analyze(
        snapshot: MixerSnapshot,
        recommendation: MixerSettingRecommendation,
        channelMapping: [Int: InputSource],
        splPreference: SPLPreference? = nil
    ) -> MixerAnalysis {

        var channelDeltas: [ChannelDelta] = []

        for snapshotChannel in snapshot.channels {
            let matchedSource = channelMapping[snapshotChannel.channelNumber]

            // Find matching recommendation by source type and channel name
            let matchedRec = recommendation.channelRecommendations.first { rec in
                if let source = matchedSource {
                    return rec.channel.source == source
                }
                return rec.channel.label.lowercased() == snapshotChannel.name.lowercased()
            }

            let delta = analyzeChannel(
                snapshot: snapshotChannel,
                recommendation: matchedRec,
                source: matchedSource
            )
            channelDeltas.append(delta)
        }

        let overallScore = calculateOverallScore(channelDeltas: channelDeltas)
        let splEstimate = estimateSPL(
            snapshot: snapshot,
            recommendation: recommendation,
            splPreference: splPreference
        )
        let globalSuggestions = generateGlobalSuggestions(
            channelDeltas: channelDeltas,
            splEstimate: splEstimate
        )

        return MixerAnalysis(
            snapshot: snapshot,
            recommendation: recommendation,
            channelDeltas: channelDeltas,
            overallScore: overallScore,
            splEstimate: splEstimate,
            globalSuggestions: globalSuggestions
        )
    }


    // MARK: - Per-Channel Analysis

    private func analyzeChannel(
        snapshot: ChannelSnapshot,
        recommendation: ChannelRecommendation?,
        source: InputSource?
    ) -> ChannelDelta {

        var suggestions: [String] = []

        // ── Gain Analysis ──
        let gainStatus: DeltaStatus
        if let actualGain = snapshot.gainDB, let rec = recommendation {
            let range = rec.gainRangeDB
            if range.contains(actualGain) {
                gainStatus = .optimal
            } else {
                let distance = actualGain < range.lowerBound
                    ? range.lowerBound - actualGain
                    : actualGain - range.upperBound
                if distance <= 3.0 {
                    gainStatus = .close
                    suggestions.append("Gain is \(String(format: "%.0f", distance)) dB outside recommended range (\(Int(range.lowerBound))–\(Int(range.upperBound)) dB)")
                } else {
                    gainStatus = .attention
                    let direction = actualGain < range.lowerBound ? "under" : "over"
                    suggestions.append("Gain is \(String(format: "%.0f", distance)) dB \(direction) — recommended range is \(Int(range.lowerBound))–\(Int(range.upperBound)) dB")
                }
            }
        } else {
            gainStatus = .missing
        }

        // ── Fader Analysis ──
        let faderStatus: DeltaStatus
        if let actualFader = snapshot.faderDB, let rec = recommendation {
            let diff = abs(actualFader - rec.faderStartDB)
            if diff <= 2.0 {
                faderStatus = .optimal
            } else if diff <= 5.0 {
                faderStatus = .close
            } else {
                faderStatus = .attention
                suggestions.append("Fader at \(String(format: "%.0f", actualFader)) dB vs recommended \(String(format: "%.0f", rec.faderStartDB)) dB")
            }
        } else {
            faderStatus = .missing
        }

        // ── HPF Analysis ──
        let hpfStatus: DeltaStatus
        if let recHPF = recommendation?.hpfFrequency {
            if let actualHPF = snapshot.hpfFrequency, snapshot.hpfEnabled {
                let diff = abs(actualHPF - recHPF) / recHPF
                if diff <= 0.15 {
                    hpfStatus = .optimal
                } else if diff <= 0.30 {
                    hpfStatus = .close
                } else {
                    hpfStatus = .attention
                    let direction = actualHPF < recHPF ? "low" : "high"
                    suggestions.append("HPF at \(Int(actualHPF)) Hz is \(direction) — recommend \(Int(recHPF)) Hz")
                }
            } else if !snapshot.hpfEnabled {
                hpfStatus = .attention
                suggestions.append("HPF is bypassed — recommend enabling at \(Int(recHPF)) Hz")
            } else {
                hpfStatus = .missing
            }
        } else {
            hpfStatus = snapshot.hpfEnabled ? .optimal : .missing
        }

        // ── EQ Analysis ──
        let eqDeltas = analyzeEQ(
            snapshotBands: snapshot.eqBands,
            recommendedBands: recommendation?.eqBands ?? []
        )

        // Flag problematic EQ
        for eqDelta in eqDeltas where abs(eqDelta.deltaDB) > 3.0 {
            suggestions.append(eqDelta.suggestion)
        }

        // ── Compression Analysis ──
        let compDelta = analyzeCompressor(
            snapshot: snapshot,
            recommendation: recommendation?.compressor
        )

        if let comp = compDelta, comp.ratioStatus == .attention {
            suggestions.append(comp.suggestion)
        }

        // ── Overall Score ──
        let statuses = [gainStatus, faderStatus, hpfStatus]
        let score = scoreFromStatuses(statuses)

        return ChannelDelta(
            id: UUID(),
            channelName: snapshot.name,
            channelNumber: snapshot.channelNumber,
            source: source,
            actualGainDB: snapshot.gainDB,
            recommendedGainRange: recommendation?.gainRangeDB,
            gainStatus: gainStatus,
            actualFaderDB: snapshot.faderDB,
            recommendedFaderDB: recommendation?.faderStartDB,
            faderStatus: faderStatus,
            actualHPF: snapshot.hpfEnabled ? snapshot.hpfFrequency : nil,
            recommendedHPF: recommendation?.hpfFrequency,
            hpfStatus: hpfStatus,
            eqDeltas: eqDeltas,
            compDelta: compDelta,
            overallScore: score,
            suggestions: suggestions
        )
    }


    // MARK: - EQ Analysis

    private func analyzeEQ(
        snapshotBands: [SnapshotEQBand],
        recommendedBands: [EQRecommendation]
    ) -> [EQBandDelta] {

        var deltas: [EQBandDelta] = []

        // Match snapshot bands to recommended bands by frequency proximity
        for recBand in recommendedBands {
            let closest = snapshotBands.min(by: {
                abs($0.frequency - recBand.frequency) < abs($1.frequency - recBand.frequency)
            })

            if let actual = closest, abs(actual.frequency - recBand.frequency) / recBand.frequency < 0.25 {
                // Matched — compare gains
                let delta = actual.gainDB - recBand.gainDB
                var suggestion = ""
                if abs(delta) > 3.0 {
                    let direction = delta > 0 ? "more boost" : "more cut"
                    suggestion = "EQ at \(Int(recBand.frequency)) Hz: you have \(String(format: "%+.1f", actual.gainDB)) dB, recommend \(String(format: "%+.1f", recBand.gainDB)) dB (\(direction) than needed)"
                }
                deltas.append(EQBandDelta(
                    frequency: recBand.frequency,
                    actualGainDB: actual.gainDB,
                    recommendedGainDB: recBand.gainDB,
                    suggestion: suggestion
                ))
            } else {
                // No matching band — flag the recommendation as not applied
                deltas.append(EQBandDelta(
                    frequency: recBand.frequency,
                    actualGainDB: 0.0,
                    recommendedGainDB: recBand.gainDB,
                    suggestion: "Recommended \(String(format: "%+.1f", recBand.gainDB)) dB at \(Int(recBand.frequency)) Hz not applied — \(recBand.reason)"
                ))
            }
        }

        // Check for large boosts in snapshot that have no recommendation
        for actual in snapshotBands where actual.enabled && abs(actual.gainDB) > 4.0 {
            let alreadyMatched = deltas.contains { abs($0.frequency - actual.frequency) / actual.frequency < 0.25 }
            if !alreadyMatched {
                deltas.append(EQBandDelta(
                    frequency: actual.frequency,
                    actualGainDB: actual.gainDB,
                    recommendedGainDB: 0.0,
                    suggestion: "You have \(String(format: "%+.1f", actual.gainDB)) dB at \(Int(actual.frequency)) Hz — engine suggests flat here"
                ))
            }
        }

        return deltas
    }


    // MARK: - Compressor Analysis

    private func analyzeCompressor(
        snapshot: ChannelSnapshot,
        recommendation: CompressorRecommendation?
    ) -> CompressorDelta? {

        guard let rec = recommendation else {
            // No compression recommended
            if let actualRatio = snapshot.compRatio, actualRatio > 1.5 {
                return CompressorDelta(
                    actualThreshold: snapshot.compThresholdDB,
                    recommendedThreshold: nil,
                    actualRatio: actualRatio,
                    recommendedRatio: nil,
                    thresholdStatus: .close,
                    ratioStatus: .close,
                    suggestion: "Compression active (\(String(format: "%.0f", actualRatio)):1) but not recommended for this source"
                )
            }
            return nil
        }

        let thresholdStatus: DeltaStatus
        if let actualThresh = snapshot.compThresholdDB {
            let diff = abs(actualThresh - rec.thresholdDB)
            thresholdStatus = diff <= 3.0 ? .optimal : (diff <= 6.0 ? .close : .attention)
        } else {
            thresholdStatus = .missing
        }

        let ratioStatus: DeltaStatus
        var suggestion = ""
        if let actualRatio = snapshot.compRatio {
            let diff = abs(actualRatio - rec.ratio)
            if diff <= 0.5 {
                ratioStatus = .optimal
            } else if diff <= 1.5 {
                ratioStatus = .close
            } else {
                ratioStatus = .attention
                if actualRatio > 5.0 {
                    suggestion = "Ratio \(String(format: "%.0f", actualRatio)):1 is aggressive — recommend \(String(format: "%.0f", rec.ratio)):1 to avoid pumping"
                } else {
                    suggestion = "Ratio \(String(format: "%.0f", actualRatio)):1 vs recommended \(String(format: "%.0f", rec.ratio)):1"
                }
            }
        } else {
            ratioStatus = .missing
        }

        return CompressorDelta(
            actualThreshold: snapshot.compThresholdDB,
            recommendedThreshold: rec.thresholdDB,
            actualRatio: snapshot.compRatio,
            recommendedRatio: rec.ratio,
            thresholdStatus: thresholdStatus,
            ratioStatus: ratioStatus,
            suggestion: suggestion
        )
    }


    // MARK: - SPL Estimation

    private func estimateSPL(
        snapshot: MixerSnapshot,
        recommendation: MixerSettingRecommendation,
        splPreference: SPLPreference?
    ) -> SPLEstimate? {

        guard let pref = splPreference, let offset = pref.calibrationOffset else { return nil }

        // Estimate peak output level from fader positions and gains
        // Sum the active channel contributions (simplified: loudest channel + 10*log10(n) for n similar channels)
        let activeChannels = snapshot.channels.filter { ch in
            (ch.faderDB ?? -120) > -60
        }

        guard !activeChannels.isEmpty else { return nil }

        // Find the hottest channel (highest gain + fader sum)
        let levels = activeChannels.compactMap { ch -> Double? in
            guard let gain = ch.gainDB, let fader = ch.faderDB else { return nil }
            return gain + fader
        }

        guard let maxLevel = levels.max() else { return nil }

        // Rough estimate: peak master bus level ~= max channel level + 6 dB (headroom margin)
        // Apply calibration offset to convert dBFS to SPL
        let estimatedMasterDBFS = maxLevel - 18.0 // Relative to nominal -18 dBFS
        let estimatedSPL = estimatedMasterDBFS + offset

        // Account for song intensity (driving sections +3-5 dB over average)
        let maxIntensityOffset = recommendation.service.setlist
            .map { $0.intensity.faderOffsetDB }
            .max() ?? 0.0
        let peakSPL = estimatedSPL + maxIntensityOffset

        let delta = peakSPL - pref.targetDB
        let flagged = delta > pref.flagThresholdDB

        var message: String
        if flagged {
            message = "Estimated peak SPL: \(String(format: "%.0f", peakSPL)) dB — \(String(format: "%.0f", delta)) dB over your \(Int(pref.targetDB)) dB target"
        } else if delta > 0 {
            message = "Estimated peak SPL: \(String(format: "%.0f", peakSPL)) dB — \(String(format: "%.0f", delta)) dB over target but within \(pref.flaggingMode.localizedName) threshold"
        } else {
            message = "Estimated peak SPL: \(String(format: "%.0f", peakSPL)) dB — \(String(format: "%.0f", abs(delta))) dB under target"
        }

        return SPLEstimate(
            estimatedPeakDB: peakSPL,
            targetDB: pref.targetDB,
            deltaDB: delta,
            flagged: flagged,
            message: message
        )
    }


    // MARK: - Scoring

    private func scoreFromStatuses(_ statuses: [DeltaStatus]) -> AnalysisScore {
        let attentionCount = statuses.filter { $0 == .attention }.count
        let closeCount = statuses.filter { $0 == .close }.count

        if attentionCount >= 2 { return .poor }
        if attentionCount == 1 { return .fair }
        if closeCount >= 2 { return .fair }
        if closeCount == 1 { return .good }
        return .excellent
    }

    private func calculateOverallScore(channelDeltas: [ChannelDelta]) -> AnalysisScore {
        let scores = channelDeltas.map { $0.overallScore }
        let poorCount = scores.filter { $0 == .poor }.count
        let fairCount = scores.filter { $0 == .fair }.count

        if poorCount >= 3 { return .poor }
        if poorCount >= 1 || fairCount >= 4 { return .fair }
        if fairCount >= 2 { return .good }
        return .excellent
    }

    private func generateGlobalSuggestions(
        channelDeltas: [ChannelDelta],
        splEstimate: SPLEstimate?
    ) -> [String] {

        var suggestions: [String] = []

        // Gain issues
        let gainIssues = channelDeltas.filter { $0.gainStatus == .attention }
        if gainIssues.count >= 3 {
            suggestions.append("Multiple channels have gain staging issues. Consider reviewing your overall gain structure — the preamp should target -18 dBFS for optimal headroom.")
        }

        // HPF issues
        let hpfIssues = channelDeltas.filter { $0.hpfStatus == .attention }
        if hpfIssues.count >= 2 {
            suggestions.append("\(hpfIssues.count) channels have HPF issues. High-pass filters are critical for reducing low-end mud — especially in rooms with longer reverb tails.")
        }

        // Compression issues
        let compIssues = channelDeltas.compactMap { $0.compDelta }.filter { $0.ratioStatus == .attention }
        if !compIssues.isEmpty {
            suggestions.append("Some channels have aggressive compression ratios. For worship, keep ratios between 2:1 and 4:1 to avoid audible pumping.")
        }

        // SPL
        if let spl = splEstimate, spl.flagged {
            suggestions.append(spl.message)
        }

        return suggestions
    }
}
