// ============================================================================
// PCOTests.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Unit Tests
// Purpose: Tests for Planning Center Online integration — JSON:API model
//          decoding, musical key parsing, team position mapping, and domain
//          model creation. Focuses on pure logic (no network mocking needed).
// ============================================================================

import XCTest
@testable import SanctuarySound


// MARK: - ─── PCO Models JSON Decoding Tests ──────────────────────────────

final class PCOModelsDecodingTests: XCTestCase {

    private let decoder = JSONDecoder()


    // MARK: - ─── Service Type Decoding ───────────────────────────────────

    func testDecodeServiceTypesResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "1001",
                    "type": "ServiceType",
                    "attributes": {
                        "name": "Sunday AM Worship",
                        "frequency": "Weekly",
                        "last_plan_from": "2026-02-08"
                    }
                },
                {
                    "id": "1002",
                    "type": "ServiceType",
                    "attributes": {
                        "name": "Wednesday Night",
                        "frequency": "Every Other Week",
                        "last_plan_from": null
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOServiceTypeAttributes>.self, from: json)

        XCTAssertEqual(response.data.count, 2)

        let first = response.data[0]
        XCTAssertEqual(first.id, "1001")
        XCTAssertEqual(first.type, "ServiceType")
        XCTAssertEqual(first.attributes.name, "Sunday AM Worship")
        XCTAssertEqual(first.attributes.frequency, "Weekly")
        XCTAssertEqual(first.attributes.lastPlanFrom, "2026-02-08")

        let second = response.data[1]
        XCTAssertEqual(second.id, "1002")
        XCTAssertEqual(second.attributes.name, "Wednesday Night")
        XCTAssertEqual(second.attributes.frequency, "Every Other Week")
        XCTAssertNil(second.attributes.lastPlanFrom)
    }


    // MARK: - ─── Plan Decoding ──────────────────────────────────────────

    func testDecodePlansResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "5001",
                    "type": "Plan",
                    "attributes": {
                        "title": "Sunday Service",
                        "series_title": "Unstoppable",
                        "dates": "February 9, 2026",
                        "sort_date": "2026-02-09T09:30:00Z",
                        "created_at": "2026-01-15T10:00:00Z"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOPlanAttributes>.self, from: json)

        XCTAssertEqual(response.data.count, 1)

        let plan = response.data[0]
        XCTAssertEqual(plan.id, "5001")
        XCTAssertEqual(plan.type, "Plan")
        XCTAssertEqual(plan.attributes.title, "Sunday Service")
        XCTAssertEqual(plan.attributes.seriesTitle, "Unstoppable")
        XCTAssertEqual(plan.attributes.dates, "February 9, 2026")
        XCTAssertEqual(plan.attributes.sortDate, "2026-02-09T09:30:00Z")
        XCTAssertEqual(plan.attributes.createdAt, "2026-01-15T10:00:00Z")
    }

    func testDecodePlanWithNullOptionalFields() throws {
        let json = """
        {
            "data": [
                {
                    "id": "5002",
                    "type": "Plan",
                    "attributes": {
                        "title": null,
                        "series_title": null,
                        "dates": "February 16, 2026",
                        "sort_date": "2026-02-16T09:30:00Z",
                        "created_at": null
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOPlanAttributes>.self, from: json)
        let plan = response.data[0]

        XCTAssertNil(plan.attributes.title)
        XCTAssertNil(plan.attributes.seriesTitle)
        XCTAssertEqual(plan.attributes.dates, "February 16, 2026")
        XCTAssertNil(plan.attributes.createdAt)
    }


    // MARK: - ─── Plan Item (Song) Decoding ──────────────────────────────

    func testDecodePlanItemsResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "9001",
                    "type": "Item",
                    "attributes": {
                        "title": "Praise",
                        "item_type": "song",
                        "length": 300,
                        "description": "Elevation Worship",
                        "song_id": "7001",
                        "key": "G"
                    }
                },
                {
                    "id": "9002",
                    "type": "Item",
                    "attributes": {
                        "title": "Welcome",
                        "item_type": "header",
                        "length": null,
                        "description": null,
                        "song_id": null,
                        "key": null
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOPlanItemAttributes>.self, from: json)

        XCTAssertEqual(response.data.count, 2)

        let song = response.data[0]
        XCTAssertEqual(song.id, "9001")
        XCTAssertEqual(song.type, "Item")
        XCTAssertEqual(song.attributes.title, "Praise")
        XCTAssertEqual(song.attributes.itemType, "song")
        XCTAssertEqual(song.attributes.length, 300)
        XCTAssertEqual(song.attributes.description, "Elevation Worship")
        XCTAssertEqual(song.attributes.songId, "7001")
        XCTAssertEqual(song.attributes.key, "G")

        let header = response.data[1]
        XCTAssertEqual(header.attributes.itemType, "header")
        XCTAssertNil(header.attributes.length)
        XCTAssertNil(header.attributes.songId)
        XCTAssertNil(header.attributes.key)
    }


    // MARK: - ─── Team Member Decoding ───────────────────────────────────

    func testDecodeTeamMembersResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "3001",
                    "type": "PlanPerson",
                    "attributes": {
                        "name": "Sarah Johnson",
                        "status": "C",
                        "team_position_name": "Worship Leader"
                    }
                },
                {
                    "id": "3002",
                    "type": "PlanPerson",
                    "attributes": {
                        "name": "Marcus Lee",
                        "status": "U",
                        "team_position_name": "Electric Guitar"
                    }
                },
                {
                    "id": "3003",
                    "type": "PlanPerson",
                    "attributes": {
                        "name": "Alex Rivera",
                        "status": "D",
                        "team_position_name": "Drums"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOTeamMemberAttributes>.self, from: json)

        XCTAssertEqual(response.data.count, 3)

        let leader = response.data[0]
        XCTAssertEqual(leader.id, "3001")
        XCTAssertEqual(leader.type, "PlanPerson")
        XCTAssertEqual(leader.attributes.name, "Sarah Johnson")
        XCTAssertEqual(leader.attributes.status, "C")
        XCTAssertEqual(leader.attributes.teamPositionName, "Worship Leader")

        let guitarist = response.data[1]
        XCTAssertEqual(guitarist.attributes.status, "U")
        XCTAssertEqual(guitarist.attributes.teamPositionName, "Electric Guitar")

        let drummer = response.data[2]
        XCTAssertEqual(drummer.attributes.status, "D")
    }

    func testDecodeTeamMemberWithNullFields() throws {
        let json = """
        {
            "data": [
                {
                    "id": "3010",
                    "type": "PlanPerson",
                    "attributes": {
                        "name": null,
                        "status": null,
                        "team_position_name": null
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOTeamMemberAttributes>.self, from: json)
        let member = response.data[0]

        XCTAssertNil(member.attributes.name)
        XCTAssertNil(member.attributes.status)
        XCTAssertNil(member.attributes.teamPositionName)
    }


    // MARK: - ─── Song (Single Resource) Decoding ────────────────────────

    func testDecodeSingleSongResponse() throws {
        let json = """
        {
            "data": {
                "id": "7001",
                "type": "Song",
                "attributes": {
                    "title": "Praise",
                    "author": "Elevation Worship",
                    "copyright": "2023 Elevation Worship Publishing",
                    "ccli_number": 7219685
                }
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOSingleResponse<PCOSongAttributes>.self, from: json)

        XCTAssertEqual(response.data.id, "7001")
        XCTAssertEqual(response.data.type, "Song")
        XCTAssertEqual(response.data.attributes.title, "Praise")
        XCTAssertEqual(response.data.attributes.author, "Elevation Worship")
        XCTAssertEqual(response.data.attributes.copyright, "2023 Elevation Worship Publishing")
        XCTAssertEqual(response.data.attributes.ccliNumber, 7219685)
    }

    func testDecodeSongWithNullOptionalFields() throws {
        let json = """
        {
            "data": {
                "id": "7002",
                "type": "Song",
                "attributes": {
                    "title": "Original Composition",
                    "author": null,
                    "copyright": null,
                    "ccli_number": null
                }
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOSingleResponse<PCOSongAttributes>.self, from: json)

        XCTAssertEqual(response.data.attributes.title, "Original Composition")
        XCTAssertNil(response.data.attributes.author)
        XCTAssertNil(response.data.attributes.copyright)
        XCTAssertNil(response.data.attributes.ccliNumber)
    }


    // MARK: - ─── Arrangement Decoding ───────────────────────────────────

    func testDecodeArrangementsResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "8001",
                    "type": "Arrangement",
                    "attributes": {
                        "name": "Default Arrangement",
                        "bpm": 140.0,
                        "length": 285,
                        "meter_numerator": 4,
                        "meter_denominator": 4
                    }
                },
                {
                    "id": "8002",
                    "type": "Arrangement",
                    "attributes": {
                        "name": "Acoustic Version",
                        "bpm": 72.5,
                        "length": 320,
                        "meter_numerator": 3,
                        "meter_denominator": 4
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOArrangementAttributes>.self, from: json)

        XCTAssertEqual(response.data.count, 2)

        let first = response.data[0]
        XCTAssertEqual(first.id, "8001")
        XCTAssertEqual(first.type, "Arrangement")
        XCTAssertEqual(first.attributes.name, "Default Arrangement")
        XCTAssertEqual(first.attributes.bpm, 140.0)
        XCTAssertEqual(first.attributes.length, 285)
        XCTAssertEqual(first.attributes.meterNumerator, 4)
        XCTAssertEqual(first.attributes.meterDenominator, 4)

        let second = response.data[1]
        XCTAssertEqual(second.attributes.bpm, 72.5)
        XCTAssertEqual(second.attributes.meterNumerator, 3)
    }

    func testDecodeArrangementWithNullFields() throws {
        let json = """
        {
            "data": [
                {
                    "id": "8003",
                    "type": "Arrangement",
                    "attributes": {
                        "name": null,
                        "bpm": null,
                        "length": null,
                        "meter_numerator": null,
                        "meter_denominator": null
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOArrangementAttributes>.self, from: json)
        let arrangement = response.data[0]

        XCTAssertNil(arrangement.attributes.name)
        XCTAssertNil(arrangement.attributes.bpm)
        XCTAssertNil(arrangement.attributes.length)
        XCTAssertNil(arrangement.attributes.meterNumerator)
        XCTAssertNil(arrangement.attributes.meterDenominator)
    }


    // MARK: - ─── Meta & Included Decoding ───────────────────────────────

    func testDecodeResponseWithMeta() throws {
        let json = """
        {
            "data": [
                {
                    "id": "1001",
                    "type": "ServiceType",
                    "attributes": {
                        "name": "Sunday AM",
                        "frequency": "Weekly",
                        "last_plan_from": null
                    }
                }
            ],
            "meta": {
                "total_count": 42,
                "count": 1,
                "next": {
                    "offset": 25
                }
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOServiceTypeAttributes>.self, from: json)

        XCTAssertNotNil(response.meta)
        XCTAssertEqual(response.meta?.totalCount, 42)
        XCTAssertEqual(response.meta?.count, 1)
        XCTAssertEqual(response.meta?.next?.offset, 25)
    }

    func testDecodeResponseWithoutMeta() throws {
        let json = """
        {
            "data": [
                {
                    "id": "1001",
                    "type": "ServiceType",
                    "attributes": {
                        "name": "Sunday AM",
                        "frequency": null,
                        "last_plan_from": null
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOServiceTypeAttributes>.self, from: json)
        XCTAssertNil(response.meta)
    }

    func testDecodeEmptyDataArray() throws {
        let json = """
        {
            "data": []
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOPlanAttributes>.self, from: json)
        XCTAssertTrue(response.data.isEmpty)
    }

    func testPCOResourceConformsToIdentifiable() throws {
        let json = """
        {
            "data": {
                "id": "unique-resource-42",
                "type": "Song",
                "attributes": {
                    "title": "Test Song",
                    "author": null,
                    "copyright": null,
                    "ccli_number": null
                }
            }
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOSingleResponse<PCOSongAttributes>.self, from: json)
        XCTAssertEqual(response.data.id, "unique-resource-42")
    }
}


// MARK: - ─── Musical Key Parsing Tests ───────────────────────────────────

@MainActor
final class PCOKeyParsingTests: XCTestCase {

    private var manager: PlanningCenterManager!

    override func setUp() {
        super.setUp()
        manager = PlanningCenterManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }


    // MARK: - ─── Standard Natural Keys ──────────────────────────────────

    func testParseKey_C() {
        XCTAssertEqual(manager.parseMusicalKey("C"), .C)
    }

    func testParseKey_D() {
        XCTAssertEqual(manager.parseMusicalKey("D"), .D)
    }

    func testParseKey_E() {
        XCTAssertEqual(manager.parseMusicalKey("E"), .E)
    }

    func testParseKey_F() {
        XCTAssertEqual(manager.parseMusicalKey("F"), .F)
    }

    func testParseKey_G() {
        XCTAssertEqual(manager.parseMusicalKey("G"), .G)
    }

    func testParseKey_A() {
        XCTAssertEqual(manager.parseMusicalKey("A"), .A)
    }

    func testParseKey_B() {
        XCTAssertEqual(manager.parseMusicalKey("B"), .B)
    }


    // MARK: - ─── Sharp Keys (Enharmonic to Flat) ────────────────────────

    func testParseKey_CSharp_mapsToDb() {
        XCTAssertEqual(manager.parseMusicalKey("C#"), .Db)
    }

    func testParseKey_FSharp_mapsToGb() {
        XCTAssertEqual(manager.parseMusicalKey("F#"), .Gb)
    }

    func testParseKey_GSharp_mapsToAb() {
        XCTAssertEqual(manager.parseMusicalKey("G#"), .Ab)
    }

    func testParseKey_DSharp_mapsToEb() {
        XCTAssertEqual(manager.parseMusicalKey("D#"), .Eb)
    }

    func testParseKey_ASharp_mapsToBb() {
        XCTAssertEqual(manager.parseMusicalKey("A#"), .Bb)
    }


    // MARK: - ─── Flat Keys (ASCII) ──────────────────────────────────────

    func testParseKey_Db() {
        XCTAssertEqual(manager.parseMusicalKey("Db"), .Db)
    }

    func testParseKey_Eb() {
        XCTAssertEqual(manager.parseMusicalKey("Eb"), .Eb)
    }

    func testParseKey_Gb() {
        XCTAssertEqual(manager.parseMusicalKey("Gb"), .Gb)
    }

    func testParseKey_Ab() {
        XCTAssertEqual(manager.parseMusicalKey("Ab"), .Ab)
    }

    func testParseKey_Bb() {
        XCTAssertEqual(manager.parseMusicalKey("Bb"), .Bb)
    }


    // MARK: - ─── Unicode Flat Symbol ────────────────────────────────────

    func testParseKey_unicodeEFlat() {
        XCTAssertEqual(manager.parseMusicalKey("E\u{266D}"), .Eb,
            "Unicode flat symbol (U+266D) should parse to Eb")
    }

    func testParseKey_unicodeAFlat() {
        XCTAssertEqual(manager.parseMusicalKey("A\u{266D}"), .Ab,
            "Unicode flat symbol (U+266D) should parse to Ab")
    }

    func testParseKey_unicodeBFlat() {
        XCTAssertEqual(manager.parseMusicalKey("B\u{266D}"), .Bb,
            "Unicode flat symbol (U+266D) should parse to Bb")
    }


    // MARK: - ─── Keys With Modifiers ────────────────────────────────────

    func testParseKey_EbMajor_stripsModifier() {
        XCTAssertEqual(manager.parseMusicalKey("Eb Major"), .Eb,
            "Should strip ' Major' and return Eb")
    }

    func testParseKey_FSharpMinor_stripsModifier() {
        XCTAssertEqual(manager.parseMusicalKey("F# minor"), .Gb,
            "Should strip ' minor' and map F# to Gb")
    }

    func testParseKey_Am_stripsMinorIndicator() {
        XCTAssertEqual(manager.parseMusicalKey("Am"), .A,
            "Should strip 'm' minor indicator and return A")
    }

    func testParseKey_Gm_stripsMinorIndicator() {
        XCTAssertEqual(manager.parseMusicalKey("Gm"), .G,
            "Should strip 'm' minor indicator and return G")
    }

    func testParseKey_Bbm_stripsMinorIndicator() {
        // "Bbm" -> strip "m" -> "Bb" -> .Bb
        XCTAssertEqual(manager.parseMusicalKey("Bbm"), .Bb,
            "Should handle Bbm by stripping m to get Bb")
    }


    // MARK: - ─── Edge Cases ─────────────────────────────────────────────

    func testParseKey_nil_returnsNil() {
        XCTAssertNil(manager.parseMusicalKey(nil),
            "Nil input should return nil")
    }

    func testParseKey_emptyString_returnsNil() {
        XCTAssertNil(manager.parseMusicalKey(""),
            "Empty string should return nil")
    }

    func testParseKey_whitespaceOnly_returnsNil() {
        XCTAssertNil(manager.parseMusicalKey("   "),
            "Whitespace-only string should return nil")
    }

    func testParseKey_invalidString_returnsNil() {
        XCTAssertNil(manager.parseMusicalKey("XYZ"),
            "Invalid key string should return nil")
    }

    func testParseKey_numericString_returnsNil() {
        XCTAssertNil(manager.parseMusicalKey("123"),
            "Numeric string should return nil")
    }

    func testParseKey_leadingTrailingWhitespace_trims() {
        XCTAssertEqual(manager.parseMusicalKey("  G  "), .G,
            "Should trim whitespace and parse key correctly")
    }
}


// MARK: - ─── Position Mapping Tests ──────────────────────────────────────

@MainActor
final class PCOPositionMappingTests: XCTestCase {

    private var manager: PlanningCenterManager!

    override func setUp() {
        super.setUp()
        manager = PlanningCenterManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }


    // MARK: - ─── Vocal Positions ────────────────────────────────────────

    func testMapPosition_worshipLeader_returnsLeadVocal() {
        XCTAssertEqual(manager.mapPositionToSource("Worship Leader"), .leadVocal)
    }

    func testMapPosition_leadVocal_returnsLeadVocal() {
        XCTAssertEqual(manager.mapPositionToSource("Lead Vocal"), .leadVocal)
    }

    func testMapPosition_leadVocalUppercase_returnsLeadVocal() {
        XCTAssertEqual(manager.mapPositionToSource("LEAD VOCAL"), .leadVocal)
    }

    func testMapPosition_bgv_returnsBackingVocal() {
        XCTAssertEqual(manager.mapPositionToSource("BGV"), .backingVocal)
    }

    func testMapPosition_backupVocal_returnsBackingVocal() {
        XCTAssertEqual(manager.mapPositionToSource("Backup Vocal"), .backingVocal)
    }

    func testMapPosition_backingVocal_returnsBackingVocal() {
        XCTAssertEqual(manager.mapPositionToSource("Backing Vocal"), .backingVocal)
    }

    func testMapPosition_singer_returnsBackingVocal() {
        XCTAssertEqual(manager.mapPositionToSource("Singer"), .backingVocal)
    }

    func testMapPosition_vocalTeam_returnsBackingVocal() {
        XCTAssertEqual(manager.mapPositionToSource("Vocal Team"), .backingVocal)
    }


    // MARK: - ─── Instrument Positions ───────────────────────────────────

    func testMapPosition_electricGuitar_returnsModeler() {
        XCTAssertEqual(manager.mapPositionToSource("Electric Guitar"), .electricGtrModeler)
    }

    func testMapPosition_eGuitar_returnsModeler() {
        XCTAssertEqual(manager.mapPositionToSource("E. Guitar"), .electricGtrModeler)
    }

    func testMapPosition_acousticGuitar_returnsDI() {
        XCTAssertEqual(manager.mapPositionToSource("Acoustic Guitar"), .acousticGtrDI)
    }

    func testMapPosition_aGuitar_returnsDI() {
        XCTAssertEqual(manager.mapPositionToSource("A. Guitar"), .acousticGtrDI)
    }

    func testMapPosition_bass_returnsBassGtrDI() {
        XCTAssertEqual(manager.mapPositionToSource("Bass"), .bassGtrDI)
    }

    func testMapPosition_bassGuitar_returnsBassGtrDI() {
        XCTAssertEqual(manager.mapPositionToSource("Bass Guitar"), .bassGtrDI)
    }

    func testMapPosition_keyboard_returnsDigitalPiano() {
        XCTAssertEqual(manager.mapPositionToSource("Keyboard"), .digitalPiano)
    }

    func testMapPosition_keys_returnsDigitalPiano() {
        XCTAssertEqual(manager.mapPositionToSource("Keys"), .digitalPiano)
    }

    func testMapPosition_piano_returnsDigitalPiano() {
        XCTAssertEqual(manager.mapPositionToSource("Piano"), .digitalPiano)
    }

    func testMapPosition_synth_returnsDigitalPiano() {
        XCTAssertEqual(manager.mapPositionToSource("Synth Pad"), .digitalPiano)
    }

    func testMapPosition_drums_returnsKickDrum() {
        XCTAssertEqual(manager.mapPositionToSource("Drums"), .kickDrum)
    }

    func testMapPosition_drummer_returnsKickDrum() {
        XCTAssertEqual(manager.mapPositionToSource("Drummer"), .kickDrum)
    }


    // MARK: - ─── Production Positions ───────────────────────────────────

    func testMapPosition_tracks_returnsTracksLeft() {
        XCTAssertEqual(manager.mapPositionToSource("Tracks"), .tracksLeft)
    }

    func testMapPosition_click_returnsTracksLeft() {
        XCTAssertEqual(manager.mapPositionToSource("Click"), .tracksLeft)
    }

    func testMapPosition_playback_returnsTracksLeft() {
        XCTAssertEqual(manager.mapPositionToSource("Playback"), .tracksLeft)
    }

    func testMapPosition_trackOperator_returnsTracksLeft() {
        XCTAssertEqual(manager.mapPositionToSource("Track Operator"), .tracksLeft)
    }


    // MARK: - ─── Fallback Behavior ──────────────────────────────────────

    func testMapPosition_unknownPosition_fallsBackToBackingVocal() {
        XCTAssertEqual(manager.mapPositionToSource("Lighting Tech"), .backingVocal,
            "Unknown position should fall back to backing vocal")
    }

    func testMapPosition_emptyString_fallsBackToBackingVocal() {
        XCTAssertEqual(manager.mapPositionToSource(""), .backingVocal,
            "Empty position should fall back to backing vocal")
    }

    func testMapPosition_soundEngineer_fallsBackToBackingVocal() {
        XCTAssertEqual(manager.mapPositionToSource("Sound Engineer"), .backingVocal,
            "Sound Engineer should fall back to backing vocal")
    }


    // MARK: - ─── Priority / Ordering ────────────────────────────────────

    func testMapPosition_leadVocalTakesPriorityOverGenericVocal() {
        // "Lead Vocal" matches lead vocal check before generic vocal check
        XCTAssertEqual(manager.mapPositionToSource("Lead Vocal"), .leadVocal,
            "Lead Vocal should match lead vocal, not generic backing vocal")
    }

    func testMapPosition_worshipLeaderTakesPriorityOverVocal() {
        // "Worship Leader" matches lead vocal check before any other
        XCTAssertEqual(manager.mapPositionToSource("Worship Leader"), .leadVocal,
            "Worship Leader should map to lead vocal even though it does not contain 'vocal'")
    }
}


// MARK: - ─── Domain Model Creation Tests ─────────────────────────────────

final class PCODomainModelCreationTests: XCTestCase {


    // MARK: - ─── SetlistSong Creation ───────────────────────────────────

    func testCreateSetlistSong_withAllFields() {
        let song = SetlistSong(title: "Praise", key: .G, bpm: 140)

        XCTAssertEqual(song.title, "Praise")
        XCTAssertEqual(song.key, .G)
        XCTAssertEqual(song.bpm, 140)
        XCTAssertEqual(song.intensity, .medium,
            "Default intensity should be medium")
        XCTAssertFalse(song.id.uuidString.isEmpty,
            "Song should have a valid UUID")
    }

    func testCreateSetlistSong_withDefaultBPM() {
        let song = SetlistSong(title: "Trust In God", key: .E)

        XCTAssertEqual(song.title, "Trust In God")
        XCTAssertEqual(song.key, .E)
        XCTAssertNil(song.bpm,
            "BPM should be nil when not provided")
    }

    func testCreateSetlistSong_defaultKeyIsG() {
        let song = SetlistSong(title: "Default Song")

        XCTAssertEqual(song.key, .G,
            "Default key should be G as defined in the model")
    }

    func testSetlistSong_uniqueIDs() {
        let song1 = SetlistSong(title: "Song A", key: .C)
        let song2 = SetlistSong(title: "Song B", key: .D)

        XCTAssertNotEqual(song1.id, song2.id,
            "Each song should have a unique UUID")
    }


    // MARK: - ─── InputChannel Creation ──────────────────────────────────

    func testCreateInputChannel_withLabel() {
        let channel = InputChannel(label: "Sarah", source: .leadVocal)

        XCTAssertEqual(channel.label, "Sarah")
        XCTAssertEqual(channel.source, .leadVocal)
        XCTAssertTrue(channel.isActive,
            "Channels should default to active")
        XCTAssertNil(channel.vocalProfile,
            "Non-vocal-profiled channel should have nil vocalProfile")
    }

    func testCreateInputChannel_emptyLabel_usesSourceName() {
        let channel = InputChannel(label: "", source: .electricGtrModeler)

        XCTAssertEqual(channel.label, InputSource.electricGtrModeler.localizedName,
            "Empty label should fall back to source localized name")
        XCTAssertEqual(channel.source, .electricGtrModeler)
    }

    func testCreateInputChannel_withVocalProfile() {
        let profile = VocalProfile(
            range: .soprano,
            style: .contemporary,
            micType: .dynamicCardioid
        )
        let channel = InputChannel(
            label: "Lead Vocal",
            source: .leadVocal,
            vocalProfile: profile
        )

        XCTAssertNotNil(channel.vocalProfile)
        XCTAssertEqual(channel.vocalProfile?.range, .soprano)
        XCTAssertEqual(channel.vocalProfile?.style, .contemporary)
        XCTAssertEqual(channel.vocalProfile?.micType, .dynamicCardioid)
    }

    func testCreateInputChannel_forDISource() {
        let channel = InputChannel(label: "Keys L", source: .digitalPiano)

        XCTAssertEqual(channel.label, "Keys L")
        XCTAssertEqual(channel.source, .digitalPiano)
        XCTAssertTrue(channel.source.isLineLevel,
            "Digital piano should be a line-level source")
    }

    func testCreateInputChannel_forDrumSource() {
        let channel = InputChannel(label: "Kick", source: .kickDrum)

        XCTAssertEqual(channel.source, .kickDrum)
        XCTAssertFalse(channel.source.isLineLevel,
            "Kick drum is a mic-level source")
        XCTAssertEqual(channel.source.category, .drums)
    }

    func testCreateInputChannel_uniqueIDs() {
        let ch1 = InputChannel(label: "Ch1", source: .leadVocal)
        let ch2 = InputChannel(label: "Ch2", source: .leadVocal)

        XCTAssertNotEqual(ch1.id, ch2.id,
            "Each channel should have a unique UUID")
    }


    // MARK: - ─── PCO to Domain Mapping Sanity ───────────────────────────

    func testSourceCategoryMapping_vocals() {
        XCTAssertEqual(InputSource.leadVocal.category, .vocals)
        XCTAssertEqual(InputSource.backingVocal.category, .vocals)
    }

    func testSourceCategoryMapping_instruments() {
        XCTAssertEqual(InputSource.electricGtrModeler.category, .guitars)
        XCTAssertEqual(InputSource.acousticGtrDI.category, .guitars)
        XCTAssertEqual(InputSource.bassGtrDI.category, .guitars)
        XCTAssertEqual(InputSource.digitalPiano.category, .keys)
        XCTAssertEqual(InputSource.kickDrum.category, .drums)
    }

    func testSourceCategoryMapping_playback() {
        XCTAssertEqual(InputSource.tracksLeft.category, .playback)
    }

    func testSourceLineLevel_diSources() {
        XCTAssertTrue(InputSource.digitalPiano.isLineLevel)
        XCTAssertTrue(InputSource.electricGtrModeler.isLineLevel)
        XCTAssertTrue(InputSource.bassGtrDI.isLineLevel)
        XCTAssertTrue(InputSource.acousticGtrDI.isLineLevel)
        XCTAssertTrue(InputSource.tracksLeft.isLineLevel)
    }

    func testSourceLineLevel_micSources() {
        XCTAssertFalse(InputSource.leadVocal.isLineLevel)
        XCTAssertFalse(InputSource.backingVocal.isLineLevel)
        XCTAssertFalse(InputSource.kickDrum.isLineLevel)
    }
}


// MARK: - ─── PCO Tokens Tests ────────────────────────────────────────────

final class PCOTokensTests: XCTestCase {

    func testPCOTokensEncodeDecode() throws {
        let original = PCOTokens(
            accessToken: "test-access-token-abc123",
            refreshToken: "test-refresh-token-xyz789",
            expiresAt: Date(timeIntervalSince1970: 1800000000),
            scope: "services"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PCOTokens.self, from: data)

        XCTAssertEqual(decoded.accessToken, "test-access-token-abc123")
        XCTAssertEqual(decoded.refreshToken, "test-refresh-token-xyz789")
        XCTAssertEqual(decoded.expiresAt, Date(timeIntervalSince1970: 1800000000))
        XCTAssertEqual(decoded.scope, "services")
    }
}
