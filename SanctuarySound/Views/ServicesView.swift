// ============================================================================
// ServicesView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Services tab — create, edit, import, and manage worship services.
//          Supports venue/room hierarchy for multi-location churches.
// ============================================================================

import SwiftUI


// MARK: - ─── Services View ───────────────────────────────────────────────────

struct ServicesView: View {
    @ObservedObject var store: ServiceStore
    @ObservedObject var pcoManager: PlanningCenterManager
    @State private var showNewService = false

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Quick Actions ──
                        quickActionsSection

                        // ── Recent Services ──
                        if !store.savedServices.isEmpty {
                            recentServicesSection
                        }

                        // ── Venues ──
                        venuesSection

                        // ── All Services ──
                        if !store.savedServices.isEmpty {
                            allServicesSection
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showNewService) {
                InputEntryView(store: store, pcoManager: pcoManager)
            }
        }
    }


    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        SectionCard(title: "Quick Start") {
            Button {
                showNewService = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Service")
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let lastService = store.savedServices.first {
                Button {
                    duplicateService(lastService)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                        Text("Duplicate Last Service")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .foregroundStyle(BoothColors.textSecondary)
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }


    // MARK: - Recent Services

    private var recentServicesSection: some View {
        SectionCard(title: "Recent Services") {
            ForEach(store.savedServices.prefix(5)) { service in
                serviceRow(service)
            }
        }
    }


    // MARK: - Venues

    private var venuesSection: some View {
        SectionCard(title: "Venues (\(store.venues.count))") {
            if store.venues.isEmpty {
                emptyVenueState
            } else {
                ForEach(store.venues) { venue in
                    venueRow(venue)
                }
            }
        }
    }

    private var emptyVenueState: some View {
        VStack(spacing: 8) {
            Image(systemName: "building.2")
                .font(.system(size: 28))
                .foregroundStyle(BoothColors.textMuted)
            Text("No venues configured")
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }


    // MARK: - All Services

    private var allServicesSection: some View {
        SectionCard(title: "All Services (\(store.savedServices.count))") {
            ForEach(store.savedServices) { service in
                serviceRow(service)
            }
        }
    }


    // MARK: - Row Components

    private func serviceRow(_ service: WorshipService) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                HStack(spacing: 6) {
                    Text("\(service.channels.count) ch")
                    Text("\u{00B7}")
                    Text(service.mixer.shortName)
                    Text("\u{00B7}")
                    Text("\(service.setlist.count) songs")
                }
                .font(.system(size: 11))
                .foregroundStyle(BoothColors.textSecondary)
            }
            Spacer()
            Text(formatDate(service.date))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func venueRow(_ venue: Venue) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "building.2")
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.accent)
                Text(venue.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                Spacer()
                Text("\(venue.rooms.count) room\(venue.rooms.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textMuted)
            }

            ForEach(venue.rooms) { room in
                HStack(spacing: 8) {
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 10))
                        .foregroundStyle(BoothColors.textMuted)
                        .frame(width: 20)
                    Text(room.name)
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.textSecondary)
                    Spacer()
                    if let mixer = room.defaultMixer {
                        Text(mixer.shortName)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(BoothColors.accent.opacity(0.7))
                    }
                }
                .padding(.leading, 24)
            }
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }


    // MARK: - Helpers

    private func duplicateService(_ service: WorshipService) {
        let duplicate = WorshipService(
            name: service.name,
            date: Date(),
            mixer: service.mixer,
            bandComposition: service.bandComposition,
            drumConfig: service.drumConfig,
            room: service.room,
            channels: service.channels,
            setlist: service.setlist,
            experienceLevel: service.experienceLevel,
            venueID: service.venueID,
            roomID: service.roomID,
            consoleProfileID: service.consoleProfileID
        )
        store.saveService(duplicate)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
