// ============================================================================
// SampleDataInjector.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Debug Utility
// Purpose: Populates ServiceStore with realistic sample data for UI testing
//          and App Store screenshot generation. Compiled out in Release builds.
// ============================================================================

#if DEBUG

import Foundation

// MARK: - ─── Sample Data Injector ─────────────────────────────────────────

@MainActor
struct SampleDataInjector {

    static func populate(_ store: ServiceStore) {
        // Avoid double-populating
        guard store.savedServices.isEmpty else { return }

        let venue = createVenue()
        store.saveVenue(venue)

        let room = venue.rooms[0]
        let console = createConsoleProfile(venueID: venue.id, roomID: room.id)
        store.saveConsoleProfile(console)

        let vocalists = createVocalists()
        for vocalist in vocalists {
            store.saveVocalist(vocalist)
        }

        let inputs = createInputs(vocalists: vocalists)
        for input in inputs {
            store.saveInput(input)
        }

        let service = createService(
            venueID: venue.id,
            roomID: room.id,
            consoleProfileID: console.id,
            vocalists: vocalists
        )
        store.saveService(service)

        let report = createSPLReport()
        store.saveReport(report)

        var prefs = store.userPreferences
        prefs.colorTheme = .darkBooth
        prefs.defaultDetailLevel = .full
        prefs.defaultMixer = .allenHeathAvantis
        prefs.defaultRoomSize = .large
        prefs.defaultRoomSurface = .mixed
        store.updatePreferences(prefs)
    }

    // MARK: - ─── Venue ────────────────────────────────────────────────────

    private static func createVenue() -> Venue {
        Venue(
            name: "Grace Community Church",
            address: "2847 Worship Ln, Nashville, TN 37203",
            rooms: [
                Room(
                    name: "Main Sanctuary",
                    roomSize: .large,
                    roomSurface: .mixed,
                    defaultMixer: .allenHeathAvantis
                )
            ]
        )
    }

    // MARK: - ─── Console Profile ──────────────────────────────────────────

    private static func createConsoleProfile(venueID: UUID, roomID: UUID) -> ConsoleProfile {
        ConsoleProfile(
            name: "FOH — Avantis 64",
            model: .allenHeathAvantis,
            ipAddress: "192.168.1.100",
            connectionType: .tcpMIDI,
            linkedVenueID: venueID,
            linkedRoomID: roomID,
            notes: "Main sanctuary FOH position"
        )
    }

    // MARK: - ─── Vocalists ────────────────────────────────────────────────

    private static func createVocalists() -> [SavedVocalist] {
        [
            SavedVocalist(name: "Sarah M.", range: .soprano, style: .contemporary, preferredMic: .dynamicCardioid),
            SavedVocalist(name: "Emily R.", range: .alto, style: .contemporary, preferredMic: .dynamicCardioid),
            SavedVocalist(name: "Marcus T.", range: .tenor, style: .contemporary, preferredMic: .dynamicCardioid),
            SavedVocalist(name: "David K.", range: .baritone, style: .contemporary, preferredMic: .dynamicCardioid)
        ]
    }

    // MARK: - ─── Inputs ───────────────────────────────────────────────────

    private static func createInputs(vocalists: [SavedVocalist]) -> [SavedInput] {
        [
            SavedInput(name: "Lead Vocal", source: .leadVocal,
                       vocalProfile: VocalProfile(from: vocalists[0]),
                       tags: ["vocal", "lead"], micModel: "SM58"),
            SavedInput(name: "BV — Emily", source: .backingVocal,
                       vocalProfile: VocalProfile(from: vocalists[1]),
                       tags: ["vocal", "backing"], micModel: "SM58"),
            SavedInput(name: "Electric GTR L", source: .electricGtrModeler,
                       tags: ["guitar", "stage-left"]),
            SavedInput(name: "Acoustic GTR", source: .acousticGtrDI,
                       tags: ["guitar", "acoustic"]),
            SavedInput(name: "Bass DI", source: .bassGtrDI,
                       tags: ["bass", "di"]),
            SavedInput(name: "Keys Left", source: .digitalPiano,
                       tags: ["keys", "stereo-l"]),
            SavedInput(name: "Kick In", source: .kickDrum,
                       tags: ["drums", "kick"], micModel: "Beta 52A"),
            SavedInput(name: "Snare Top", source: .snareDrum,
                       tags: ["drums", "snare"], micModel: "SM57")
        ]
    }

    // MARK: - ─── Worship Service ──────────────────────────────────────────

    private static func createService(
        venueID: UUID,
        roomID: UUID,
        consoleProfileID: UUID,
        vocalists: [SavedVocalist]
    ) -> WorshipService {
        let channels: [InputChannel] = [
            InputChannel(label: "Lead Vocal", source: .leadVocal,
                         vocalProfile: VocalProfile(from: vocalists[0])),
            InputChannel(label: "BV — Emily", source: .backingVocal,
                         vocalProfile: VocalProfile(from: vocalists[1])),
            InputChannel(label: "BV — Marcus", source: .backingVocal,
                         vocalProfile: VocalProfile(from: vocalists[2])),
            InputChannel(label: "Electric GTR L", source: .electricGtrModeler),
            InputChannel(label: "Acoustic GTR", source: .acousticGtrDI),
            InputChannel(label: "Bass DI", source: .bassGtrDI),
            InputChannel(label: "Keys Left", source: .digitalPiano),
            InputChannel(label: "Keys Right", source: .tracksLeft),
            InputChannel(label: "Kick In", source: .kickDrum),
            InputChannel(label: "Snare Top", source: .snareDrum)
        ]

        let setlist: [SetlistSong] = [
            SetlistSong(title: "Goodness of God", key: .Ab, bpm: 72, intensity: .medium),
            SetlistSong(title: "Way Maker", key: .E, bpm: 68, intensity: .driving),
            SetlistSong(title: "Build My Life", key: .G, bpm: 68, intensity: .medium),
            SetlistSong(title: "King of Kings", key: .D, bpm: 136, intensity: .allOut)
        ]

        return WorshipService(
            name: "Sunday Morning Worship",
            date: Date(),
            mixer: .allenHeathAvantis,
            bandComposition: .live,
            drumConfig: .drumCage,
            room: RoomProfile(size: .large, surface: .mixed),
            channels: channels,
            setlist: setlist,
            detailLevel: .full,
            venueID: venueID,
            roomID: roomID,
            consoleProfileID: consoleProfileID
        )
    }

    // MARK: - ─── SPL Report ───────────────────────────────────────────────

    private static func createSPLReport() -> SPLSessionReport {
        let sessionStart = Calendar.current.date(
            byAdding: .hour, value: -2, to: Date()
        ) ?? Date()
        let sessionEnd = Calendar.current.date(
            byAdding: .minute, value: -15, to: Date()
        ) ?? Date()

        let breachEvents = [
            SPLBreachEvent(
                startTime: Calendar.current.date(
                    byAdding: .minute, value: 25, to: sessionStart
                ) ?? sessionStart,
                endTime: Calendar.current.date(
                    byAdding: .minute, value: 26, to: sessionStart
                ) ?? sessionStart,
                peakDB: 93.2,
                targetDB: 90.0,
                thresholdDB: 90.0
            ),
            SPLBreachEvent(
                startTime: Calendar.current.date(
                    byAdding: .minute, value: 68, to: sessionStart
                ) ?? sessionStart,
                endTime: Calendar.current.date(
                    byAdding: .minute, value: 69, to: sessionStart
                ) ?? sessionStart,
                peakDB: 91.5,
                targetDB: 90.0,
                thresholdDB: 90.0
            )
        ]

        return SPLSessionReport(
            sessionStart: sessionStart,
            sessionEnd: sessionEnd,
            targetDB: 90.0,
            flaggingMode: .balanced,
            breachEvents: breachEvents,
            overallPeakDB: 93.2,
            overallAverageDB: 85.4,
            totalMonitoringSeconds: 6300
        )
    }
}

#endif
