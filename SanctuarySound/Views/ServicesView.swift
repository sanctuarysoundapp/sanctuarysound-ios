// ============================================================================
// ServicesView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Services tab — create, edit, import, and manage worship services.
//          Supports venue/room hierarchy for multi-location churches.
//          Phase 3: Full build with venue management, search, service detail.
// ============================================================================

import SwiftUI
import TipKit


// MARK: - ─── Services View ───────────────────────────────────────────────────

struct ServicesView: View {
    @ObservedObject var store: ServiceStore
    @ObservedObject var pcoManager: PlanningCenterManager
    @State private var showNewService = false
    @State private var showAddVenue = false
    @State private var searchText = ""
    @State private var expandedVenueID: UUID?
    @State private var editingVenue: Venue?
    @State private var editingRoom: RoomEditContext?
    @State private var addingRoomToVenueID: UUID?
    @State private var selectedService: WorshipService?
    @State private var deleteConfirmService: WorshipService?
    @State private var deleteConfirmVenue: Venue?
    @State private var deleteConfirmRoom: RoomDeleteContext?

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                if store.savedServices.isEmpty && store.venues.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // ── Quick Actions ──
                            quickActionsSection

                            // ── Recent Services ──
                            if !store.savedServices.isEmpty {
                                recentServicesSection
                            }

                            // ── Venues & Rooms ──
                            venuesSection

                            // ── All Services (searchable) ──
                            if !store.savedServices.isEmpty {
                                allServicesSection
                            }
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showNewService) {
                InputEntryView(store: store, pcoManager: pcoManager)
            }
            .sheet(isPresented: $showAddVenue) {
                AddVenueSheet(store: store)
            }
            .sheet(item: $editingVenue) { venue in
                EditVenueSheet(store: store, venue: venue)
            }
            .sheet(item: $editingRoom) { context in
                EditRoomSheet(store: store, venueID: context.venueID, room: context.room)
            }
            .sheet(item: $addingRoomToVenueID) { venueID in
                AddRoomSheet(store: store, venueID: venueID)
            }
            .sheet(item: $selectedService) { service in
                ServiceDetailView(store: store, service: service, pcoManager: pcoManager)
            }
            .alert("Delete Service", isPresented: .init(
                get: { deleteConfirmService != nil },
                set: { if !$0 { deleteConfirmService = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let service = deleteConfirmService {
                        withAnimation { store.deleteService(id: service.id) }
                    }
                }
                Button("Cancel", role: .cancel) { deleteConfirmService = nil }
            } message: {
                Text("This will permanently remove the service. This cannot be undone.")
            }
            .alert("Delete Venue", isPresented: .init(
                get: { deleteConfirmVenue != nil },
                set: { if !$0 { deleteConfirmVenue = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let venue = deleteConfirmVenue {
                        withAnimation { store.deleteVenue(id: venue.id) }
                    }
                }
                Button("Cancel", role: .cancel) { deleteConfirmVenue = nil }
            } message: {
                Text("This will remove the venue and all its rooms. Services linked to this venue will be unaffected.")
            }
            .alert("Delete Room", isPresented: .init(
                get: { deleteConfirmRoom != nil },
                set: { if !$0 { deleteConfirmRoom = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let context = deleteConfirmRoom {
                        withAnimation { store.deleteRoom(id: context.roomID, fromVenueID: context.venueID) }
                    }
                }
                Button("Cancel", role: .cancel) { deleteConfirmRoom = nil }
            } message: {
                Text("This will remove the room from its venue.")
            }
        }
    }


    // MARK: - ─── Empty State ──────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 16) {
            TipView(CreateServiceTip())
                .tipBackground(BoothColors.surface)
                .padding(.horizontal, 24)

            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundStyle(BoothColors.textMuted)

            Text("No services yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BoothColors.textPrimary)

            Text("Create your first service to get mixer recommendations tailored to your band, room, and setlist.")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showNewService = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Service")
                }
                .font(.system(size: 15, weight: .bold))
                .frame(width: 200, height: 48)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("New Service")
            .accessibilityHint("Opens the service setup wizard")
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    // MARK: - ─── Quick Actions ────────────────────────────────────────────────

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
            .accessibilityLabel("New Service")
            .accessibilityHint("Opens the service setup wizard")

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
                .accessibilityLabel("Duplicate Last Service")
                .accessibilityHint("Creates a copy of \(lastService.name)")
            }

            if pcoManager.client.isAuthenticated {
                Button {
                    showNewService = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                        Text("Import from Planning Center")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .foregroundStyle(BoothColors.accent.opacity(0.9))
                    .background(BoothColors.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel("Import from Planning Center")
                .accessibilityHint("Opens service setup with Planning Center import")
            }
        }
    }


    // MARK: - ─── Recent Services ──────────────────────────────────────────────

    private var recentServicesSection: some View {
        SectionCard(title: "Recent Services") {
            ForEach(store.savedServices.prefix(5)) { service in
                serviceRow(service)
            }
        }
    }


    // MARK: - ─── Venues & Rooms ───────────────────────────────────────────────

    private var venuesSection: some View {
        SectionCard(title: "Venues (\(store.venues.count))") {
            if store.venues.isEmpty {
                emptyVenueState
            } else {
                ForEach(store.venues) { venue in
                    venueCard(venue)
                }
            }

            Button {
                showAddVenue = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                    Text("Add Venue")
                }
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .foregroundStyle(BoothColors.textSecondary)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .accessibilityLabel("Add Venue")
            .accessibilityHint("Opens a form to create a new venue")
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
            Text("Add your church or venue to organize rooms and services.")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func venueCard(_ venue: Venue) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Venue header (tappable to expand)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedVenueID = expandedVenueID == venue.id ? nil : venue.id
                }
            } label: {
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
                    Image(systemName: expandedVenueID == venue.id ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(BoothColors.textMuted)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(venue.name), \(venue.rooms.count) room\(venue.rooms.count == 1 ? "" : "s")")
            .accessibilityHint(expandedVenueID == venue.id ? "Collapse rooms" : "Expand rooms")

            // Expanded room list
            if expandedVenueID == venue.id {
                VStack(spacing: 4) {
                    ForEach(venue.rooms) { room in
                        roomRow(room, venueID: venue.id)
                    }

                    // Add Room button
                    Button {
                        addingRoomToVenueID = venue.id
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10))
                            Text("Add Room")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(BoothColors.accent.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(BoothColors.accent.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .accessibilityLabel("Add Room to \(venue.name)")
                    .padding(.leading, 24)
                    .padding(.top, 2)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button {
                editingVenue = venue
            } label: {
                Label("Edit Venue", systemImage: "pencil")
            }
            Button(role: .destructive) {
                deleteConfirmVenue = venue
            } label: {
                Label("Delete Venue", systemImage: "trash")
            }
        }
    }

    private func roomRow(_ room: Room, venueID: UUID) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "door.left.hand.open")
                .font(.system(size: 10))
                .foregroundStyle(BoothColors.textMuted)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(room.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BoothColors.textSecondary)
                HStack(spacing: 4) {
                    Text(roomSizeShort(room.roomSize))
                    Text("\u{00B7}")
                    Text(roomSurfaceShort(room.roomSurface))
                }
                .font(.system(size: 9))
                .foregroundStyle(BoothColors.textMuted)
            }
            Spacer()
            if let mixer = room.defaultMixer {
                Text(mixer.shortName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(BoothColors.accent.opacity(0.7))
            }
        }
        .padding(.leading, 24)
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(room.name), \(roomSizeShort(room.roomSize)), \(roomSurfaceShort(room.roomSurface))\(room.defaultMixer.map { ", \($0.shortName)" } ?? "")")
        .contextMenu {
            Button {
                editingRoom = RoomEditContext(venueID: venueID, room: room)
            } label: {
                Label("Edit Room", systemImage: "pencil")
            }
            Button(role: .destructive) {
                deleteConfirmRoom = RoomDeleteContext(venueID: venueID, roomID: room.id)
            } label: {
                Label("Delete Room", systemImage: "trash")
            }
        }
    }


    // MARK: - ─── All Services (Searchable) ────────────────────────────────────

    private var allServicesSection: some View {
        SectionCard(title: "All Services (\(store.savedServices.count))") {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.textMuted)
                TextField("Search services...", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.textPrimary)
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel("Search services")
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(BoothColors.textMuted)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(10)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Filtered service list
            let filtered = filteredServices
            if filtered.isEmpty {
                VStack(spacing: 4) {
                    Text("No matching services")
                        .font(.system(size: 13))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                ForEach(filtered) { service in
                    serviceRow(service)
                }
            }
        }
    }

    private var filteredServices: [WorshipService] {
        guard !searchText.isEmpty else { return store.savedServices }
        let lowered = searchText.lowercased()
        return store.savedServices.filter { service in
            service.name.localizedCaseInsensitiveContains(lowered) ||
            service.mixer.shortName.localizedCaseInsensitiveContains(lowered) ||
            venueName(for: service).localizedCaseInsensitiveContains(lowered)
        }
    }


    // MARK: - ─── Row Components ───────────────────────────────────────────────

    private func serviceRow(_ service: WorshipService) -> some View {
        Button {
            selectedService = service
        } label: {
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
                        if !venueName(for: service).isEmpty {
                            Text("\u{00B7}")
                            Text(venueName(for: service))
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatDate(service.date))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(BoothColors.textMuted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(BoothColors.textMuted)
                }
            }
            .padding(10)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(service.name), \(service.channels.count) channels, \(service.mixer.shortName), \(service.setlist.count) songs")
        .accessibilityHint("Opens service details")
        .contextMenu {
            Button {
                duplicateService(service)
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            Button(role: .destructive) {
                deleteConfirmService = service
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }


    // MARK: - ─── Helpers ──────────────────────────────────────────────────────

    private func duplicateService(_ service: WorshipService) {
        let duplicate = WorshipService(
            name: service.name + " (Copy)",
            date: Date(),
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
        AppDateFormatter.shortDate.string(from: date)
    }

    private func venueName(for service: WorshipService) -> String {
        guard let venueID = service.venueID,
              let venue = store.venue(for: venueID) else { return "" }
        if let roomID = service.roomID, let room = store.room(for: roomID) {
            return "\(venue.name) — \(room.name)"
        }
        return venue.name
    }

    private func roomSizeShort(_ size: RoomSize) -> String {
        switch size {
        case .small:  return "Small"
        case .medium: return "Medium"
        case .large:  return "Large"
        }
    }

    private func roomSurfaceShort(_ surface: RoomSurface) -> String {
        switch surface {
        case .absorbent:  return "Absorb"
        case .reflective: return "Reflect"
        case .mixed:      return "Mixed"
        }
    }
}


// MARK: - ─── Supporting Context Types ─────────────────────────────────────

/// Context for editing a room within a specific venue.
struct RoomEditContext: Identifiable {
    let id = UUID()
    let venueID: UUID
    let room: Room
}

/// Context for deleting a room from a specific venue.
struct RoomDeleteContext {
    let venueID: UUID
    let roomID: UUID
}

/// Wrapper to make UUID Identifiable for `.sheet(item:)`.
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}


