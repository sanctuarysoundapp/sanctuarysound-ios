// ============================================================================
// ToolsView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Tools tab — utility features organized into three sections:
//          Monitoring (SPL Meter), Analysis (EQ, RT60), and Learning (Q&A).
// ============================================================================

import SwiftUI
import TipKit


// MARK: - ─── Tools View ──────────────────────────────────────────────────────

struct ToolsView: View {
    @ObservedObject var store: ServiceStore
    @Binding var splPreference: SPLPreference

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── TipKit Hint ──
                        TipView(SPLMeterTip())
                            .tipBackground(BoothColors.surface)

                        // ── Monitoring ──
                        monitoringSection

                        // ── Analysis ──
                        analysisSection

                        // ── Learning & Development ──
                        learningSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }


    // MARK: - ─── Monitoring ──────────────────────────────────────────────────

    private var monitoringSection: some View {
        SectionCard(title: "Monitoring") {
            NavigationLink {
                SPLCalibrationView(
                    store: store,
                    splMeter: store.splMeter,
                    splPreference: $splPreference,
                    onSave: { pref in store.updateSPLPreference(pref) }
                )
            } label: {
                toolCard(
                    title: "SPL Meter",
                    icon: "speaker.wave.2.fill",
                    description: "Monitor sound levels in real-time with calibration, alerts, and session reports.",
                    accentColor: BoothColors.accent,
                    isActive: store.splMeter.isRunning
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("SPL Meter\(store.splMeter.isRunning ? ", active" : "")")
            .accessibilityHint("Monitor sound levels in real-time with calibration and alerts")
        }
    }


    // MARK: - ─── Analysis ────────────────────────────────────────────────────

    private var analysisSection: some View {
        SectionCard(title: "Analysis") {
            NavigationLink {
                EQAnalyzerView()
            } label: {
                toolCard(
                    title: "EQ Analyzer",
                    icon: "waveform",
                    description: "Real-time 1/3-octave frequency spectrum for room and mix analysis.",
                    accentColor: BoothColors.accent,
                    isActive: false
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("EQ Analyzer")
            .accessibilityHint("Real-time frequency spectrum for room and mix analysis")

            NavigationLink {
                RT60MeasurementView()
            } label: {
                toolCard(
                    title: "Room Acoustics",
                    icon: "building.2",
                    description: "Measure RT60 reverb time using a clap test with your iPhone mic.",
                    accentColor: BoothColors.accent,
                    isActive: false
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Room Acoustics")
            .accessibilityHint("Measure RT60 reverb time using a clap test")
        }
    }


    // MARK: - ─── Learning & Development ──────────────────────────────────────

    private var learningSection: some View {
        SectionCard(title: "Learning & Development") {
            NavigationLink {
                QABrowserView()
            } label: {
                toolCard(
                    title: "Sound Engineer Q&A",
                    icon: "questionmark.bubble",
                    description: "Audio engineering knowledge base with articles on gain staging, EQ, compression, mixer setup, and more.",
                    accentColor: BoothColors.accent,
                    isActive: false
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sound Engineer Q&A")
            .accessibilityHint("Audio engineering knowledge base")
        }
    }


    // MARK: - ─── Tool Card Component ─────────────────────────────────────────

    private func toolCard(
        title: String,
        icon: String,
        description: String,
        accentColor: Color,
        isActive: Bool
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BoothColors.textPrimary)
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(BoothColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textMuted)
        }
        .padding(12)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
