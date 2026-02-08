// ============================================================================
// SplashView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Animated launch screen displayed on app startup. Shows the app
//          icon with scaling + glow animation, sound wave bars, and brand
//          text before transitioning to the main HomeView.
// ============================================================================

import SwiftUI


// MARK: - ─── Splash View ──────────────────────────────────────────────────

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.4
    @State private var iconOpacity: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var titleOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 20.0
    @State private var subtitleOpacity: Double = 0.0
    @State private var subtitleOffset: CGFloat = 15.0
    @State private var barsAnimating = false
    @State private var isFinished = false

    /// Bar count for the equalizer animation.
    private let barCount = 7

    var body: some View {
        ZStack {
            BoothColors.background
                .ignoresSafeArea()

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
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 180, height: 180)
                        .opacity(glowOpacity)

                    Image("AppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: BoothColors.accent.opacity(0.4), radius: 20)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                // ── Brand Text ──
                VStack(spacing: 6) {
                    Text("SANCTUARYSOUND")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(BoothColors.textPrimary)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)

                    Text("Virtual Audio Director")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BoothColors.textSecondary)
                        .opacity(subtitleOpacity)
                        .offset(y: subtitleOffset)
                }
                .padding(.top, 24)

                Spacer()

                // ── Animated Equalizer Bars ──
                equalizerBars
                    .padding(.bottom, 60)
            }
        }
        .onAppear { startAnimationSequence() }
    }


    // MARK: - Equalizer Bars

    private var equalizerBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                EqualizerBar(
                    isAnimating: barsAnimating,
                    delay: Double(index) * 0.08
                )
            }
        }
        .frame(height: 36)
    }


    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Phase 1: Icon scales up + fades in (spring bounce)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6, blendDuration: 0)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // Phase 2: Glow pulses in
        withAnimation(.easeInOut(duration: 0.6).delay(0.3)) {
            glowOpacity = 1.0
        }

        // Phase 3: Title slides up + fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            titleOpacity = 1.0
            titleOffset = 0.0
        }

        // Phase 4: Subtitle follows
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            subtitleOpacity = 1.0
            subtitleOffset = 0.0
        }

        // Phase 5: Equalizer bars start bouncing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            barsAnimating = true
        }

        // Phase 6: Mark finished after total duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isFinished = true
            }
        }
    }
}


// MARK: - ─── Equalizer Bar ────────────────────────────────────────────────

/// A single animated bar in the equalizer visualization.
private struct EqualizerBar: View {
    let isAnimating: Bool
    let delay: Double

    @State private var barHeight: CGFloat = 4.0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [
                        BoothColors.accent,
                        BoothColors.accent.opacity(0.5)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 4, height: barHeight)
            .onChange(of: isAnimating) { _, animating in
                guard animating else { return }
                startBarAnimation()
            }
    }

    private func startBarAnimation() {
        withAnimation(
            .easeInOut(duration: 0.4 + Double.random(in: 0.0...0.3))
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            barHeight = CGFloat.random(in: 12...36)
        }
    }
}


// MARK: - ─── Root View (Splash → Onboarding → Home Transition) ───────────

/// Wraps the splash animation, onboarding flow, and main content
/// with crossfade transitions. Manages app-level purchase state.
struct RootView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showSplash = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(2)
            } else if !hasSeenOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                HomeView()
                    .transition(.opacity)
                    .sheet(isPresented: $purchaseManager.showPaywall) {
                        PaywallView(purchaseManager: purchaseManager)
                    }
            }
        }
        .onAppear {
            // Dismiss splash after the animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
        .task {
            await purchaseManager.loadProducts()
            await purchaseManager.checkEntitlement()
        }
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("Splash Screen") {
    SplashView()
}

#Preview("Root View") {
    RootView()
        .environmentObject(PurchaseManager())
}
