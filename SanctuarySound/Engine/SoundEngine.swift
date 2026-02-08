// ============================================================================
// SoundEngine.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Business Logic Layer
// Purpose: Accepts a WorshipService model and returns a complete
//          MixerSettingRecommendation with per-channel gain, EQ,
//          compression, and key-aware warnings.
// Reference Level: -18 dBFS (see AudioConstants)
// ============================================================================

import Foundation

// MARK: - ─── Sound Engine ─────────────────────────────────────────────────

/// The core calculation engine. Stateless and pure — takes inputs, returns outputs.
/// Designed to be easily testable with no side effects.
final class SoundEngine {
    
    // MARK: - Public API
    
    /// Generate a complete mix recommendation for a worship service.
    /// This is the single entry point for the entire engine.
    ///
    /// - Parameter service: A fully populated `WorshipService` model.
    /// - Returns: A `MixerSettingRecommendation` with per-channel advice.
    func generateRecommendation(for service: WorshipService) -> MixerSettingRecommendation {
        
        let channelRecs = service.channels
            .filter { $0.isActive }
            .map { channel in
                calculateChannelRecommendation(
                    channel: channel,
                    mixer: service.mixer,
                    room: service.room,
                    drumConfig: service.drumConfig,
                    setlist: service.setlist,
                    experienceLevel: service.experienceLevel,
                    bandComposition: service.bandComposition
                )
            }
        
        let globalNotes = generateGlobalNotes(for: service)
        
        return MixerSettingRecommendation(
            service: service,
            channelRecommendations: channelRecs,
            globalNotes: globalNotes
        )
    }
    
    
    // MARK: - Per-Channel Calculation Pipeline
    
    /// The master calculation for a single channel. Orchestrates all sub-calculations.
    private func calculateChannelRecommendation(
        channel: InputChannel,
        mixer: MixerModel,
        room: RoomProfile,
        drumConfig: DrumConfiguration,
        setlist: [SetlistSong],
        experienceLevel: ExperienceLevel,
        bandComposition: BandComposition
    ) -> ChannelRecommendation {
        
        // ── Step 1: Gain Staging ──
        let gainResult = calculateGain(
            source: channel.source,
            mixer: mixer,
            vocalProfile: channel.vocalProfile,
            drumConfig: drumConfig
        )
        
        // ── Step 2: Fader Position ──
        let faderStart = calculateFaderStart(
            source: channel.source,
            bandComposition: bandComposition,
            setlist: setlist
        )
        
        // ── Step 3: HPF ──
        let hpf = calculateHPF(
            source: channel.source,
            room: room,
            setlist: setlist
        )
        
        // ── Step 4: EQ ──
        let eqBands: [EQRecommendation]
        if experienceLevel.showsEQ {
            eqBands = calculateEQ(
                source: channel.source,
                vocalProfile: channel.vocalProfile,
                room: room,
                setlist: setlist,
                mixer: mixer
            )
        } else {
            eqBands = []
        }
        
        // ── Step 5: Compression ──
        let compressor: CompressorRecommendation?
        if experienceLevel.showsCompression {
            compressor = calculateCompressor(
                source: channel.source,
                vocalProfile: channel.vocalProfile
            )
        } else {
            compressor = nil
        }
        
        // ── Step 6: Key Warnings ──
        let keyWarnings = generateKeyWarnings(
            source: channel.source,
            setlist: setlist
        )
        
        // ── Step 7: Contextual Notes ──
        let notes = generateChannelNotes(
            channel: channel,
            room: room,
            drumConfig: drumConfig,
            experienceLevel: experienceLevel
        )
        
        return ChannelRecommendation(
            id: UUID(),
            channel: channel,
            gainRangeDB: gainResult.range,
            faderStartDB: faderStart,
            headroomDB: AudioConstants.headroomDB - (gainResult.nominal + faderStart - AudioConstants.nominalLevelDBFS),
            hpfFrequency: hpf,
            eqBands: eqBands,
            compressor: compressor,
            keyWarnings: keyWarnings,
            notes: notes
        )
    }
    
    
    // MARK: - ─── Gain Staging ─────────────────────────────────────────────
    
    private struct GainResult {
        let range: ClosedRange<Double>  // Safe gain window
        let nominal: Double              // Center-point recommendation
    }
    
    /// Calculate the optimal preamp gain range for a source.
    ///
    /// Logic:
    /// 1. Start from expected SPL/level of the source.
    /// 2. Apply mic sensitivity offset (dynamic vs condenser).
    /// 3. Apply drum isolation offset.
    /// 4. Clamp to the mixer's physical gain range.
    /// 5. Target -18 dBFS at the preamp output.
    private func calculateGain(
        source: InputSource,
        mixer: MixerModel,
        vocalProfile: VocalProfile?,
        drumConfig: DrumConfiguration
    ) -> GainResult {

        let splRange = source.expectedSPLRange
        let splMid = (splRange.lowerBound + splRange.upperBound) / 2.0

        var nominalGain: Double

        if source.isLineLevel {
            // Line-level sources: gain needed = target - source level
            // DI sources output around -20 to +4 dBu. At -18 dBFS target:
            // Most consoles' 0 dBFS ≈ +24 dBu, so -18 dBFS ≈ +6 dBu
            // Gain needed ≈ +6 dBu - source level
            let targetDBu: Double = 6.0  // -18 dBFS in dBu for most consoles
            nominalGain = targetDBu - splMid
            nominalGain = max(nominalGain, 0) // Line inputs rarely need negative gain
        } else {
            // Mic-level sources: convert SPL to required preamp gain.
            // Uses mixer-specific reference gain (dB needed at 94 dB SPL to
            // reach -18 dBFS). Each console has a different 0 dBFS-to-dBu
            // alignment, so the reference gain varies by platform.
            let referenceSPL: Double = 94.0

            // For vocals, use the range-specific close-mic SPL estimate
            // which reflects real-world worship SPL (102-108 dB) rather than
            // the generic 94 dB reference. This produces gains matching
            // real console settings (~10-15 dB for close-mic vocals on SM58).
            let effectiveSPL: Double
            if let vocal = vocalProfile {
                effectiveSPL = vocal.expectedCloseMicSPL
            } else if source.category == .vocals || source.category == .speech {
                effectiveSPL = 105.0  // Default close-mic worship vocal SPL
            } else {
                effectiveSPL = splMid
            }

            nominalGain = mixer.referenceGainAt94SPL + (referenceSPL - effectiveSPL)

            // Apply mic sensitivity offset (condensers need less gain)
            if let vocal = vocalProfile {
                nominalGain += vocal.micType.sensitivityOffsetDB
            }
        }
        
        // Apply drum isolation offset for drum sources
        if source.category == .drums && source != .electronicDrums {
            nominalGain += drumConfig.isolationReductionDB
        }
        
        // Define the "safe zone" — ±5 dB around nominal
        let margin: Double = 5.0
        let rawLow = nominalGain - margin
        let rawHigh = nominalGain + margin
        
        // Clamp to mixer's physical range
        let clampedLow = max(rawLow, mixer.gainRange.lowerBound)
        let clampedHigh = min(rawHigh, mixer.gainRange.upperBound)
        let clampedNominal = min(max(nominalGain, mixer.gainRange.lowerBound), mixer.gainRange.upperBound)

        // Guard against invalid range when clamping inverts bounds
        // (e.g., drum cage isolation pushes gain below mixer minimum)
        let safeLow = min(clampedLow, clampedHigh)
        let safeHigh = max(clampedLow, clampedHigh)

        return GainResult(
            range: safeLow...safeHigh,
            nominal: clampedNominal
        )
    }
    
    
    // MARK: - ─── Fader Start Position ─────────────────────────────────────
    
    /// Calculate suggested fader start position.
    /// If gain staging is correct (-18 dBFS at preamp), fader at unity (0 dB)
    /// should yield nominal level. We offset based on song intensity.
    private func calculateFaderStart(
        source: InputSource,
        bandComposition: BandComposition,
        setlist: [SetlistSong]
    ) -> Double {
        
        // Base: unity (0 dB)
        var fader: Double = 0.0
        
        // Offset by average setlist intensity
        if !setlist.isEmpty {
            let avgIntensityOffset = setlist.map { $0.intensity.faderOffsetDB }.reduce(0, +) / Double(setlist.count)
            // Don't apply full offset — fader is a starting point. Apply half.
            fader += avgIntensityOffset * 0.5
        }
        
        // Source-specific offsets
        switch source.category {
        case .vocals, .speech:
            // Vocals typically sit slightly above instruments
            fader += 0.0  // Keep at unity; gain should be set correctly
        case .drums:
            // In a live band, drums are already loud acoustically.
            // Fader may need to be lower.
            fader -= 3.0
        case .playback:
            // Tracks tend to be mastered hot; pull back
            fader -= 5.0
        default:
            break
        }
        
        // Tracks-only setups need less overall fader movement
        if bandComposition == .tracks {
            fader -= 3.0
        }
        
        return fader.rounded(to: 1)
    }
    
    
    // MARK: - ─── High-Pass Filter ─────────────────────────────────────────
    
    /// Calculate the HPF frequency, adjusted for musical key and room.
    private func calculateHPF(
        source: InputSource,
        room: RoomProfile,
        setlist: [SetlistSong]
    ) -> Double? {
        
        guard var baseFreq = source.baseHPFFrequency else { return nil }
        
        // Room correction: reflective rooms with long RT60 benefit from higher HPFs
        // on non-bass instruments to reduce low-end mud.
        if room.hasLowEndProblem && source.category != .guitars && source != .kickDrum && source != .bassGtrAmp && source != .bassGtrDI {
            baseFreq *= 1.15  // Raise HPF by ~15% in boomy rooms
        }
        
        // Key-aware adjustment: if most songs are in low keys (E, F, G),
        // the low end gets crowded. Be more aggressive with HPF on non-bass sources.
        if !setlist.isEmpty {
            let avgFundamental = setlist.map { $0.key.fundamentalHz }.reduce(0, +) / Double(setlist.count)
            if avgFundamental < 45.0 && source != .kickDrum && source != .bassGtrAmp && source != .bassGtrDI {
                // Low-key setlist — raise HPF slightly to clear space
                baseFreq *= 1.1
            }
        }
        
        return baseFreq.rounded(to: 5)  // Round to nearest 5 Hz
    }
    
    
    // MARK: - ─── EQ Calculation ───────────────────────────────────────────
    
    /// Generate EQ recommendations for a channel.
    /// Combines: base source EQ + vocal profile + room corrections + key-aware adjustments.
    private func calculateEQ(
        source: InputSource,
        vocalProfile: VocalProfile?,
        room: RoomProfile,
        setlist: [SetlistSong],
        mixer: MixerModel
    ) -> [EQRecommendation] {
        
        var bands: [EQRecommendation] = []
        
        // ── 1. Source-specific base EQ ──
        bands.append(contentsOf: baseEQForSource(source))
        
        // ── 2. Vocal-specific EQ ──
        if let vocal = vocalProfile {
            bands.append(contentsOf: vocalEQ(vocal, source: source))
        }
        
        // ── 3. Room correction EQ ──
        bands.append(contentsOf: roomCorrectionEQ(room, source: source))
        
        // ── 4. Key-aware EQ adjustments ──
        for song in setlist {
            bands.append(contentsOf: keyAwareEQ(
                key: song.key,
                source: source,
                songTitle: song.title
            ))
        }
        
        // Deduplicate: if multiple bands target similar frequencies, merge them.
        bands = deduplicateEQBands(bands)
        
        // Limit to mixer's available band count
        let maxBands = mixer.eqBandCount
        if bands.count > maxBands {
            // Prioritize by absolute gain magnitude (biggest corrections first)
            bands.sort { abs($0.gainDB) > abs($1.gainDB) }
            bands = Array(bands.prefix(maxBands))
        }
        
        // Sort by frequency for display
        bands.sort { $0.frequency < $1.frequency }
        
        return bands
    }
    
    /// Base EQ suggestions per source type (the "always do this" recommendations).
    private func baseEQForSource(_ source: InputSource) -> [EQRecommendation] {
        switch source {
            
        case .acousticGtrMic, .acousticGtrDI:
            return [
                EQRecommendation(frequency: 200, gainDB: -2.0, q: 1.5, reason: "Reduce body resonance / boxiness"),
                EQRecommendation(frequency: 5000, gainDB: 2.0, q: 1.0, type: .highShelf, reason: "Add string clarity and shimmer")
            ]
            
        case .electricGtrAmp:
            return [
                EQRecommendation(frequency: 400, gainDB: -2.5, q: 1.5, reason: "Cut mud from amp cabinet"),
                EQRecommendation(frequency: 3000, gainDB: 1.5, q: 2.0, reason: "Add presence and cut-through")
            ]
            
        case .electricGtrModeler:
            return [
                EQRecommendation(frequency: 350, gainDB: -1.5, q: 2.0, reason: "Reduce digital mud (modeler profiles run boxy)"),
            ]
            
        case .digitalPiano:
            return [
                EQRecommendation(frequency: 300, gainDB: -1.5, q: 1.5, reason: "Reduce low-mid mud on DI piano"),
                EQRecommendation(frequency: 4000, gainDB: 1.0, q: 1.5, reason: "Add key attack definition")
            ]
            
        case .grandPiano:
            return [
                EQRecommendation(frequency: 250, gainDB: -2.0, q: 1.5, reason: "Tame resonance inside the piano body"),
                EQRecommendation(frequency: 6000, gainDB: 1.5, q: 1.0, type: .highShelf, reason: "Open up the high-end sparkle")
            ]
            
        case .kickDrum:
            return [
                EQRecommendation(frequency: 60, gainDB: 2.0, q: 2.0, reason: "Reinforce low-end thump"),
                EQRecommendation(frequency: 400, gainDB: -4.0, q: 1.5, reason: "Remove cardboard boxiness"),
                EQRecommendation(frequency: 4000, gainDB: 3.0, q: 2.0, reason: "Add beater click / attack")
            ]
            
        case .snareDrum:
            return [
                EQRecommendation(frequency: 200, gainDB: 2.0, q: 1.5, reason: "Add body / fatness"),
                EQRecommendation(frequency: 800, gainDB: -2.0, q: 2.0, reason: "Reduce ring / ping"),
                EQRecommendation(frequency: 5000, gainDB: 2.0, q: 1.5, reason: "Add crack and snap")
            ]
            
        case .bassGtrDI, .bassGtrAmp:
            return [
                EQRecommendation(frequency: 80, gainDB: 1.5, q: 2.0, reason: "Reinforce fundamental low end"),
                EQRecommendation(frequency: 250, gainDB: -2.0, q: 1.5, reason: "Clean up low-mid mud"),
                EQRecommendation(frequency: 800, gainDB: 1.0, q: 2.0, reason: "Add finger/pick definition")
            ]
            
        case .overheadL, .overheadR:
            return [
                EQRecommendation(frequency: 400, gainDB: -2.0, q: 1.0, reason: "Reduce drum bleed boxiness"),
                EQRecommendation(frequency: 8000, gainDB: 1.5, q: 1.0, type: .highShelf, reason: "Enhance cymbal shimmer")
            ]
            
        case .cajon:
            return [
                EQRecommendation(frequency: 100, gainDB: 2.0, q: 2.0, reason: "Add bass port thump"),
                EQRecommendation(frequency: 500, gainDB: -2.0, q: 1.5, reason: "Reduce box resonance"),
                EQRecommendation(frequency: 3500, gainDB: 2.0, q: 2.0, reason: "Add slap attack")
            ]
            
        default:
            return []
        }
    }
    
    /// Vocal-specific EQ based on the singer's profile.
    private func vocalEQ(_ vocal: VocalProfile, source: InputSource) -> [EQRecommendation] {
        var bands: [EQRecommendation] = []
        
        // Proximity effect correction — dynamic mics close-up build low end
        if vocal.micType.proximityFactor > 0.5 {
            let cutAmount = -2.0 * vocal.micType.proximityFactor
            bands.append(EQRecommendation(
                frequency: 200,
                gainDB: cutAmount,
                q: 1.5,
                reason: "Proximity effect correction for \(vocal.micType.rawValue)"
            ))
        }
        
        // Presence boost in the intelligibility zone
        let presenceMid = (vocal.presenceZone.lowerBound + vocal.presenceZone.upperBound) / 2.0
        bands.append(EQRecommendation(
            frequency: presenceMid,
            gainDB: 2.0,
            q: 1.5,
            reason: "Presence boost for \(vocal.range.rawValue) voice"
        ))

        // "Air" boost for soprano/mezzo-soprano range or contemporary worship
        if vocal.range == .soprano || vocal.range == .mezzoSoprano || vocal.style == .contemporary {
            bands.append(EQRecommendation(
                frequency: 10000,
                gainDB: 1.5,
                q: 0.7,
                type: .highShelf,
                reason: "Air / breathiness for contemporary worship vocal"
            ))
        }
        
        // Gospel dynamic range: slight low-mid cut to prevent muddiness during belting
        if vocal.style == .gospel {
            bands.append(EQRecommendation(
                frequency: 300,
                gainDB: -2.5,
                q: 1.5,
                reason: "Low-mid cleanup for gospel belting dynamics"
            ))
        }
        
        return bands
    }
    
    /// Room-specific EQ corrections applied to all channels.
    private func roomCorrectionEQ(_ room: RoomProfile, source: InputSource) -> [EQRecommendation] {
        var bands: [EQRecommendation] = []
        
        // Low-mid correction for reflective/boomy rooms
        if abs(room.surface.lowMidBiasDB) > 0.5 {
            bands.append(EQRecommendation(
                frequency: 350,
                gainDB: room.surface.lowMidBiasDB,
                q: 1.0,
                reason: "Room correction: \(room.surface.rawValue) surfaces"
            ))
        }
        
        // High-frequency correction (only for non-cymbal sources)
        if abs(room.surface.highFrequencyBiasDB) > 0.5 && source.category != .drums {
            bands.append(EQRecommendation(
                frequency: 8000,
                gainDB: room.surface.highFrequencyBiasDB,
                q: 0.7,
                type: .highShelf,
                reason: "Room HF correction: \(room.surface.rawValue) surfaces"
            ))
        }
        
        return bands
    }
    
    /// Key-aware EQ: adjusts recommendations based on the song's key and the source.
    /// This is the "Option B" differentiator feature.
    private func keyAwareEQ(key: MusicalKey, source: InputSource, songTitle: String) -> [EQRecommendation] {
        var bands: [EQRecommendation] = []
        
        let harmonics = key.harmonics(count: 4)
        
        // Bass vs Kick frequency conflict detection
        if source == .kickDrum {
            let bassHz = key.bassRangeHz  // Octave 2 (bass guitar territory)
            // If the kick's sweet spot overlaps with the bass fundamental,
            // suggest a slight scoop on the kick at that frequency.
            if bassHz > 50 && bassHz < 120 {
                bands.append(EQRecommendation(
                    frequency: bassHz,
                    gainDB: -2.0,
                    q: 3.0,
                    reason: "[\(songTitle)] Key of \(key.rawValue): carve space for bass at \(Int(bassHz)) Hz"
                ))
            }
        }
        
        // Low-mid mud accumulation on guitars/keys when the key's 3rd harmonic
        // lands in the 200-500 Hz range
        if source.category == .guitars || source.category == .keys {
            if harmonics.count >= 3 {
                let h3 = harmonics[2]  // 3rd harmonic
                if h3 > 150 && h3 < 500 {
                    bands.append(EQRecommendation(
                        frequency: h3,
                        gainDB: -1.5,
                        q: 2.5,
                        reason: "[\(songTitle)] Key of \(key.rawValue): 3rd harmonic buildup at \(Int(h3)) Hz"
                    ))
                }
            }
        }
        
        // Bass guitar fundamental reinforcement or conflict management
        if source == .bassGtrDI || source == .bassGtrAmp {
            let fundamental = key.bassRangeHz
            // Ensure the bass fundamental is present
            bands.append(EQRecommendation(
                frequency: fundamental,
                gainDB: 1.5,
                q: 2.5,
                reason: "[\(songTitle)] Reinforce bass fundamental in key of \(key.rawValue) (\(Int(fundamental)) Hz)"
            ))
        }
        
        return bands
    }
    
    
    // MARK: - ─── Compression ──────────────────────────────────────────────
    
    /// Calculate compressor settings for a channel.
    private func calculateCompressor(
        source: InputSource,
        vocalProfile: VocalProfile?
    ) -> CompressorRecommendation? {
        
        switch source.category {
        case .vocals, .speech:
            let dynFactor = vocalProfile?.style.dynamicRangeFactor ?? 1.0
            let isSpoken = (vocalProfile?.style == .spoken || source == .pastorLapel ||
                           source == .pastorHandheld || source == .pastorHeadset)
            
            if isSpoken {
                return CompressorRecommendation(
                    thresholdDB: -20.0,
                    ratio: 4.0,
                    attackMS: 5.0,
                    releaseMS: 80.0,
                    makeupGainDB: 2.0,
                    reason: "Speech compression: tight control for consistent sermon level"
                )
            } else {
                // Singing vocal — threshold adjusts with dynamic range factor
                let threshold = -18.0 - (dynFactor * 3.0)
                let ratio = dynFactor > 1.2 ? 4.0 : 3.0
                return CompressorRecommendation(
                    thresholdDB: threshold,
                    ratio: ratio,
                    attackMS: 10.0,
                    releaseMS: 120.0,
                    makeupGainDB: 1.5,
                    reason: "Vocal compression for \(vocalProfile?.style.rawValue ?? "worship") style"
                )
            }
            
        case .drums:
            switch source {
            case .kickDrum:
                return CompressorRecommendation(
                    thresholdDB: -15.0, ratio: 4.0,
                    attackMS: 10.0, releaseMS: 80.0,
                    reason: "Kick: fast release to preserve punch, tame peaks"
                )
            case .snareDrum:
                return CompressorRecommendation(
                    thresholdDB: -12.0, ratio: 3.0,
                    attackMS: 5.0, releaseMS: 60.0,
                    reason: "Snare: preserve crack, control rim shots"
                )
            default:
                return nil  // Toms/OH/percussion rarely need compression in HOW
            }
            
        case .guitars:
            if source == .bassGtrDI || source == .bassGtrAmp {
                return CompressorRecommendation(
                    thresholdDB: -18.0, ratio: 4.0,
                    attackMS: 15.0, releaseMS: 100.0,
                    makeupGainDB: 1.0,
                    reason: "Bass: even out finger dynamics, keep low end consistent"
                )
            } else if source == .acousticGtrMic || source == .acousticGtrDI {
                return CompressorRecommendation(
                    thresholdDB: -16.0, ratio: 3.0,
                    attackMS: 20.0, releaseMS: 150.0,
                    reason: "Acoustic guitar: gentle leveling for strumming dynamics"
                )
            }
            return nil
            
        case .playback:
            return nil  // Tracks are already mastered
            
        default:
            return nil
        }
    }
    
    
    // MARK: - ─── Key Warnings ─────────────────────────────────────────────
    
    /// Generate per-channel warnings about frequency conflicts based on the setlist keys.
    private func generateKeyWarnings(
        source: InputSource,
        setlist: [SetlistSong]
    ) -> [KeyWarning] {
        
        var warnings: [KeyWarning] = []
        
        for song in setlist {
            let key = song.key
            let fundamental = key.fundamentalHz
            let bassHz = key.bassRangeHz
            
            // Warning: Key of E/F/G → extreme low-end buildup
            if fundamental < 45 && (source == .kickDrum || source == .bassGtrDI || source == .bassGtrAmp) {
                warnings.append(KeyWarning(
                    song: song,
                    conflictFrequency: bassHz,
                    affectedSource: source,
                    severity: .high,
                    suggestion: "Key of \(key.rawValue) puts heavy energy at \(Int(bassHz)) Hz. Watch your low-end balance between kick and bass. Consider a tight notch cut on one to let the other breathe."
                ))
            }
            
            // Warning: Low-mid mud accumulation on stage
            let lowMid = key.lowMidRangeHz
            if lowMid > 150 && lowMid < 400 && source.category == .guitars {
                warnings.append(KeyWarning(
                    song: song,
                    conflictFrequency: lowMid,
                    affectedSource: source,
                    severity: .moderate,
                    suggestion: "Key of \(key.rawValue) generates harmonics at \(Int(lowMid)) Hz (\"mud zone\"). Consider a subtle cut on guitars around this frequency."
                ))
            }
            
            // Warning: Vocal fundamental might mask piano
            if source.category == .keys && !setlist.isEmpty {
                let keyH2 = fundamental * 2.0
                if keyH2 > 200 && keyH2 < 500 {
                    warnings.append(KeyWarning(
                        song: song,
                        conflictFrequency: keyH2,
                        affectedSource: source,
                        severity: .low,
                        suggestion: "Key of \(key.rawValue): piano and vocals may compete at \(Int(keyH2)) Hz. Subtle EQ separation could help clarity."
                    ))
                }
            }
        }
        
        return warnings
    }
    
    
    // MARK: - ─── Contextual Notes ─────────────────────────────────────────
    
    /// Human-readable tips for a specific channel.
    private func generateChannelNotes(
        channel: InputChannel,
        room: RoomProfile,
        drumConfig: DrumConfiguration,
        experienceLevel: ExperienceLevel
    ) -> [String] {
        var notes: [String] = []
        
        let source = channel.source
        
        // Drum isolation notes
        if source.category == .drums && drumConfig == .openStage {
            notes.append("⚠️ Open drums on stage — be conservative with fader levels. Acoustic bleed will do much of the work in the room.")
        }
        
        if source.category == .drums && drumConfig == .drumShield {
            notes.append("Shield is in place. High frequencies are partially contained, but low-end still leaks underneath. Monitor your kick/snare carefully.")
        }
        
        // Room-specific tips
        if room.hasLowEndProblem && (source == .bassGtrDI || source == .bassGtrAmp || source == .kickDrum) {
            notes.append("🔊 This room has a long reverb tail. Low-end sources will accumulate fast. Keep your sub-200 Hz content tight and controlled.")
        }
        
        // DI-specific
        if source.isLineLevel && experienceLevel == .beginner {
            notes.append("This is a line-level (DI) source. Make sure your preamp is set to 'Line' not 'Mic' on the console.")
        }
        
        // Vocal tips
        if let vocal = channel.vocalProfile {
            if vocal.style == .gospel {
                notes.append("🎤 Gospel vocalist detected — expect extreme dynamics from whisper to full belt. Compression is your friend here. Ride the fader actively during the set.")
            }
            if vocal.micType == .lavalier {
                notes.append("Lapel mics are prone to clothing rustle. Ensure it's clipped securely and the cable has a strain relief loop.")
            }
        }
        
        // Tracks
        if source == .clickTrack {
            notes.append("🚫 CRITICAL: Click track must NEVER be routed to FOH or any speaker output. Verify it's routed ONLY to the musician in-ear mix.")
        }
        
        return notes
    }
    
    
    // MARK: - ─── Global Notes ─────────────────────────────────────────────
    
    /// Service-wide notes and tips.
    private func generateGlobalNotes(for service: WorshipService) -> [String] {
        var notes: [String] = []
        
        // Room warning
        if service.room.effectiveRT60 > 2.0 {
            notes.append("⚠️ High estimated reverb time (\(String(format: "%.1f", service.room.effectiveRT60))s RT60). Consider reducing any digital reverb effects and keeping the mix dry and tight.")
        }
        
        // Key diversity check
        let uniqueKeys = Set(service.setlist.map { $0.key })
        if uniqueKeys.count == 1 && !service.setlist.isEmpty {
            let key = service.setlist.first!.key
            notes.append("📎 All songs are in the key of \(key.rawValue). This means harmonic buildup at \(Int(key.bassRangeHz)) Hz and \(Int(key.lowMidRangeHz)) Hz will be persistent throughout the set. Monitor these frequencies closely.")
        }
        
        // Intensity progression
        if service.setlist.count >= 3 {
            let lastSong = service.setlist.last!
            if lastSong.intensity == .allOut || lastSong.intensity == .driving {
                notes.append("🎵 Your set builds to high energy. Consider pulling faders back -3 dB at the start and riding them up gradually to create dynamic range across the entire set.")
            }
        }
        
        // Hybrid / Tracks check
        if service.bandComposition == .hybrid {
            notes.append("🔗 Hybrid setup: Ensure tracks playback is time-aligned with live instruments. A 5-10ms delay on the tracks bus can help if there's a noticeable flamming effect.")
        }
        
        return notes
    }
    
    
    // MARK: - ─── Utility Functions ────────────────────────────────────────
    
    /// Merge EQ bands that target frequencies within 15% of each other.
    private func deduplicateEQBands(_ bands: [EQRecommendation]) -> [EQRecommendation] {
        guard !bands.isEmpty else { return [] }
        
        var sorted = bands.sorted { $0.frequency < $1.frequency }
        var merged: [EQRecommendation] = [sorted.removeFirst()]
        
        for band in sorted {
            if let last = merged.last,
               abs(band.frequency - last.frequency) / last.frequency < 0.15 {
                // Merge: average the frequencies, sum the gains (capped)
                let avgFreq = (last.frequency + band.frequency) / 2.0
                let sumGain = max(min(last.gainDB + band.gainDB, 6.0), -8.0)
                let combinedReason = [last.reason, band.reason]
                    .filter { !$0.isEmpty }
                    .joined(separator: " + ")
                
                merged[merged.count - 1] = EQRecommendation(
                    id: last.id,
                    frequency: avgFreq,
                    gainDB: sumGain,
                    q: min(last.q, band.q),
                    type: last.type,
                    reason: combinedReason
                )
            } else {
                merged.append(band)
            }
        }
        
        return merged
    }
}


// MARK: - ─── Double Rounding Extension ────────────────────────────────────

private extension Double {
    /// Round to the nearest multiple of `nearest`.
    func rounded(to nearest: Double) -> Double {
        let n = 1 / nearest
        return (self * n).rounded() / n
    }
}
