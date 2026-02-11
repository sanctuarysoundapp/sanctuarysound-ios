// ============================================================================
// WatchWidgetScreenshotTests.swift
// SanctuarySoundTests — Watch & Widget Screenshot Generation
// ============================================================================
// Architecture: XCTest + ImageRenderer
// Purpose: Renders iOS-compilable replica views of Watch app screens and Widget
//          complications to PNG via ImageRenderer. Produces App Store screenshots
//          at exact Apple Watch pixel dimensions without requiring watchOS UI tests.
//
// Run: xcodebuild test -scheme SanctuarySound \
//        -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
//        -only-testing:SanctuarySoundTests/WatchWidgetScreenshotTests
// ============================================================================

import XCTest
@testable import SanctuarySound
import SwiftUI


// MARK: - ─── Watch & Widget Screenshot Tests ───────────────────────────────

@MainActor
final class WatchWidgetScreenshotTests: XCTestCase {

    // MARK: - ─── Render Helper ─────────────────────────────────────────────

    /// Renders a SwiftUI view to a PNG attachment using ImageRenderer.
    /// - Parameters:
    ///   - view: The SwiftUI view to render.
    ///   - name: Attachment name (used as filename in xcresult extraction).
    ///   - width: Frame width in points.
    ///   - height: Frame height in points.
    ///   - scale: Render scale (2.0 for Retina). Defaults to 1.0 for pixel-accurate
    ///            watch screenshots where width/height ARE the pixel dimensions.
    private func renderToAttachment<V: View>(
        view: V,
        name: String,
        width: CGFloat,
        height: CGFloat,
        scale: CGFloat = 1.0
    ) {
        let framedView = view
            .frame(width: width, height: height)
            .clipped()

        let renderer = ImageRenderer(content: framedView)
        renderer.scale = scale

        guard let cgImage = renderer.cgImage else {
            XCTFail("ImageRenderer failed to produce CGImage for '\(name)'")
            return
        }

        let uiImage = UIImage(cgImage: cgImage)
        guard let pngData = uiImage.pngData() else {
            XCTFail("Failed to create PNG data for '\(name)'")
            return
        }

        let attachment = XCTAttachment(
            data: pngData,
            uniformTypeIdentifier: "public.png"
        )
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }


    // MARK: - ─── Watch Dashboard — Ultra 3 (422×514) ──────────────────────

    func test01_watchDashboard_safe_ultra3() throws {
        let view = WatchDashboardPreview(
            currentDB: 85,
            peakDB: 88,
            targetDB: 90,
            alertState: "safe",
            isRunning: true,
            flaggingMode: "BAL",
            isPhoneReachable: true,
            sessionElapsed: 2340  // 39 minutes
        )

        renderToAttachment(
            view: view,
            name: "watch_01_dashboard_safe",
            width: 422,
            height: 514
        )
    }

    func test02_watchDashboard_alert_ultra3() throws {
        let view = WatchDashboardPreview(
            currentDB: 93,
            peakDB: 95,
            targetDB: 90,
            alertState: "alert",
            isRunning: true,
            flaggingMode: "BAL",
            isPhoneReachable: true,
            sessionElapsed: 4920  // 1 hour 22 minutes
        )

        renderToAttachment(
            view: view,
            name: "watch_02_dashboard_alert",
            width: 422,
            height: 514
        )
    }

    func test03_watchReportsList_ultra3() throws {
        let reports = Self.sampleReports()

        let view = WatchReportListPreview(reports: reports)

        renderToAttachment(
            view: view,
            name: "watch_03_reports_list",
            width: 422,
            height: 514
        )
    }

    func test04_watchReportDetail_ultra3() throws {
        // Hero detail: "Good" grade (1 breach, relatable for volunteers)
        let report = Self.sampleReports()[0]

        let view = WatchReportDetailPreview(report: report)

        renderToAttachment(
            view: view,
            name: "watch_04_report_detail",
            width: 422,
            height: 514
        )
    }


    // MARK: - ─── Watch Dashboard — Series 11 (416×496) ────────────────────

    func test05_watchDashboard_safe_series11() throws {
        let view = WatchDashboardPreview(
            currentDB: 85,
            peakDB: 88,
            targetDB: 90,
            alertState: "safe",
            isRunning: true,
            flaggingMode: "BAL",
            isPhoneReachable: true,
            sessionElapsed: 2340  // 39 minutes
        )

        renderToAttachment(
            view: view,
            name: "watch_05_dashboard_safe_s11",
            width: 416,
            height: 496
        )
    }

    func test06_watchDashboard_alert_series11() throws {
        let view = WatchDashboardPreview(
            currentDB: 93,
            peakDB: 95,
            targetDB: 90,
            alertState: "alert",
            isRunning: true,
            flaggingMode: "BAL",
            isPhoneReachable: true,
            sessionElapsed: 4920  // 1 hour 22 minutes
        )

        renderToAttachment(
            view: view,
            name: "watch_06_dashboard_alert_s11",
            width: 416,
            height: 496
        )
    }

    func test07_watchReportsList_series11() throws {
        let reports = Self.sampleReports()

        let view = WatchReportListPreview(reports: reports)

        renderToAttachment(
            view: view,
            name: "watch_07_reports_list_s11",
            width: 416,
            height: 496
        )
    }

    func test08_watchReportDetail_series11() throws {
        let report = Self.sampleReports()[0]

        let view = WatchReportDetailPreview(report: report)

        renderToAttachment(
            view: view,
            name: "watch_08_report_detail_s11",
            width: 416,
            height: 496
        )
    }


    // MARK: - ─── Widget Complications ──────────────────────────────────────

    func test09_widgetCircular() throws {
        let entry = ScreenshotComplicationEntry(
            currentDB: 85,
            alertState: "safe",
            targetDB: 90,
            isRunning: true
        )

        let view = WidgetCircularPreview(entry: entry)
            .background(Color.black)

        renderToAttachment(
            view: view,
            name: "complication_circular",
            width: 84,
            height: 84,
            scale: 2.0
        )
    }

    func test10_widgetCorner() throws {
        let entry = ScreenshotComplicationEntry(
            currentDB: 85,
            alertState: "safe",
            targetDB: 90,
            isRunning: true
        )

        let view = WidgetCornerPreview(entry: entry)
            .background(Color.black)

        renderToAttachment(
            view: view,
            name: "complication_corner",
            width: 40,
            height: 40,
            scale: 2.0
        )
    }

    func test11_widgetRectangular() throws {
        let entry = ScreenshotComplicationEntry(
            currentDB: 85,
            alertState: "safe",
            targetDB: 90,
            isRunning: true
        )

        let view = WidgetRectangularPreview(entry: entry)
            .background(Color.black)

        renderToAttachment(
            view: view,
            name: "complication_rectangular",
            width: 172,
            height: 76,
            scale: 2.0
        )
    }


    // MARK: - ─── Sample Data ───────────────────────────────────────────────

    /// Creates 6 sample SPL reports spanning all 4 grade levels for rich screenshots.
    /// Grades: Excellent (0% breaches), Good (<5%), Fair (5-15%), Needs Work (≥15%).
    private static func sampleReports() -> [SPLSessionReport] {
        let now = Date()
        let calendar = Calendar.current

        // ── Report 1: Good (hero) — 1 breach, 1 day ago ──
        let r1Start = calendar.date(byAdding: .hour, value: -26, to: now) ?? now
        let r1End = calendar.date(byAdding: .hour, value: -24, to: now) ?? now

        // ── Report 2: Excellent — 0 breaches, 3 days ago ──
        let r2Start = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        let r2End = calendar.date(byAdding: .minute, value: 95, to: r2Start) ?? r2Start

        // ── Report 3: Fair — 2 breaches (1 danger), 7 days ago ──
        let r3Start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let r3End = calendar.date(byAdding: .minute, value: 110, to: r3Start) ?? r3Start

        // ── Report 4: Needs Work — 4 breaches (2 danger), 10 days ago ──
        let r4Start = calendar.date(byAdding: .day, value: -10, to: now) ?? now
        let r4End = calendar.date(byAdding: .minute, value: 90, to: r4Start) ?? r4Start

        // ── Report 5: Excellent — 0 breaches, 14 days ago ──
        let r5Start = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        let r5End = calendar.date(byAdding: .minute, value: 120, to: r5Start) ?? r5Start

        // ── Report 6: Good — 1 breach, 21 days ago ──
        let r6Start = calendar.date(byAdding: .day, value: -21, to: now) ?? now
        let r6End = calendar.date(byAdding: .minute, value: 100, to: r6Start) ?? r6Start

        return [
            // Report 1: Good — 1 breach at 25min mark
            SPLSessionReport(
                date: r1Start,
                sessionStart: r1Start,
                sessionEnd: r1End,
                targetDB: 90.0,
                flaggingMode: .balanced,
                breachEvents: [
                    SPLBreachEvent(
                        startTime: calendar.date(byAdding: .minute, value: 25, to: r1Start) ?? r1Start,
                        endTime: calendar.date(byAdding: .minute, value: 26, to: r1Start) ?? r1Start,
                        peakDB: 93.2,
                        targetDB: 90.0,
                        thresholdDB: 5.0
                    )
                ],
                overallPeakDB: 93.2,
                overallAverageDB: 85.4,
                totalMonitoringSeconds: 7200
            ),

            // Report 2: Excellent — clean session
            SPLSessionReport(
                date: r2Start,
                sessionStart: r2Start,
                sessionEnd: r2End,
                targetDB: 90.0,
                flaggingMode: .balanced,
                breachEvents: [],
                overallPeakDB: 88.5,
                overallAverageDB: 82.1,
                totalMonitoringSeconds: 5700
            ),

            // Report 3: Fair — 2 breaches, 1 danger
            SPLSessionReport(
                date: r3Start,
                sessionStart: r3Start,
                sessionEnd: r3End,
                targetDB: 90.0,
                flaggingMode: .strict,
                breachEvents: [
                    SPLBreachEvent(
                        startTime: calendar.date(byAdding: .minute, value: 40, to: r3Start) ?? r3Start,
                        endTime: calendar.date(byAdding: .minute, value: 42, to: r3Start) ?? r3Start,
                        peakDB: 94.8,
                        targetDB: 90.0,
                        thresholdDB: 2.0
                    ),
                    SPLBreachEvent(
                        startTime: calendar.date(byAdding: .minute, value: 75, to: r3Start) ?? r3Start,
                        endTime: calendar.date(byAdding: .minute, value: 76, to: r3Start) ?? r3Start,
                        peakDB: 91.3,
                        targetDB: 90.0,
                        thresholdDB: 2.0
                    )
                ],
                overallPeakDB: 94.8,
                overallAverageDB: 86.7,
                totalMonitoringSeconds: 6600
            ),

            // Report 4: Needs Work — 4 breaches, 2 danger
            SPLSessionReport(
                date: r4Start,
                sessionStart: r4Start,
                sessionEnd: r4End,
                targetDB: 90.0,
                flaggingMode: .balanced,
                breachEvents: [
                    SPLBreachEvent(
                        startTime: calendar.date(byAdding: .minute, value: 10, to: r4Start) ?? r4Start,
                        endTime: calendar.date(byAdding: .minute, value: 15, to: r4Start) ?? r4Start,
                        peakDB: 97.1,
                        targetDB: 90.0,
                        thresholdDB: 5.0
                    ),
                    SPLBreachEvent(
                        startTime: calendar.date(byAdding: .minute, value: 30, to: r4Start) ?? r4Start,
                        endTime: calendar.date(byAdding: .minute, value: 35, to: r4Start) ?? r4Start,
                        peakDB: 96.5,
                        targetDB: 90.0,
                        thresholdDB: 5.0
                    ),
                    SPLBreachEvent(
                        startTime: calendar.date(byAdding: .minute, value: 55, to: r4Start) ?? r4Start,
                        endTime: calendar.date(byAdding: .minute, value: 58, to: r4Start) ?? r4Start,
                        peakDB: 93.2,
                        targetDB: 90.0,
                        thresholdDB: 5.0
                    ),
                    SPLBreachEvent(
                        startTime: calendar.date(byAdding: .minute, value: 75, to: r4Start) ?? r4Start,
                        endTime: calendar.date(byAdding: .minute, value: 78, to: r4Start) ?? r4Start,
                        peakDB: 94.0,
                        targetDB: 90.0,
                        thresholdDB: 5.0
                    )
                ],
                overallPeakDB: 97.1,
                overallAverageDB: 89.2,
                totalMonitoringSeconds: 5400
            ),

            // Report 5: Excellent — another clean session
            SPLSessionReport(
                date: r5Start,
                sessionStart: r5Start,
                sessionEnd: r5End,
                targetDB: 90.0,
                flaggingMode: .balanced,
                breachEvents: [],
                overallPeakDB: 87.0,
                overallAverageDB: 80.5,
                totalMonitoringSeconds: 7200
            ),

            // Report 6: Good — 1 breach, older session
            SPLSessionReport(
                date: r6Start,
                sessionStart: r6Start,
                sessionEnd: r6End,
                targetDB: 90.0,
                flaggingMode: .balanced,
                breachEvents: [
                    SPLBreachEvent(
                        startTime: calendar.date(byAdding: .minute, value: 50, to: r6Start) ?? r6Start,
                        endTime: calendar.date(byAdding: .minute, value: 51, to: r6Start) ?? r6Start,
                        peakDB: 91.5,
                        targetDB: 90.0,
                        thresholdDB: 5.0
                    )
                ],
                overallPeakDB: 91.5,
                overallAverageDB: 84.3,
                totalMonitoringSeconds: 6000
            )
        ]
    }
}
