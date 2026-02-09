// ============================================================================
// WatchSPLViewModelTests.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: Unit Tests
// Purpose: Tests for WatchSPLViewModel — snapshot updates, alert transitions,
//          haptic triggers, command formatting, report persistence.
// ============================================================================

import XCTest
@testable import SanctuarySoundWatch


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
