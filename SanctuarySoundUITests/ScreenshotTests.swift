// ============================================================================
// ScreenshotTests.swift
// SanctuarySoundUITests — App Store Screenshot Automation
// ============================================================================
// Architecture: XCUITest
// Purpose: Captures 9 App Store screenshots by navigating through the app
//          with sample data pre-populated via launch arguments.
//          Run: xcodebuild test -only-testing:SanctuarySoundUITests
// ============================================================================

import XCTest


// MARK: - ─── App Store Screenshot Tests ───────────────────────────────────

final class AppStoreScreenshotTests: ScreenshotTestCase {

    // MARK: 1 — Services Tab

    func test01_ServicesTab() throws {
        tapTab("Services")
        Thread.sleep(forTimeInterval: 0.5)
        captureScreenshot(named: "01_Services")
    }

    // MARK: 2 — Service Setup Wizard

    func test02_ServiceSetupWizard() throws {
        tapTab("Services")

        // Tap the + button to start a new service
        let addButton = app.navigationBars.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Add' OR label CONTAINS 'New' OR label CONTAINS 'plus'")
        ).firstMatch

        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            captureScreenshot(named: "02_ServiceSetup")
        } else {
            // Fallback: capture the services tab itself
            captureScreenshot(named: "02_ServiceSetup")
        }
    }

    // MARK: 3 — Recommendation Output

    func test03_Recommendations() throws {
        tapTab("Services")
        Thread.sleep(forTimeInterval: 0.5)

        // Tap the first saved service to open it
        let firstService = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Sunday' OR label CONTAINS 'Worship'")
        ).firstMatch

        if firstService.waitForExistence(timeout: 3) {
            firstService.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Look for a Generate button
            let generateButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'Generate'")
            ).firstMatch

            if generateButton.waitForExistence(timeout: 3) {
                generateButton.tap()
                Thread.sleep(forTimeInterval: 1.0)
            }
        }

        captureScreenshot(named: "03_Recommendations")
    }

    // MARK: 4 — Input Library

    func test04_InputLibrary() throws {
        tapTab("Inputs")
        Thread.sleep(forTimeInterval: 0.5)
        captureScreenshot(named: "04_InputLibrary")
    }

    // MARK: 5 — Console Profiles

    func test05_Consoles() throws {
        tapTab("Consoles")
        Thread.sleep(forTimeInterval: 0.5)
        captureScreenshot(named: "05_Consoles")
    }

    // MARK: 6 — SPL Meter

    func test06_SPLMeter() throws {
        tapTab("Tools")
        Thread.sleep(forTimeInterval: 0.5)

        let splButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'SPL'")
        ).firstMatch

        if splButton.waitForExistence(timeout: 3) {
            splButton.tap()
            Thread.sleep(forTimeInterval: 1.0)
        }

        captureScreenshot(named: "06_SPLMeter")
    }

    // MARK: 7 — EQ Analyzer

    func test07_EQAnalyzer() throws {
        tapTab("Tools")
        Thread.sleep(forTimeInterval: 0.5)

        let eqButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'EQ' OR label CONTAINS 'Analyzer'")
        ).firstMatch

        if eqButton.waitForExistence(timeout: 3) {
            eqButton.tap()
            Thread.sleep(forTimeInterval: 1.0)
        }

        captureScreenshot(named: "07_EQAnalyzer")
    }

    // MARK: 8 — Q&A Knowledge Base

    func test08_QABrowser() throws {
        tapTab("Tools")
        Thread.sleep(forTimeInterval: 0.5)

        let qaButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Q&A' OR label CONTAINS 'Knowledge'")
        ).firstMatch

        if qaButton.waitForExistence(timeout: 3) {
            qaButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        captureScreenshot(named: "08_QABrowser")
    }

    // MARK: 9 — Settings

    func test09_Settings() throws {
        tapTab("Settings")
        Thread.sleep(forTimeInterval: 0.5)
        captureScreenshot(named: "09_Settings")
    }
}
