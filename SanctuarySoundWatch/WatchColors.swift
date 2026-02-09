// ============================================================================
// WatchColors.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: Design System (watchOS)
// Purpose: Theme-aware color system for the Watch app. Reads the theme ID
//          synced from iPhone via WatchConnectivity (@AppStorage). Provides
//          the same 5 booth-friendly dark themes as the iOS app, optimized
//          for OLED watch displays.
// ============================================================================

import SwiftUI


// MARK: - ─── Watch Colors ───────────────────────────────────────────────────

/// Theme-aware booth-friendly colors for the Watch. Synced from iPhone settings.
enum WatchColors {

    // ── Theme Selection ──

    /// Current theme ID stored by WatchConnectivity preference sync.
    @AppStorage("watchThemeID") private static var themeID: String = "Dark Booth"

    // ── Shared Accent Colors (identical across all themes) ──

    static let accent       = Color(red: 0.30, green: 0.75, blue: 0.55)
    static let accentWarm   = Color(red: 0.95, green: 0.65, blue: 0.20)
    static let accentDanger = Color(red: 0.95, green: 0.30, blue: 0.25)

    // ── Theme-Dependent Colors ──

    static var background: Color { activeTheme.background }
    static var surface: Color { activeTheme.surface }
    static var surfaceElevated: Color { activeTheme.surfaceElevated }
    static var textPrimary: Color { activeTheme.textPrimary }
    static var textSecondary: Color { activeTheme.textSecondary }
    static var textMuted: Color { activeTheme.textMuted }

    // ── Active Theme Resolution ──

    private static var activeTheme: WatchTheme {
        switch themeID {
        case "Midnight Blue":   return .midnightBlue
        case "Warm Amber":      return .arcticSerenity
        case "Forest Canopy":   return .forestCanopy
        case "Volcanic Wonder": return .volcanicWonder
        default:                return .darkBooth
        }
    }
}


// MARK: - ─── Watch Theme ────────────────────────────────────────────────────

/// Lightweight theme struct holding only the colors that vary between themes.
/// Accent colors (green, amber, red) are shared across all themes.
private struct WatchTheme {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
}


// MARK: - ─── Theme Definitions ──────────────────────────────────────────────

extension WatchTheme {

    /// Northern Lights — Classic dark palette with green accents.
    static let darkBooth = WatchTheme(
        background:      Color(red: 0.06, green: 0.06, blue: 0.08),
        surface:         Color(red: 0.10, green: 0.10, blue: 0.13),
        surfaceElevated: Color(red: 0.14, green: 0.14, blue: 0.18),
        textPrimary:     Color(red: 0.92, green: 0.92, blue: 0.94),
        textSecondary:   Color(red: 0.55, green: 0.55, blue: 0.60),
        textMuted:       Color(red: 0.35, green: 0.35, blue: 0.40)
    )

    /// Ocean Depths — Blue-tinted dark palette.
    static let midnightBlue = WatchTheme(
        background:      Color(red: 0.05, green: 0.06, blue: 0.10),
        surface:         Color(red: 0.08, green: 0.09, blue: 0.16),
        surfaceElevated: Color(red: 0.11, green: 0.13, blue: 0.21),
        textPrimary:     Color(red: 0.90, green: 0.92, blue: 0.96),
        textSecondary:   Color(red: 0.50, green: 0.55, blue: 0.65),
        textMuted:       Color(red: 0.32, green: 0.35, blue: 0.45)
    )

    /// Arctic Serenity — Deep purple-tinted dark palette.
    static let arcticSerenity = WatchTheme(
        background:      Color(red: 0.055, green: 0.04, blue: 0.08),
        surface:         Color(red: 0.086, green: 0.067, blue: 0.165),
        surfaceElevated: Color(red: 0.125, green: 0.094, blue: 0.212),
        textPrimary:     Color(red: 0.90, green: 0.88, blue: 0.95),
        textSecondary:   Color(red: 0.50, green: 0.47, blue: 0.62),
        textMuted:       Color(red: 0.33, green: 0.30, blue: 0.44)
    )

    /// Forest Canopy — Deep forest green-tinted dark palette.
    static let forestCanopy = WatchTheme(
        background:      Color(red: 0.03, green: 0.06, blue: 0.04),
        surface:         Color(red: 0.06, green: 0.10, blue: 0.07),
        surfaceElevated: Color(red: 0.08, green: 0.13, blue: 0.10),
        textPrimary:     Color(red: 0.88, green: 0.92, blue: 0.89),
        textSecondary:   Color(red: 0.47, green: 0.55, blue: 0.49),
        textMuted:       Color(red: 0.30, green: 0.38, blue: 0.32)
    )

    /// Volcanic Wonder — Dark charcoal with warm red/ember undertones.
    static let volcanicWonder = WatchTheme(
        background:      Color(red: 0.07, green: 0.03, blue: 0.03),
        surface:         Color(red: 0.11, green: 0.06, blue: 0.055),
        surfaceElevated: Color(red: 0.15, green: 0.085, blue: 0.08),
        textPrimary:     Color(red: 0.94, green: 0.90, blue: 0.89),
        textSecondary:   Color(red: 0.60, green: 0.50, blue: 0.48),
        textMuted:       Color(red: 0.40, green: 0.32, blue: 0.30)
    )
}
