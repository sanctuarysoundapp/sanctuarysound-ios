// ============================================================================
// SettingsView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Full settings screen with sections for service defaults, appearance,
//          about/mission, donation links, community links, and legal info.
//          Replaces the AboutView toolbar target from the Setup tab.
// ============================================================================

import SwiftUI


// MARK: - ─── Settings View ────────────────────────────────────────────────

struct SettingsView: View {
    @ObservedObject var store: ServiceStore
    @ObservedObject var pcoManager: PlanningCenterManager
    @State private var prefs: UserPreferences = UserPreferences()

    var body: some View {
        ZStack {
            BoothColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ── Service Defaults ──
                    defaultsSection

                    // ── Planning Center ──
                    planningCenterSection

                    // ── Appearance ──
                    appearanceSection

                    // ── About ──
                    aboutSection

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
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear {
            prefs = store.userPreferences
        }
    }


    // MARK: - ─── Service Defaults ─────────────────────────────────────────────

    private var defaultsSection: some View {
        SectionCard(title: "Service Defaults") {
            Text("New services will start with these settings. You can always change them per service.")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textSecondary)
                .lineSpacing(3)

            // ── Console ──
            settingsRow(label: "Console") {
                Picker("Console", selection: $prefs.defaultMixer) {
                    ForEach(MixerModel.allCases) { mixer in
                        Text(mixer.rawValue).tag(mixer)
                    }
                }
                .pickerStyle(.menu)
                .tint(BoothColors.accent)
                .onChange(of: prefs.defaultMixer) { _, _ in savePrefs() }
            }

            // ── Experience Level ──
            settingsRow(label: "Experience Level") {
                Picker("Level", selection: $prefs.defaultExperienceLevel) {
                    ForEach(ExperienceLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(.menu)
                .tint(BoothColors.accent)
                .onChange(of: prefs.defaultExperienceLevel) { _, _ in savePrefs() }
            }

            // ── Band Composition ──
            settingsRow(label: "Band") {
                Picker("Band", selection: $prefs.defaultBandComposition) {
                    ForEach(BandComposition.allCases) { band in
                        Text(band.rawValue).tag(band)
                    }
                }
                .pickerStyle(.menu)
                .tint(BoothColors.accent)
                .onChange(of: prefs.defaultBandComposition) { _, _ in savePrefs() }
            }

            // ── Drum Config ──
            settingsRow(label: "Drums") {
                Picker("Drums", selection: $prefs.defaultDrumConfig) {
                    ForEach(DrumConfiguration.allCases) { config in
                        Text(config.rawValue).tag(config)
                    }
                }
                .pickerStyle(.menu)
                .tint(BoothColors.accent)
                .onChange(of: prefs.defaultDrumConfig) { _, _ in savePrefs() }
            }

            // ── Room Size ──
            settingsRow(label: "Room Size") {
                Picker("Size", selection: $prefs.defaultRoomSize) {
                    ForEach(RoomSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(.menu)
                .tint(BoothColors.accent)
                .onChange(of: prefs.defaultRoomSize) { _, _ in savePrefs() }
            }

            // ── Room Surface ──
            settingsRow(label: "Room Surface") {
                Picker("Surface", selection: $prefs.defaultRoomSurface) {
                    ForEach(RoomSurface.allCases) { surface in
                        Text(surface.rawValue).tag(surface)
                    }
                }
                .pickerStyle(.menu)
                .tint(BoothColors.accent)
                .onChange(of: prefs.defaultRoomSurface) { _, _ in savePrefs() }
            }

            // ── Target SPL ──
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Target SPL")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BoothColors.textPrimary)
                    Spacer()
                    Text("\(Int(prefs.defaultTargetSPL)) dB")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.accent)
                }

                HStack(spacing: 12) {
                    Slider(value: $prefs.defaultTargetSPL, in: 70...100, step: 1)
                        .tint(BoothColors.accent)

                    Stepper("", value: $prefs.defaultTargetSPL, in: 70...100, step: 1)
                        .labelsHidden()
                        .tint(BoothColors.accent)
                }
                .onChange(of: prefs.defaultTargetSPL) { _, _ in savePrefs() }
            }
        }
    }


    // MARK: - ─── Planning Center ────────────────────────────────────────────────

    private var planningCenterSection: some View {
        SectionCard(title: "Planning Center") {
            Text("Connect to Planning Center Online to import setlists and team rosters directly into your services.")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textSecondary)
                .lineSpacing(3)

            HStack(spacing: 12) {
                Image(systemName: pcoManager.client.isAuthenticated
                      ? "checkmark.circle.fill"
                      : "link.badge.plus")
                    .font(.system(size: 16))
                    .foregroundStyle(pcoManager.client.isAuthenticated
                                    ? BoothColors.accent
                                    : BoothColors.textMuted)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pcoManager.client.isAuthenticated ? "Connected" : "Not Connected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BoothColors.textPrimary)
                    Text(pcoManager.client.isAuthenticated
                         ? "Tap to disconnect"
                         : "Sign in to import setlists & teams")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textSecondary)
                }

                Spacer()
            }
            .padding(12)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                if pcoManager.client.isAuthenticated {
                    pcoManager.client.disconnect()
                } else {
                    Task {
                        try? await pcoManager.client.authenticate()
                    }
                }
            } label: {
                Text(pcoManager.client.isAuthenticated ? "Disconnect" : "Connect to Planning Center")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(pcoManager.client.isAuthenticated
                                    ? BoothColors.accentDanger
                                    : BoothColors.background)
                    .background(pcoManager.client.isAuthenticated
                                ? BoothColors.surfaceElevated
                                : BoothColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }


    // MARK: - ─── Appearance ───────────────────────────────────────────────────

    private var appearanceSection: some View {
        SectionCard(title: "Appearance") {
            Text("All themes are dark and booth-friendly — designed for low-light sound booths during live services.")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textSecondary)
                .lineSpacing(3)

            ForEach(ColorThemeID.allCases) { theme in
                themeRow(theme: theme, isSelected: prefs.colorTheme == theme)
            }
        }
    }

    private func themeRow(theme: ColorThemeID, isSelected: Bool) -> some View {
        Button {
            prefs.colorTheme = theme
            savePrefs()
            ThemeProvider.shared.apply(themeID: theme)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: theme.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? BoothColors.accent : BoothColors.textMuted)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BoothColors.textPrimary)
                    Text(theme.description)
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(BoothColors.accent)
                }
            }
            .padding(12)
            .background(isSelected ? BoothColors.surfaceElevated : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }


    // MARK: - ─── About ────────────────────────────────────────────────────────

    private var aboutSection: some View {
        SectionCard(title: "About") {
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
                                startRadius: 20,
                                endRadius: 55
                            )
                        )
                        .frame(width: 90, height: 90)

                    Image("AppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: BoothColors.accent.opacity(0.3), radius: 8)
                }

                Text("SANCTUARYSOUND")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(BoothColors.textPrimary)

                Text("v\(AppConfig.version) (\(AppConfig.buildNumber))")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(maxWidth: .infinity)

            Text(AppConfig.missionStatement)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BoothColors.accent)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(AppConfig.missionDescription)
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textSecondary)
                .lineSpacing(3)
        }
    }


    // MARK: - ─── Support ──────────────────────────────────────────────────────

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

            settingsLink(
                icon: "chevron.left.forwardslash.chevron.right",
                title: "GitHub Sponsors",
                subtitle: "For developer contributions",
                url: AppConfig.githubSponsorsURL
            )
        }
    }


    // MARK: - ─── Community ────────────────────────────────────────────────────

    private var communitySection: some View {
        SectionCard(title: "Community") {
            settingsLink(
                icon: "curlybraces",
                title: "View Source Code",
                subtitle: "Open-source on GitHub",
                url: AppConfig.githubURL
            )

            settingsLink(
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


    // MARK: - ─── Legal ────────────────────────────────────────────────────────

    private var legalSection: some View {
        SectionCard(title: "Legal") {
            settingsLink(
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


    // MARK: - ─── Components ───────────────────────────────────────────────────

    private func settingsRow<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BoothColors.textPrimary)
            Spacer()
            content()
        }
    }

    private func settingsLink(
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

    private func savePrefs() {
        store.updatePreferences(prefs)
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("Settings") {
    NavigationStack {
        SettingsView(store: ServiceStore(), pcoManager: PlanningCenterManager())
    }
}
