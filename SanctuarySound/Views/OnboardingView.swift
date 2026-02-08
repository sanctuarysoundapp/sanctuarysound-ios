// ============================================================================
// OnboardingView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Three-screen welcome flow shown on first launch. Introduces
//          the app's purpose, explains the workflow, and lets the user
//          choose their experience level before entering the main app.
// ============================================================================

import SwiftUI


// MARK: - ─── Onboarding View ──────────────────────────────────────────────

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            BoothColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Page Content ──
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    howItWorksPage.tag(1)
                    getStartedPage.tag(2)
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

                Image("AppIcon")
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

            VStack(spacing: 24) {
                workflowStep(
                    number: "1",
                    icon: "slider.horizontal.3",
                    title: "Set Up Your Service",
                    description: "Add your mixer, channels, vocalist profiles, and setlist with musical keys."
                )
                workflowStep(
                    number: "2",
                    icon: "bolt.fill",
                    title: "Generate Recommendations",
                    description: "The engine calculates gain, EQ, compression, and HPF for every channel."
                )
                workflowStep(
                    number: "3",
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


    // MARK: - ─── Page 3: Get Started ──────────────────────────────────────

    private var getStartedPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("READY TO MIX")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(BoothColors.textPrimary)

            Text("SanctuarySound adapts to your experience level.\nYou can change this anytime in the setup wizard.")
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(spacing: 12) {
                experienceLevelCard(
                    level: "Beginner",
                    description: "Gain & fader positions only — the essentials",
                    icon: "1.circle.fill",
                    color: BoothColors.accent
                )
                experienceLevelCard(
                    level: "Intermediate",
                    description: "Adds EQ curves and high-pass filters",
                    icon: "2.circle.fill",
                    color: BoothColors.accentWarm
                )
                experienceLevelCard(
                    level: "Advanced",
                    description: "Full channel strip with compression and key warnings",
                    icon: "3.circle.fill",
                    color: BoothColors.accentDanger
                )
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }


    // MARK: - ─── Components ───────────────────────────────────────────────

    private func workflowStep(
        number: String,
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

    private func experienceLevelCard(
        level: String,
        description: String,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(level)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BoothColors.textPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(BoothColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
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
            if currentPage < 2 {
                withAnimation { currentPage += 1 }
            } else {
                hasSeenOnboarding = true
            }
        } label: {
            Text(currentPage < 2 ? "Continue" : "Get Started")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("Onboarding") {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
