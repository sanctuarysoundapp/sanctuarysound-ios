// ============================================================================
// SettingsView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Full settings screen with sections for about/mission, service
//          defaults, appearance, data management, community, and donation.
// ============================================================================

import SwiftUI


// MARK: - ─── Settings View ────────────────────────────────────────────────

struct SettingsView: View {
    @ObservedObject var store: ServiceStore
    @ObservedObject var pcoManager: PlanningCenterManager
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var prefs: UserPreferences = UserPreferences()
    @State private var showClearDataAlert = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── About & Support ──
                        aboutSupportSection

                        // ── Service Defaults ──
                        consoleSection
                        bandRoomSection
                        splTargetSection

                        // ── Integrations ──
                        planningCenterSection

                        // ── Appearance ──
                        appearanceSection

                        // ── Data Management ──
                        dataManagementSection

                        // ── Community & Open Source ──
                        communitySection
                }
                .padding()
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            prefs = store.userPreferences
        }
    }


    // MARK: - ─── About & Support ────────────────────────────────────────────

    private var aboutSupportSection: some View {
        SectionCard(title: "About & Support") {
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

                    Image("AppIconImage")
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
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(AppConfig.missionDescription)
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textSecondary)
                .lineSpacing(3)

            Text("No data collected, ever.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(BoothColors.textMuted)

            // ── Hero Donation CTA ──
            Link(destination: AppConfig.donationURL) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                    Text("Support This Ministry")
                }
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Support This Ministry")
            .accessibilityHint("Opens donation page")

            settingsLink(
                icon: "chevron.left.forwardslash.chevron.right",
                title: "GitHub Sponsors",
                subtitle: "For developer contributions",
                url: AppConfig.githubSponsorsURL
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
                message: Text("Check out SanctuarySound — a free, open-source app that calculates mixer settings for church production & worship teams.")
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


    // MARK: - ─── Console & Detail Level ───────────────────────────────────────

    private var consoleSection: some View {
        SectionCard(title: "Console & Detail Level") {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                pickerCell(label: "Console") {
                    Picker("Console", selection: $prefs.defaultMixer) {
                        ForEach(MixerModel.allCases) { mixer in
                            Text(mixer.localizedName).tag(mixer)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)
                    .onChange(of: prefs.defaultMixer) { _, _ in savePrefs() }
                }

                pickerCell(label: "Level") {
                    Picker("Level", selection: $prefs.defaultDetailLevel) {
                        ForEach(DetailLevel.allCases) { level in
                            Text(level.localizedName).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)
                    .onChange(of: prefs.defaultDetailLevel) { _, _ in savePrefs() }
                }
            }
        }
    }


    // MARK: - ─── Band & Room ────────────────────────────────────────────────

    private var bandRoomSection: some View {
        SectionCard(title: "Band & Room") {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                // ── Band Composition ──
                pickerCell(label: "Band") {
                    Picker("Band", selection: $prefs.defaultBandComposition) {
                        ForEach(BandComposition.allCases) { band in
                            Text(band.localizedName).tag(band)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)
                    .onChange(of: prefs.defaultBandComposition) { _, _ in savePrefs() }
                }

                // ── Drum Config ──
                pickerCell(label: "Drums") {
                    Picker("Drums", selection: $prefs.defaultDrumConfig) {
                        ForEach(DrumConfiguration.allCases) { config in
                            Text(config.localizedName).tag(config)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)
                    .onChange(of: prefs.defaultDrumConfig) { _, _ in savePrefs() }
                }

                // ── Room Size ──
                pickerCell(label: "Size") {
                    Picker("Size", selection: $prefs.defaultRoomSize) {
                        ForEach(RoomSize.allCases) { size in
                            Text(size.localizedName).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)
                    .onChange(of: prefs.defaultRoomSize) { _, _ in savePrefs() }
                }

                // ── Room Surface ──
                pickerCell(label: "Surfaces") {
                    Picker("Surface", selection: $prefs.defaultRoomSurface) {
                        ForEach(RoomSurface.allCases) { surface in
                            Text(surface.localizedName).tag(surface)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)
                    .onChange(of: prefs.defaultRoomSurface) { _, _ in savePrefs() }
                }
            }
        }
    }


    // MARK: - ─── SPL Target ─────────────────────────────────────────────────

    private var splTargetSection: some View {
        SectionCard(title: "SPL Target") {
            Text("Preferred maximum SPL during the loudest moments of worship.")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textSecondary)
                .lineSpacing(3)

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
                        .accessibilityLabel("Target SPL")
                        .accessibilityValue("\(Int(prefs.defaultTargetSPL)) dB")

                    Stepper("", value: $prefs.defaultTargetSPL, in: 70...100, step: 1)
                        .labelsHidden()
                        .tint(BoothColors.accent)
                        .accessibilityLabel("Adjust target SPL")
                        .accessibilityValue("\(Int(prefs.defaultTargetSPL)) dB")
                }
                .onChange(of: prefs.defaultTargetSPL) { _, _ in savePrefs() }
            }
        }
    }


    // MARK: - ─── Planning Center ────────────────────────────────────────────

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
            .accessibilityLabel(pcoManager.client.isAuthenticated ? "Disconnect from Planning Center" : "Connect to Planning Center")
            .accessibilityHint(pcoManager.client.isAuthenticated ? "Signs out of Planning Center" : "Signs in to import setlists and teams")
        }
    }


    // MARK: - ─── Appearance ─────────────────────────────────────────────────

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
                    Text(theme.localizedName)
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
        .accessibilityLabel("\(theme.localizedName) theme")
        .accessibilityHint(theme.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }


    // MARK: - ─── Data Management ──────────────────────────────────────────────

    private var dataManagementSection: some View {
        SectionCard(title: "Data Management") {
            VStack(spacing: 8) {
                dataRow(label: "Services", count: store.savedServices.count)
                dataRow(label: "Inputs", count: store.savedInputs.count)
                dataRow(label: "Vocalists", count: store.savedVocalists.count)
                dataRow(label: "Venues", count: store.venues.count)
                dataRow(label: "Consoles", count: store.consoleProfiles.count)
                dataRow(label: "Snapshots", count: store.savedSnapshots.count)
                dataRow(label: "SPL Reports", count: store.savedReports.count)
            }

            Divider()
                .background(BoothColors.divider)

            Button(role: .destructive) {
                showClearDataAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("Clear All Data")
                }
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(BoothColors.accentDanger)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .alert("Clear All Data?", isPresented: $showClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear Everything", role: .destructive) {
                    store.clearAllData()
                    prefs = store.userPreferences
                    ThemeProvider.shared.apply(themeID: prefs.colorTheme)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasSeenOnboarding = false
                    }
                }
            } message: {
                Text("This will permanently delete all services, inputs, vocalists, venues, consoles, snapshots, and SPL reports. You'll be guided through Quick Setup again to reconfigure your defaults. This cannot be undone.")
            }
        }
    }

    private func dataRow(label: String, count: Int) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BoothColors.textPrimary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(count > 0 ? BoothColors.accent : BoothColors.textMuted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(count)")
    }


    // MARK: - ─── Community & Open Source ─────────────────────────────────────

    private var communitySection: some View {
        SectionCard(title: "Community & Open Source") {
            settingsLink(
                icon: "curlybraces",
                title: "View Source Code",
                subtitle: "Open-source on GitHub",
                url: AppConfig.githubURL
            )

            settingsLink(
                icon: "hand.raised.fill",
                title: "Privacy Policy",
                subtitle: "No data collected, ever",
                url: AppConfig.privacyPolicyURL
            )

            settingsLink(
                icon: "doc.text",
                title: "MIT License",
                subtitle: "Free and open-source forever",
                url: AppConfig.licenseURL
            )
        }
    }


    // MARK: - ─── Components ─────────────────────────────────────────────────

    private func pickerCell<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
                .tracking(0.5)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityHint("Opens in browser")
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
