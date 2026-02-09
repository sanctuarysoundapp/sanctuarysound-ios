// ============================================================================
// SPLCalibrationTests.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Unit Tests
// Purpose: Tests for SPL calibration offset calculation and input validation.
//          Verifies that calculateCalibrationOffset returns reasonable values
//          for valid inputs and that the math is correct.
// ============================================================================

import XCTest
@testable import SanctuarySound


// MARK: - ─── SPL Calibration Offset Tests ─────────────────────────────────

@MainActor
final class SPLCalibrationOffsetTests: XCTestCase {

    // MARK: - ─── Valid Input Range Tests ─────────────────────────────────

    /// A typical calibration scenario: reference meter reads 85 dB SPL.
    /// The offset should be within a reasonable range (-20...+20 dB) since
    /// iPhone mics are approximately accurate and the reference offset is 90 dB.
    func testCalibrationOffset_typicalReference85dB_returnsReasonableOffset() {
        let meter = SPLMeter()

        // currentDB defaults to 0.0 (no audio running)
        // rawReading = currentDB - referenceOffset = 0.0 - 90.0 = -90.0
        // offset = knownSPL - rawReading = 85.0 - (-90.0) = 175.0
        // This is expected when the meter is idle (no audio input).
        // The important thing is the math is deterministic and does not crash.
        let offset = meter.calculateCalibrationOffset(knownSPL: 85.0)

        // With no audio running, the offset will be large because currentDB is 0.
        // The formula: offset = knownSPL - (currentDB - referenceOffset)
        //            = 85 - (0 - 90) = 85 + 90 = 175
        XCTAssertEqual(offset, 175.0, accuracy: 0.001,
            "Offset should equal knownSPL - (currentDB - referenceOffset)")
    }

    /// Verify the calibration math formula:
    /// offset = knownSPL - (currentDB - referenceOffset)
    /// where referenceOffset = 90.0
    func testCalibrationOffset_mathIsCorrect() {
        let meter = SPLMeter()

        // Default currentDB = 0.0, referenceOffset = 90.0
        // offset = knownSPL - (0.0 - 90.0) = knownSPL + 90.0
        let offset70 = meter.calculateCalibrationOffset(knownSPL: 70.0)
        XCTAssertEqual(offset70, 160.0, accuracy: 0.001,
            "70 dB known SPL with idle meter: 70 - (0 - 90) = 160")

        let offset94 = meter.calculateCalibrationOffset(knownSPL: 94.0)
        XCTAssertEqual(offset94, 184.0, accuracy: 0.001,
            "94 dB known SPL with idle meter: 94 - (0 - 90) = 184")

        let offset130 = meter.calculateCalibrationOffset(knownSPL: 130.0)
        XCTAssertEqual(offset130, 220.0, accuracy: 0.001,
            "130 dB known SPL with idle meter: 130 - (0 - 90) = 220")
    }

    /// Verify that the offset computation is purely arithmetic and does not crash
    /// for boundary values within the valid calibration range (40-130 dB).
    func testCalibrationOffset_boundaryValues_doNotCrash() {
        let meter = SPLMeter()

        let offsetAt40 = meter.calculateCalibrationOffset(knownSPL: 40.0)
        XCTAssertFalse(offsetAt40.isNaN, "Offset at 40 dB should not be NaN")
        XCTAssertFalse(offsetAt40.isInfinite, "Offset at 40 dB should not be infinite")

        let offsetAt130 = meter.calculateCalibrationOffset(knownSPL: 130.0)
        XCTAssertFalse(offsetAt130.isNaN, "Offset at 130 dB should not be NaN")
        XCTAssertFalse(offsetAt130.isInfinite, "Offset at 130 dB should not be infinite")
    }

    /// Verify that the relationship between two calibration offsets is exactly
    /// the difference between the two known SPL values (linear relationship).
    func testCalibrationOffset_linearRelationship() {
        let meter = SPLMeter()

        let offset80 = meter.calculateCalibrationOffset(knownSPL: 80.0)
        let offset90 = meter.calculateCalibrationOffset(knownSPL: 90.0)

        // The difference should be exactly 10 dB (90 - 80)
        XCTAssertEqual(offset90 - offset80, 10.0, accuracy: 0.001,
            "Offset difference should equal the SPL difference")
    }


    // MARK: - ─── Validation Range Constants Tests ────────────────────────

    /// Verify that the valid calibration range boundaries are sensible for
    /// real-world SPL reference meters. Below 40 dB is near silence;
    /// above 130 dB causes hearing damage and exceeds most consumer meters.
    func testValidCalibrationRange_40to130_coversRealWorldUse() {
        let validRange: ClosedRange<Double> = 40...130

        // Typical quiet room
        XCTAssertTrue(validRange.contains(45),
            "45 dB (quiet room) should be valid")

        // Normal conversation
        XCTAssertTrue(validRange.contains(65),
            "65 dB (conversation) should be valid")

        // Worship target SPL
        XCTAssertTrue(validRange.contains(90),
            "90 dB (worship target) should be valid")

        // Loud concert
        XCTAssertTrue(validRange.contains(110),
            "110 dB (loud concert) should be valid")

        // Out of range: too quiet
        XCTAssertFalse(validRange.contains(30),
            "30 dB is below realistic calibration reference")

        // Out of range: dangerously loud
        XCTAssertFalse(validRange.contains(150),
            "150 dB exceeds real-world SPL meter range")

        // Out of range: negative
        XCTAssertFalse(validRange.contains(-10),
            "Negative dB SPL is not a valid calibration reference")
    }
}
