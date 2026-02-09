// ============================================================================
// SanctuarySoundWatchApp.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: watchOS App Entry Point
// Purpose: @main entry point for the Apple Watch companion app. Initializes
//          WatchConnectivity and presents the SPL monitoring interface.
// ============================================================================

import SwiftUI


// MARK: - ─── Watch App ──────────────────────────────────────────────────────

@main
struct SanctuarySoundWatchApp: App {
    @StateObject private var viewModel = WatchSPLViewModel()

    var body: some Scene {
        WindowGroup {
            WatchSPLView(viewModel: viewModel)
        }
    }
}
