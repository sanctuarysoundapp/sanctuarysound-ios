// ============================================================================
// ServiceModels.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Data Layer
// Purpose: Core service types — detail levels, band composition, input sources,
//          musical keys, room acoustics, channels, setlist, and saved presets.
// Reference Level: -18 dBFS (nominal digital zero)
// ============================================================================

import Foundation


// MARK: - ─── Detail Level ─────────────────────────────────────────────────

/// Controls the depth of recommendations shown to the user.
/// Maps directly to the 3-level system defined in the spec.
enum DetailLevel: String, CaseIterable, Identifiable, Codable {
    case essentials = "Essentials"   // Level 1: Gain & Fader only
    case detailed   = "Detailed"     // Level 2: + EQ & HPF
    case full       = "Full"         // Level 3: Full channel strip

    var id: String { rawValue }

    var description: String {
        switch self {
        case .essentials:
            return "Gain & fader start-points only"
        case .detailed:
            return "Adds EQ suggestions & high-pass filter"
        case .full:
            return "Full channel strip: EQ, compression, HPF, & gain staging"
        }
    }

    /// Abbreviated label for compact badges
    var shortName: String {
        switch self {
        case .essentials: return "Ess"
        case .detailed:   return "Det"
        case .full:       return "Full"
        }
    }

    var showsEQ: Bool { self != .essentials }
    var showsCompression: Bool { self == .full }
    var showsHPF: Bool { self != .essentials }
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


// MARK: - ─── Room Acoustics (3x3 Matrix) ──────────────────────────────────

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
    var detailLevel: DetailLevel

    // ── Venue/Room/Console References (optional for backward compat) ──
    var venueID: UUID?
    var roomID: UUID?
    var consoleProfileID: UUID?

    // ── Backward-Compatible CodingKeys ──

    private enum CodingKeys: String, CodingKey {
        case id, name, date, mixer, bandComposition, drumConfig, room
        case channels, setlist, detailLevel
        case experienceLevel    // Legacy key for reading old data
        case venueID, roomID, consoleProfileID
    }

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
        detailLevel: DetailLevel = .detailed,
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
        self.detailLevel = detailLevel
        self.venueID = venueID
        self.roomID = roomID
        self.consoleProfileID = consoleProfileID
    }

    // ── Backward-Compatible Decoder ──

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        date = try container.decode(Date.self, forKey: .date)
        mixer = try container.decode(MixerModel.self, forKey: .mixer)
        bandComposition = try container.decode(BandComposition.self, forKey: .bandComposition)
        drumConfig = try container.decode(DrumConfiguration.self, forKey: .drumConfig)
        room = try container.decode(RoomProfile.self, forKey: .room)
        channels = try container.decode([InputChannel].self, forKey: .channels)
        setlist = try container.decode([SetlistSong].self, forKey: .setlist)

        // Migration: try new key first, then fall back to legacy key with value mapping
        if let detail = try container.decodeIfPresent(DetailLevel.self, forKey: .detailLevel) {
            detailLevel = detail
        } else if let legacyRaw = try container.decodeIfPresent(String.self, forKey: .experienceLevel) {
            switch legacyRaw {
            case "Beginner":     detailLevel = .essentials
            case "Intermediate": detailLevel = .detailed
            case "Advanced":     detailLevel = .full
            default:             detailLevel = .detailed
            }
        } else {
            detailLevel = .detailed
        }

        venueID = try container.decodeIfPresent(UUID.self, forKey: .venueID)
        roomID = try container.decodeIfPresent(UUID.self, forKey: .roomID)
        consoleProfileID = try container.decodeIfPresent(UUID.self, forKey: .consoleProfileID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(date, forKey: .date)
        try container.encode(mixer, forKey: .mixer)
        try container.encode(bandComposition, forKey: .bandComposition)
        try container.encode(drumConfig, forKey: .drumConfig)
        try container.encode(room, forKey: .room)
        try container.encode(channels, forKey: .channels)
        try container.encode(setlist, forKey: .setlist)
        try container.encode(detailLevel, forKey: .detailLevel)
        try container.encodeIfPresent(venueID, forKey: .venueID)
        try container.encodeIfPresent(roomID, forKey: .roomID)
        try container.encodeIfPresent(consoleProfileID, forKey: .consoleProfileID)
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


// MARK: - ─── Localized Display Names ────────────────────────────────────────
// Each user-facing enum gets a `localizedName` computed property that wraps its
// rawValue through `String(localized:)`. This enables Xcode String Catalogs to
// extract strings for translation while keeping rawValues stable for Codable.

extension DetailLevel {
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
