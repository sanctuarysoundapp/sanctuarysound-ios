// ============================================================================
// OnboardingView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Five-screen welcome flow shown on first launch. Introduces the
//          app's purpose, explains the workflow, shows the tab tour, lets the
//          user configure quick setup defaults, and transitions to the main app.
// ============================================================================

import SwiftUI


// MARK: - ─── Onboarding View ──────────────────────────────────────────────

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @ObservedObject var store: ServiceStore
    @State private var currentPage = 0

    // Quick Setup state (Screen 4)
    @State private var selectedMixer: MixerModel = .allenHeathAvantis
    @State private var selectedLevel: DetailLevel = .detailed
    @State private var selectedRoomSize: RoomSize = .medium

    private let totalPages = 5

    var body: some View {
        ZStack {
            BoothColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Page Content ──
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    howItWorksPage.tag(1)
                    tabTourPage.tag(2)
                    quickSetupPage.tag(3)
                    getStartedPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // ── Page Indicators ──
                pageIndicators
                    .padding(.bottom, 16)

                // ── Navigation Button ──
                navigationButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }


    // MARK: - ─── Page 1: Welcome ──────────────────────────────────────────

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                BoothColors.accent.opacity(0.25),
                                BoothColors.accent.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 90
                        )
                    )
                    .frame(width: 160, height: 160)

                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: BoothColors.accent.opacity(0.4), radius: 16)
            }

            VStack(spacing: 8) {
                Text("SANCTUARYSOUND")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(BoothColors.textPrimary)

                Text(AppConfig.missionStatement)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(BoothColors.accent)
            }

            Text("Precision mixer settings for every\nSunday service. Open source.\nNo paywalls. Free forever.")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }


    // MARK: - ─── Page 2: How It Works ─────────────────────────────────────

    private var howItWorksPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("HOW IT WORKS")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(BoothColors.textPrimary)

            Text("We do the math. You do the mixing.")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.accent)

            VStack(spacing: 24) {
                workflowStep(
                    icon: "slider.horizontal.3",
                    title: "Configure Your Service",
                    description: "Add your mixer, channels, vocalist profiles, and setlist with musical keys."
                )
                workflowStep(
                    icon: "bolt.fill",
                    title: "Generate Recommendations",
                    description: "The engine calculates gain, EQ, compression, and HPF for every channel."
                )
                workflowStep(
                    icon: "music.mic",
                    title: "Mix with Confidence",
                    description: "Start your service with a solid foundation instead of guessing."
                )
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }


    // MARK: - ─── Page 3: Tab Tour ─────────────────────────────────────────

    private var tabTourPage: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("YOUR WORKSPACE")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(BoothColors.textPrimary)

            Text("Five tabs designed for Sunday mornings")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textSecondary)

            VStack(spacing: 12) {
                tabTourRow(
                    icon: "music.note.list",
                    title: "Services",
                    description: "Plan your Sunday service"
                )
                tabTourRow(
                    icon: "pianokeys",
                    title: "Inputs",
                    description: "Build your channel library"
                )
                tabTourRow(
                    icon: "slider.horizontal.below.rectangle",
                    title: "Consoles",
                    description: "Connect to your mixer"
                )
                tabTourRow(
                    icon: "wrench.and.screwdriver",
                    title: "Tools",
                    description: "Monitor sound levels"
                )
                tabTourRow(
                    icon: "gearshape",
                    title: "Settings",
                    description: "Customize your experience"
                )
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }


    // MARK: - ─── Page 4: Quick Setup ──────────────────────────────────────

    private var quickSetupPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("QUICK SETUP")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(BoothColors.textPrimary)

            Text("Set your defaults — change anytime in Settings")
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                // Console picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR CONSOLE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                        .tracking(1)

                    Menu {
                        ForEach(MixerModel.allCases) { mixer in
                            Button(mixer.shortName) {
                                selectedMixer = mixer
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedMixer.shortName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(BoothColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12))
                                .foregroundStyle(BoothColors.textMuted)
                        }
                        .padding(12)
                        .background(BoothColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Experience level
                VStack(alignment: .leading, spacing: 6) {
                    Text("DETAIL LEVEL")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                        .tracking(1)

                    HStack(spacing: 8) {
                        experienceButton(.essentials, label: "Essentials", icon: "1.circle.fill", color: BoothColors.accent)
                        experienceButton(.detailed, label: "Detailed", icon: "2.circle.fill", color: BoothColors.accentWarm)
                        experienceButton(.full, label: "Full", icon: "3.circle.fill", color: BoothColors.accentDanger)
                    }
                }

                // Room size
                VStack(alignment: .leading, spacing: 6) {
                    Text("ROOM SIZE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                        .tracking(1)

                    HStack(spacing: 8) {
                        roomSizeButton(.small, label: "Small", detail: "<300 seats", icon: "person.2.fill")
                        roomSizeButton(.medium, label: "Medium", detail: "300-800", icon: "person.3.fill")
                        roomSizeButton(.large, label: "Large", detail: "800+", icon: "person.3.sequence.fill")
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }


    // MARK: - ─── Page 5: Get Started ──────────────────────────────────────

    private var getStartedPage: some View {
        VStack(spacing: 32) {
            Spacer()

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
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "waveform.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(BoothColors.accent)
            }

            Text("YOU'RE ALL SET")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(BoothColors.textPrimary)

            Text("Create your first service to get\npersonalized mixer recommendations\ntailored to your setup.")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }


    // MARK: - ─── Components ───────────────────────────────────────────────

    private func workflowStep(
        icon: String,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(BoothColors.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(BoothColors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BoothColors.textPrimary)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(BoothColors.textSecondary)
                    .lineSpacing(2)
            }
            Spacer()
        }
    }

    private func tabTourRow(
        icon: String,
        title: String,
        description: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(BoothColors.accent)
                .frame(width: 36, height: 36)
                .background(BoothColors.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BoothColors.textPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(BoothColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func experienceButton(
        _ level: DetailLevel,
        label: String,
        icon: String,
        color: Color
    ) -> some View {
        Button {
            selectedLevel = level
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(selectedLevel == level ? color : BoothColors.textMuted)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selectedLevel == level ? BoothColors.textPrimary : BoothColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedLevel == level ? color.opacity(0.12) : BoothColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedLevel == level ? color.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func roomSizeButton(
        _ size: RoomSize,
        label: String,
        detail: String,
        icon: String
    ) -> some View {
        Button {
            selectedRoomSize = size
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(selectedRoomSize == size ? BoothColors.accent : BoothColors.textMuted)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(selectedRoomSize == size ? BoothColors.textPrimary : BoothColors.textMuted)
                Text(detail)
                    .font(.system(size: 9))
                    .foregroundStyle(BoothColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selectedRoomSize == size ? BoothColors.accent.opacity(0.12) : BoothColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedRoomSize == size ? BoothColors.accent.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(
                        index == currentPage
                            ? BoothColors.accent
                            : BoothColors.textMuted
                    )
                    .frame(
                        width: index == currentPage ? 8 : 6,
                        height: index == currentPage ? 8 : 6
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    private var navigationButton: some View {
        Button {
            if currentPage < totalPages - 1 {
                withAnimation { currentPage += 1 }
            } else {
                completeOnboarding()
            }
        } label: {
            Text(currentPage < totalPages - 1 ? "Continue" : "Get Started")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }


    // MARK: - ─── Actions ──────────────────────────────────────────────────

    private func completeOnboarding() {
        // Save quick setup choices to user preferences
        var prefs = store.userPreferences
        prefs.defaultMixer = selectedMixer
        prefs.defaultDetailLevel = selectedLevel
        prefs.defaultRoomSize = selectedRoomSize
        store.updatePreferences(prefs)

        // Create default venue + room from selections if none exist
        if store.venues.isEmpty {
            let room = Room(
                id: UUID(),
                name: "Main Room",
                roomSize: selectedRoomSize,
                roomSurface: .mixed,
                defaultMixer: selectedMixer,
                notes: nil
            )
            let venue = Venue(
                id: UUID(),
                name: "My Church",
                address: nil,
                rooms: [room],
                createdAt: Date()
            )
            store.saveVenue(venue)
        }

        // Create default console profile if none exist
        if store.consoleProfiles.isEmpty {
            let console = ConsoleProfile(
                id: UUID(),
                name: selectedMixer.shortName,
                model: selectedMixer,
                ipAddress: nil,
                port: 51325,
                connectionType: .csvOnly,
                linkedVenueID: store.venues.first?.id,
                linkedRoomID: store.venues.first?.rooms.first?.id,
                notes: nil,
                dateAdded: Date()
            )
            store.saveConsoleProfile(console)
        }

        hasSeenOnboarding = true
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("Onboarding") {
    OnboardingView(
        hasSeenOnboarding: .constant(false),
        store: ServiceStore()
    )
}
