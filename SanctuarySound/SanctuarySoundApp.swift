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
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(purchaseManager)
        }
    }
}
