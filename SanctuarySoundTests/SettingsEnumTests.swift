// ============================================================================
// SettingsEnumTests.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Unit Tests
// Purpose: Verify pickerDisplayName properties on all Settings picker enums are
//          non-empty and within the 16-character limit for compact display.
// ============================================================================

import XCTest
@testable import SanctuarySound


final class SettingsEnumTests: XCTestCase {

    // MARK: - ─── MixerModel ──────────────────────────────────────────────────

    func testMixerModelPickerDisplayNameNotEmpty() {
        for mixer in MixerModel.allCases {
            XCTAssertFalse(mixer.pickerDisplayName.isEmpty, "\(mixer) should have a non-empty pickerDisplayName")
        }
    }

    func testMixerModelPickerDisplayNameMaxLength() {
        for mixer in MixerModel.allCases {
            XCTAssertLessThanOrEqual(
                mixer.pickerDisplayName.count, 16,
                "\(mixer).pickerDisplayName '\(mixer.pickerDisplayName)' exceeds 16 chars"
            )
        }
    }


    // MARK: - ─── BandComposition ─────────────────────────────────────────────

    func testBandCompositionPickerDisplayNameNotEmpty() {
        for band in BandComposition.allCases {
            XCTAssertFalse(band.pickerDisplayName.isEmpty, "\(band) should have a non-empty pickerDisplayName")
        }
    }

    func testBandCompositionPickerDisplayNameMaxLength() {
        for band in BandComposition.allCases {
            XCTAssertLessThanOrEqual(
                band.pickerDisplayName.count, 16,
                "\(band).pickerDisplayName '\(band.pickerDisplayName)' exceeds 16 chars"
            )
        }
    }


    // MARK: - ─── DrumConfiguration ───────────────────────────────────────────

    func testDrumConfigPickerDisplayNameNotEmpty() {
        for config in DrumConfiguration.allCases {
            XCTAssertFalse(config.pickerDisplayName.isEmpty, "\(config) should have a non-empty pickerDisplayName")
        }
    }

    func testDrumConfigPickerDisplayNameMaxLength() {
        for config in DrumConfiguration.allCases {
            XCTAssertLessThanOrEqual(
                config.pickerDisplayName.count, 16,
                "\(config).pickerDisplayName '\(config.pickerDisplayName)' exceeds 16 chars"
            )
        }
    }


    // MARK: - ─── RoomSize ────────────────────────────────────────────────────

    func testRoomSizePickerDisplayNameNotEmpty() {
        for size in RoomSize.allCases {
            XCTAssertFalse(size.pickerDisplayName.isEmpty, "\(size) should have a non-empty pickerDisplayName")
        }
    }

    func testRoomSizePickerDisplayNameMaxLength() {
        for size in RoomSize.allCases {
            XCTAssertLessThanOrEqual(
                size.pickerDisplayName.count, 16,
                "\(size).pickerDisplayName '\(size.pickerDisplayName)' exceeds 16 chars"
            )
        }
    }


    // MARK: - ─── RoomSurface ─────────────────────────────────────────────────

    func testRoomSurfacePickerDisplayNameNotEmpty() {
        for surface in RoomSurface.allCases {
            XCTAssertFalse(surface.pickerDisplayName.isEmpty, "\(surface) should have a non-empty pickerDisplayName")
        }
    }

    func testRoomSurfacePickerDisplayNameMaxLength() {
        for surface in RoomSurface.allCases {
            XCTAssertLessThanOrEqual(
                surface.pickerDisplayName.count, 16,
                "\(surface).pickerDisplayName '\(surface.pickerDisplayName)' exceeds 16 chars"
            )
        }
    }


    // MARK: - ─── DetailLevel ─────────────────────────────────────────────────

    func testDetailLevelShortNameNotEmpty() {
        for level in DetailLevel.allCases {
            XCTAssertFalse(level.shortName.isEmpty, "\(level) should have a non-empty shortName")
        }
    }

    func testDetailLevelShortNameMaxLength() {
        for level in DetailLevel.allCases {
            XCTAssertLessThanOrEqual(
                level.shortName.count, 16,
                "\(level).shortName '\(level.shortName)' exceeds 16 chars"
            )
        }
    }
}
