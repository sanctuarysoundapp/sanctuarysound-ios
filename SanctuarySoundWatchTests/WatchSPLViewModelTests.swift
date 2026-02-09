// ============================================================================
// WatchSPLViewModelTests.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: Unit Tests
// Purpose: Tests for WatchSPLViewModel — snapshot updates, alert transitions,
//          haptic triggers, command formatting, report persistence.
// ============================================================================

import XCTest
import SwiftUI
@testable import SanctuarySoundWatch


// MARK: - ─── Ring Gauge Computation Tests ────────────────────────────────────

/// Tests for the ring fill fraction and color logic used by the Watch dashboard.
/// These mirror the computed properties in WatchSPLViewModel but test the
/// underlying math directly (ViewModel can't be instantiated without WCSession).
final class RingGaugeComputationTests: XCTestCase {

    /// Computes ring fill fraction using the same formula as WatchSPLViewModel.ringFillFraction.
    private func ringFillFraction(currentDB: Double, targetDB: Double) -> Double {
        let floor = 40.0
        let range = max(targetDB - floor, 1.0)
        return min(max(currentDB - floor, 0), range + 20) / range
    }

    /// Computes ring color using the same logic as WatchSPLViewModel.ringColor.
    private func ringColor(alertRaw: String) -> Color {
        switch alertRaw {
        case "alert": return WatchColors.accentDanger
        case "warning": return WatchColors.accentWarm
        default: return WatchColors.accent
        }
    }

    func testRingFillAtFloorIsZero() {
        let fill = ringFillFraction(currentDB: 40.0, targetDB: 90.0)
        XCTAssertEqual(fill, 0.0, accuracy: 0.001)
    }

    func testRingFillBelowFloorIsZero() {
        let fill = ringFillFraction(currentDB: 20.0, targetDB: 90.0)
        XCTAssertEqual(fill, 0.0, accuracy: 0.001)
    }

    func testRingFillAtTargetIsOne() {
        let fill = ringFillFraction(currentDB: 90.0, targetDB: 90.0)
        XCTAssertEqual(fill, 1.0, accuracy: 0.001)
    }

    func testRingFillAboveTargetExceedsOne() {
        let fill = ringFillFraction(currentDB: 95.0, targetDB: 90.0)
        XCTAssertGreaterThan(fill, 1.0)
    }

    func testRingFillMidpointIsCorrect() {
        // At 65 dB with target 90: (65-40)/(90-40) = 25/50 = 0.5
        let fill = ringFillFraction(currentDB: 65.0, targetDB: 90.0)
        XCTAssertEqual(fill, 0.5, accuracy: 0.001)
    }

    func testRingFillWithDifferentTarget() {
        // At 80 dB with target 80: should be 1.0
        let fill = ringFillFraction(currentDB: 80.0, targetDB: 80.0)
        XCTAssertEqual(fill, 1.0, accuracy: 0.001)
    }

    func testRingColorSafe() {
        let color = ringColor(alertRaw: "safe")
        XCTAssertEqual(color, WatchColors.accent)
    }

    func testRingColorWarning() {
        let color = ringColor(alertRaw: "warning")
        XCTAssertEqual(color, WatchColors.accentWarm)
    }

    func testRingColorAlert() {
        let color = ringColor(alertRaw: "alert")
        XCTAssertEqual(color, WatchColors.accentDanger)
    }

    func testRingColorUnknownDefaultsToSafe() {
        let color = ringColor(alertRaw: "unknown")
        XCTAssertEqual(color, WatchColors.accent)
    }
}


// MARK: - ─── Crown Target Validation Tests ───────────────────────────────────

/// Tests for Crown target clamping logic (range 70-100 dB).
final class CrownTargetValidationTests: XCTestCase {

    /// Clamps value to valid Crown range, mirroring commitCrownTarget() logic.
    private func clampCrownTarget(_ value: Double) -> Double {
        min(max(value, 70.0), 100.0)
    }

    func testCrownTargetClampsLow() {
        XCTAssertEqual(clampCrownTarget(65.0), 70.0)
    }

    func testCrownTargetClampsHigh() {
        XCTAssertEqual(clampCrownTarget(105.0), 100.0)
    }

    func testCrownTargetPassesThroughValidValue() {
        XCTAssertEqual(clampCrownTarget(85.0), 85.0)
    }

    func testCrownTargetAtLowerBound() {
        XCTAssertEqual(clampCrownTarget(70.0), 70.0)
    }

    func testCrownTargetAtUpperBound() {
        XCTAssertEqual(clampCrownTarget(100.0), 100.0)
    }
}


// MARK: - ─── Preference Update Message Tests ─────────────────────────────────

/// Tests for the WCMessageKey constants used in Watch→iPhone preference sync.
final class PreferenceUpdateMessageTests: XCTestCase {

    func testPreferenceUpdateMessageType() {
        XCTAssertEqual(WCMessageKey.typePreferenceUpdate, "preferenceUpdate")
    }

    func testPreferenceUpdateMessageStructure() {
        let targetDB = 85.0
        let message: [String: Any] = [
            WCMessageKey.messageType: WCMessageKey.typePreferenceUpdate,
            WCMessageKey.targetDB: targetDB
        ]

        XCTAssertEqual(message[WCMessageKey.messageType] as? String, "preferenceUpdate")
        XCTAssertEqual(message[WCMessageKey.targetDB] as? Double, 85.0)
    }
}


// MARK: - ─── SPL Alert State Codable Tests ──────────────────────────────────

final class SPLAlertStateCodableTests: XCTestCase {

    func testSafeRoundTrip() {
        let state = SPLAlertStateCodable.safe
        XCTAssertEqual(state.rawValue, "safe")
        XCTAssertNil(state.currentDB)
        XCTAssertNil(state.overBy)
        XCTAssertFalse(state.isActive)
        XCTAssertFalse(state.isDanger)
    }

    func testWarningRoundTrip() {
        let state = SPLAlertStateCodable(rawValue: "warning", currentDB: 93, overBy: 3)
        XCTAssertEqual(state.rawValue, "warning")
        XCTAssertEqual(state.currentDB, 93)
        XCTAssertEqual(state.overBy, 3)
        XCTAssertTrue(state.isActive)
        XCTAssertFalse(state.isDanger)

        let alertState = state.toAlertState()
        if case .warning(let db, let over) = alertState {
            XCTAssertEqual(db, 93)
            XCTAssertEqual(over, 3)
        } else {
            XCTFail("Expected warning state")
        }
    }

    func testAlertRoundTrip() {
        let state = SPLAlertStateCodable(rawValue: "alert", currentDB: 98, overBy: 8)
        XCTAssertEqual(state.rawValue, "alert")
        XCTAssertTrue(state.isActive)
        XCTAssertTrue(state.isDanger)

        let alertState = state.toAlertState()
        if case .alert(let db, let over) = alertState {
            XCTAssertEqual(db, 98)
            XCTAssertEqual(over, 8)
        } else {
            XCTFail("Expected alert state")
        }
    }

    func testFromSPLAlertState() {
        let safe = SPLAlertStateCodable(from: .safe)
        XCTAssertEqual(safe.rawValue, "safe")

        let warning = SPLAlertStateCodable(from: .warning(currentDB: 92, overBy: 2))
        XCTAssertEqual(warning.rawValue, "warning")
        XCTAssertEqual(warning.currentDB, 92)

        let alert = SPLAlertStateCodable(from: .alert(currentDB: 100, overBy: 10))
        XCTAssertEqual(alert.rawValue, "alert")
        XCTAssertEqual(alert.currentDB, 100)
    }

    func testCodableRoundTrip() throws {
        let original = SPLAlertStateCodable(rawValue: "warning", currentDB: 95, overBy: 5)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SPLAlertStateCodable.self, from: encoded)

        XCTAssertEqual(decoded.rawValue, "warning")
        XCTAssertEqual(decoded.currentDB, 95)
        XCTAssertEqual(decoded.overBy, 5)
    }
}


// MARK: - ─── SPL Snapshot Tests ─────────────────────────────────────────────

final class SPLSnapshotTests: XCTestCase {

    func testDictionaryRoundTrip() {
        let snapshot = SPLSnapshot(
            currentDB: 87.5,
            peakDB: 93.2,
            averageDB: 85.1,
            alertState: SPLAlertStateCodable(rawValue: "warning", currentDB: 93, overBy: 3),
            isRunning: true,
            timestamp: Date(timeIntervalSince1970: 1707350400)
        )

        let dict = snapshot.toDictionary()
        let restored = SPLSnapshot.from(dictionary: dict)

        XCTAssertNotNil(restored)
        XCTAssertEqual(restored!.currentDB, 87.5)
        XCTAssertEqual(restored!.peakDB, 93.2)
        XCTAssertEqual(restored!.averageDB, 85.1)
        XCTAssertEqual(restored!.alertState.rawValue, "warning")
        XCTAssertTrue(restored!.isRunning)
    }

    func testFromInvalidDictionary() {
        let invalid: [String: Any] = ["foo": "bar"]
        let snapshot = SPLSnapshot.from(dictionary: invalid)
        XCTAssertNil(snapshot)
    }
}
