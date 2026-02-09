// ============================================================================
// WatchColors.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: Design System (watchOS)
// Purpose: Simplified color system for the Watch app. Uses @AppStorage to
//          read the theme ID synced from iPhone via WatchConnectivity.
//          Falls back to the default "Dark Booth" theme colors.
// ============================================================================

import SwiftUI


// MARK: - ─── Watch Colors ───────────────────────────────────────────────────

/// Simplified booth-friendly colors for the Watch. Theme-aware via @AppStorage.
enum WatchColors {

    // Fixed dark booth palette — optimized for OLED watch displays
    static let background      = Color(red: 0.06, green: 0.06, blue: 0.08)
    static let surface         = Color(red: 0.10, green: 0.10, blue: 0.13)
    static let surfaceElevated = Color(red: 0.14, green: 0.14, blue: 0.18)
    static let accent          = Color(red: 0.30, green: 0.75, blue: 0.55)
    static let accentWarm      = Color(red: 0.95, green: 0.65, blue: 0.20)
    static let accentDanger    = Color(red: 0.95, green: 0.30, blue: 0.25)
    static let textPrimary     = Color(red: 0.92, green: 0.92, blue: 0.94)
    static let textSecondary   = Color(red: 0.55, green: 0.55, blue: 0.60)
    static let textMuted       = Color(red: 0.35, green: 0.35, blue: 0.40)
}
