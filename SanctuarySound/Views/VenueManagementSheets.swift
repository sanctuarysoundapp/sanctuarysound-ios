// ============================================================================
// VenueManagementSheets.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Sheet views for venue and room CRUD — extracted from ServicesView.swift
//          to keep each file focused and under 800 lines.
// ============================================================================

import SwiftUI


// MARK: - ─── Add Venue Sheet ──────────────────────────────────────────────

struct AddVenueSheet: View {
    @ObservedObject var store: ServiceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var address = ""
    @State private var firstRoomName = "Main Room"
    @State private var roomSize: RoomSize = .medium
    @State private var roomSurface: RoomSurface = .mixed
    @State private var defaultMixer: MixerModel = .allenHeathAvantis

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Venue Details") {
                            BoothTextField(label: "Venue Name", text: $name, placeholder: "Main Campus")
                            BoothTextField(label: "Address (optional)", text: $address, placeholder: "123 Church St")
                        }

                        SectionCard(title: "First Room") {
                            BoothTextField(label: "Room Name", text: $firstRoomName, placeholder: "Sanctuary")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("ROOM SIZE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Room Size", selection: $roomSize) {
                                    ForEach(RoomSize.allCases) { size in
                                        Text(size.localizedName).tag(size)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("ROOM SURFACE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Room Surface", selection: $roomSurface) {
                                    ForEach(RoomSurface.allCases) { surface in
                                        Text(surfaceLabel(surface)).tag(surface)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("DEFAULT CONSOLE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Console", selection: $defaultMixer) {
                                    ForEach(MixerModel.allCases) { mixer in
                                        Text(mixer.shortName).tag(mixer)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }
                        }

                        Button {
                            save()
                        } label: {
                            Text("Save Venue")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(name.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func save() {
        let room = Room(
            name: firstRoomName.isEmpty ? "Main Room" : firstRoomName,
            roomSize: roomSize,
            roomSurface: roomSurface,
            defaultMixer: defaultMixer
        )
        let venue = Venue(
            name: name,
            address: address.isEmpty ? nil : address,
            rooms: [room]
        )
        store.saveVenue(venue)
        dismiss()
    }

    private func surfaceLabel(_ surface: RoomSurface) -> String {
        switch surface {
        case .absorbent:  return "Absorbent"
        case .reflective: return "Reflective"
        case .mixed:      return "Mixed"
        }
    }
}


// MARK: - ─── Edit Venue Sheet ─────────────────────────────────────────────

struct EditVenueSheet: View {
    @ObservedObject var store: ServiceStore
    @Environment(\.dismiss) private var dismiss
    let venue: Venue
    @State private var name: String
    @State private var address: String

    init(store: ServiceStore, venue: Venue) {
        self.store = store
        self.venue = venue
        _name = State(initialValue: venue.name)
        _address = State(initialValue: venue.address ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Venue Details") {
                            BoothTextField(label: "Venue Name", text: $name, placeholder: "Main Campus")
                            BoothTextField(label: "Address (optional)", text: $address, placeholder: "123 Church St")
                        }

                        Button {
                            save()
                        } label: {
                            Text("Save Changes")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(name.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func save() {
        var updated = venue
        updated.name = name
        updated.address = address.isEmpty ? nil : address
        store.saveVenue(updated)
        dismiss()
    }
}


// MARK: - ─── Add Room Sheet ───────────────────────────────────────────────

struct AddRoomSheet: View {
    @ObservedObject var store: ServiceStore
    let venueID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var roomSize: RoomSize = .medium
    @State private var roomSurface: RoomSurface = .mixed
    @State private var defaultMixer: MixerModel = .allenHeathAvantis

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Room Details") {
                            BoothTextField(label: "Room Name", text: $name, placeholder: "Sanctuary")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("ROOM SIZE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Room Size", selection: $roomSize) {
                                    ForEach(RoomSize.allCases) { size in
                                        Text(roomSizeLabel(size)).tag(size)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("ROOM SURFACE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Room Surface", selection: $roomSurface) {
                                    ForEach(RoomSurface.allCases) { surface in
                                        Text(roomSurfaceLabel(surface)).tag(surface)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("DEFAULT CONSOLE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Console", selection: $defaultMixer) {
                                    ForEach(MixerModel.allCases) { mixer in
                                        Text(mixer.shortName).tag(mixer)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }
                        }

                        Button {
                            save()
                        } label: {
                            Text("Add Room")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(name.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func save() {
        let room = Room(
            name: name,
            roomSize: roomSize,
            roomSurface: roomSurface,
            defaultMixer: defaultMixer
        )
        store.addRoom(room, toVenueID: venueID)
        dismiss()
    }

    private func roomSizeLabel(_ size: RoomSize) -> String {
        switch size {
        case .small:  return "Small"
        case .medium: return "Medium"
        case .large:  return "Large"
        }
    }

    private func roomSurfaceLabel(_ surface: RoomSurface) -> String {
        switch surface {
        case .absorbent:  return "Absorbent"
        case .reflective: return "Reflective"
        case .mixed:      return "Mixed"
        }
    }
}


// MARK: - ─── Edit Room Sheet ──────────────────────────────────────────────

struct EditRoomSheet: View {
    @ObservedObject var store: ServiceStore
    let venueID: UUID
    let room: Room
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var roomSize: RoomSize
    @State private var roomSurface: RoomSurface
    @State private var defaultMixer: MixerModel
    @State private var notes: String

    init(store: ServiceStore, venueID: UUID, room: Room) {
        self.store = store
        self.venueID = venueID
        self.room = room
        _name = State(initialValue: room.name)
        _roomSize = State(initialValue: room.roomSize)
        _roomSurface = State(initialValue: room.roomSurface)
        _defaultMixer = State(initialValue: room.defaultMixer ?? .allenHeathAvantis)
        _notes = State(initialValue: room.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Room Details") {
                            BoothTextField(label: "Room Name", text: $name, placeholder: "Sanctuary")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("ROOM SIZE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Room Size", selection: $roomSize) {
                                    ForEach(RoomSize.allCases) { size in
                                        Text(roomSizeLabel(size)).tag(size)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("ROOM SURFACE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Room Surface", selection: $roomSurface) {
                                    ForEach(RoomSurface.allCases) { surface in
                                        Text(roomSurfaceLabel(surface)).tag(surface)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("DEFAULT CONSOLE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Console", selection: $defaultMixer) {
                                    ForEach(MixerModel.allCases) { mixer in
                                        Text(mixer.shortName).tag(mixer)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            BoothTextField(label: "Notes (optional)", text: $notes, placeholder: "Any notes about this room...")
                        }

                        Button {
                            save()
                        } label: {
                            Text("Save Changes")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(name.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func save() {
        var updated = room
        updated.name = name
        updated.roomSize = roomSize
        updated.roomSurface = roomSurface
        updated.defaultMixer = defaultMixer
        updated.notes = notes.isEmpty ? nil : notes
        store.updateRoom(updated, inVenueID: venueID)
        dismiss()
    }

    private func roomSizeLabel(_ size: RoomSize) -> String {
        switch size {
        case .small:  return "Small"
        case .medium: return "Medium"
        case .large:  return "Large"
        }
    }

    private func roomSurfaceLabel(_ surface: RoomSurface) -> String {
        switch surface {
        case .absorbent:  return "Absorbent"
        case .reflective: return "Reflective"
        case .mixed:      return "Mixed"
        }
    }
}
