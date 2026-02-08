// ============================================================================
// SanctuarySoundApp.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: App Entry Point
// Purpose: SwiftUI application lifecycle root.
// ============================================================================

import SwiftUI

@main
struct SanctuarySoundApp: App {

    init() {
        // Load saved color theme at startup so BoothColors resolves correctly
        // before any views render. Uses MainActor.assumeIsolated since App.init
        // runs on the main thread in SwiftUI.
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("user_preferences.json")
        if let data = try? Data(contentsOf: url),
           let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            MainActor.assumeIsolated {
                ThemeProvider.shared.apply(themeID: prefs.colorTheme)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
