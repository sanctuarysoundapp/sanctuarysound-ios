// ============================================================================
// InputEntryView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: The main service setup screen where volunteers define their
//          Sunday service profile (mixer, band, room, channels, setlist).
// Design: High-contrast, dark-mode-first for use in sound booths.
// ============================================================================

import SwiftUI


// MARK: - ─── Color System (Theme-Driven) ────────────────────────────────

/// Delegates to the active ColorTheme via ThemeProvider.activeColors.
/// All existing BoothColors.xyz references resolve dynamically to the
/// current theme — no call-site changes needed across the codebase.
struct BoothColors {
    static var background:      Color { ThemeProvider.activeColors.background }
    static var surface:         Color { ThemeProvider.activeColors.surface }
    static var surfaceElevated: Color { ThemeProvider.activeColors.surfaceElevated }
    static var accent:          Color { ThemeProvider.activeColors.accent }
    static var accentWarm:      Color { ThemeProvider.activeColors.accentWarm }
    static var accentDanger:    Color { ThemeProvider.activeColors.accentDanger }
    static var textPrimary:     Color { ThemeProvider.activeColors.textPrimary }
    static var textSecondary:   Color { ThemeProvider.activeColors.textSecondary }
    static var textMuted:       Color { ThemeProvider.activeColors.textMuted }
    static var divider:         Color { ThemeProvider.activeColors.divider }
}


// MARK: - ─── Main Entry View ──────────────────────────────────────────────

struct InputEntryView: View {
    @StateObject private var vm = ServiceSetupViewModel()
    @ObservedObject var store: ServiceStore
    @ObservedObject var pcoManager: PlanningCenterManager
    @State private var showPCOFullServiceImport = false

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    StepIndicatorBar(currentStep: vm.currentStep, progress: vm.stepProgress)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    TabView(selection: $vm.currentStep) {
                        BasicsStepView(
                            vm: vm,
                            isPCOAuthenticated: pcoManager.client.isAuthenticated,
                            onImportFromPCO: { showPCOFullServiceImport = true }
                        )
                            .tag(SetupStep.basics)
                        ChannelsStepView(vm: vm, store: store, pcoManager: pcoManager)
                            .tag(SetupStep.channels)
                        SetlistStepView(vm: vm, pcoManager: pcoManager)
                            .tag(SetupStep.setlist)
                        ReviewStepView(vm: vm, store: store)
                            .tag(SetupStep.review)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.25), value: vm.currentStep)

                    StepNavigationBar(vm: vm)
                }
            }
            .navigationTitle("SanctuarySound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView(store: store, pcoManager: pcoManager)
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(BoothColors.textSecondary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                vm.applyDefaults(from: store.userPreferences)
            }
            .sheet(isPresented: $showPCOFullServiceImport) {
                PCOImportSheet(
                    manager: pcoManager,
                    mode: .fullService,
                    venues: store.venues,
                    drumTemplate: store.userPreferences.preferredDrumTemplate,
                    onImportSetlist: { _ in },
                    onImportTeam: { _ in },
                    onImportService: { pcoImport in
                        vm.applyPCOServiceImport(
                            pcoImport,
                            venues: store.venues,
                            consoles: store.consoleProfiles,
                            prefs: store.userPreferences
                        )
                    }
                )
            }
        }
    }
}


// MARK: - ─── Step 1: Basics ──────────────────────────────────────────────

struct BasicsStepView: View {
    @ObservedObject var vm: ServiceSetupViewModel
    var isPCOAuthenticated: Bool = false
    var onImportFromPCO: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // PCO Full Service Import
                if isPCOAuthenticated {
                    Button {
                        onImportFromPCO?()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import from Planning Center")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Songs, team, and service details")
                                    .font(.system(size: 11))
                                    .foregroundStyle(BoothColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(BoothColors.textMuted)
                        }
                        .padding(14)
                        .foregroundStyle(BoothColors.accentWarm)
                        .background(BoothColors.accentWarm.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(BoothColors.accentWarm.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityLabel("Import from Planning Center")
                    .accessibilityHint("Import songs, team, and service details from Planning Center Online")
                }

                SectionCard(title: "Service Info") {
                    BoothTextField(label: "Service Name", text: $vm.service.name, placeholder: "e.g., Sunday 9:30 AM")

                    DatePicker("Date", selection: $vm.service.date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .foregroundStyle(BoothColors.textPrimary)
                        .tint(BoothColors.accent)
                }

                SectionCard(title: "Console") {
                    Picker("Mixer", selection: $vm.service.mixer) {
                        ForEach(MixerModel.allCases) { mixer in
                            Text(mixer.localizedName).tag(mixer)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)

                    HStack {
                        InfoBadge(label: "Gain", value: "\(Int(vm.service.mixer.gainRange.lowerBound))–\(Int(vm.service.mixer.gainRange.upperBound)) dB")
                        InfoBadge(label: "EQ Bands", value: "\(vm.service.mixer.eqBandCount)")
                    }
                }

                SectionCard(title: "Band") {
                    Picker("Composition", selection: $vm.service.bandComposition) {
                        ForEach(BandComposition.allCases) { comp in
                            Text(comp.localizedName).tag(comp)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)

                    Picker("Drum Setup", selection: $vm.service.drumConfig) {
                        ForEach(DrumConfiguration.allCases) { config in
                            Text(config.localizedName).tag(config)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)
                }

                SectionCard(title: "Room Size") {
                    IconPicker(
                        items: [
                            (value: RoomSize.small, icon: "person.2.fill", label: "Small"),
                            (value: RoomSize.medium, icon: "person.3.fill", label: "Medium"),
                            (value: RoomSize.large, icon: "building.2.fill", label: "Large")
                        ],
                        selection: $vm.service.room.size
                    )

                    // Room size detail
                    Text(vm.service.room.size.localizedName)
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Picker("Surfaces", selection: $vm.service.room.surface) {
                        ForEach(RoomSurface.allCases) { surface in
                            Text(surface.localizedName).tag(surface)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BoothColors.accent)

                    HStack {
                        InfoBadge(label: "Est. RT60", value: String(format: "%.1fs", vm.service.room.effectiveRT60))
                        if vm.service.room.hasLowEndProblem {
                            InfoBadge(label: "Warning", value: "Boomy", color: BoothColors.accentWarm)
                        }
                    }
                }

                SectionCard(title: "Detail Level") {
                    IconPicker(
                        items: [
                            (value: DetailLevel.essentials, icon: "lightbulb.fill", label: "Essentials"),
                            (value: DetailLevel.detailed, icon: "slider.horizontal.3", label: "Detailed"),
                            (value: DetailLevel.full, icon: "waveform", label: "Full")
                        ],
                        selection: $vm.service.detailLevel
                    )

                    Text(vm.service.detailLevel.description)
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .padding()
        }
    }
}


// MARK: - ─── Step 2: Input Channels ──────────────────────────────────────

struct ChannelsStepView: View {
    @ObservedObject var vm: ServiceSetupViewModel
    @ObservedObject var store: ServiceStore
    @ObservedObject var pcoManager: PlanningCenterManager
    @State private var showSavedInputs = false
    @State private var showPCOImport = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(vm.activeChannelCount) Channels")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(BoothColors.accent)

                Spacer()

                if pcoManager.client.isAuthenticated {
                    Button {
                        showPCOImport = true
                    } label: {
                        Label("Import", systemImage: "arrow.down.circle")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.accentWarm)
                    }
                    .accessibilityLabel("Import channels from Planning Center")
                }

                if !store.savedInputs.isEmpty {
                    Button {
                        showSavedInputs = true
                    } label: {
                        Label("Library", systemImage: "tray.full.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.accentWarm)
                    }
                    .accessibilityLabel("Open saved inputs library")
                    .padding(.trailing, 12)
                }

                Button {
                    vm.resetChannelDraft()
                    vm.showAddChannel = true
                } label: {
                    Label("Add Input", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BoothColors.accent)
                }
                .accessibilityLabel("Add input channel")
                .accessibilityHint("Opens a sheet to configure a new input channel")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            if vm.service.channels.isEmpty {
                EmptyStateView(
                    icon: "cable.connector",
                    title: "No Inputs Yet",
                    subtitle: "Add your first channel to start building the input list."
                )
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(vm.service.channels.enumerated()), id: \.element.id) { index, channel in
                            VStack(spacing: 0) {
                                ChannelRow(channel: channel)
                                    .padding(.horizontal, 16)

                                // ── Inline action buttons ──
                                HStack(spacing: 0) {
                                    Spacer()
                                    Button {
                                        vm.startEditingChannel(at: index)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(BoothColors.accent)
                                    }
                                    .accessibilityLabel("Edit \(channel.label)")
                                    Spacer()
                                    Divider().frame(height: 14)
                                    Spacer()
                                    Button {
                                        vm.duplicateChannel(at: index)
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(BoothColors.accentWarm)
                                    }
                                    .accessibilityLabel("Duplicate \(channel.label)")
                                    Spacer()
                                    Divider().frame(height: 14)
                                    Spacer()
                                    Button(role: .destructive) {
                                        vm.service.channels.remove(at: index)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(BoothColors.accentDanger)
                                    }
                                    .accessibilityLabel("Remove \(channel.label)")
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .background(BoothColors.surfaceElevated)
                            }
                            .background(BoothColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .sheet(isPresented: $vm.showAddChannel, onDismiss: { vm.editingChannelIndex = nil }) {
            AddChannelSheet(vm: vm)
        }
        .sheet(isPresented: $showSavedInputs) {
            SavedInputsSheet(store: store) { input in
                vm.service.channels.append(input.toInputChannel())
            }
        }
        .sheet(isPresented: $showPCOImport) {
            PCOImportSheet(
                manager: pcoManager,
                mode: .team,
                onImportSetlist: { _ in },
                onImportTeam: { channels in
                    vm.service.channels.append(contentsOf: channels)
                }
            )
        }
    }
}


// MARK: - ─── Saved Inputs Sheet ─────────────────────────────────────────

struct SavedInputsSheet: View {
    @ObservedObject var store: ServiceStore
    var onAdd: (SavedInput) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                if store.savedInputs.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "No Saved Inputs",
                        subtitle: "Inputs are saved automatically when you generate recommendations."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(store.savedInputs) { input in
                                Button {
                                    onAdd(input)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: input.source.category.systemIcon)
                                            .font(.system(size: 16))
                                            .foregroundStyle(BoothColors.accent)
                                            .frame(width: 28)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(input.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(BoothColors.textPrimary)
                                            Text(input.source.localizedName)
                                                .font(.system(size: 11))
                                                .foregroundStyle(BoothColors.textSecondary)
                                        }

                                        Spacer()

                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 18))
                                            .foregroundStyle(BoothColors.accent)
                                    }
                                    .padding(12)
                                    .background(BoothColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Saved Inputs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(BoothColors.accent)
                }
            }
        }
    }
}


// MARK: - ─── Add/Edit Channel Sheet ─────────────────────────────────────

struct AddChannelSheet: View {
    @ObservedObject var vm: ServiceSetupViewModel
    @Environment(\.dismiss) private var dismiss

    private var needsVocalProfile: Bool {
        vm.draftChannelSource.category == .vocals ||
        vm.draftChannelSource.category == .speech
    }

    private var isEditing: Bool { vm.isEditingChannel }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Source Type") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(InputCategory.allCases) { cat in
                                        Button {
                                            vm.selectedChannelCategory = cat
                                            if let first = InputSource.allCases.first(where: { $0.category == cat }) {
                                                vm.draftChannelSource = first
                                            }
                                        } label: {
                                            Label(cat.localizedName, systemImage: cat.systemIcon)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundStyle(
                                                    vm.selectedChannelCategory == cat
                                                    ? BoothColors.background
                                                    : BoothColors.textSecondary
                                                )
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(
                                                    vm.selectedChannelCategory == cat
                                                    ? BoothColors.accent
                                                    : BoothColors.surfaceElevated
                                                )
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            Picker("Input", selection: $vm.draftChannelSource) {
                                ForEach(InputSource.allCases.filter { $0.category == vm.selectedChannelCategory }) { source in
                                    Text(source.localizedName).tag(source)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 120)
                        }

                        SectionCard(title: "Label (Optional)") {
                            BoothTextField(
                                label: "Channel Name",
                                text: $vm.draftChannelLabel,
                                placeholder: "e.g., Sarah's Vocal, Stage Left GTR"
                            )
                        }

                        if needsVocalProfile {
                            SectionCard(title: "Vocal Profile") {
                                IconPicker(
                                    items: VocalRange.allCases.map { range in
                                        (value: range, icon: vocalRangeIcon(range), label: range.localizedName)
                                    },
                                    selection: $vm.draftVocalProfile.range,
                                    columns: 3
                                )

                                Picker("Style", selection: $vm.draftVocalProfile.style) {
                                    ForEach(VocalStyle.allCases) { s in Text(s.localizedName).tag(s) }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)

                                Picker("Mic", selection: $vm.draftVocalProfile.micType) {
                                    ForEach(MicType.allCases) { m in Text(m.localizedName).tag(m) }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Channel" : "Add Input Channel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.resetChannelDraft()
                    }
                    .foregroundStyle(BoothColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        if isEditing {
                            vm.updateChannel()
                        } else {
                            vm.addChannel()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(BoothColors.accent)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

/// Maps vocal ranges to SF Symbol icons for the icon picker.
private func vocalRangeIcon(_ range: VocalRange) -> String {
    switch range {
    case .soprano:      return "arrow.up.circle"
    case .mezzoSoprano: return "arrow.up.right.circle"
    case .alto:         return "arrow.right.circle"
    case .tenor:        return "arrow.down.right.circle"
    case .baritone:     return "arrow.down.circle"
    case .bass:         return "arrow.down.to.line"
    }
}


// MARK: - ─── Step 3: Setlist ─────────────────────────────────────────────

struct SetlistStepView: View {
    @ObservedObject var vm: ServiceSetupViewModel
    @ObservedObject var pcoManager: PlanningCenterManager
    @State private var showPCOImport = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(vm.service.setlist.count) Songs")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(BoothColors.accent)

                Spacer()

                if pcoManager.client.isAuthenticated {
                    Button {
                        showPCOImport = true
                    } label: {
                        Label("Import", systemImage: "arrow.down.circle")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.accentWarm)
                    }
                    .accessibilityLabel("Import setlist from Planning Center")
                }

                Button {
                    vm.resetSongDraft()
                    vm.showAddSong = true
                } label: {
                    Label("Add Song", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BoothColors.accent)
                }
                .accessibilityLabel("Add song to setlist")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            if vm.service.setlist.isEmpty {
                EmptyStateView(
                    icon: "music.note",
                    title: "No Songs Yet",
                    subtitle: "Add songs with their key to enable key-aware EQ recommendations."
                )
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(vm.service.setlist.enumerated()), id: \.element.id) { index, song in
                            VStack(spacing: 0) {
                                SongRow(index: index + 1, song: song)
                                    .padding(.horizontal, 16)

                                // ── Inline action buttons ──
                                HStack(spacing: 0) {
                                    Spacer()
                                    Button {
                                        vm.startEditingSong(at: index)
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(BoothColors.accent)
                                    }
                                    .accessibilityLabel("Edit \(song.title)")
                                    Spacer()
                                    Divider().frame(height: 14)
                                    Spacer()
                                    Button {
                                        vm.duplicateSong(at: index)
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(BoothColors.accentWarm)
                                    }
                                    .accessibilityLabel("Duplicate \(song.title)")
                                    Spacer()
                                    Divider().frame(height: 14)
                                    Spacer()
                                    Button(role: .destructive) {
                                        vm.service.setlist.remove(at: index)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(BoothColors.accentDanger)
                                    }
                                    .accessibilityLabel("Remove \(song.title)")
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                                .background(BoothColors.surfaceElevated)
                            }
                            .background(BoothColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 12)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .sheet(isPresented: $vm.showAddSong, onDismiss: { vm.editingSongIndex = nil }) {
            AddSongSheet(vm: vm)
        }
        .sheet(isPresented: $showPCOImport) {
            PCOImportSheet(
                manager: pcoManager,
                mode: .setlist,
                onImportSetlist: { songs in
                    vm.service.setlist.append(contentsOf: songs)
                },
                onImportTeam: { _ in }
            )
        }
    }
}


// MARK: - ─── Add/Edit Song Sheet ────────────────────────────────────────

struct AddSongSheet: View {
    @ObservedObject var vm: ServiceSetupViewModel
    @Environment(\.dismiss) private var dismiss

    private var isEditing: Bool { vm.isEditingSong }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Song Info") {
                            BoothTextField(label: "Title", text: $vm.draftSongTitle, placeholder: "e.g., Good Grace")
                        }

                        BPMPickerCard(bpm: $vm.draftSongBPM)

                        SectionCard(title: "Key") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                                ForEach(MusicalKey.allCases) { key in
                                    Button {
                                        vm.draftSongKey = key
                                    } label: {
                                        Text(key.localizedName)
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(
                                                vm.draftSongKey == key
                                                ? BoothColors.background
                                                : BoothColors.textSecondary
                                            )
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(
                                                vm.draftSongKey == key
                                                ? BoothColors.accent
                                                : BoothColors.surfaceElevated
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Key of \(key.localizedName)")
                                    .accessibilityAddTraits(vm.draftSongKey == key ? .isSelected : [])
                                }
                            }

                            HStack(spacing: 16) {
                                InfoBadge(label: "Root", value: "\(Int(vm.draftSongKey.fundamentalHz)) Hz")
                                InfoBadge(label: "Bass Zone", value: "\(Int(vm.draftSongKey.bassRangeHz)) Hz")
                                InfoBadge(label: "Mud Zone", value: "\(Int(vm.draftSongKey.lowMidRangeHz)) Hz")
                            }
                        }

                        SectionCard(title: "Intensity") {
                            IconPicker(
                                items: [
                                    (value: SongIntensity.soft, icon: "leaf.fill", label: "Soft"),
                                    (value: SongIntensity.medium, icon: "music.note", label: "Medium"),
                                    (value: SongIntensity.driving, icon: "bolt.fill", label: "Driving"),
                                    (value: SongIntensity.allOut, icon: "flame.fill", label: "Full Send")
                                ],
                                selection: $vm.draftSongIntensity
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Song" : "Add Song")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.resetSongDraft()
                    }
                    .foregroundStyle(BoothColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        if isEditing {
                            vm.updateSong()
                        } else {
                            vm.addSong()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(BoothColors.accent)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}


// MARK: - ─── BPM Picker Card ─────────────────────────────────────────────

private struct BPMPickerCard: View {
    @Binding var bpm: Int?

    private static let bpmMin: Int = 40
    private static let bpmMax: Int = 200

    /// Internal slider value — 0 when BPM is nil (off)
    private var sliderValue: Double {
        Double(bpm ?? 72)
    }

    var body: some View {
        SectionCard(title: "BPM (Optional)") {
            VStack(spacing: 14) {
                // ── Toggle + readout ──
                HStack {
                    Toggle(isOn: Binding(
                        get: { bpm != nil },
                        set: { enabled in
                            if enabled {
                                bpm = 72
                            } else {
                                bpm = nil
                            }
                        }
                    )) {
                        Text("Set Tempo")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.textSecondary)
                    }
                    .tint(BoothColors.accent)
                }

                if bpm != nil {
                    // ── Large BPM readout ──
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(bpm ?? 72)")
                            .font(.system(size: 42, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.textPrimary)
                            .contentTransition(.numericText())
                        Text("bpm")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(BoothColors.textMuted)
                    }

                    // ── Stepper + slider ──
                    HStack(spacing: 12) {
                        Button {
                            adjustBPM(by: -1)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(
                                    (bpm ?? 72) <= Self.bpmMin
                                        ? BoothColors.textMuted
                                        : BoothColors.accent
                                )
                        }
                        .disabled((bpm ?? 72) <= Self.bpmMin)

                        Slider(
                            value: Binding(
                                get: { sliderValue },
                                set: { bpm = Int($0) }
                            ),
                            in: Double(Self.bpmMin)...Double(Self.bpmMax),
                            step: 1
                        )
                        .tint(BoothColors.accent)

                        Button {
                            adjustBPM(by: 1)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(
                                    (bpm ?? 72) >= Self.bpmMax
                                        ? BoothColors.textMuted
                                        : BoothColors.accent
                                )
                        }
                        .disabled((bpm ?? 72) >= Self.bpmMax)
                    }

                    // ── Range labels + descriptor ──
                    HStack {
                        Text("\(Self.bpmMin)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(BoothColors.textMuted)
                        Spacer()
                        Text(tempoDescription)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(BoothColors.accentWarm)
                        Spacer()
                        Text("\(Self.bpmMax)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(BoothColors.textMuted)
                    }
                }
            }
        }
    }

    private func adjustBPM(by amount: Int) {
        let current = bpm ?? 72
        bpm = min(Self.bpmMax, max(Self.bpmMin, current + amount))
    }

    private var tempoDescription: String {
        let v = bpm ?? 72
        if v <= 60 { return "Ballad" }
        if v <= 80 { return "Slow Worship" }
        if v <= 100 { return "Moderate" }
        if v <= 120 { return "Groove" }
        if v <= 140 { return "Upbeat" }
        if v <= 170 { return "Driving" }
        return "Fast"
    }
}


// MARK: - ─── Step 4: Review & Generate ───────────────────────────────────

struct ReviewStepView: View {
    @ObservedObject var vm: ServiceSetupViewModel
    @ObservedObject var store: ServiceStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SectionCard(title: "Summary") {
                    SummaryRow(label: "Console", value: vm.service.mixer.localizedName)
                    SummaryRow(label: "Band", value: vm.service.bandComposition.localizedName)
                    SummaryRow(label: "Drums", value: vm.service.drumConfig.localizedName)
                    SummaryRow(label: "Room", value: "\(vm.service.room.size.localizedName) / \(vm.service.room.surface.localizedName)")
                    SummaryRow(label: "RT60 (est.)", value: String(format: "%.1f s", vm.service.room.effectiveRT60))
                    SummaryRow(label: "Channels", value: "\(vm.activeChannelCount)")
                    SummaryRow(label: "Songs", value: "\(vm.service.setlist.count)")
                    SummaryRow(label: "Detail Level", value: vm.service.detailLevel.localizedName)
                }

                if !vm.service.setlist.isEmpty {
                    SectionCard(title: "Key Distribution") {
                        HStack(spacing: 6) {
                            ForEach(vm.service.setlist) { song in
                                VStack(spacing: 4) {
                                    Text(song.key.localizedName)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(BoothColors.accent)
                                    Text(song.title.prefix(8) + (song.title.count > 8 ? "..." : ""))
                                        .font(.system(size: 9))
                                        .foregroundStyle(BoothColors.textMuted)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(BoothColors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }

                Button {
                    vm.generateRecommendation()
                } label: {
                    HStack(spacing: 10) {
                        if vm.isGenerating {
                            ProgressView()
                                .tint(BoothColors.background)
                        } else {
                            Image(systemName: "waveform.badge.magnifyingglass")
                        }
                        Text(vm.isGenerating ? "Calculating..." : "Generate Mix Recommendations")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(BoothColors.background)
                    .background(vm.canGenerate ? BoothColors.accent : BoothColors.textMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!vm.canGenerate || vm.isGenerating)
                .accessibilityLabel(vm.isGenerating ? "Calculating mix recommendations" : "Generate mix recommendations")
                .accessibilityHint(vm.canGenerate ? "Runs the sound engine to compute gain, EQ, and compression settings for all channels" : "Add at least one input channel first")
                .padding(.top, 8)

                if !vm.canGenerate {
                    Text("Add at least one input channel to generate recommendations.")
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.accentWarm)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .sheet(item: $vm.recommendation, onDismiss: {
            // Auto-save service, inputs, and vocalist profiles
            store.saveService(vm.service)
            store.autoSaveInputs(from: vm.service.channels)
            store.autoSaveVocalists(from: vm.service.channels)
        }) { rec in
            RecommendationDetailView(recommendation: rec)
        }
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview {
    InputEntryView(store: ServiceStore(), pcoManager: PlanningCenterManager())
}
