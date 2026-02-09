// ============================================================================
// ConsolesView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Consoles tab — manage console library, TCP/MIDI connections,
//          CSV import, and delta analysis. Merges former Analysis + Mixer tabs.
//          Phase 5: Full build with Add Console, console detail, snapshot CRUD.
// ============================================================================

import SwiftUI
import TipKit


// MARK: - ─── Consoles View ───────────────────────────────────────────────────

struct ConsolesView: View {
    @ObservedObject var store: ServiceStore
    @ObservedObject var connectionManager: MixerConnectionManager
    @State private var showAddConsole = false
    @State private var editingConsole: ConsoleProfile?
    @State private var deleteConfirmConsole: ConsoleProfile?
    @State private var deleteConfirmSnapshot: MixerSnapshot?
    @State private var showCSVImport = false
    @State private var selectedSnapshot: MixerSnapshot?
    @State private var analysisResult: MixerAnalysis?

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                if store.consoleProfiles.isEmpty && store.savedSnapshots.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // ── Console Library ──
                            consoleLibrarySection

                            // ── Quick Import ──
                            importSection

                            // ── Snapshots ──
                            snapshotsSection
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Consoles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddConsole) {
                AddConsoleSheet(store: store)
            }
            .sheet(item: $editingConsole) { console in
                EditConsoleSheet(store: store, console: console)
            }
            .sheet(isPresented: $showCSVImport) {
                CSVImportSheet(
                    onImport: { snapshot in
                        selectedSnapshot = snapshot
                        store.saveSnapshot(snapshot)
                    }
                )
            }
            .sheet(item: $analysisResult) { analysis in
                AnalysisView(analysis: analysis)
            }
            .alert("Delete Console", isPresented: .init(
                get: { deleteConfirmConsole != nil },
                set: { if !$0 { deleteConfirmConsole = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let console = deleteConfirmConsole {
                        withAnimation { store.deleteConsoleProfile(id: console.id) }
                    }
                }
                Button("Cancel", role: .cancel) { deleteConfirmConsole = nil }
            } message: {
                Text("This will remove the console profile.")
            }
            .alert("Delete Snapshot", isPresented: .init(
                get: { deleteConfirmSnapshot != nil },
                set: { if !$0 { deleteConfirmSnapshot = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let snapshot = deleteConfirmSnapshot {
                        if selectedSnapshot?.id == snapshot.id {
                            selectedSnapshot = nil
                        }
                        withAnimation { store.deleteSnapshot(id: snapshot.id) }
                    }
                }
                Button("Cancel", role: .cancel) { deleteConfirmSnapshot = nil }
            } message: {
                Text("This will permanently remove the snapshot.")
            }
        }
    }


    // MARK: - ─── Empty State ──────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 16) {
            TipView(ConsoleConnectTip())
                .tipBackground(BoothColors.surface)
                .padding(.horizontal, 24)

            Image(systemName: "slider.horizontal.below.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(BoothColors.textMuted)

            Text("No consoles configured")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BoothColors.textPrimary)

            Text("Add your mixer to import settings, connect live, or run delta analysis against engine recommendations.")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showAddConsole = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Console")
                }
                .font(.system(size: 15, weight: .bold))
                .frame(width: 200, height: 48)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    // MARK: - ─── Console Library ──────────────────────────────────────────────

    private var consoleLibrarySection: some View {
        SectionCard(title: "My Consoles (\(store.consoleProfiles.count))") {
            if store.consoleProfiles.isEmpty {
                VStack(spacing: 8) {
                    Text("No consoles added yet")
                        .font(.system(size: 13))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                ForEach(store.consoleProfiles) { profile in
                    consoleRow(profile)
                }
            }

            Button {
                showAddConsole = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Console")
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

    private func consoleRow(_ profile: ConsoleProfile) -> some View {
        VStack(spacing: 0) {
            Button {
                editingConsole = profile
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            // Connection status indicator
                            if profile.connectionType == .tcpMIDI
                                && connectionManager.status.isConnected {
                                Circle()
                                    .fill(BoothColors.accent)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: BoothColors.accent.opacity(0.6), radius: 3)
                            }

                            Text(profile.name.isEmpty ? profile.model.shortName : profile.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(BoothColors.textPrimary)
                            connectionBadge(for: profile)
                        }

                        HStack(spacing: 6) {
                            Text(profile.model.localizedName)
                                .font(.system(size: 11))
                                .foregroundStyle(BoothColors.textSecondary)
                            if let ip = profile.ipAddress, !ip.isEmpty {
                                Text("\u{00B7}")
                                    .foregroundStyle(BoothColors.textMuted)
                                Text(ip)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                            }
                        }

                        // Linked venue/room
                        if let venueID = profile.linkedVenueID, let venue = store.venue(for: venueID) {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 9))
                                Text(venue.name)
                                if let roomID = profile.linkedRoomID, let room = store.room(for: roomID) {
                                    Text("\u{00B7}")
                                    Text(room.name)
                                }
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(BoothColors.textMuted)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.textMuted)
                }
                .padding(10)
            }
            .buttonStyle(.plain)

            // TCP Connect button for TCP-capable consoles
            if profile.connectionType == .tcpMIDI {
                NavigationLink {
                    MixerConnectionView(
                        connectionManager: connectionManager,
                        store: store,
                        initialHost: profile.ipAddress,
                        initialPort: String(profile.port),
                        initialMixer: profile.model
                    )
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "cable.connector")
                            .font(.system(size: 11))
                        Text("Connect Live")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(BoothColors.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(BoothColors.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.bottom, 8)
            }
        }
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button {
                editingConsole = profile
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            if profile.connectionType == .tcpMIDI {
                Button {
                    // Navigate handled by NavigationLink above
                } label: {
                    Label("Connect Live", systemImage: "cable.connector")
                }
            }
            Button(role: .destructive) {
                deleteConfirmConsole = profile
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func connectionBadge(for profile: ConsoleProfile) -> some View {
        Group {
            switch profile.connectionType {
            case .tcpMIDI:
                Text("TCP")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accent)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(BoothColors.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            case .csvOnly:
                Text("CSV")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accentWarm)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(BoothColors.accentWarm.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
    }


    // MARK: - ─── Import Section ───────────────────────────────────────────────

    private var importSection: some View {
        SectionCard(title: "Import") {
            Button {
                showCSVImport = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                    Text("Import CSV File")
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text("Import a CSV export from Allen & Heath Director to compare your current mix against engine recommendations.")
                .font(.system(size: 11))
                .foregroundStyle(BoothColors.textMuted)
        }
    }


    // MARK: - ─── Snapshots ────────────────────────────────────────────────────

    private var snapshotsSection: some View {
        SectionCard(title: "Mixer Snapshots (\(store.savedSnapshots.count))") {
            if store.savedSnapshots.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "camera.metering.unknown")
                        .font(.system(size: 28))
                        .foregroundStyle(BoothColors.textMuted)
                    Text("No snapshots yet. Import a CSV to create one.")
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(store.savedSnapshots) { snapshot in
                    snapshotRow(snapshot)
                }
            }
        }
    }

    private func snapshotRow(_ snapshot: MixerSnapshot) -> some View {
        Button {
            selectedSnapshot = snapshot
            runAnalysis(snapshot)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(snapshot.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.textPrimary)
                        if selectedSnapshot?.id == snapshot.id {
                            Text("SELECTED")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundStyle(BoothColors.accent)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(BoothColors.accent.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        }
                    }
                    HStack(spacing: 6) {
                        Text("\(snapshot.channels.count) channels")
                        Text("\u{00B7}")
                        Text(snapshot.mixer.shortName)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("Analyze")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(BoothColors.accent)
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.accent)
                }
            }
            .padding(10)
            .background(
                selectedSnapshot?.id == snapshot.id
                    ? BoothColors.accent.opacity(0.06)
                    : BoothColors.surfaceElevated
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                deleteConfirmSnapshot = snapshot
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }


    // MARK: - ─── Analysis Logic ───────────────────────────────────────────────

    private func runAnalysis(_ snapshot: MixerSnapshot) {
        // Auto-generate channels from snapshot names for analysis
        let channels = snapshot.channels.compactMap { ch -> InputChannel? in
            guard let source = guessInputSource(from: ch.name) else { return nil }
            return InputChannel(label: ch.name, source: source)
        }

        let service = WorshipService(
            name: "Analysis Service",
            mixer: snapshot.mixer,
            channels: channels,
            setlist: [SetlistSong(title: "Default", key: .G)],
            detailLevel: .full
        )

        let engine = SoundEngine()
        let recommendation = engine.generateRecommendation(for: service)

        var channelMapping: [Int: InputSource] = [:]
        for channel in snapshot.channels {
            if let matched = guessInputSource(from: channel.name) {
                channelMapping[channel.channelNumber] = matched
            }
        }

        let analysisEngine = AnalysisEngine()
        analysisResult = analysisEngine.analyze(
            snapshot: snapshot,
            recommendation: recommendation,
            channelMapping: channelMapping,
            splPreference: store.splPreference
        )
    }

    /// Best-effort matching of channel name to InputSource.
    private func guessInputSource(from name: String) -> InputSource? {
        let lowered = name.lowercased()

        if lowered.contains("kick") { return .kickDrum }
        if lowered.contains("snare") { return .snareDrum }
        if lowered.contains("hat") || lowered.contains("hh") { return .hiHat }
        if lowered.contains("oh") && lowered.contains("l") { return .overheadL }
        if lowered.contains("oh") && lowered.contains("r") { return .overheadR }
        if lowered.contains("overhead") { return .overheadL }
        if lowered.contains("tom") {
            if lowered.contains("floor") || lowered.contains("fl") { return .tomFloor }
            if lowered.contains("hi") { return .tomHigh }
            return .tomMid
        }
        if lowered.contains("lead") && lowered.contains("voc") { return .leadVocal }
        if lowered.contains("bv") || lowered.contains("back") { return .backingVocal }
        if lowered.contains("voc") || lowered.contains("vocal") { return .leadVocal }
        if lowered.contains("keys") || lowered.contains("piano") || lowered.contains("kb") { return .digitalPiano }
        if lowered.contains("e.gtr") || (lowered.contains("elec") && lowered.contains("gtr")) { return .electricGtrModeler }
        if lowered.contains("a.gtr") || (lowered.contains("acou") && lowered.contains("gtr")) { return .acousticGtrDI }
        if lowered.contains("bass") { return .bassGtrDI }
        if lowered.contains("track") { return .tracksLeft }
        if lowered.contains("click") { return .clickTrack }
        if lowered.contains("pastor") || lowered.contains("speak") { return .pastorHandheld }

        return nil
    }
}


// MARK: - ─── Add Console Sheet ───────────────────────────────────────────────

struct AddConsoleSheet: View {
    @ObservedObject var store: ServiceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var model: MixerModel = .allenHeathAvantis
    @State private var connectionType: ConsoleConnectionType = .tcpMIDI
    @State private var ipAddress = ""
    @State private var port = "51325"
    @State private var linkedVenueID: UUID?
    @State private var linkedRoomID: UUID?
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Console Details") {
                            BoothTextField(label: "Name", text: $name, placeholder: "John's Avantis")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("CONSOLE MODEL")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Model", selection: $model) {
                                    ForEach(MixerModel.allCases) { mixer in
                                        Text(mixer.localizedName).tag(mixer)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("CONNECTION TYPE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Connection", selection: $connectionType) {
                                    ForEach(ConsoleConnectionType.allCases) { type in
                                        Text(type.localizedName).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        // TCP/MIDI connection details
                        if connectionType == .tcpMIDI {
                            SectionCard(title: "Connection") {
                                BoothTextField(label: "IP Address", text: $ipAddress, placeholder: "192.168.1.100")
                                BoothTextField(label: "Port", text: $port, placeholder: "51325")
                            }
                        }

                        // Venue/Room link
                        if !store.venues.isEmpty {
                            SectionCard(title: "Location (Optional)") {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("VENUE")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(BoothColors.textMuted)
                                        .tracking(1)
                                    Picker("Venue", selection: $linkedVenueID) {
                                        Text("None").tag(nil as UUID?)
                                        ForEach(store.venues) { venue in
                                            Text(venue.name).tag(venue.id as UUID?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(BoothColors.accent)
                                }

                                if let venueID = linkedVenueID,
                                   let venue = store.venue(for: venueID),
                                   !venue.rooms.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("ROOM")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(BoothColors.textMuted)
                                            .tracking(1)
                                        Picker("Room", selection: $linkedRoomID) {
                                            Text("None").tag(nil as UUID?)
                                            ForEach(venue.rooms) { room in
                                                Text(room.name).tag(room.id as UUID?)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(BoothColors.accent)
                                    }
                                }
                            }
                        }

                        SectionCard(title: "Notes") {
                            BoothTextField(label: "Notes (optional)", text: $notes, placeholder: "Any notes about this console...")
                        }

                        Button {
                            save()
                        } label: {
                            Text("Add Console")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Console")
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
        let profile = ConsoleProfile(
            name: name.isEmpty ? model.shortName : name,
            model: model,
            ipAddress: ipAddress.isEmpty ? nil : ipAddress,
            port: Int(port) ?? 51325,
            connectionType: connectionType,
            linkedVenueID: linkedVenueID,
            linkedRoomID: linkedRoomID,
            notes: notes.isEmpty ? nil : notes
        )
        store.saveConsoleProfile(profile)
        dismiss()
    }
}


// MARK: - ─── Edit Console Sheet ──────────────────────────────────────────────

struct EditConsoleSheet: View {
    @ObservedObject var store: ServiceStore
    let console: ConsoleProfile
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var model: MixerModel
    @State private var connectionType: ConsoleConnectionType
    @State private var ipAddress: String
    @State private var port: String
    @State private var linkedVenueID: UUID?
    @State private var linkedRoomID: UUID?
    @State private var notes: String

    init(store: ServiceStore, console: ConsoleProfile) {
        self.store = store
        self.console = console
        _name = State(initialValue: console.name)
        _model = State(initialValue: console.model)
        _connectionType = State(initialValue: console.connectionType)
        _ipAddress = State(initialValue: console.ipAddress ?? "")
        _port = State(initialValue: String(console.port))
        _linkedVenueID = State(initialValue: console.linkedVenueID)
        _linkedRoomID = State(initialValue: console.linkedRoomID)
        _notes = State(initialValue: console.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Console Details") {
                            BoothTextField(label: "Name", text: $name, placeholder: "John's Avantis")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("CONSOLE MODEL")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Model", selection: $model) {
                                    ForEach(MixerModel.allCases) { mixer in
                                        Text(mixer.localizedName).tag(mixer)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("CONNECTION TYPE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Connection", selection: $connectionType) {
                                    ForEach(ConsoleConnectionType.allCases) { type in
                                        Text(type.localizedName).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        if connectionType == .tcpMIDI {
                            SectionCard(title: "Connection") {
                                BoothTextField(label: "IP Address", text: $ipAddress, placeholder: "192.168.1.100")
                                BoothTextField(label: "Port", text: $port, placeholder: "51325")
                            }
                        }

                        if !store.venues.isEmpty {
                            SectionCard(title: "Location") {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("VENUE")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(BoothColors.textMuted)
                                        .tracking(1)
                                    Picker("Venue", selection: $linkedVenueID) {
                                        Text("None").tag(nil as UUID?)
                                        ForEach(store.venues) { venue in
                                            Text(venue.name).tag(venue.id as UUID?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(BoothColors.accent)
                                }

                                if let venueID = linkedVenueID,
                                   let venue = store.venue(for: venueID),
                                   !venue.rooms.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("ROOM")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(BoothColors.textMuted)
                                            .tracking(1)
                                        Picker("Room", selection: $linkedRoomID) {
                                            Text("None").tag(nil as UUID?)
                                            ForEach(venue.rooms) { room in
                                                Text(room.name).tag(room.id as UUID?)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(BoothColors.accent)
                                    }
                                }
                            }
                        }

                        SectionCard(title: "Notes") {
                            BoothTextField(label: "Notes", text: $notes, placeholder: "Any notes about this console...")
                        }

                        // Console specs (read-only)
                        SectionCard(title: "Specs") {
                            HStack(spacing: 12) {
                                InfoBadge(label: "Gain", value: "\(Int(model.gainRange.lowerBound))–\(Int(model.gainRange.upperBound)) dB")
                                InfoBadge(label: "EQ Bands", value: "\(model.eqBandCount)")
                                InfoBadge(label: "Port", value: "\(console.port)")
                            }
                        }

                        Button {
                            save()
                        } label: {
                            Text("Save Changes")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Console")
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
        var updated = console
        updated.name = name
        updated.model = model
        updated.connectionType = connectionType
        updated.ipAddress = ipAddress.isEmpty ? nil : ipAddress
        updated.port = Int(port) ?? 51325
        updated.linkedVenueID = linkedVenueID
        updated.linkedRoomID = linkedRoomID
        updated.notes = notes.isEmpty ? nil : notes
        store.saveConsoleProfile(updated)
        dismiss()
    }
}
