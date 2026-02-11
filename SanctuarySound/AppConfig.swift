// ============================================================================
// AppConfig.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: App Configuration
// Purpose: Centralized app constants, URLs, and version metadata.
//          The donationURL is a single hook point for the external
//          donation platform — update it here when the URL is decided.
// ============================================================================

import Foundation


// MARK: - ─── App Configuration ──────────────────────────────────────────────

struct AppConfig {

    // ── Version ──

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // ── Planning Center Online ──

    /// PCO OAuth client ID — register at api.planningcenteronline.com/oauth/applications
    static let pcoClientID = "8576274ffac59a854b27aa574a601ff5066a7cb54ffa8d09f7398584a9366479"

    /// PCO OAuth redirect URI — must match URL scheme in Info.plist
    static let pcoRedirectURI = "sanctuarysound://oauth/callback"

    // ── URLs ──

    /// Donation page — Ko-fi for community support.
    static let donationURL = URL(string: "https://ko-fi.com/sanctuarysoundapp")!

    /// GitHub repository.
    static let githubURL = URL(string: "https://github.com/sanctuarysoundapp/sanctuarysound-ios")!

    /// GitHub Sponsors page for developer contributions.
    static let githubSponsorsURL = URL(string: "https://github.com/sponsors/sanctuarysoundapp")!

    /// Privacy policy (hosted on GitHub).
    static let privacyPolicyURL = URL(string: "https://github.com/sanctuarysoundapp/sanctuarysound-ios/blob/main/PRIVACY.md")!

    /// GitHub Issues for feedback and bug reports.
    static let feedbackURL = URL(string: "https://github.com/sanctuarysoundapp/sanctuarysound-ios/issues")!

    /// MIT License (hosted on GitHub).
    static let licenseURL = URL(string: "https://github.com/sanctuarysoundapp/sanctuarysound-ios/blob/main/LICENSE")!

    // ── Mission ──

    static let missionStatement = String(localized: "Built For The Church, By The Church, Free Forever.")

    static let missionDescription = String(localized: "SanctuarySound is an open-source ministry tool that helps church production & worship teams get better sound every Sunday. It will always be free. If this app blesses your ministry, consider buying us a coffee.")
}
