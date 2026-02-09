// ============================================================================
// SPLFormattingTests.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Unit Tests
// Purpose: Verifies that SPLSessionReport formatting methods produce correct
//          output and that static DateFormatter caching does not alter results.
//          Covers formatSessionDate(), formatTime(_:), and formatDuration(_:).
// ============================================================================

import XCTest
@testable import SanctuarySound


// MARK: - ─── SPL Report Formatting Tests ──────────────────────────────────

final class SPLFormattingTests: XCTestCase {

    /// A fixed reference date for deterministic testing.
    /// February 9, 2026 at 10:30:15 AM (local time zone).
    private func makeFixedDate() -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 9
        components.hour = 10
        components.minute = 30
        components.second = 15
        return Calendar.current.date(from: components)!
    }

    /// Creates a minimal SPLSessionReport with the given session start date.
    private func makeReport(sessionStart: Date) -> SPLSessionReport {
        SPLSessionReport(
            date: sessionStart,
            sessionStart: sessionStart,
            sessionEnd: sessionStart.addingTimeInterval(3600),
            targetDB: 90.0,
            flaggingMode: .balanced,
            breachEvents: [],
            overallPeakDB: 92.0,
            overallAverageDB: 85.0,
            totalMonitoringSeconds: 3600
        )
    }


    // MARK: - ─── formatSessionDate Tests ──────────────────────────────────

    /// formatSessionDate should return a string containing the day name and time.
    func testFormatSessionDate_containsDayAndTime() {
        let date = makeFixedDate()
        let report = makeReport(sessionStart: date)

        let result = report.formatSessionDate()

        // Should contain day of week (Monday for Feb 9, 2026)
        XCTAssertTrue(result.contains("Monday") || result.contains("Mon"),
            "formatSessionDate should include day name, got: \(result)")
        // Should contain the time portion
        XCTAssertTrue(result.contains("10:30"),
            "formatSessionDate should include time, got: \(result)")
        // Should contain "Feb" or "2"
        XCTAssertTrue(result.contains("Feb") || result.contains("2"),
            "formatSessionDate should include month, got: \(result)")
    }

    /// Calling formatSessionDate twice should produce identical results
    /// (verifies static formatter caching does not break idempotency).
    func testFormatSessionDate_isIdempotent() {
        let date = makeFixedDate()
        let report = makeReport(sessionStart: date)

        let first = report.formatSessionDate()
        let second = report.formatSessionDate()

        XCTAssertEqual(first, second,
            "Repeated calls should return identical results")
    }


    // MARK: - ─── formatTime Tests ─────────────────────────────────────────

    /// formatTime should return a string with hours, minutes, seconds, and AM/PM.
    func testFormatTime_containsHoursMinutesSeconds() {
        let date = makeFixedDate()
        let report = makeReport(sessionStart: date)

        let result = report.formatTime(date)

        // Should contain "10:30:15"
        XCTAssertTrue(result.contains("10:30:15"),
            "formatTime should include h:mm:ss, got: \(result)")
        // Should contain AM/PM indicator
        XCTAssertTrue(result.uppercased().contains("AM") || result.uppercased().contains("PM"),
            "formatTime should include AM/PM, got: \(result)")
    }

    /// Calling formatTime twice with the same date should produce identical results.
    func testFormatTime_isIdempotent() {
        let date = makeFixedDate()
        let report = makeReport(sessionStart: date)

        let first = report.formatTime(date)
        let second = report.formatTime(date)

        XCTAssertEqual(first, second,
            "Repeated calls should return identical results")
    }

    /// formatTime with a PM date should show PM.
    func testFormatTime_pmDate() {
        var components = DateComponents()
        components.year = 2026
        components.month = 2
        components.day = 9
        components.hour = 14
        components.minute = 45
        components.second = 30
        let date = Calendar.current.date(from: components)!
        let report = makeReport(sessionStart: date)

        let result = report.formatTime(date)

        XCTAssertTrue(result.contains("2:45:30"),
            "formatTime should show 12-hour format, got: \(result)")
        XCTAssertTrue(result.uppercased().contains("PM"),
            "formatTime should show PM for afternoon, got: \(result)")
    }


    // MARK: - ─── formatDuration Tests ─────────────────────────────────────

    /// Duration under 60 seconds should show seconds only.
    func testFormatDuration_secondsOnly() {
        let report = makeReport(sessionStart: Date())

        XCTAssertEqual(report.formatDuration(0), "0s")
        XCTAssertEqual(report.formatDuration(1), "1s")
        XCTAssertEqual(report.formatDuration(45), "45s")
        XCTAssertEqual(report.formatDuration(59), "59s")
    }

    /// Duration between 60 seconds and 1 hour should show minutes and seconds.
    func testFormatDuration_minutesAndSeconds() {
        let report = makeReport(sessionStart: Date())

        XCTAssertEqual(report.formatDuration(60), "1m 0s")
        XCTAssertEqual(report.formatDuration(90), "1m 30s")
        XCTAssertEqual(report.formatDuration(3599), "59m 59s")
    }

    /// Duration of 1 hour or more should show hours and minutes.
    func testFormatDuration_hoursAndMinutes() {
        let report = makeReport(sessionStart: Date())

        XCTAssertEqual(report.formatDuration(3600), "1h 0m")
        XCTAssertEqual(report.formatDuration(3900), "1h 5m")
        XCTAssertEqual(report.formatDuration(7200), "2h 0m")
    }
}
