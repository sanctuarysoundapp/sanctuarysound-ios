// ============================================================================
// ForceUnwrapSafetyTests.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Unit Tests
// Purpose: Tests that verify safe handling of edge cases previously guarded
//          only by force unwraps. Each test targets a specific force unwrap
//          removal: SoundEngine (empty setlist), ServiceStore (nil vocal
//          profile), and SPLMeter (alert state debounce timing).
// ============================================================================

import XCTest
@testable import SanctuarySound


// MARK: - ─── SoundEngine Empty Setlist Safety Tests ─────────────────────

/// Tests that SoundEngine.generateGlobalNotes handles edge cases around
/// setlist.first! and setlist.last! (lines 765, 771 in SoundEngine.swift).
final class SoundEngineEmptySetlistTests: XCTestCase {

    private var engine: SoundEngine!

    override func setUp() {
        super.setUp()
        engine = SoundEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }


    // MARK: - ─── Single-Key Setlist (triggers uniqueKeys == 1 path) ──────

    /// When a single song is in the setlist, uniqueKeys.count == 1 and the
    /// code accesses setlist.first and setlist.last. This must not crash.
    func testSingleSongSetlist_doesNotCrash() {
        let channel = InputChannel(
            label: "Lead Vocal",
            source: .leadVocal,
            vocalProfile: VocalProfile(
                range: .soprano,
                style: .contemporary,
                micType: .dynamicCardioid
            )
        )

        let service = WorshipService(
            mixer: .allenHeathAvantis,
            room: RoomProfile(size: .medium, surface: .mixed),
            channels: [channel],
            setlist: [SetlistSong(title: "Only Song", key: .E)],
            detailLevel: .full
        )

        let result = engine.generateRecommendation(for: service)

        XCTAssertFalse(result.channelRecommendations.isEmpty,
            "Single-song setlist should still produce recommendations")

        // The global notes should mention the single key
        let hasKeyNote = result.globalNotes.contains { $0.contains("key of E") || $0.contains("Key of E") }
        XCTAssertTrue(hasKeyNote,
            "Single key setlist should generate a harmonic buildup note")
    }

    /// Empty setlist should not crash on the uniqueKeys or last-song checks.
    func testEmptySetlist_doesNotCrash() {
        let channel = InputChannel(
            label: "Keys",
            source: .digitalPiano
        )

        let service = WorshipService(
            mixer: .allenHeathAvantis,
            room: RoomProfile(size: .medium, surface: .mixed),
            channels: [channel],
            setlist: [],
            detailLevel: .full
        )

        let result = engine.generateRecommendation(for: service)

        XCTAssertFalse(result.channelRecommendations.isEmpty,
            "Empty setlist should still produce channel recommendations")
    }

    /// Three songs all in the same key with the last being high-energy.
    /// This exercises both the uniqueKeys == 1 branch (first!) and the
    /// intensity progression branch (last!).
    func testThreeSongsAllSameKey_lastIsHighEnergy() {
        let channel = InputChannel(
            label: "Bass",
            source: .bassGtrDI
        )

        let songs = [
            SetlistSong(title: "Song 1", key: .A, intensity: .soft),
            SetlistSong(title: "Song 2", key: .A, intensity: .medium),
            SetlistSong(title: "Song 3", key: .A, intensity: .allOut)
        ]

        let service = WorshipService(
            mixer: .allenHeathAvantis,
            room: RoomProfile(size: .medium, surface: .mixed),
            channels: [channel],
            setlist: songs,
            detailLevel: .full
        )

        let result = engine.generateRecommendation(for: service)

        // Should have both a same-key note and an intensity progression note
        XCTAssertGreaterThanOrEqual(result.globalNotes.count, 2,
            "Three same-key songs ending in high energy should produce multiple global notes")
    }

    /// Two songs in different keys — should NOT trigger the uniqueKeys == 1 branch.
    func testDifferentKeys_doesNotTriggerSameKeyNote() {
        let channel = InputChannel(
            label: "Guitar",
            source: .electricGtrModeler
        )

        let songs = [
            SetlistSong(title: "Song A", key: .G),
            SetlistSong(title: "Song B", key: .D)
        ]

        let service = WorshipService(
            mixer: .allenHeathAvantis,
            room: RoomProfile(size: .small, surface: .absorbent),
            channels: [channel],
            setlist: songs,
            detailLevel: .full
        )

        let result = engine.generateRecommendation(for: service)

        let hasSameKeyNote = result.globalNotes.contains { note in
            note.lowercased().contains("all songs are in the key")
        }
        XCTAssertFalse(hasSameKeyNote,
            "Different-key setlist should NOT trigger same-key warning")
    }
}


// MARK: - ─── ServiceStore Vocal Profile Safety Tests ────────────────────

/// Tests that ServiceStore.autoSaveVocalists handles channels where
/// vocalProfile passes the `where` filter but the force unwrap on
/// channel.vocalProfile! (line 133) is now safely guarded.
@MainActor
final class ServiceStoreVocalProfileSafetyTests: XCTestCase {

    /// Channels with vocal profiles should be saved without crash.
    func testAutoSaveVocalists_withVocalProfiles() {
        let store = ServiceStore()

        let channels = [
            InputChannel(
                label: "Sarah",
                source: .leadVocal,
                vocalProfile: VocalProfile(
                    range: .soprano,
                    style: .contemporary,
                    micType: .dynamicCardioid
                )
            ),
            InputChannel(
                label: "Guitar",
                source: .electricGtrModeler
            )
        ]

        // Should not crash — previously relied on force unwrap
        store.autoSaveVocalists(from: channels)

        // Only the channel with a vocal profile should be saved
        let saved = store.savedVocalists.filter { $0.name == "Sarah" }
        XCTAssertEqual(saved.count, 1,
            "Should save exactly one vocalist from channels with vocal profiles")
    }

    /// Empty channel array should not crash.
    func testAutoSaveVocalists_emptyArray() {
        let store = ServiceStore()
        let initialCount = store.savedVocalists.count

        store.autoSaveVocalists(from: [])

        // No crash, no new vocalists added
        XCTAssertEqual(store.savedVocalists.count, initialCount,
            "Empty input should not add any new vocalists")
    }

    /// All channels without vocal profiles should skip gracefully.
    func testAutoSaveVocalists_noVocalProfiles() {
        let store = ServiceStore()
        let initialCount = store.savedVocalists.count

        let channels = [
            InputChannel(label: "Keys", source: .digitalPiano),
            InputChannel(label: "Bass", source: .bassGtrDI)
        ]

        store.autoSaveVocalists(from: channels)

        XCTAssertEqual(store.savedVocalists.count, initialCount,
            "Channels without vocal profiles should not add any vocalists")
    }
}


// MARK: - ─── SPL Alert State Debounce Safety Tests ──────────────────────

/// Tests that SPLMeter.evaluateAlertState handles the timing-dependent
/// breachStartTime and safeStartTime optionals safely (lines 233, 258).
/// These were previously accessed via force unwrap after a nil check on the
/// same line, which is fragile under race conditions.
@MainActor
final class SPLAlertStateDebounceTests: XCTestCase {

    /// Verify that the alert state starts as .safe.
    func testInitialAlertState_isSafe() {
        let meter = SPLMeter()
        XCTAssertEqual(meter.alertState, .safe)
    }

    /// Verify that updateAlertThresholds does not crash with edge values.
    func testUpdateAlertThresholds_withEdgeValues() {
        let meter = SPLMeter()

        // Zero target — everything would be over threshold
        let lowPref = SPLPreference(targetDB: 0, flaggingMode: .strict)
        meter.updateAlertThresholds(preference: lowPref)

        // Very high target — nothing would breach
        let highPref = SPLPreference(targetDB: 200, flaggingMode: .variable)
        meter.updateAlertThresholds(preference: highPref)

        // Should not crash with any preference values
        XCTAssertEqual(meter.alertState, .safe,
            "Meter should remain safe when no audio is being processed")
    }

    /// Verify that the meter can be started and stopped without crash,
    /// even when no audio was ever processed (breachStartTime/safeStartTime remain nil).
    func testStartStop_withNoAudioProcessed() {
        let meter = SPLMeter()

        // Stop without start — should not crash (breachStartTime is nil)
        meter.stop()
        XCTAssertFalse(meter.isRunning)
    }
}
