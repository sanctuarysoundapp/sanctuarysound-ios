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
                        "key_name": "G",
                        "arrangement_name": "Default Arrangement",
                        "arrangement_sequence": "V1,C,V2,C,B,C"
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
                        "key_name": null,
                        "arrangement_name": null,
                        "arrangement_sequence": null
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
        XCTAssertEqual(song.attributes.keyName, "G")
        XCTAssertEqual(song.attributes.arrangementName, "Default Arrangement")
        XCTAssertEqual(song.attributes.arrangementSequence, "V1,C,V2,C,B,C")

        let header = response.data[1]
        XCTAssertEqual(header.attributes.itemType, "header")
        XCTAssertNil(header.attributes.length)
        XCTAssertNil(header.attributes.songId)
        XCTAssertNil(header.attributes.keyName)
        XCTAssertNil(header.attributes.arrangementName)
        XCTAssertNil(header.attributes.arrangementSequence)
    }


    func testDecodePlanItemsResponse_withMissingOptionalFields() throws {
        // Verifies backward compatibility when new fields are absent from the response
        let json = """
        {
            "data": [
                {
                    "id": "9003",
                    "type": "Item",
                    "attributes": {
                        "title": "Trust In God",
                        "item_type": "song",
                        "length": 240,
                        "description": null,
                        "song_id": "7003"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOPlanItemAttributes>.self, from: json)
        let item = response.data[0]

        XCTAssertEqual(item.attributes.title, "Trust In God")
        XCTAssertEqual(item.attributes.songId, "7003")
        XCTAssertNil(item.attributes.keyName,
            "key_name should be nil when absent from JSON")
        XCTAssertNil(item.attributes.arrangementName,
            "arrangement_name should be nil when absent from JSON")
        XCTAssertNil(item.attributes.arrangementSequence,
            "arrangement_sequence should be nil when absent from JSON")
    }

    func testDecodeArrangementWithKeyName() throws {
        let json = """
        {
            "data": [
                {
                    "id": "8010",
                    "type": "Arrangement",
                    "attributes": {
                        "name": "Worship Version",
                        "bpm": 78.0,
                        "length": 300,
                        "meter_numerator": 4,
                        "meter_denominator": 4,
                        "key_name": "Ab"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOArrangementAttributes>.self, from: json)
        let arrangement = response.data[0]

        XCTAssertEqual(arrangement.attributes.keyName, "Ab")
        XCTAssertEqual(arrangement.attributes.bpm, 78.0)
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
                        "meter_denominator": 4,
                        "key_name": "G"
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
                        "meter_denominator": 4,
                        "key_name": "A"
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
        XCTAssertEqual(first.attributes.keyName, "G")

        let second = response.data[1]
        XCTAssertEqual(second.attributes.bpm, 72.5)
        XCTAssertEqual(second.attributes.meterNumerator, 3)
        XCTAssertEqual(second.attributes.keyName, "A")
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
                        "meter_denominator": null,
                        "key_name": null
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
        XCTAssertNil(arrangement.attributes.keyName)
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

    func testMapPosition_percussion_returnsKickDrum() {
        XCTAssertEqual(manager.mapPositionToSource("Percussion"), .kickDrum)
    }

    func testMapPosition_cajon_returnsKickDrum() {
        XCTAssertEqual(manager.mapPositionToSource("Cajon"), .kickDrum)
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

    func testMapPosition_instrumentsCheckedBeforeGenericVocal() {
        // Instruments should be matched before generic "vocal" keyword catch-all
        XCTAssertEqual(manager.mapPositionToSource("Drums"), .kickDrum,
            "Drums should map to kickDrum, not fall through to backing vocal")
        XCTAssertEqual(manager.mapPositionToSource("Bass"), .bassGtrDI,
            "Bass should map to bassGtrDI, not fall through to backing vocal")
        XCTAssertEqual(manager.mapPositionToSource("Keys"), .digitalPiano,
            "Keys should map to digitalPiano, not fall through to backing vocal")
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


// MARK: - ─── Folder Decoding Tests ──────────────────────────────────────

final class PCOFolderDecodingTests: XCTestCase {

    private let decoder = JSONDecoder()

    func testDecodeFolderResponse() throws {
        let json = """
        {
            "data": [
                {
                    "id": "F001",
                    "type": "Folder",
                    "attributes": {
                        "name": "Pell City",
                        "container": "Organization",
                        "created_at": "2024-01-01T00:00:00Z",
                        "updated_at": "2026-02-01T12:00:00Z"
                    }
                },
                {
                    "id": "F002",
                    "type": "Folder",
                    "attributes": {
                        "name": "Lincoln",
                        "container": null,
                        "created_at": null,
                        "updated_at": null
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOFolderAttributes>.self, from: json)

        XCTAssertEqual(response.data.count, 2)

        let first = response.data[0]
        XCTAssertEqual(first.id, "F001")
        XCTAssertEqual(first.type, "Folder")
        XCTAssertEqual(first.attributes.name, "Pell City")
        XCTAssertEqual(first.attributes.container, "Organization")
        XCTAssertEqual(first.attributes.createdAt, "2024-01-01T00:00:00Z")

        let second = response.data[1]
        XCTAssertEqual(second.id, "F002")
        XCTAssertEqual(second.attributes.name, "Lincoln")
        XCTAssertNil(second.attributes.container)
        XCTAssertNil(second.attributes.createdAt)
    }

    func testDecodeFolderWithMinimalAttributes() throws {
        let json = """
        {
            "data": [
                {
                    "id": "F010",
                    "type": "Folder",
                    "attributes": {
                        "name": "Central Services"
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOFolderAttributes>.self, from: json)
        let folder = response.data[0]

        XCTAssertEqual(folder.attributes.name, "Central Services")
        XCTAssertNil(folder.attributes.container)
        XCTAssertNil(folder.attributes.createdAt)
        XCTAssertNil(folder.attributes.updatedAt)
    }

    func testDecodeEmptyFolderList() throws {
        let json = """
        {
            "data": []
        }
        """.data(using: .utf8)!

        let response = try decoder.decode(PCOResponse<PCOFolderAttributes>.self, from: json)
        XCTAssertTrue(response.data.isEmpty)
    }
}


// MARK: - ─── PCO Folder Item Tests ──────────────────────────────────────

final class PCOFolderItemTests: XCTestCase {

    func testFolderItemFolder_id() {
        let resource = PCOResource<PCOFolderAttributes>(
            id: "F100",
            type: "Folder",
            attributes: PCOFolderAttributes(
                name: "Test Campus",
                container: nil,
                createdAt: nil,
                updatedAt: nil
            )
        )
        let item = PCOFolderItem.folder(resource)

        XCTAssertEqual(item.id, "folder-F100")
    }

    func testFolderItemServiceType_id() {
        let resource = PCOResource<PCOServiceTypeAttributes>(
            id: "ST200",
            type: "ServiceType",
            attributes: PCOServiceTypeAttributes(
                name: "Sunday AM",
                frequency: "Weekly",
                lastPlanFrom: nil
            )
        )
        let item = PCOFolderItem.serviceType(resource)

        XCTAssertEqual(item.id, "stype-ST200")
    }

    func testFolderItemFolder_name() {
        let resource = PCOResource<PCOFolderAttributes>(
            id: "F101",
            type: "Folder",
            attributes: PCOFolderAttributes(
                name: "Pell City",
                container: nil,
                createdAt: nil,
                updatedAt: nil
            )
        )
        let item = PCOFolderItem.folder(resource)

        XCTAssertEqual(item.name, "Pell City")
    }

    func testFolderItemServiceType_name() {
        let resource = PCOResource<PCOServiceTypeAttributes>(
            id: "ST201",
            type: "ServiceType",
            attributes: PCOServiceTypeAttributes(
                name: "[PC] Sunday",
                frequency: nil,
                lastPlanFrom: nil
            )
        )
        let item = PCOFolderItem.serviceType(resource)

        XCTAssertEqual(item.name, "[PC] Sunday")
    }
}


// MARK: - ─── Venue Matching from Breadcrumbs Tests ──────────────────────

@MainActor
final class PCOVenueMatchingTests: XCTestCase {

    private var manager: PlanningCenterManager!

    override func setUp() {
        super.setUp()
        manager = PlanningCenterManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testMatchVenue_exactMatch() {
        manager.folderBreadcrumbs = [(id: "F1", name: "Pell City")]
        let venues = [Venue(name: "Pell City")]

        let match = manager.matchVenueFromBreadcrumbs(venues: venues)

        XCTAssertEqual(match, venues[0].id)
    }

    func testMatchVenue_caseInsensitive() {
        manager.folderBreadcrumbs = [(id: "F1", name: "PELL CITY")]
        let venues = [Venue(name: "pell city")]

        let match = manager.matchVenueFromBreadcrumbs(venues: venues)

        XCTAssertEqual(match, venues[0].id)
    }

    func testMatchVenue_trailingWhitespace() {
        manager.folderBreadcrumbs = [(id: "F1", name: "Pell City  ")]
        let venues = [Venue(name: " Pell City")]

        let match = manager.matchVenueFromBreadcrumbs(venues: venues)

        XCTAssertEqual(match, venues[0].id)
    }

    func testMatchVenue_noMatch() {
        manager.folderBreadcrumbs = [(id: "F1", name: "Talladega")]
        let venues = [Venue(name: "Pell City")]

        let match = manager.matchVenueFromBreadcrumbs(venues: venues)

        XCTAssertNil(match)
    }

    func testMatchVenue_emptyBreadcrumbs() {
        manager.folderBreadcrumbs = []
        let venues = [Venue(name: "Pell City")]

        let match = manager.matchVenueFromBreadcrumbs(venues: venues)

        XCTAssertNil(match)
    }

    func testMatchVenue_emptyVenues() {
        manager.folderBreadcrumbs = [(id: "F1", name: "Pell City")]

        let match = manager.matchVenueFromBreadcrumbs(venues: [])

        XCTAssertNil(match)
    }

    func testMatchVenue_matchesFirstBreadcrumb() {
        // If multiple breadcrumbs could match, first takes priority
        let venue1 = Venue(name: "Pell City")
        let venue2 = Venue(name: "Central Services")
        manager.folderBreadcrumbs = [
            (id: "F1", name: "Pell City"),
            (id: "F2", name: "Central Services"),
        ]

        let match = manager.matchVenueFromBreadcrumbs(venues: [venue1, venue2])

        XCTAssertEqual(match, venue1.id)
    }

    func testMatchVenue_nestedFolderMatches() {
        // When root folder doesn't match but subfolder does
        let venue = Venue(name: "Central Services")
        manager.folderBreadcrumbs = [
            (id: "F1", name: "Victory Church"),
            (id: "F2", name: "Central Services"),
        ]

        let match = manager.matchVenueFromBreadcrumbs(venues: [venue])

        XCTAssertEqual(match, venue.id)
    }
}


// MARK: - ─── Position Classification Tests ──────────────────────────────

@MainActor
final class PCOPositionClassificationTests: XCTestCase {

    private var manager: PlanningCenterManager!

    override func setUp() {
        super.setUp()
        manager = PlanningCenterManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }


    // MARK: - ─── Production Positions ────────────────────────────────────

    func testClassify_FOHSound_isProduction() {
        XCTAssertEqual(manager.classifyPosition("FOH Sound"), .production)
    }

    func testClassify_Lights_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Lights"), .production)
    }

    func testClassify_Lyrics_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Lyrics"), .production)
    }

    func testClassify_Director_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Director"), .production)
    }

    func testClassify_Producer_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Producer"), .production)
    }

    func testClassify_Photography_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Photography"), .production)
    }

    func testClassify_CameraOperator_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Camera Operator"), .production)
    }

    func testClassify_Streaming_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Streaming"), .production)
    }

    func testClassify_SoundEngineer_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Sound Engineer"), .production)
    }

    func testClassify_StageManager_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Stage Manager"), .production)
    }

    func testClassify_Usher_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Usher"), .production)
    }

    func testClassify_KidsMinistry_isProduction() {
        XCTAssertEqual(manager.classifyPosition("Kids"), .production)
    }


    // MARK: - ─── Audio Positions ─────────────────────────────────────────

    func testClassify_VOX1_isAudio() {
        XCTAssertEqual(manager.classifyPosition("VOX 1"), .audio)
    }

    func testClassify_ElectricGuitar_isAudio() {
        XCTAssertEqual(manager.classifyPosition("Electric Guitar"), .audio)
    }

    func testClassify_Keys_isAudio() {
        XCTAssertEqual(manager.classifyPosition("Keys"), .audio)
    }

    func testClassify_Bass_isAudio() {
        XCTAssertEqual(manager.classifyPosition("Bass"), .audio)
    }

    func testClassify_WorshipLeader_isAudio() {
        XCTAssertEqual(manager.classifyPosition("Worship Leader"), .audio)
    }


    // MARK: - ─── Drum Positions ──────────────────────────────────────────

    func testClassify_Drums_isDrums() {
        XCTAssertEqual(manager.classifyPosition("Drums"), .drums)
    }

    func testClassify_Percussion_isDrums() {
        XCTAssertEqual(manager.classifyPosition("Percussion"), .drums)
    }

    func testClassify_Cajon_isDrums() {
        XCTAssertEqual(manager.classifyPosition("Cajon"), .drums)
    }

    func testClassify_Drummer_isDrums() {
        XCTAssertEqual(manager.classifyPosition("Drummer"), .drums)
    }


    // MARK: - ─── Edge Cases ──────────────────────────────────────────────

    func testClassify_emptyString_isUnknown() {
        XCTAssertEqual(manager.classifyPosition(""), .unknown)
    }

    func testClassify_caseInsensitive() {
        XCTAssertEqual(manager.classifyPosition("FOH SOUND"), .production)
        XCTAssertEqual(manager.classifyPosition("foh sound"), .production)
        XCTAssertEqual(manager.classifyPosition("Foh Sound"), .production)
    }
}


// MARK: - ─── Abbreviation Expansion Tests ───────────────────────────────

@MainActor
final class PCOAbbreviationTests: XCTestCase {

    private var manager: PlanningCenterManager!

    override func setUp() {
        super.setUp()
        manager = PlanningCenterManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testExpand_EG_toElectricGuitar() {
        XCTAssertEqual(manager.expandAbbreviations("EG"), "electric guitar")
    }

    func testExpand_AG_toAcousticGuitar() {
        XCTAssertEqual(manager.expandAbbreviations("AG"), "acoustic guitar")
    }

    func testExpand_BGV_toBackingVocal() {
        XCTAssertEqual(manager.expandAbbreviations("BGV"), "backing vocal")
    }

    func testExpand_MD_toWorshipLeader() {
        XCTAssertEqual(manager.expandAbbreviations("MD"), "worship leader")
    }

    func testExpand_EGLead_prefix() {
        XCTAssertEqual(manager.expandAbbreviations("EG Lead"), "electric guitar Lead")
    }

    func testExpand_VOX_toVocal() {
        XCTAssertEqual(manager.expandAbbreviations("VOX"), "vocal")
    }

    func testExpand_VOX1_prefix() {
        XCTAssertEqual(manager.expandAbbreviations("VOX 1"), "vocal 1")
    }

    func testExpand_unknownReturnsOriginal() {
        XCTAssertEqual(manager.expandAbbreviations("Bass"), "Bass")
    }

    func testExpand_caseInsensitive() {
        XCTAssertEqual(manager.expandAbbreviations("eg"), "electric guitar")
        XCTAssertEqual(manager.expandAbbreviations("Eg"), "electric guitar")
    }
}


// MARK: - ─── Abbreviation → Position Mapping Tests ──────────────────────

@MainActor
final class PCOAbbreviationMappingTests: XCTestCase {

    private var manager: PlanningCenterManager!

    override func setUp() {
        super.setUp()
        manager = PlanningCenterManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testMap_EG_toElectricGtr() {
        XCTAssertEqual(manager.mapPositionToSource("EG"), .electricGtrModeler)
    }

    func testMap_EGLead_toElectricGtr() {
        XCTAssertEqual(manager.mapPositionToSource("EG Lead"), .electricGtrModeler)
    }

    func testMap_EGRhythm_toElectricGtr() {
        XCTAssertEqual(manager.mapPositionToSource("EG Rhythm"), .electricGtrModeler)
    }

    func testMap_AG_toAcousticGtr() {
        XCTAssertEqual(manager.mapPositionToSource("AG"), .acousticGtrDI)
    }

    func testMap_VOX1_toBackingVocal() {
        XCTAssertEqual(manager.mapPositionToSource("VOX 1"), .backingVocal)
    }

    func testMap_MD_toLeadVocal() {
        XCTAssertEqual(manager.mapPositionToSource("MD"), .leadVocal)
    }
}


// MARK: - ─── Drum Kit Template Tests ────────────────────────────────────

final class DrumKitTemplateTests: XCTestCase {

    func testBasic3_hasThreeChannels() {
        XCTAssertEqual(DrumKitTemplate.basic3.channels.count, 3)
    }

    func testStandard5_hasFiveChannels() {
        XCTAssertEqual(DrumKitTemplate.standard5.channels.count, 5)
    }

    func testFull7_hasSevenChannels() {
        XCTAssertEqual(DrumKitTemplate.full7.channels.count, 7)
    }

    func testAllDrumSources_count() {
        XCTAssertEqual(DrumKitTemplate.allDrumSources.count, 9)
    }

    func testBasic3_containsKickSnareOverhead() {
        let sources = DrumKitTemplate.basic3.channels.map(\.source)
        XCTAssertTrue(sources.contains(.kickDrum))
        XCTAssertTrue(sources.contains(.snareDrum))
        XCTAssertTrue(sources.contains(.overheadL))
    }

    func testStandard5_containsKickSnareHiHatOverheads() {
        let sources = DrumKitTemplate.standard5.channels.map(\.source)
        XCTAssertTrue(sources.contains(.kickDrum))
        XCTAssertTrue(sources.contains(.snareDrum))
        XCTAssertTrue(sources.contains(.hiHat))
    }

    func testCustom_returnsStandard5AsDefault() {
        // Custom template returns standard5 channels as a starting point
        XCTAssertEqual(DrumKitTemplate.custom.channels.count,
                       DrumKitTemplate.standard5.channels.count)
    }

    func testTemplate_codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for template in DrumKitTemplate.allCases {
            let data = try encoder.encode(template)
            let decoded = try decoder.decode(DrumKitTemplate.self, from: data)
            XCTAssertEqual(decoded, template, "Codable roundtrip failed for \(template)")
        }
    }
}


// MARK: - ─── Drum Expansion Tests ───────────────────────────────────────

@MainActor
final class PCODrumExpansionTests: XCTestCase {

    private var manager: PlanningCenterManager!

    override func setUp() {
        super.setUp()
        manager = PlanningCenterManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testExpandDrums_basic3_returns3Items() {
        let items = manager.expandDrumPosition(
            personName: "Alex",
            positionName: "Drums",
            template: .basic3
        )
        XCTAssertEqual(items.count, 3)
    }

    func testExpandDrums_standard5_returns5Items() {
        let items = manager.expandDrumPosition(
            personName: "Alex",
            positionName: "Drums",
            template: .standard5
        )
        XCTAssertEqual(items.count, 5)
    }

    func testExpandDrums_full7_returns7Items() {
        let items = manager.expandDrumPosition(
            personName: "Alex",
            positionName: "Drums",
            template: .full7
        )
        XCTAssertEqual(items.count, 7)
    }

    func testExpandDrums_allItemsAreDrumsCategory() {
        let items = manager.expandDrumPosition(
            personName: "Alex",
            positionName: "Drums",
            template: .standard5
        )
        for item in items {
            XCTAssertEqual(item.positionCategory, .drums)
        }
    }

    func testExpandDrums_allItemsIncluded() {
        let items = manager.expandDrumPosition(
            personName: "Alex",
            positionName: "Drums",
            template: .standard5
        )
        for item in items {
            XCTAssertTrue(item.isIncluded)
        }
    }

    func testExpandDrums_preservesPersonName() {
        let items = manager.expandDrumPosition(
            personName: "Alex Rivera",
            positionName: "Drums",
            template: .basic3
        )
        for item in items {
            XCTAssertEqual(item.personName, "Alex Rivera")
        }
    }

    func testExpandDrums_labelsMatchTemplate() {
        let items = manager.expandDrumPosition(
            personName: "Alex",
            positionName: "Drums",
            template: .basic3
        )
        let labels = items.map(\.channelLabel)
        let templateLabels = DrumKitTemplate.basic3.channels.map(\.label)
        XCTAssertEqual(labels, templateLabels)
    }
}


// MARK: - ─── Process Team Members Tests ─────────────────────────────────

@MainActor
final class PCOProcessTeamMembersTests: XCTestCase {

    private var manager: PlanningCenterManager!

    override func setUp() {
        super.setUp()
        manager = PlanningCenterManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testProcessTeam_usesPositionNameAsLabel() {
        let members: [PCOTeamMemberAttributes] = [
            PCOTeamMemberAttributes(name: "Sarah Johnson", status: "C", teamPositionName: "VOX 1"),
        ]

        let items = manager.processTeamMembers(members)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].channelLabel, "VOX 1")
        XCTAssertEqual(items[0].personName, "Sarah Johnson")
    }

    func testProcessTeam_filtersDeclinedMembers() {
        let members: [PCOTeamMemberAttributes] = [
            PCOTeamMemberAttributes(name: "Alice", status: "C", teamPositionName: "VOX 1"),
            PCOTeamMemberAttributes(name: "Bob", status: "D", teamPositionName: "VOX 2"),
        ]

        let items = manager.processTeamMembers(members)

        // Only confirmed (C) member should be included
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].personName, "Alice")
    }

    func testProcessTeam_includesUnconfirmed() {
        let members: [PCOTeamMemberAttributes] = [
            PCOTeamMemberAttributes(name: "Marcus", status: "U", teamPositionName: "Bass"),
        ]

        let items = manager.processTeamMembers(members)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].personName, "Marcus")
    }

    func testProcessTeam_productionExcludedByDefault() {
        let members: [PCOTeamMemberAttributes] = [
            PCOTeamMemberAttributes(name: "Tech Person", status: "C", teamPositionName: "FOH Sound"),
        ]

        let items = manager.processTeamMembers(members)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].positionCategory, .production)
        XCTAssertFalse(items[0].isIncluded)
    }

    func testProcessTeam_audioIncludedByDefault() {
        let members: [PCOTeamMemberAttributes] = [
            PCOTeamMemberAttributes(name: "Guitarist", status: "C", teamPositionName: "Electric Guitar"),
        ]

        let items = manager.processTeamMembers(members)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].positionCategory, .audio)
        XCTAssertTrue(items[0].isIncluded)
    }

    func testProcessTeam_drumsExpanded() {
        let members: [PCOTeamMemberAttributes] = [
            PCOTeamMemberAttributes(name: "Alex", status: "C", teamPositionName: "Drums"),
        ]

        let items = manager.processTeamMembers(members, drumTemplate: .basic3)

        XCTAssertEqual(items.count, 3, "Drums should expand to 3 channels with basic3 template")
        for item in items {
            XCTAssertEqual(item.positionCategory, .drums)
        }
    }

    func testProcessTeam_mixedTeam() {
        let members: [PCOTeamMemberAttributes] = [
            PCOTeamMemberAttributes(name: "Sarah", status: "C", teamPositionName: "Worship Leader"),
            PCOTeamMemberAttributes(name: "Bob", status: "C", teamPositionName: "Electric Guitar"),
            PCOTeamMemberAttributes(name: "Alex", status: "C", teamPositionName: "Drums"),
            PCOTeamMemberAttributes(name: "Tech", status: "C", teamPositionName: "Lights"),
            PCOTeamMemberAttributes(name: "Skip", status: "D", teamPositionName: "Bass"),
        ]

        let items = manager.processTeamMembers(members, drumTemplate: .basic3)

        // Sarah (audio) + Bob (audio) + Alex (3 drum channels) + Tech (production) = 6
        // Skip is declined, excluded
        XCTAssertEqual(items.count, 6)

        let audioItems = items.filter { $0.positionCategory == .audio }
        let drumItems = items.filter { $0.positionCategory == .drums }
        let prodItems = items.filter { $0.positionCategory == .production }

        XCTAssertEqual(audioItems.count, 2)
        XCTAssertEqual(drumItems.count, 3)
        XCTAssertEqual(prodItems.count, 1)
    }
}


// MARK: - ─── PCO Team Import Item Tests ─────────────────────────────────

final class PCOTeamImportItemTests: XCTestCase {

    func testItem_defaultIsIncluded() {
        let item = PCOTeamImportItem(
            personName: "Test",
            positionName: "Bass",
            positionCategory: .audio,
            channelLabel: "Bass",
            source: .bassGtrDI,
            isIncluded: true
        )
        XCTAssertTrue(item.isIncluded)
    }

    func testItem_uniqueIDs() {
        let item1 = PCOTeamImportItem(
            personName: "A",
            positionName: "VOX 1",
            positionCategory: .audio,
            channelLabel: "VOX 1",
            source: .backingVocal,
            isIncluded: true
        )
        let item2 = PCOTeamImportItem(
            personName: "B",
            positionName: "VOX 2",
            positionCategory: .audio,
            channelLabel: "VOX 2",
            source: .backingVocal,
            isIncluded: true
        )
        XCTAssertNotEqual(item1.id, item2.id)
    }

    func testItem_equatable() {
        let item = PCOTeamImportItem(
            personName: "Test",
            positionName: "Keys",
            positionCategory: .audio,
            channelLabel: "Keys",
            source: .digitalPiano,
            isIncluded: true
        )
        // Same item should equal itself
        XCTAssertEqual(item, item)
    }
}


// MARK: - ─── Date Parsing Tests ─────────────────────────────────────────

@MainActor
final class PCODateParsingTests: XCTestCase {

    private var manager: PlanningCenterManager!

    override func setUp() {
        super.setUp()
        manager = PlanningCenterManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testParsePlanDate_validISO8601() {
        let date = manager.parsePlanDate("2026-02-09T09:30:00Z")

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 9)
    }

    func testParsePlanDate_withFractionalSeconds() {
        let date = manager.parsePlanDate("2026-02-09T09:30:00.123Z")

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 2)
    }

    func testParsePlanDate_dateOnly() {
        let date = manager.parsePlanDate("2026-02-15")

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 15)
    }

    func testParsePlanDate_nilInput_returnsCurrent() {
        let before = Date()
        let date = manager.parsePlanDate(nil)
        let after = Date()

        XCTAssertTrue(date >= before && date <= after,
            "Nil input should return approximately current date")
    }

    func testParsePlanDate_emptyString_returnsCurrent() {
        let before = Date()
        let date = manager.parsePlanDate("")
        let after = Date()

        XCTAssertTrue(date >= before && date <= after,
            "Empty string should return approximately current date")
    }

    func testParsePlanDate_invalidString_returnsCurrent() {
        let before = Date()
        let date = manager.parsePlanDate("not-a-date")
        let after = Date()

        XCTAssertTrue(date >= before && date <= after,
            "Invalid string should return approximately current date")
    }

    func testParsePlanDate_withTimezone() {
        let date = manager.parsePlanDate("2026-06-15T14:00:00-05:00")

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 19) // 14:00 CDT = 19:00 UTC
    }
}


// MARK: - ─── User Preferences Backward Compat Tests ─────────────────────

final class PCOUserPreferencesTests: XCTestCase {

    func testUserPreferences_defaultDrumTemplate() {
        let prefs = UserPreferences()
        XCTAssertEqual(prefs.preferredDrumTemplate, .standard5)
    }

    func testUserPreferences_decodeWithoutDrumTemplate() throws {
        // JSON from before preferredDrumTemplate was added
        let json = """
        {
            "defaultMixer": "Allen & Heath Avantis",
            "defaultExperienceLevel": "Intermediate",
            "defaultBandComposition": "Full Live Band",
            "defaultDrumConfig": "Open Stage (No Isolation)",
            "defaultRoomSize": "Medium (300–800 seats)",
            "defaultRoomSurface": "Mixed (Typical Sanctuary)",
            "defaultTargetSPL": 90.0,
            "colorTheme": "Dark Booth"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let prefs = try decoder.decode(UserPreferences.self, from: json)

        XCTAssertEqual(prefs.preferredDrumTemplate, .standard5,
            "Missing preferredDrumTemplate should default to standard5")
        XCTAssertEqual(prefs.defaultTargetSPL, 90.0)
        XCTAssertEqual(prefs.colorTheme, .darkBooth)
    }

    func testUserPreferences_encodeDecodeWithDrumTemplate() throws {
        var prefs = UserPreferences()
        prefs.preferredDrumTemplate = .full7

        let encoder = JSONEncoder()
        let data = try encoder.encode(prefs)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserPreferences.self, from: data)

        XCTAssertEqual(decoded.preferredDrumTemplate, .full7)
    }
}


// MARK: - ─── PCO Position Category Tests ────────────────────────────────

final class PCOPositionCategoryTests: XCTestCase {

    func testPositionCategory_allCases() {
        let allCases = PCOPositionCategory.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.audio))
        XCTAssertTrue(allCases.contains(.production))
        XCTAssertTrue(allCases.contains(.drums))
        XCTAssertTrue(allCases.contains(.unknown))
    }

    func testPositionCategory_codableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for category in PCOPositionCategory.allCases {
            let data = try encoder.encode(category)
            let decoded = try decoder.decode(PCOPositionCategory.self, from: data)
            XCTAssertEqual(decoded, category)
        }
    }
}
