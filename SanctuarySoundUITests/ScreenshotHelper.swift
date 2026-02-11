// ============================================================================
// ScreenshotHelper.swift
// SanctuarySoundUITests — App Store Screenshot Automation
// ============================================================================
// Architecture: XCUITest Base Class
// Purpose: Provides shared setup, launch argument configuration, and
//          screenshot capture utilities for App Store screenshot tests.
// ============================================================================

import XCTest


// MARK: - ─── Base UI Test Case ────────────────────────────────────────────

class ScreenshotTestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        app.launchArguments = [
            "-UITesting",
            "-skipOnboarding",
            "-useSampleData",
            "-disableAnimations"
        ]

        app.launch()

        // Wait for the main tab view to appear
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 5),
            "Tab bar should appear after launch with skip-onboarding"
        )
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - ─── Screenshot Capture ───────────────────────────────────────

    func captureScreenshot(named name: String) {
        // Brief pause to let any remaining transitions settle
        Thread.sleep(forTimeInterval: 0.5)

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - ─── Navigation Helpers ───────────────────────────────────────

    func tapTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 3), "Tab '\(label)' should exist")
        tab.tap()
    }
}
