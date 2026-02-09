// ============================================================================
// ColorTheme.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Model Layer
// Purpose: Defines the color theme struct and three booth-friendly dark themes.
//          All themes are dark — designed for low-light sound booth use during
//          live services. The "Dark Booth" theme matches the original BoothColors
//          values exactly for zero visual regression.
// ============================================================================

import SwiftUI


// MARK: - ─── Color Theme ──────────────────────────────────────────────────

struct ColorTheme: Equatable {
    let background: Color
    let surface: Color
    let surfaceElevated: Color
    let accent: Color
    let accentWarm: Color
    let accentDanger: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let divider: Color
}


// MARK: - ─── Theme Factories ──────────────────────────────────────────────

extension ColorTheme {

    /// Classic dark palette with green accents — original BoothColors values.
    static let darkBooth = ColorTheme(
        background:      Color(red: 0.06, green: 0.06, blue: 0.08),
        surface:         Color(red: 0.10, green: 0.10, blue: 0.13),
        surfaceElevated: Color(red: 0.14, green: 0.14, blue: 0.18),
        accent:          Color(red: 0.30, green: 0.75, blue: 0.55),
        accentWarm:      Color(red: 0.95, green: 0.65, blue: 0.20),
        accentDanger:    Color(red: 0.95, green: 0.30, blue: 0.25),
        textPrimary:     Color(red: 0.92, green: 0.92, blue: 0.94),
        textSecondary:   Color(red: 0.55, green: 0.55, blue: 0.60),
        textMuted:       Color(red: 0.35, green: 0.35, blue: 0.40),
        divider:         Color(red: 0.18, green: 0.18, blue: 0.22)
    )

    /// Blue-tinted dark palette for low-light booths.
    static let midnightBlue = ColorTheme(
        background:      Color(red: 0.05, green: 0.06, blue: 0.10),
        surface:         Color(red: 0.08, green: 0.09, blue: 0.16),
        surfaceElevated: Color(red: 0.11, green: 0.13, blue: 0.21),
        accent:          Color(red: 0.30, green: 0.75, blue: 0.55),
        accentWarm:      Color(red: 0.95, green: 0.65, blue: 0.20),
        accentDanger:    Color(red: 0.95, green: 0.30, blue: 0.25),
        textPrimary:     Color(red: 0.90, green: 0.92, blue: 0.96),
        textSecondary:   Color(red: 0.50, green: 0.55, blue: 0.65),
        textMuted:       Color(red: 0.32, green: 0.35, blue: 0.45),
        divider:         Color(red: 0.14, green: 0.16, blue: 0.24)
    )

    /// Deep purple-tinted dark palette — cool and calm.
    static let arcticSerenity = ColorTheme(
        background:      Color(red: 0.055, green: 0.04, blue: 0.08),
        surface:         Color(red: 0.086, green: 0.067, blue: 0.165),
        surfaceElevated: Color(red: 0.125, green: 0.094, blue: 0.212),
        accent:          Color(red: 0.30, green: 0.75, blue: 0.55),
        accentWarm:      Color(red: 0.95, green: 0.65, blue: 0.20),
        accentDanger:    Color(red: 0.95, green: 0.30, blue: 0.25),
        textPrimary:     Color(red: 0.90, green: 0.88, blue: 0.95),
        textSecondary:   Color(red: 0.50, green: 0.47, blue: 0.62),
        textMuted:       Color(red: 0.33, green: 0.30, blue: 0.44),
        divider:         Color(red: 0.16, green: 0.13, blue: 0.25)
    )

    /// Deep forest green-tinted dark palette — nature-inspired.
    static let forestCanopy = ColorTheme(
        background:      Color(red: 0.03, green: 0.06, blue: 0.04),
        surface:         Color(red: 0.06, green: 0.10, blue: 0.07),
        surfaceElevated: Color(red: 0.08, green: 0.13, blue: 0.10),
        accent:          Color(red: 0.30, green: 0.75, blue: 0.55),
        accentWarm:      Color(red: 0.95, green: 0.65, blue: 0.20),
        accentDanger:    Color(red: 0.95, green: 0.30, blue: 0.25),
        textPrimary:     Color(red: 0.88, green: 0.92, blue: 0.89),
        textSecondary:   Color(red: 0.47, green: 0.55, blue: 0.49),
        textMuted:       Color(red: 0.30, green: 0.38, blue: 0.32),
        divider:         Color(red: 0.10, green: 0.16, blue: 0.12)
    )

    /// Dark charcoal with warm red/ember undertones — dramatic.
    static let volcanicWonder = ColorTheme(
        background:      Color(red: 0.07, green: 0.03, blue: 0.03),
        surface:         Color(red: 0.11, green: 0.06, blue: 0.055),
        surfaceElevated: Color(red: 0.15, green: 0.085, blue: 0.08),
        accent:          Color(red: 0.30, green: 0.75, blue: 0.55),
        accentWarm:      Color(red: 0.95, green: 0.65, blue: 0.20),
        accentDanger:    Color(red: 0.95, green: 0.30, blue: 0.25),
        textPrimary:     Color(red: 0.94, green: 0.90, blue: 0.89),
        textSecondary:   Color(red: 0.60, green: 0.50, blue: 0.48),
        textMuted:       Color(red: 0.40, green: 0.32, blue: 0.30),
        divider:         Color(red: 0.20, green: 0.12, blue: 0.11)
    )

    /// Returns the theme for a given theme ID.
    static func theme(for id: ColorThemeID) -> ColorTheme {
        switch id {
        case .darkBooth:      return .darkBooth
        case .midnightBlue:   return .midnightBlue
        case .warmAmber:      return .arcticSerenity
        case .forestCanopy:   return .forestCanopy
        case .volcanic:       return .volcanicWonder
        }
    }
}
