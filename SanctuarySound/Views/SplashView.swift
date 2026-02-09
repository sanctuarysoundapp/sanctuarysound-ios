// ============================================================================
// SplashView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Animated launch screen displayed on app startup. Shows the app
//          icon with scaling + glow animation, VU-meter equalizer bars, tagline,
//          and brand text before transitioning to the main HomeView.
// ============================================================================

import SwiftUI


// MARK: - ─── Splash View ──────────────────────────────────────────────────

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var backgroundPulseScale: CGFloat = 1.0
    @State private var titleOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 20.0
    @State private var taglineOpacity: Double = 0.0
    @State private var taglineOffset: CGFloat = 15.0
    @State private var subtitleOpacity: Double = 0.0
    @State private var subtitleOffset: CGFloat = 12.0
    @State private var barsAnimating = false

    /// Bar count for the equalizer animation.
    private let barCount = 15

    var body: some View {
        ZStack {
            BoothColors.background
                .ignoresSafeArea()

            // ── Subtle Background Pulse ──
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            BoothColors.accent.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .scaleEffect(backgroundPulseScale)
                .opacity(glowOpacity)

            VStack(spacing: 0) {
                Spacer()

                // ── App Icon with Glow ──
                ZStack {
                    // Glow ring behind icon
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    BoothColors.accent.opacity(0.3),
                                    BoothColors.accent.opacity(0.0)
                                ],
                                center: .center,
                                startRadius: 60,
                                endRadius: 150
                            )
                        )
                        .frame(width: 280, height: 280)
                        .opacity(glowOpacity)

                    Image("AppIconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                        .shadow(color: BoothColors.accent.opacity(0.4), radius: 30)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                // ── Brand Text ──
                VStack(spacing: 6) {
                    Text("SANCTUARYSOUND")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .tracking(6)
                        .foregroundStyle(BoothColors.textPrimary)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)

                    Text("Built For The Church, By The Church, Free Forever.")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(BoothColors.accent)
                        .minimumScaleFactor(0.8)
                        .opacity(taglineOpacity)
                        .offset(y: taglineOffset)

                    Text("Virtual Audio Director")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(BoothColors.textSecondary)
                        .opacity(subtitleOpacity)
                        .offset(y: subtitleOffset)
                }
                .padding(.top, 28)

                Spacer()

                // ── Animated VU-Meter Equalizer Bars ──
                equalizerBars
                    .padding(.bottom, 50)
            }
        }
        .onAppear { startAnimationSequence() }
    }


    // MARK: - Equalizer Bars

    private var equalizerBars: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                EqualizerBar(
                    isAnimating: barsAnimating,
                    delay: Double(index) * 0.05,
                    profile: barProfile(for: index)
                )
            }
        }
        .frame(height: 70)
    }

    private func barProfile(for index: Int) -> EqualizerBar.BarProfile {
        switch index {
        case 5...9:       return .center
        case 3...4, 10...11: return .mid
        default:          return .edge
        }
    }


    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Phase 1: Icon scales up + fades in (spring bounce)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.55, blendDuration: 0)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // Phase 2: Glow blooms + background pulse starts
        withAnimation(.easeOut(duration: 0.55).delay(0.25)) {
            glowOpacity = 1.0
        }
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
            .delay(0.25)
        ) {
            backgroundPulseScale = 1.15
        }

        // Phase 3: Title slides up + fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            titleOpacity = 1.0
            titleOffset = 0.0
        }

        // Phase 4: Tagline slides up + fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            taglineOpacity = 1.0
            taglineOffset = 0.0
        }

        // Phase 5: Subtitle slides up + fades in
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0.0
        }

        // Phase 6: Equalizer bars start bouncing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            barsAnimating = true
        }
    }
}


// MARK: - ─── Equalizer Bar ────────────────────────────────────────────────

/// A single animated bar in the VU-meter equalizer visualization.
/// Uses a green→amber→red gradient to mimic a real LED meter stack.
private struct EqualizerBar: View {
    let isAnimating: Bool
    let delay: Double
    let profile: BarProfile

    @State private var barHeight: CGFloat = 4.0

    /// Controls height range based on position in the spectrum.
    /// Center bars (midrange) trend taller, edge bars (sub/air) shorter.
    enum BarProfile {
        case center  // indices 5-9
        case mid     // indices 3-4, 10-11
        case edge    // indices 0-2, 12-14

        var heightRange: ClosedRange<CGFloat> {
            switch self {
            case .center: return 35...60
            case .mid:    return 20...50
            case .edge:   return 12...40
            }
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(barGradient)
            .frame(width: 6, height: barHeight)
            .onChange(of: isAnimating) { _, animating in
                guard animating else { return }
                powerOnThenLoop()
            }
    }

    private var barGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: BoothColors.accent, location: 0.0),
                .init(color: BoothColors.accent, location: 0.5),
                .init(color: BoothColors.accentWarm, location: 0.75),
                .init(color: BoothColors.accentDanger, location: 1.0)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    /// Two-phase animation: quick power-on rise, then continuous loop.
    private func powerOnThenLoop() {
        // Phase 1: Quick rise to initial position
        let initialHeight = CGFloat.random(in: profile.heightRange)
        withAnimation(.easeOut(duration: 0.3).delay(delay)) {
            barHeight = initialHeight
        }

        // Phase 2: Continuous randomized bounce
        let loopDelay = delay + 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + loopDelay) {
            let loopDuration = 0.35 + Double.random(in: 0.0...0.25)
            withAnimation(
                .easeInOut(duration: loopDuration)
                .repeatForever(autoreverses: true)
            ) {
                barHeight = CGFloat.random(in: profile.heightRange)
            }
        }
    }
}


// MARK: - ─── Root View (Splash → Onboarding → Home Transition) ───────────

/// Wraps the splash animation, onboarding flow, and main content
/// with crossfade transitions.
struct RootView: View {
    @State private var showSplash = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var themeProvider = ThemeProvider.shared
    @StateObject private var store = ServiceStore()

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(2)
            } else if !hasSeenOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding, store: store)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                HomeView(store: store)
                    .transition(.opacity)
            }
        }
        .environmentObject(themeProvider)
        .onAppear {
            // Activate WatchConnectivity session
            WatchSessionManager.shared.activate()

            // Dismiss splash after the animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("Splash Screen") {
    SplashView()
}

#Preview("Root View") {
    RootView()
}
