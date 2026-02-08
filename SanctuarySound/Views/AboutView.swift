// ============================================================================
// AboutView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Settings/About page displaying app info, mission statement,
//          donation links, community links, and share action.
//          Accessible from the Setup tab's navigation bar.
// ============================================================================

import SwiftUI


// MARK: - ─── About View ────────────────────────────────────────────────────

struct AboutView: View {
    var body: some View {
        ZStack {
            BoothColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ── App Identity ──
                    appIdentitySection

                    // ── Mission ──
                    missionSection

                    // ── Support ──
                    supportSection

                    // ── Community ──
                    communitySection

                    // ── Legal ──
                    legalSection
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
    }


    // MARK: - ─── App Identity ───────────────────────────────────────────────

    private var appIdentitySection: some View {
        VStack(spacing: 12) {
            // App icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                BoothColors.accent.opacity(0.2),
                                BoothColors.accent.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 25,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)

                Image("AppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: BoothColors.accent.opacity(0.3), radius: 12)
            }

            Text("SANCTUARYSOUND")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .tracking(3)
                .foregroundStyle(BoothColors.textPrimary)

            Text("Virtual Audio Director")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BoothColors.textSecondary)

            Text("v\(AppConfig.version) (\(AppConfig.buildNumber))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }


    // MARK: - ─── Mission ────────────────────────────────────────────────────

    private var missionSection: some View {
        SectionCard(title: "Our Mission") {
            Text(AppConfig.missionStatement)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BoothColors.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(AppConfig.missionDescription)
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textSecondary)
                .lineSpacing(4)
        }
    }


    // MARK: - ─── Support ────────────────────────────────────────────────────

    private var supportSection: some View {
        SectionCard(title: "Support This Ministry") {
            Text("Your generosity keeps this app free for every church. Donations are tax-deductible through our church's 501(c)(3).")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textSecondary)
                .lineSpacing(3)

            Link(destination: AppConfig.donationURL) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                    Text("Support Development")
                }
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Link(destination: AppConfig.githubSponsorsURL) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 13))
                    Text("GitHub Sponsors")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BoothColors.textPrimary)
                .padding(12)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }


    // MARK: - ─── Community ──────────────────────────────────────────────────

    private var communitySection: some View {
        SectionCard(title: "Community") {
            aboutLink(
                icon: "curlybraces",
                title: "View Source Code",
                subtitle: "Open-source on GitHub",
                url: AppConfig.githubURL
            )

            aboutLink(
                icon: "bubble.left.and.exclamationmark.bubble.right",
                title: "Feedback & Bug Reports",
                subtitle: "Report issues on GitHub",
                url: AppConfig.feedbackURL
            )

            ShareLink(
                item: AppConfig.githubURL,
                subject: Text("SanctuarySound"),
                message: Text("Check out SanctuarySound — a free, open-source app that calculates mixer settings for church audio volunteers.")
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(BoothColors.accent)
                        .frame(width: 28, height: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share This App")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.textPrimary)
                        Text("Help other churches find better sound")
                            .font(.system(size: 11))
                            .foregroundStyle(BoothColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .padding(12)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }


    // MARK: - ─── Legal ──────────────────────────────────────────────────────

    private var legalSection: some View {
        SectionCard(title: "Legal") {
            aboutLink(
                icon: "hand.raised.fill",
                title: "Privacy Policy",
                subtitle: "No data collected, ever",
                url: AppConfig.privacyPolicyURL
            )

            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.accent)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("License")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BoothColors.textPrimary)
                    Text("MIT — Free to use, modify, and distribute")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textSecondary)
                }

                Spacer()
            }
            .padding(12)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }


    // MARK: - ─── Components ─────────────────────────────────────────────────

    private func aboutLink(
        icon: String,
        title: String,
        subtitle: String,
        url: URL
    ) -> some View {
        Link(destination: url) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.accent)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BoothColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textMuted)
            }
            .padding(12)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("About") {
    NavigationStack {
        AboutView()
    }
}
