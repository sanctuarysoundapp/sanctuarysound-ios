// ============================================================================
// WatchSplashView.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Brief animated splash screen shown on Watch app launch. Displays
//          the app icon with glow ring animation, brand text, and equalizer
//          bars before transitioning to the SPL dashboard (~1.8s).
// ============================================================================

import SwiftUI


// MARK: - ─── Watch Splash View ────────────────────────────────────────────

struct WatchSplashView: View {
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0.0
    @State private var glowScale: CGFloat = 0.7
    @State private var glowOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var taglineOpacity: Double = 0.0
    @State private var barsAnimating = false

    private let barCount = 7

    var body: some View {
        ZStack {
            WatchColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── App Icon with Glow Ring ──
                ZStack {
                    // Glow stroke ring
                    Circle()
                        .stroke(
                            WatchColors.accent.opacity(0.6),
                            lineWidth: 3
                        )
                        .frame(width: 90, height: 90)
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity)

                    Image("AppIconImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: WatchColors.accent.opacity(0.3), radius: 12)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                // ── Brand Text ──
                VStack(spacing: 3) {
                    Text("SANCTUARYSOUND")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(WatchColors.textPrimary)

                    Text("For The Church")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(WatchColors.accent)
                }
                .opacity(textOpacity)
                .padding(.top, 8)

                Spacer()

                // ── Equalizer Bars ──
                equalizerBars
                    .padding(.bottom, 12)
            }
        }
        .onAppear { startAnimationSequence() }
    }


    // MARK: - Equalizer Bars

    private var equalizerBars: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                WatchEqualizerBar(
                    isAnimating: barsAnimating,
                    delay: Double(index) * 0.04
                )
            }
        }
        .frame(height: 28)
    }


    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Phase 1: Icon springs in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }

        // Phase 2: Glow ring scales up
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            glowScale = 1.0
            glowOpacity = 1.0
        }

        // Phase 3: Brand text fades in
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            textOpacity = 1.0
        }

        // Phase 4: Tagline fades in
        withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
            taglineOpacity = 1.0
        }

        // Phase 5: Bars start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            barsAnimating = true
        }
    }
}


// MARK: - ─── Watch Equalizer Bar ──────────────────────────────────────────

/// A single animated bar for the Watch splash equalizer.
private struct WatchEqualizerBar: View {
    let isAnimating: Bool
    let delay: Double

    @State private var barHeight: CGFloat = 3.0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [
                        WatchColors.accent,
                        WatchColors.accent.opacity(0.4)
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
            .easeInOut(duration: 0.3 + Double.random(in: 0.0...0.2))
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            barHeight = CGFloat.random(in: 6...24)
        }
    }
}
