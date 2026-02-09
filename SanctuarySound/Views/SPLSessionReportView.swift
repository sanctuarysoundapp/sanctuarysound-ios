// ============================================================================
// SPLSessionReportView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Post-service SPL report display with grade card, summary stats,
//          breach timeline, and shareable image export. Uses grade/format
//          helpers from the SPLSessionReport extension (SPLReportFormatting).
// ============================================================================

import SwiftUI
import UIKit


// MARK: - ─── SPL Session Report View ─────────────────────────────────────────

/// Post-service report showing SPL behavior, breach events, and overall grade.
struct SPLSessionReportView: View {
    let report: SPLSessionReport
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: UIImage?
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Grade Card ──
                        gradeCard

                        // ── Summary Stats ──
                        summarySection

                        // ── Breach Timeline ──
                        if !report.breachEvents.isEmpty {
                            breachListSection
                        }

                        // ── Share Button ──
                        shareSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Service Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(BoothColors.accent)
                }
                ToolbarItem(placement: .primaryAction) {
                    if let image = renderedImage {
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview(
                                "SPL Report — \(report.formatSessionDate())",
                                image: Image(uiImage: image)
                            )
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(BoothColors.accent)
                        }
                    } else {
                        Button {
                            renderReportImage()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(BoothColors.accent)
                        }
                    }
                }
            }
            .onAppear {
                renderReportImage()
            }
        }
    }

    // MARK: - Image Rendering

    /// Renders the report content as a shareable PNG image using ImageRenderer.
    private func renderReportImage() {
        guard !isRendering else { return }
        isRendering = true

        let reportContent = ReportExportView(report: report)

        Task { @MainActor in
            let renderer = ImageRenderer(content: reportContent)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                renderedImage = uiImage
            }
            isRendering = false
        }
    }


    // MARK: - Share Section

    private var shareSection: some View {
        VStack(spacing: 12) {
            if let image = renderedImage {
                ShareLink(
                    item: Image(uiImage: image),
                    preview: SharePreview(
                        "SPL Report — \(report.formatSessionDate())",
                        image: Image(uiImage: image)
                    )
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Report as Image")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(BoothColors.background)
                    .background(BoothColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                Button {
                    renderReportImage()
                } label: {
                    HStack(spacing: 8) {
                        if isRendering {
                            ProgressView()
                                .tint(BoothColors.background)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "photo")
                        }
                        Text(isRendering ? "Rendering..." : "Prepare Shareable Image")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .foregroundStyle(BoothColors.textPrimary)
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isRendering)
            }

            Text("Exports the report as a shareable image — send via Messages, email, or save to Photos.")
                .font(.system(size: 10))
                .foregroundStyle(BoothColors.textMuted)
                .multilineTextAlignment(.center)
        }
    }


    // MARK: - Grade Card

    private var gradeCard: some View {
        VStack(spacing: 12) {
            Text(report.gradeEmoji)
                .font(.system(size: 48))

            Text(report.gradeLabel)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(report.gradeColor)

            Text(report.gradeSummary)
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)

            // Date/time
            Text(report.formatSessionDate())
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(report.gradeColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(report.gradeColor.opacity(0.2), lineWidth: 1)
        )
    }


    // MARK: - Summary Section

    private var summarySection: some View {
        SectionCard(title: "Session Summary") {
            // ── Row 1: Key stats ──
            HStack(spacing: 8) {
                ReportStatBadge(
                    label: "Duration",
                    value: report.formatDuration(report.totalMonitoringSeconds),
                    color: BoothColors.textPrimary
                )
                ReportStatBadge(
                    label: "Target",
                    value: "\(Int(report.targetDB)) dB",
                    color: BoothColors.accent
                )
                ReportStatBadge(
                    label: "Mode",
                    value: report.flaggingMode.localizedName,
                    color: BoothColors.accentWarm
                )
            }

            // ── Row 2: Levels ──
            HStack(spacing: 8) {
                ReportStatBadge(
                    label: "Peak",
                    value: "\(Int(report.overallPeakDB)) dB",
                    color: report.overallPeakDB > report.targetDB
                        ? BoothColors.accentDanger
                        : BoothColors.accent
                )
                ReportStatBadge(
                    label: "Average",
                    value: "\(Int(report.overallAverageDB)) dB",
                    color: BoothColors.textPrimary
                )
                ReportStatBadge(
                    label: "Breaches",
                    value: "\(report.breachCount)",
                    color: report.breachCount > 0
                        ? BoothColors.accentWarm
                        : BoothColors.accent
                )
            }

            // ── Row 3: Breach stats (if any) ──
            if report.breachCount > 0 {
                HStack(spacing: 8) {
                    ReportStatBadge(
                        label: "Over Target",
                        value: String(format: "%.0f%%", report.breachPercentage),
                        color: BoothColors.accentDanger
                    )
                    ReportStatBadge(
                        label: "Longest",
                        value: report.formatDuration(report.longestBreachSeconds),
                        color: BoothColors.accentWarm
                    )
                    ReportStatBadge(
                        label: "Danger",
                        value: "\(report.dangerCount)",
                        color: report.dangerCount > 0
                            ? BoothColors.accentDanger
                            : BoothColors.accent
                    )
                }
            }
        }
    }


    // MARK: - Breach List

    private var breachListSection: some View {
        SectionCard(title: "Breach Events (\(report.breachCount))") {
            ForEach(report.breachEvents) { event in
                HStack(spacing: 12) {
                    // Severity indicator
                    Circle()
                        .fill(event.wasDanger ? BoothColors.accentDanger : BoothColors.accentWarm)
                        .frame(width: 8, height: 8)

                    // Time
                    Text(report.formatTime(event.startTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(BoothColors.textSecondary)
                        .frame(width: 70, alignment: .leading)

                    // Peak
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Peak \(Int(event.peakDB)) dB")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(event.wasDanger ? BoothColors.accentDanger : BoothColors.accentWarm)
                        Text("+\(Int(event.overTargetDB)) dB over · \(report.formatDuration(event.durationSeconds))")
                            .font(.system(size: 10))
                            .foregroundStyle(BoothColors.textMuted)
                    }

                    Spacer()
                }
                .padding(8)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}


// MARK: - ─── Report Stat Badge ───────────────────────────────────────────────

struct ReportStatBadge: View {
    let label: String
    let value: String
    var color: Color = BoothColors.textPrimary

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(BoothColors.textMuted)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
