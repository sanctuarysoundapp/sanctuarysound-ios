// ============================================================================
// ThemeProvider.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: ViewModel Layer
// Purpose: Observable environment object providing the active color theme to
//          all views. Exposes a nonisolated activeColors for BoothColors
//          compatibility, plus @Published colors for reactive SwiftUI updates.
// ============================================================================

import SwiftUI


// MARK: - ─── Active Theme Storage ─────────────────────────────────────────

/// Thread-safe storage for the active color theme, accessible from any
/// isolation context. BoothColors reads from this directly.
private struct ActiveThemeStorage {
    nonisolated(unsafe) static var colors: ColorTheme = .darkBooth
}


// MARK: - ─── Theme Provider ───────────────────────────────────────────────

@MainActor
final class ThemeProvider: ObservableObject {

    /// Shared singleton — used by RootView as @StateObject.
    static let shared = ThemeProvider()

    /// Nonisolated access to current theme colors for BoothColors delegation.
    nonisolated static var activeColors: ColorTheme {
        ActiveThemeStorage.colors
    }

    @Published private(set) var colors: ColorTheme

    private(set) var activeThemeID: ColorThemeID

    init(themeID: ColorThemeID = .darkBooth) {
        self.activeThemeID = themeID
        self.colors = ColorTheme.theme(for: themeID)
        ActiveThemeStorage.colors = self.colors
    }

    func apply(themeID: ColorThemeID) {
        guard themeID != activeThemeID else { return }
        activeThemeID = themeID
        let newColors = ColorTheme.theme(for: themeID)
        ActiveThemeStorage.colors = newColors
        withAnimation(.easeInOut(duration: 0.3)) {
            colors = newColors
        }
    }
}
