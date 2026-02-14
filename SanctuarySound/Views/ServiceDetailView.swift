// ============================================================================
// ServiceDetailView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Detail sheet for a saved worship service — summary, channels,
//          setlist, venue info, and actions (re-generate, duplicate).
//          Extracted from ServicesView.swift to keep each file focused.
// ============================================================================

import SwiftUI


// MARK: - ─── Service Detail View ──────────────────────────────────────────

struct ServiceDetailView: View {
    @ObservedObject var store: ServiceStore
    let service: WorshipService
    @ObservedObject var pcoManager: PlanningCenterManager
    @Environment(\.dismiss) private var dismiss
    @State private var showRecommendation = false
    @State private var recommendation: MixerSettingRecommendation?

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Service Summary ──
                        summarySection

                        // ── Channels ──
                        channelsSection

                        // ── Setlist ──
                        setlistSection

                        // ── Venue Info ──
                        if service.venueID != nil {
                            venueInfoSection
                        }

                        // ── Actions ──
                        actionsSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(service.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showRecommendation) {
                if let rec = recommendation {
                    RecommendationDetailView(recommendation: rec)
                }
            }
        }
    }


    // MARK: - Summary

    private var summarySection: some View {
        SectionCard(title: "Service Details") {
            HStack(spacing: 12) {
                InfoBadge(label: "Date", value: formatDate(service.date))
                InfoBadge(label: "Mixer", value: service.mixer.shortName)
                InfoBadge(label: "Level", value: service.detailLevel.shortName)
            }

            HStack(spacing: 12) {
                InfoBadge(label: "Channels", value: "\(service.channels.count)")
                InfoBadge(label: "Songs", value: "\(service.setlist.count)")
                InfoBadge(label: "Room", value: roomSizeShort(service.room.size))
            }
        }
    }

    private func roomSizeShort(_ size: RoomSize) -> String {
        switch size {
        case .small:  return "Small"
        case .medium: return "Med"
        case .large:  return "Large"
        }
    }


    // MARK: - Channels

    private var channelsSection: some View {
        SectionCard(title: "Channels (\(service.channels.count))") {
            if service.channels.isEmpty {
                Text("No channels configured")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textMuted)
            } else {
                ForEach(service.channels) { channel in
                    HStack(spacing: 10) {
                        Image(systemName: channel.source.category.systemIcon)
                            .font(.system(size: 12))
                            .foregroundStyle(BoothColors.accent)
                            .frame(width: 20)
                        Text(channel.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.textPrimary)
                        Spacer()
                        Text(channel.source.isLineLevel ? "LINE" : "MIC")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(channel.source.isLineLevel ? BoothColors.accentWarm : BoothColors.accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background((channel.source.isLineLevel ? BoothColors.accentWarm : BoothColors.accent).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }


    // MARK: - Setlist

    private var setlistSection: some View {
        SectionCard(title: "Setlist (\(service.setlist.count))") {
            if service.setlist.isEmpty {
                Text("No songs in setlist")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textMuted)
            } else {
                ForEach(Array(service.setlist.enumerated()), id: \.element.id) { index, song in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.textMuted)
                            .frame(width: 20)
                        Text(song.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.textPrimary)
                        Spacer()
                        Text(song.key.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BoothColors.accent.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                        if let bpm = song.bpm {
                            Text("\(bpm)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(BoothColors.textMuted)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }


    // MARK: - Venue Info

    private var venueInfoSection: some View {
        SectionCard(title: "Venue") {
            if let venueID = service.venueID, let venue = store.venue(for: venueID) {
                HStack(spacing: 8) {
                    Image(systemName: "building.2")
                        .font(.system(size: 14))
                        .foregroundStyle(BoothColors.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(venue.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(BoothColors.textPrimary)
                        if let roomID = service.roomID, let room = store.room(for: roomID) {
                            Text(room.name)
                                .font(.system(size: 12))
                                .foregroundStyle(BoothColors.textSecondary)
                        }
                    }
                    Spacer()
                }
            }
        }
    }


    // MARK: - Actions

    private var actionsSection: some View {
        SectionCard(title: "Actions") {
            // Re-generate recommendations
            Button {
                regenerate()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Re-Generate Recommendations")
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Re-Generate Recommendations")
            .accessibilityHint("Runs the sound engine to calculate new mixer settings")

            // Duplicate for next Sunday
            Button {
                duplicateForNextSunday()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                    Text("Duplicate for Next Sunday")
                }
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .foregroundStyle(BoothColors.textSecondary)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Duplicate for Next Sunday")
            .accessibilityHint("Creates a copy of this service dated for next Sunday")
        }
    }

    private func regenerate() {
        let engine = SoundEngine()
        recommendation = engine.generateRecommendation(for: service)
        showRecommendation = true
    }

    private func duplicateForNextSunday() {
        let nextSunday = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(weekday: 1),
            matchingPolicy: .nextTime
        ) ?? Date()

        let duplicate = WorshipService(
            name: service.name,
            date: nextSunday,
            mixer: service.mixer,
            bandComposition: service.bandComposition,
            drumConfig: service.drumConfig,
            room: service.room,
            channels: service.channels,
            setlist: service.setlist,
            detailLevel: service.detailLevel,
            venueID: service.venueID,
            roomID: service.roomID,
            consoleProfileID: service.consoleProfileID
        )
        store.saveService(duplicate)
    }

    private func formatDate(_ date: Date) -> String {
        AppDateFormatter.fullDate.string(from: date)
    }
}
