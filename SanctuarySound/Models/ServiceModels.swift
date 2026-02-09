// ============================================================================
// ServiceModels.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Data Layer
// Purpose: Defines every enum, struct, and model the app uses.
// Reference Level: -18 dBFS (nominal digital zero)
// ============================================================================

import Foundation

// MARK: - ─── Core Constants ───────────────────────────────────────────────

/// Central reference values for the entire audio engine.
struct AudioConstants {
    /// Nominal operating level. All gain calculations target this.
    static let nominalLevelDBFS: Double = -18.0
    
    /// Maximum headroom above nominal before digital clip (0 dBFS).
    static let headroomDB: Double = 18.0
    
    /// Default High-Pass Filter frequency (Hz) when no specific recommendation applies.
    static let defaultHPF: Double = 80.0
    
    /// A4 tuning reference (Hz) — used for key-to-frequency conversion.
    static let a4Reference: Double = 440.0
}


// MARK: - ─── Mixer Ecosystem ──────────────────────────────────────────────

/// Supported digital mixer models and their hardware-specific parameters.
enum MixerModel: String, CaseIterable, Identifiable, Codable {
    case allenHeathAvantis = "Allen & Heath Avantis"
    case allenHeathSQ   = "Allen & Heath SQ"
    case allenHeathDLive = "Allen & Heath dLive"
    case behringerX32   = "Behringer X32"
    case midasM32       = "Midas M32"
    case yamahaTF       = "Yamaha TF Series"
    case yamahaCLQL     = "Yamaha CL/QL Series"
    case soundcraftSi   = "Soundcraft Si Series"
    case presonusSL     = "PreSonus StudioLive"
    
    var id: String { rawValue }
    
    /// Preamp gain range in dB (min, max).
    var gainRange: ClosedRange<Double> {
        switch self {
        case .allenHeathAvantis:                return 5...60
        case .allenHeathSQ, .allenHeathDLive:   return 0...60
        case .behringerX32, .midasM32:          return 0...60
        case .yamahaTF:                         return -6...66
        case .yamahaCLQL:                       return -6...66
        case .soundcraftSi:                     return -5...58
        case .presonusSL:                       return 0...60
        }
    }
    
    /// Fader scale range in dB (min represents -∞ in practice).
    var faderRange: ClosedRange<Double> {
        switch self {
        case .allenHeathAvantis:                return -120...10
        case .allenHeathSQ, .allenHeathDLive:   return -120...10
        case .behringerX32, .midasM32:          return -120...10
        case .yamahaTF:                         return -138...10
        case .yamahaCLQL:                       return -138...10
        case .soundcraftSi:                     return -120...10
        case .presonusSL:                       return -120...10
        }
    }
    
    /// Unity gain fader position in dB.
    var faderUnity: Double {
        return 0.0 // All supported consoles use 0 dB as unity
    }
    
    /// Number of parametric EQ bands available per channel.
    var eqBandCount: Int {
        switch self {
        case .allenHeathAvantis:                return 4
        case .allenHeathSQ:                     return 4
        case .allenHeathDLive:                  return 8
        case .behringerX32, .midasM32:          return 6
        case .yamahaTF:                         return 4
        case .yamahaCLQL:                       return 4
        case .soundcraftSi:                     return 4
        case .presonusSL:                       return 6
        }
    }
    
    /// Preamp gain (dB) needed to bring an SM58 at 94 dB SPL to the console's
    /// nominal operating level (-18 dBFS). This is mixer-specific because each
    /// console has a different internal reference level (0 dBFS-to-dBu alignment)
    /// and preamp topology.
    ///
    /// Calibrated values:
    /// - Avantis/dLive/SQ: 0 dBFS ≈ +18 dBu → need ~22 dB gain at 94 SPL
    /// - X32/M32: 0 dBFS ≈ +22 dBu → need ~28 dB gain at 94 SPL
    /// - Yamaha TF/CL/QL: 0 dBFS ≈ +24 dBu → need ~32 dB gain at 94 SPL
    /// - Others: conservative estimate ~30 dB
    var referenceGainAt94SPL: Double {
        switch self {
        case .allenHeathAvantis, .allenHeathSQ, .allenHeathDLive:
            return 22.0
        case .behringerX32, .midasM32:
            return 28.0
        case .yamahaTF, .yamahaCLQL:
            return 32.0
        case .soundcraftSi:
            return 30.0
        case .presonusSL:
            return 30.0
        }
    }

    /// Whether the console supports built-in compressor per channel.
    var hasChannelCompressor: Bool { true } // All modern digital consoles do
    
    /// Short display label for compact UI.
    var shortName: String {
        switch self {
        case .allenHeathAvantis: return "Avantis"
        case .allenHeathSQ:     return "SQ"
        case .allenHeathDLive:  return "dLive"
        case .behringerX32:     return "X32"
        case .midasM32:         return "M32"
        case .yamahaTF:         return "TF"
        case .yamahaCLQL:       return "CL/QL"
        case .soundcraftSi:     return "Si"
        case .presonusSL:       return "SL"
        }
    }
}


// MARK: - ─── User Experience Level ────────────────────────────────────────

/// Controls the depth of recommendations shown to the user.
/// Maps directly to the 3-level system defined in the spec.
enum ExperienceLevel: String, CaseIterable, Identifiable, Codable {
    case beginner       = "Beginner"       // Level 1: Gain & Fader only
    case intermediate   = "Intermediate"   // Level 2: + EQ & HPF
    case advanced       = "Advanced"       // Level 3: Full channel strip
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .beginner:
            return "Gain & fader start-points only"
        case .intermediate:
            return "Adds EQ suggestions & high-pass filter"
        case .advanced:
            return "Full channel strip: EQ, compression, HPF, & gain staging"
        }
    }
    
    /// Abbreviated label for compact badges
    var shortName: String {
        switch self {
        case .beginner:     return "Begin"
        case .intermediate: return "Inter"
        case .advanced:     return "Adv"
        }
    }

    var showsEQ: Bool { self != .beginner }
    var showsCompression: Bool { self == .advanced }
    var showsHPF: Bool { self != .beginner }
}


// MARK: - ─── Band Composition ─────────────────────────────────────────────

/// The overall structure of the worship band for this service.
enum BandComposition: String, CaseIterable, Identifiable, Codable {
    case live       = "Full Live Band"
    case tracks     = "Tracks Only"
    case hybrid     = "Hybrid (Live + Tracks)"
    case acoustic   = "Acoustic Set"
    case solo       = "Solo Instrument + Vocal"
    
    var id: String { rawValue }
    
    /// Tracks-based setups need less gain staging on individual channels
    /// but require careful stereo bus management.
    var requiresStereoTrackInput: Bool {
        self == .tracks || self == .hybrid
    }
}


// MARK: - ─── Input Sources ────────────────────────────────────────────────

/// Every possible audio input the engine understands.
/// Each case carries metadata about expected SPL, frequency range, and behavior.
enum InputSource: String, CaseIterable, Identifiable, Codable {
    
    // ── Keys ──
    case digitalPiano       = "Digital Piano (DI)"
    case grandPiano         = "Grand Piano (Mic'd)"
    case uprightPiano       = "Upright Piano (Mic'd)"
    case organPipe          = "Pipe Organ"
    case organElectric      = "Electric Organ (B3/Keys)"
    case synthesizer        = "Synthesizer / Pad"
    
    // ── Guitars ──
    case electricGtrAmp     = "Electric Guitar (Amp Mic'd)"
    case electricGtrModeler = "Electric Guitar (Modeler/DI)"
    case acousticGtrMic     = "Acoustic Guitar (Mic'd)"
    case acousticGtrDI      = "Acoustic Guitar (DI/Pickup)"
    case bassGtrAmp         = "Bass Guitar (Amp Mic'd)"
    case bassGtrDI          = "Bass Guitar (DI)"
    
    // ── Drums & Percussion ──
    case kickDrum           = "Kick Drum"
    case snareDrum          = "Snare Drum"
    case hiHat              = "Hi-Hat"
    case tomHigh            = "Tom (High)"
    case tomMid             = "Tom (Mid)"
    case tomFloor           = "Tom (Floor)"
    case overheadL          = "Overhead L"
    case overheadR          = "Overhead R"
    case cajon              = "Cajón"
    case djembe             = "Djembe / Hand Drum"
    case electronicDrums    = "Electronic Drums (DI)"
    case percussion         = "Percussion (Shaker/Tamb)"
    
    // ── Vocals ──
    case leadVocal          = "Lead Vocal"
    case backingVocal       = "Backing Vocal"
    case choirMic           = "Choir Mic (Area)"
    case pastorLapel        = "Pastor (Lapel/Lav)"
    case pastorHandheld     = "Pastor (Handheld)"
    case pastorHeadset      = "Pastor (Headset)"
    
    // ── Orchestral / Other ──
    case violin             = "Violin"
    case viola              = "Viola"
    case cello              = "Cello"
    case trumpet            = "Trumpet"
    case saxophone          = "Saxophone"
    case flute              = "Flute"
    
    // ── Tracks & Playback ──
    case tracksLeft         = "Tracks (Left)"
    case tracksRight        = "Tracks (Right)"
    case clickTrack         = "Click Track"
    case videoPlayback      = "Video / Media Playback"
    
    var id: String { rawValue }
    
    /// Expected SPL range at the microphone (dB SPL) or nominal DI level.
    /// Used to calculate initial preamp gain.
    var expectedSPLRange: ClosedRange<Double> {
        switch self {
        // DI/Line-level sources (referenced in dBu, not SPL)
        case .digitalPiano, .synthesizer, .organElectric:           return -20...4
        case .electricGtrModeler:                                   return -20...4
        case .acousticGtrDI:                                        return -30...(-6)
        case .bassGtrDI:                                            return -20...4
        case .electronicDrums:                                      return -20...4
        case .tracksLeft, .tracksRight, .clickTrack, .videoPlayback: return -10...4
            
        // Mic'd sources (dB SPL at capsule)
        case .grandPiano, .uprightPiano:                            return 70...100
        case .organPipe:                                            return 85...110
        case .electricGtrAmp:                                       return 95...125
        case .acousticGtrMic:                                       return 65...95
        case .bassGtrAmp:                                           return 90...120
        case .kickDrum:                                             return 100...130
        case .snareDrum:                                            return 100...130
        case .hiHat:                                                return 85...110
        case .tomHigh, .tomMid, .tomFloor:                          return 95...125
        case .overheadL, .overheadR:                                return 80...110
        case .cajon:                                                return 80...105
        case .djembe, .percussion:                                  return 75...100
        case .leadVocal:                                            return 75...110
        case .backingVocal:                                         return 70...105
        case .choirMic:                                             return 65...90
        case .pastorLapel, .pastorHeadset:                          return 60...85
        case .pastorHandheld:                                       return 70...100
        case .violin, .viola:                                       return 70...95
        case .cello:                                                return 75...100
        case .trumpet:                                              return 90...120
        case .saxophone:                                            return 80...110
        case .flute:                                                return 70...100
        }
    }
    
    /// Whether this is a line-level (DI/direct) source vs a mic-level source.
    var isLineLevel: Bool {
        switch self {
        case .digitalPiano, .synthesizer, .organElectric,
             .electricGtrModeler, .acousticGtrDI, .bassGtrDI,
             .electronicDrums, .tracksLeft, .tracksRight,
             .clickTrack, .videoPlayback:
            return true
        default:
            return false
        }
    }
    
    /// Recommended HPF frequency in Hz. Nil means no HPF recommended.
    var baseHPFFrequency: Double? {
        switch self {
        // Low-end instruments — minimal or no HPF
        case .kickDrum:                                     return 30
        case .bassGtrAmp, .bassGtrDI:                       return 35
        case .cello:                                        return 50
        case .organPipe:                                    return 30
        
        // Mid-range instruments
        case .tomFloor:                                     return 60
        case .tomMid:                                       return 80
        case .tomHigh:                                      return 100
        case .snareDrum:                                    return 100
        case .cajon:                                        return 60
        case .djembe:                                       return 70
        
        // Guitars & keys
        case .digitalPiano, .grandPiano, .uprightPiano:     return 60
        case .synthesizer, .organElectric:                  return 50
        case .electricGtrAmp, .electricGtrModeler:          return 80
        case .acousticGtrMic, .acousticGtrDI:               return 80
        
        // Vocals
        case .leadVocal:                                    return 100
        case .backingVocal:                                 return 120
        case .choirMic:                                     return 120
        case .pastorLapel, .pastorHeadset:                  return 120
        case .pastorHandheld:                               return 100
        
        // Cymbals & overheads
        case .hiHat:                                        return 200
        case .overheadL, .overheadR:                        return 100
        case .percussion:                                   return 150
        
        // Orchestral
        case .violin, .viola:                               return 150
        case .trumpet:                                      return 120
        case .saxophone:                                    return 100
        case .flute:                                        return 200
        
        // Tracks — no HPF (already processed)
        case .tracksLeft, .tracksRight, .clickTrack, .videoPlayback:
            return nil
        case .electronicDrums:
            return nil
        }
    }
    
    /// Grouping category for the UI input list.
    var category: InputCategory {
        switch self {
        case .digitalPiano, .grandPiano, .uprightPiano, .organPipe,
             .organElectric, .synthesizer:
            return .keys
        case .electricGtrAmp, .electricGtrModeler, .acousticGtrMic,
             .acousticGtrDI, .bassGtrAmp, .bassGtrDI:
            return .guitars
        case .kickDrum, .snareDrum, .hiHat, .tomHigh, .tomMid, .tomFloor,
             .overheadL, .overheadR, .cajon, .djembe, .electronicDrums,
             .percussion:
            return .drums
        case .leadVocal, .backingVocal, .choirMic:
            return .vocals
        case .pastorLapel, .pastorHandheld, .pastorHeadset:
            return .speech
        case .violin, .viola, .cello, .trumpet, .saxophone, .flute:
            return .orchestral
        case .tracksLeft, .tracksRight, .clickTrack, .videoPlayback:
            return .playback
        }
    }
}

/// UI grouping for input sources.
enum InputCategory: String, CaseIterable, Identifiable, Codable {
    case keys       = "Keys"
    case guitars    = "Guitars"
    case drums      = "Drums & Percussion"
    case vocals     = "Vocals"
    case speech     = "Speech / Pastor"
    case orchestral = "Orchestral"
    case playback   = "Tracks & Playback"
    
    var id: String { rawValue }
    
    var systemIcon: String {
        switch self {
        case .keys:         return "pianokeys"
        case .guitars:      return "guitars"
        case .drums:        return "drum.fill"
        case .vocals:       return "music.mic"
        case .speech:       return "mic.fill"
        case .orchestral:   return "waveform.path"
        case .playback:     return "play.rectangle.fill"
        }
    }
}


// MARK: - ─── Vocal Profile ────────────────────────────────────────────────

/// A detailed profile for any vocal input. This significantly affects EQ recommendations.
/// Range-based system: we care about the sound characteristics of the voice,
/// not the identity of the vocalist. Vocal range drives all frequency math.
struct VocalProfile: Codable, Identifiable {
    let id: UUID
    var range: VocalRange
    var style: VocalStyle
    var micType: MicType

    init(
        id: UUID = UUID(),
        range: VocalRange = .tenor,
        style: VocalStyle = .contemporary,
        micType: MicType = .dynamicCardioid
    ) {
        self.id = id
        self.range = range
        self.style = style
        self.micType = micType
    }

    /// Create from a saved vocalist
    init(from vocalist: SavedVocalist) {
        self.id = UUID()
        self.range = vocalist.range
        self.style = vocalist.style
        self.micType = vocalist.preferredMic
    }

    /// The fundamental frequency range for this voice type (Hz).
    /// Based purely on vocal range — the acoustic property that matters for EQ.
    var fundamentalRange: ClosedRange<Double> {
        switch range {
        case .soprano:      return 250...1050
        case .mezzoSoprano: return 200...850
        case .alto:         return 175...700
        case .tenor:        return 130...500
        case .baritone:     return 100...400
        case .bass:         return 80...330
        }
    }

    /// The "presence" frequency zone where intelligibility lives.
    var presenceZone: ClosedRange<Double> {
        switch range {
        case .soprano:      return 3000...6000
        case .mezzoSoprano: return 2800...5500
        case .alto:         return 2500...5000
        case .tenor:        return 2000...5000
        case .baritone:     return 1500...4000
        case .bass:         return 1200...3500
        }
    }

    /// Expected SPL at close-mic distance for this vocal range.
    /// Higher voices tend to produce more SPL at the mic due to projection angle.
    var expectedCloseMicSPL: Double {
        switch range {
        case .soprano:      return 108.0
        case .mezzoSoprano: return 106.0
        case .alto:         return 104.0
        case .tenor:        return 106.0
        case .baritone:     return 104.0
        case .bass:         return 102.0
        }
    }
}

enum VocalRange: String, CaseIterable, Identifiable, Codable {
    case soprano        = "Soprano"
    case mezzoSoprano   = "Mezzo-Soprano"
    case alto           = "Alto"
    case tenor          = "Tenor"
    case baritone       = "Baritone"
    case bass           = "Bass"

    var id: String { rawValue }

    /// Short label for compact UI badges
    var shortName: String {
        switch self {
        case .soprano:      return "Sop"
        case .mezzoSoprano: return "Mez"
        case .alto:         return "Alto"
        case .tenor:        return "Ten"
        case .baritone:     return "Bar"
        case .bass:         return "Bass"
        }
    }
}

enum VocalStyle: String, CaseIterable, Identifiable, Codable {
    case contemporary   = "Contemporary Worship"  // Bethel, Elevation, Hillsong
    case traditional    = "Traditional / Hymn"
    case gospel         = "Gospel"
    case choir          = "Choir Section"
    case spoken         = "Spoken Word / Preaching"
    
    var id: String { rawValue }
    
    /// Gospel singers tend to have extreme dynamic range.
    /// This factor is multiplied into the compressor threshold calculation.
    var dynamicRangeFactor: Double {
        switch self {
        case .contemporary:     return 1.0
        case .traditional:      return 0.8
        case .gospel:           return 1.4
        case .choir:            return 0.7
        case .spoken:           return 0.6
        }
    }
}

enum MicType: String, CaseIterable, Identifiable, Codable {
    case dynamicCardioid    = "Dynamic (SM58, e835)"
    case condenserCardioid  = "Condenser (KSM9, e965)"
    case condenserSDC       = "Small Diaphragm Condenser"
    case ribbon             = "Ribbon"
    case lavalier           = "Lavalier / Lapel"
    case headset            = "Headset"
    case shotgun            = "Shotgun"
    
    var id: String { rawValue }
    
    /// Sensitivity offset in dB. Dynamic mics need more gain; condensers need less.
    var sensitivityOffsetDB: Double {
        switch self {
        case .dynamicCardioid:      return 0.0    // Reference (SM58 baseline)
        case .condenserCardioid:    return -10.0   // ~10 dB hotter signal
        case .condenserSDC:         return -12.0
        case .ribbon:               return 5.0     // Lower output, needs more gain
        case .lavalier:             return -6.0
        case .headset:              return -8.0
        case .shotgun:              return -10.0
        }
    }
    
    /// Proximity effect severity (0.0 = none, 1.0 = severe).
    /// Affects low-frequency EQ recommendation.
    var proximityFactor: Double {
        switch self {
        case .dynamicCardioid:      return 0.8
        case .condenserCardioid:    return 0.6
        case .condenserSDC:         return 0.3
        case .ribbon:               return 0.9
        case .lavalier:             return 0.1
        case .headset:              return 0.2
        case .shotgun:              return 0.2
        }
    }
}


// MARK: - ─── Musical Key & Frequency Math ─────────────────────────────────

/// All 12 musical keys. Used for key-aware EQ adjustments.
enum MusicalKey: String, CaseIterable, Identifiable, Codable {
    case C      = "C"
    case Db     = "D♭"
    case D      = "D"
    case Eb     = "E♭"
    case E      = "E"
    case F      = "F"
    case Gb     = "G♭"
    case G      = "G"
    case Ab     = "A♭"
    case A      = "A"
    case Bb     = "B♭"
    case B      = "B"
    
    var id: String { rawValue }
    
    /// Semitone offset from C (C=0, C#=1, D=2, ... B=11).
    var semitoneOffset: Int {
        switch self {
        case .C:  return 0
        case .Db: return 1
        case .D:  return 2
        case .Eb: return 3
        case .E:  return 4
        case .F:  return 5
        case .Gb: return 6
        case .G:  return 7
        case .Ab: return 8
        case .A:  return 9
        case .Bb: return 10
        case .B:  return 11
        }
    }
    
    /// Fundamental frequency of this key in octave 1 (lowest musically relevant octave).
    /// C1 = 32.70 Hz. Each semitone multiplies by 2^(1/12).
    var fundamentalHz: Double {
        let c1: Double = 32.703  // C1
        return c1 * pow(2.0, Double(semitoneOffset) / 12.0)
    }
    
    /// Returns the first N harmonics of the root in octave 1.
    /// These are the frequencies most likely to cause buildup.
    func harmonics(count: Int = 6) -> [Double] {
        let f0 = fundamentalHz
        return (1...count).map { Double($0) * f0 }
    }
    
    /// Returns the bass-range fundamental (octave 2, where bass guitars live).
    var bassRangeHz: Double { fundamentalHz * 2.0 }
    
    /// Returns the critical low-mid range (octave 3, where "mud" accumulates).
    var lowMidRangeHz: Double { fundamentalHz * 4.0 }
}


// MARK: - ─── Drum Configuration ───────────────────────────────────────────

/// How the drum kit is isolated. Dramatically affects overhead mic bleed and overall stage volume.
enum DrumConfiguration: String, CaseIterable, Identifiable, Codable {
    case openStage      = "Open Stage (No Isolation)"
    case drumShield     = "Drum Shield (Plexiglass)"
    case drumCage       = "Full Drum Cage / Enclosure"
    case electronic     = "Electronic / Mesh Kit"
    
    var id: String { rawValue }
    
    /// SPL reduction factor in dB applied to drum source levels.
    /// A drum cage reduces what the overheads and room mics "see."
    var isolationReductionDB: Double {
        switch self {
        case .openStage:    return 0.0
        case .drumShield:   return -6.0
        case .drumCage:     return -15.0
        case .electronic:   return -30.0
        }
    }
    
    /// Overhead mic necessity factor: 1.0 = essential, 0.0 = unnecessary.
    var overheadRelevance: Double {
        switch self {
        case .openStage:    return 1.0
        case .drumShield:   return 0.8
        case .drumCage:     return 0.5
        case .electronic:   return 0.0
        }
    }
}


// MARK: - ─── Room Acoustics (3×3 Matrix) ──────────────────────────────────

/// Room size classification.
enum RoomSize: String, CaseIterable, Identifiable, Codable {
    case small  = "Small (< 300 seats)"
    case medium = "Medium (300–800 seats)"
    case large  = "Large (800+ seats)"
    
    var id: String { rawValue }
    
    /// Estimated RT60 baseline in seconds (before surface correction).
    var baseRT60: Double {
        switch self {
        case .small:    return 0.8
        case .medium:   return 1.2
        case .large:    return 1.8
        }
    }
}

/// Dominant surface material, which dramatically affects high-frequency behavior.
enum RoomSurface: String, CaseIterable, Identifiable, Codable {
    case absorbent  = "Absorbent (Carpet, Padded Pews, Curtains)"
    case reflective = "Reflective (Concrete, Glass, Hard Walls)"
    case mixed      = "Mixed (Typical Sanctuary)"
    
    var id: String { rawValue }
    
    /// RT60 multiplier applied to the room size baseline.
    var rt60Multiplier: Double {
        switch self {
        case .absorbent:    return 0.6
        case .reflective:   return 1.5
        case .mixed:        return 1.0
        }
    }
    
    /// High-frequency EQ bias in dB. Reflective rooms need HF cuts; absorbent rooms may need boosts.
    var highFrequencyBiasDB: Double {
        switch self {
        case .absorbent:    return 1.5    // HF absorbed; slight boost might help
        case .reflective:   return -2.0   // HF bouncing everywhere; cut
        case .mixed:        return 0.0
        }
    }
    
    /// Low-mid frequency EQ bias in dB. Reflective rooms accumulate mud.
    var lowMidBiasDB: Double {
        switch self {
        case .absorbent:    return 0.0
        case .reflective:   return -2.5   // Cut 200-500 Hz mud
        case .mixed:        return -1.0
        }
    }
}

/// Composite room profile combining size and surface.
struct RoomProfile: Codable, Identifiable {
    let id: UUID
    var size: RoomSize
    var surface: RoomSurface
    
    init(id: UUID = UUID(), size: RoomSize = .medium, surface: RoomSurface = .mixed) {
        self.id = id
        self.size = size
        self.surface = surface
    }
    
    /// Effective RT60 for this room (seconds).
    var effectiveRT60: Double {
        size.baseRT60 * surface.rt60Multiplier
    }
    
    /// Whether this room requires extra care with low-end management.
    var hasLowEndProblem: Bool {
        effectiveRT60 > 1.5
    }
}


// MARK: - ─── Input Channel (User-Created) ─────────────────────────────────

/// A single channel on the user's input list for this service.
struct InputChannel: Codable, Identifiable {
    let id: UUID
    var label: String               // e.g., "Sarah's Vocal", "Stage Left GTR"
    var source: InputSource
    var vocalProfile: VocalProfile?  // Only populated for vocal/speech inputs
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        label: String = "",
        source: InputSource,
        vocalProfile: VocalProfile? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.label = label.isEmpty ? source.localizedName : label
        self.source = source
        self.vocalProfile = vocalProfile
        self.isActive = isActive
    }
}


// MARK: - ─── Setlist Song ─────────────────────────────────────────────────

/// A single song in the worship set, carrying key information for frequency analysis.
struct SetlistSong: Codable, Identifiable {
    let id: UUID
    var title: String
    var key: MusicalKey
    var bpm: Int?
    var intensity: SongIntensity
    
    init(
        id: UUID = UUID(),
        title: String = "",
        key: MusicalKey = .G,
        bpm: Int? = nil,
        intensity: SongIntensity = .medium
    ) {
        self.id = id
        self.title = title
        self.key = key
        self.bpm = bpm
        self.intensity = intensity
    }
}

/// How dynamic/loud the song is expected to be. Affects headroom recommendations.
enum SongIntensity: String, CaseIterable, Identifiable, Codable {
    case soft       = "Soft / Reflective"
    case medium     = "Medium / Standard"
    case driving    = "Driving / High Energy"
    case allOut     = "Full Send / Anthemic"
    
    var id: String { rawValue }
    
    /// dB offset applied to the fader recommendation to account for energy level.
    var faderOffsetDB: Double {
        switch self {
        case .soft:     return -6.0
        case .medium:   return 0.0
        case .driving:  return 3.0
        case .allOut:   return 5.0
        }
    }
}


// MARK: - ─── Worship Service (Top-Level Model) ───────────────────────────

/// The root model representing a complete Sunday service audio profile.
struct WorshipService: Codable, Identifiable {
    let id: UUID
    var name: String                        // e.g., "Sunday Feb 9 — 9:30 AM"
    var date: Date
    var mixer: MixerModel
    var bandComposition: BandComposition
    var drumConfig: DrumConfiguration
    var room: RoomProfile
    var channels: [InputChannel]
    var setlist: [SetlistSong]
    var experienceLevel: ExperienceLevel

    // ── Venue/Room/Console References (optional for backward compat) ──
    var venueID: UUID?
    var roomID: UUID?
    var consoleProfileID: UUID?

    init(
        id: UUID = UUID(),
        name: String = "New Service",
        date: Date = Date(),
        mixer: MixerModel = .allenHeathAvantis,
        bandComposition: BandComposition = .live,
        drumConfig: DrumConfiguration = .openStage,
        room: RoomProfile = RoomProfile(),
        channels: [InputChannel] = [],
        setlist: [SetlistSong] = [],
        experienceLevel: ExperienceLevel = .intermediate,
        venueID: UUID? = nil,
        roomID: UUID? = nil,
        consoleProfileID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.mixer = mixer
        self.bandComposition = bandComposition
        self.drumConfig = drumConfig
        self.room = room
        self.channels = channels
        self.setlist = setlist
        self.experienceLevel = experienceLevel
        self.venueID = venueID
        self.roomID = roomID
        self.consoleProfileID = consoleProfileID
    }
}


// MARK: - ─── Engine Output Models ─────────────────────────────────────────

/// The complete recommendation for a single channel.
struct ChannelRecommendation: Identifiable {
    let id: UUID
    let channel: InputChannel
    
    // ── Gain Staging ──
    let gainRangeDB: ClosedRange<Double>    // Recommended preamp gain range
    let faderStartDB: Double                 // Suggested fader position
    let headroomDB: Double                   // Available headroom at recommended gain
    
    // ── High-Pass Filter ──
    let hpfFrequency: Double?               // Recommended HPF (nil = bypass)
    
    // ── EQ Bands ──
    let eqBands: [EQRecommendation]         // Sorted by frequency, low to high
    
    // ── Dynamics ──
    let compressor: CompressorRecommendation?
    
    // ── Key-Aware Warnings ──
    let keyWarnings: [KeyWarning]
    
    // ── Contextual Notes ──
    let notes: [String]                     // Human-readable tips
}

/// A single EQ band recommendation.
struct EQRecommendation: Identifiable {
    let id: UUID
    var frequency: Double       // Center frequency (Hz)
    var gainDB: Double          // Boost (+) or cut (-) in dB
    var q: Double               // Bandwidth (Q factor)
    var type: EQBandType
    var reason: String          // e.g., "Reduce boxiness" or "Key of E buildup"
    
    init(
        id: UUID = UUID(),
        frequency: Double,
        gainDB: Double,
        q: Double = 2.0,
        type: EQBandType = .parametric,
        reason: String = ""
    ) {
        self.id = id
        self.frequency = frequency
        self.gainDB = gainDB
        self.q = q
        self.type = type
        self.reason = reason
    }
}

enum EQBandType: String, Codable {
    case lowShelf       = "Low Shelf"
    case highShelf      = "High Shelf"
    case parametric     = "Parametric (Bell)"
    case highPass       = "High-Pass"
    case lowPass        = "Low-Pass"
    case notch          = "Notch"
}

/// Compressor recommendation for a single channel.
struct CompressorRecommendation: Identifiable {
    let id: UUID
    var thresholdDB: Double     // Threshold in dBFS
    var ratio: Double           // e.g., 3.0 = 3:1
    var attackMS: Double        // Attack time in milliseconds
    var releaseMS: Double       // Release time in milliseconds
    var makeupGainDB: Double    // Makeup gain
    var reason: String
    
    init(
        id: UUID = UUID(),
        thresholdDB: Double,
        ratio: Double,
        attackMS: Double,
        releaseMS: Double,
        makeupGainDB: Double = 0.0,
        reason: String = ""
    ) {
        self.id = id
        self.thresholdDB = thresholdDB
        self.ratio = ratio
        self.attackMS = attackMS
        self.releaseMS = releaseMS
        self.makeupGainDB = makeupGainDB
        self.reason = reason
    }
}

/// A key-aware warning about potential frequency conflicts.
struct KeyWarning: Identifiable {
    let id: UUID
    let song: SetlistSong
    let conflictFrequency: Double
    let affectedSource: InputSource
    let severity: WarningSeverity
    let suggestion: String
    
    init(
        id: UUID = UUID(),
        song: SetlistSong,
        conflictFrequency: Double,
        affectedSource: InputSource,
        severity: WarningSeverity = .moderate,
        suggestion: String
    ) {
        self.id = id
        self.song = song
        self.conflictFrequency = conflictFrequency
        self.affectedSource = affectedSource
        self.severity = severity
        self.suggestion = suggestion
    }
}

enum WarningSeverity: String, Codable {
    case low        = "Info"
    case moderate   = "Watch"
    case high       = "Alert"
}

/// The top-level output from the SoundEngine for an entire service.
struct MixerSettingRecommendation: Identifiable {
    let id: UUID
    let service: WorshipService
    let channelRecommendations: [ChannelRecommendation]
    let globalNotes: [String]
    let generatedAt: Date
    
    init(
        id: UUID = UUID(),
        service: WorshipService,
        channelRecommendations: [ChannelRecommendation],
        globalNotes: [String] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.service = service
        self.channelRecommendations = channelRecommendations
        self.globalNotes = globalNotes
        self.generatedAt = generatedAt
    }
}


// MARK: - ─── Saved Vocalist (Persistent) ─────────────────────────────────────

/// A reusable vocalist profile saved independently of any service.
/// Assigned to channels per-service to drive EQ, compression, and key-aware tuning.
struct SavedVocalist: Codable, Identifiable {
    let id: UUID
    var name: String                    // e.g., "Sarah", "Marcus"
    var range: VocalRange
    var style: VocalStyle
    var preferredMic: MicType
    var notes: String                   // e.g., "Belts hard on choruses", "Quiet verses"

    init(
        id: UUID = UUID(),
        name: String = "",
        range: VocalRange = .alto,
        style: VocalStyle = .contemporary,
        preferredMic: MicType = .dynamicCardioid,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.range = range
        self.style = style
        self.preferredMic = preferredMic
        self.notes = notes
    }
}


// MARK: - ─── Saved Input (Reusable Channel Preset) ──────────────────────────

/// A saved channel configuration that can be reused across services.
/// Covers all input types: vocalists, instruments, playback, and other sources.
struct SavedInput: Codable, Identifiable {
    let id: UUID
    var name: String                    // e.g., "Sarah's Vocal", "Keys L", "ProPresenter L"
    var source: InputSource
    var vocalProfile: VocalProfile?     // Only for vocal/speech sources
    var notes: String
    var tags: [String]                  // Filterable tags: "lead", "backing", "electric", etc.
    var micModel: String?               // e.g., "Shure SM58", "Neumann U87"
    var lastUsed: Date?

    init(
        id: UUID = UUID(),
        name: String = "",
        source: InputSource = .leadVocal,
        vocalProfile: VocalProfile? = nil,
        notes: String = "",
        tags: [String] = [],
        micModel: String? = nil,
        lastUsed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.vocalProfile = vocalProfile
        self.notes = notes
        self.tags = tags
        self.micModel = micModel
        self.lastUsed = lastUsed
    }

    // Backward-compatible decoder — old JSON without tags/micModel/lastUsed still loads
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        source = try container.decode(InputSource.self, forKey: .source)
        vocalProfile = try container.decodeIfPresent(VocalProfile.self, forKey: .vocalProfile)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        micModel = try container.decodeIfPresent(String.self, forKey: .micModel)
        lastUsed = try container.decodeIfPresent(Date.self, forKey: .lastUsed)
    }

    /// Convert to an InputChannel for use in a service
    func toInputChannel() -> InputChannel {
        InputChannel(
            label: name,
            source: source,
            vocalProfile: vocalProfile
        )
    }
}


// MARK: - ─── Mixer Snapshot (Imported State) ─────────────────────────────────

/// The actual state of a mixer channel as imported from CSV or TCP/MIDI.
/// Used for delta analysis against engine recommendations.
struct ChannelSnapshot: Codable, Identifiable {
    let id: UUID
    var channelNumber: Int              // Physical channel on the mixer (1-64)
    var name: String                    // Channel name from mixer
    var gainDB: Double?                 // Current preamp gain
    var faderDB: Double?                // Current fader position
    var hpfFrequency: Double?           // Current HPF setting (nil = bypassed)
    var hpfEnabled: Bool
    var eqBands: [SnapshotEQBand]       // Current EQ state
    var compThresholdDB: Double?        // Current compressor threshold
    var compRatio: Double?
    var compAttackMS: Double?
    var compReleaseMS: Double?
    var phantomPower: Bool
    var padEnabled: Bool

    init(
        id: UUID = UUID(),
        channelNumber: Int = 1,
        name: String = "",
        gainDB: Double? = nil,
        faderDB: Double? = nil,
        hpfFrequency: Double? = nil,
        hpfEnabled: Bool = false,
        eqBands: [SnapshotEQBand] = [],
        compThresholdDB: Double? = nil,
        compRatio: Double? = nil,
        compAttackMS: Double? = nil,
        compReleaseMS: Double? = nil,
        phantomPower: Bool = false,
        padEnabled: Bool = false
    ) {
        self.id = id
        self.channelNumber = channelNumber
        self.name = name
        self.gainDB = gainDB
        self.faderDB = faderDB
        self.hpfFrequency = hpfFrequency
        self.hpfEnabled = hpfEnabled
        self.eqBands = eqBands
        self.compThresholdDB = compThresholdDB
        self.compRatio = compRatio
        self.compAttackMS = compAttackMS
        self.compReleaseMS = compReleaseMS
        self.phantomPower = phantomPower
        self.padEnabled = padEnabled
    }
}

/// A single EQ band from the imported mixer state.
struct SnapshotEQBand: Codable, Identifiable {
    let id: UUID
    var frequency: Double
    var gainDB: Double
    var q: Double
    var enabled: Bool

    init(id: UUID = UUID(), frequency: Double = 1000, gainDB: Double = 0, q: Double = 1.0, enabled: Bool = true) {
        self.id = id
        self.frequency = frequency
        self.gainDB = gainDB
        self.q = q
        self.enabled = enabled
    }
}

/// A complete mixer snapshot — all channels at a point in time.
struct MixerSnapshot: Codable, Identifiable {
    let id: UUID
    var name: String                    // e.g., "Feb 8 — Pre-service"
    var importedAt: Date
    var mixer: MixerModel
    var channels: [ChannelSnapshot]

    init(
        id: UUID = UUID(),
        name: String = "Imported Snapshot",
        importedAt: Date = Date(),
        mixer: MixerModel = .allenHeathAvantis,
        channels: [ChannelSnapshot] = []
    ) {
        self.id = id
        self.name = name
        self.importedAt = importedAt
        self.mixer = mixer
        self.channels = channels
    }
}


// MARK: - ─── SPL Configuration ───────────────────────────────────────────────

/// User's preferred SPL target and flagging behavior.
struct SPLPreference: Codable {
    var targetDB: Double                // e.g., 90.0
    var flaggingMode: SPLFlaggingMode
    var calibrationOffset: Double?      // dBFS-to-SPL offset from calibration

    init(
        targetDB: Double = 90.0,
        flaggingMode: SPLFlaggingMode = .balanced,
        calibrationOffset: Double? = nil
    ) {
        self.targetDB = targetDB
        self.flaggingMode = flaggingMode
        self.calibrationOffset = calibrationOffset
    }

    /// Threshold above target that triggers a flag, based on mode.
    var flagThresholdDB: Double {
        flaggingMode.thresholdDB
    }
}

enum SPLFlaggingMode: String, CaseIterable, Identifiable, Codable {
    case strict     = "Strict"
    case balanced   = "Balanced"
    case variable   = "Variable"

    var id: String { rawValue }

    /// How many dB above target before flagging.
    var thresholdDB: Double {
        switch self {
        case .strict:   return 2.0
        case .balanced: return 5.0
        case .variable: return 8.0
        }
    }

    var description: String {
        switch self {
        case .strict:   return "Flag at +2 dB over target"
        case .balanced: return "Flag at +5 dB over target"
        case .variable: return "Flag at +8 dB over target"
        }
    }
}


// MARK: - ─── SPL Alert State ─────────────────────────────────────────────────

/// Represents the current SPL alert level relative to user preferences.
/// Used to drive haptics, visual pulse, and cross-tab alert banner.
enum SPLAlertState: Equatable {
    /// SPL is within the safe zone (at or below target).
    case safe
    /// SPL is over target but under the flag threshold (amber warning).
    case warning(currentDB: Int, overBy: Int)
    /// SPL exceeds the flag threshold — active alert (red danger).
    case alert(currentDB: Int, overBy: Int)

    var isActive: Bool {
        switch self {
        case .safe: return false
        case .warning, .alert: return true
        }
    }

    var isDanger: Bool {
        if case .alert = self { return true }
        return false
    }
}


// MARK: - ─── SPL Breach Log ──────────────────────────────────────────────────

/// A single recorded instance of the SPL exceeding the user's target.
struct SPLBreachEvent: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date
    let peakDB: Double          // Highest dB during this breach
    let targetDB: Double        // What the target was at time of breach
    let thresholdDB: Double     // What the flag threshold was

    init(
        startTime: Date,
        endTime: Date,
        peakDB: Double,
        targetDB: Double,
        thresholdDB: Double
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.peakDB = peakDB
        self.targetDB = targetDB
        self.thresholdDB = thresholdDB
    }

    /// Duration in seconds.
    var durationSeconds: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    /// How far over target the peak was.
    var overTargetDB: Double {
        peakDB - targetDB
    }

    /// Whether this breach exceeded the flag threshold (danger level).
    var wasDanger: Bool {
        peakDB > targetDB + thresholdDB
    }
}


/// Summary of SPL behavior across a monitoring session (one service).
struct SPLSessionReport: Codable, Identifiable {
    let id: UUID
    let date: Date
    let sessionStart: Date
    let sessionEnd: Date
    let targetDB: Double
    let flaggingMode: SPLFlaggingMode
    let breachEvents: [SPLBreachEvent]
    let overallPeakDB: Double
    let overallAverageDB: Double
    let totalMonitoringSeconds: TimeInterval

    init(
        date: Date = Date(),
        sessionStart: Date,
        sessionEnd: Date,
        targetDB: Double,
        flaggingMode: SPLFlaggingMode,
        breachEvents: [SPLBreachEvent],
        overallPeakDB: Double,
        overallAverageDB: Double,
        totalMonitoringSeconds: TimeInterval
    ) {
        self.id = UUID()
        self.date = date
        self.sessionStart = sessionStart
        self.sessionEnd = sessionEnd
        self.targetDB = targetDB
        self.flaggingMode = flaggingMode
        self.breachEvents = breachEvents
        self.overallPeakDB = overallPeakDB
        self.overallAverageDB = overallAverageDB
        self.totalMonitoringSeconds = totalMonitoringSeconds
    }

    /// Total number of breach events.
    var breachCount: Int { breachEvents.count }

    /// How many were danger-level breaches.
    var dangerCount: Int { breachEvents.filter(\.wasDanger).count }

    /// Total time spent over target.
    var totalBreachSeconds: TimeInterval {
        breachEvents.reduce(0) { $0 + $1.durationSeconds }
    }

    /// Percentage of monitoring time spent over target.
    var breachPercentage: Double {
        guard totalMonitoringSeconds > 0 else { return 0 }
        return (totalBreachSeconds / totalMonitoringSeconds) * 100
    }

    /// Longest single breach event duration.
    var longestBreachSeconds: TimeInterval {
        breachEvents.map(\.durationSeconds).max() ?? 0
    }
}


// MARK: - ─── Delta Analysis Output ───────────────────────────────────────────

/// The result of comparing an imported mixer state against engine recommendations.
struct ChannelDelta: Identifiable {
    let id: UUID
    let channelName: String
    let channelNumber: Int
    let source: InputSource?            // Matched source (nil if unmatched)

    // ── Gain ──
    let actualGainDB: Double?
    let recommendedGainRange: ClosedRange<Double>?
    let gainStatus: DeltaStatus

    // ── Fader ──
    let actualFaderDB: Double?
    let recommendedFaderDB: Double?
    let faderStatus: DeltaStatus

    // ── HPF ──
    let actualHPF: Double?
    let recommendedHPF: Double?
    let hpfStatus: DeltaStatus

    // ── EQ ──
    let eqDeltas: [EQBandDelta]

    // ── Compression ──
    let compDelta: CompressorDelta?

    // ── Overall ──
    let overallScore: AnalysisScore
    let suggestions: [String]
}

/// Status of a single parameter comparison.
enum DeltaStatus: String {
    case optimal    = "Optimal"         // Within recommended range
    case close      = "Close"           // Within 3 dB of range
    case attention  = "Needs Attention" // More than 3 dB off
    case missing    = "No Data"         // Missing from import or recommendation

    var color: String {
        switch self {
        case .optimal:   return "accent"
        case .close:     return "accentWarm"
        case .attention: return "accentDanger"
        case .missing:   return "textMuted"
        }
    }
}

/// Delta for a single EQ band.
struct EQBandDelta: Identifiable {
    let id: UUID
    let frequency: Double
    let actualGainDB: Double
    let recommendedGainDB: Double
    let deltaDB: Double                 // actual - recommended
    let suggestion: String

    init(
        id: UUID = UUID(),
        frequency: Double,
        actualGainDB: Double,
        recommendedGainDB: Double,
        suggestion: String = ""
    ) {
        self.id = id
        self.frequency = frequency
        self.actualGainDB = actualGainDB
        self.recommendedGainDB = recommendedGainDB
        self.deltaDB = actualGainDB - recommendedGainDB
        self.suggestion = suggestion
    }
}

/// Delta for compressor settings.
struct CompressorDelta: Identifiable {
    let id: UUID
    let actualThreshold: Double?
    let recommendedThreshold: Double?
    let actualRatio: Double?
    let recommendedRatio: Double?
    let thresholdStatus: DeltaStatus
    let ratioStatus: DeltaStatus
    let suggestion: String

    init(
        id: UUID = UUID(),
        actualThreshold: Double? = nil,
        recommendedThreshold: Double? = nil,
        actualRatio: Double? = nil,
        recommendedRatio: Double? = nil,
        thresholdStatus: DeltaStatus = .missing,
        ratioStatus: DeltaStatus = .missing,
        suggestion: String = ""
    ) {
        self.id = id
        self.actualThreshold = actualThreshold
        self.recommendedThreshold = recommendedThreshold
        self.actualRatio = actualRatio
        self.recommendedRatio = recommendedRatio
        self.thresholdStatus = thresholdStatus
        self.ratioStatus = ratioStatus
        self.suggestion = suggestion
    }
}

/// Overall analysis score for a channel.
enum AnalysisScore: String, Codable {
    case excellent  = "Excellent"       // All params optimal
    case good       = "Good"            // Most params in range
    case fair       = "Fair"            // Some attention needed
    case poor       = "Needs Work"      // Multiple issues

    var emoji: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good:      return "checkmark.circle"
        case .fair:      return "exclamationmark.triangle"
        case .poor:      return "xmark.circle"
        }
    }
}

/// Complete analysis result for the whole mixer.
struct MixerAnalysis: Identifiable {
    let id: UUID
    let snapshot: MixerSnapshot
    let recommendation: MixerSettingRecommendation
    let channelDeltas: [ChannelDelta]
    let overallScore: AnalysisScore
    let splEstimate: SPLEstimate?
    let globalSuggestions: [String]
    let analyzedAt: Date

    init(
        id: UUID = UUID(),
        snapshot: MixerSnapshot,
        recommendation: MixerSettingRecommendation,
        channelDeltas: [ChannelDelta],
        overallScore: AnalysisScore = .good,
        splEstimate: SPLEstimate? = nil,
        globalSuggestions: [String] = [],
        analyzedAt: Date = Date()
    ) {
        self.id = id
        self.snapshot = snapshot
        self.recommendation = recommendation
        self.channelDeltas = channelDeltas
        self.overallScore = overallScore
        self.splEstimate = splEstimate
        self.globalSuggestions = globalSuggestions
        self.analyzedAt = analyzedAt
    }
}

/// Estimated SPL at the measurement point.
struct SPLEstimate {
    let estimatedPeakDB: Double         // Estimated peak SPL during loudest moment
    let targetDB: Double                // User's target
    let deltaDB: Double                 // estimated - target (positive = over)
    let flagged: Bool                   // Exceeds threshold for user's flagging mode
    let message: String
}


// MARK: - ─── Localized Display Names ────────────────────────────────────────
// Each user-facing enum gets a `localizedName` computed property that wraps its
// rawValue through `String(localized:)`. This enables Xcode String Catalogs to
// extract strings for translation while keeping rawValues stable for Codable.

extension MixerModel {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension ExperienceLevel {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension BandComposition {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension InputSource {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension InputCategory {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension VocalRange {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension VocalStyle {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension MicType {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension MusicalKey {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension DrumConfiguration {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension RoomSize {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension RoomSurface {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension SongIntensity {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension SPLFlaggingMode {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension EQBandType {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension WarningSeverity {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension DeltaStatus {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}

extension AnalysisScore {
    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}
