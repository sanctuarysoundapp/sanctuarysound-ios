// ============================================================================
// SanctuarySoundWatchApp.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: watchOS App Entry Point
// Purpose: @main entry point for the Apple Watch companion app. Shows an
//          animated splash screen briefly, then presents the SPL dashboard.
// ============================================================================

import SwiftUI


// MARK: - ─── Watch App ──────────────────────────────────────────────────────

@main
struct SanctuarySoundWatchApp: App {
    @StateObject private var viewModel = WatchSPLViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    WatchSplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
                if !showSplash {
                    WatchSPLView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showSplash)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    showSplash = false
                }
            }
        }
    }
}
