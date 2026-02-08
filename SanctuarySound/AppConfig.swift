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

    /// Donation page — Victory Church AL via Church Center (Planning Center).
    static let donationURL = URL(string: "https://victorychurchal.churchcenter.com")!

    /// GitHub repository.
    static let githubURL = URL(string: "https://github.com/sanctuarysoundapp/sanctuarysound-ios")!

    /// GitHub Sponsors page for developer contributions.
    static let githubSponsorsURL = URL(string: "https://github.com/sponsors/sanctuarysoundapp")!

    /// Privacy policy (hosted on GitHub).
    static let privacyPolicyURL = URL(string: "https://github.com/sanctuarysoundapp/sanctuarysound-ios/blob/main/PRIVACY.md")!

    /// GitHub Issues for feedback and bug reports.
    static let feedbackURL = URL(string: "https://github.com/sanctuarysoundapp/sanctuarysound-ios/issues")!

    // ── Mission ──

    static let missionStatement = "Built for the church, by the church. Free forever."

    static let missionDescription = "SanctuarySound is an open-source ministry tool that helps church audio volunteers get better sound every Sunday. It will always be free. If this app blesses your ministry, consider supporting its development."
}
