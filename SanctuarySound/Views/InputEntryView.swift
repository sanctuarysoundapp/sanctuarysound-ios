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

// MARK: - ─── View Model ───────────────────────────────────────────────────

/// Drives the InputEntryView with reactive state management.
@MainActor
final class ServiceSetupViewModel: ObservableObject {

    // ── Service Model ──
    @Published var service: WorshipService = WorshipService()

    // ── UI State ──
    @Published var currentStep: SetupStep = .basics
    @Published var showAddChannel: Bool = false
    @Published var showAddSong: Bool = false
    @Published var selectedChannelCategory: InputCategory = .vocals
    @Published var isGenerating: Bool = false
    @Published var recommendation: MixerSettingRecommendation?

    // ── Channel Draft ──
    @Published var draftChannelSource: InputSource = .leadVocal
    @Published var draftChannelLabel: String = ""
    @Published var draftVocalProfile: VocalProfile = VocalProfile()
    @Published var editingChannelIndex: Int?

    // ── Song Draft ──
    @Published var draftSongTitle: String = ""
    @Published var draftSongKey: MusicalKey = .G
    @Published var draftSongIntensity: SongIntensity = .medium
    @Published var draftSongBPM: Int? = nil
    @Published var editingSongIndex: Int?

    private let engine = SoundEngine()
    private var hasAppliedDefaults = false

    /// Apply user preferences as service defaults (called once on first appear).
    func applyDefaults(from prefs: UserPreferences) {
        guard !hasAppliedDefaults else { return }
        hasAppliedDefaults = true
        service.mixer = prefs.defaultMixer
        service.experienceLevel = prefs.defaultExperienceLevel
        service.bandComposition = prefs.defaultBandComposition
        service.drumConfig = prefs.defaultDrumConfig
        service.room = RoomProfile(size: prefs.defaultRoomSize, surface: prefs.defaultRoomSurface)
    }

    // ── Computed Properties ──

    var activeChannelCount: Int {
        service.channels.filter { $0.isActive }.count
    }

    var canGenerate: Bool {
        !service.channels.isEmpty
    }

    var stepProgress: Double {
        Double(currentStep.rawValue + 1) / Double(SetupStep.allCases.count)
    }

    var isEditingChannel: Bool { editingChannelIndex != nil }
    var isEditingSong: Bool { editingSongIndex != nil }

    // ── Channel Actions ──

    func addChannel() {
        let needsVocal = draftChannelSource.category == .vocals ||
                         draftChannelSource.category == .speech

        let channel = InputChannel(
            label: draftChannelLabel.isEmpty ? draftChannelSource.localizedName : draftChannelLabel,
            source: draftChannelSource,
            vocalProfile: needsVocal ? draftVocalProfile : nil
        )
        service.channels.append(channel)
        resetChannelDraft()
    }

    func updateChannel() {
        guard let index = editingChannelIndex, index < service.channels.count else { return }
        let needsVocal = draftChannelSource.category == .vocals ||
                         draftChannelSource.category == .speech

        let updated = InputChannel(
            id: service.channels[index].id,
            label: draftChannelLabel.isEmpty ? draftChannelSource.localizedName : draftChannelLabel,
            source: draftChannelSource,
            vocalProfile: needsVocal ? draftVocalProfile : nil
        )
        service.channels[index] = updated
        resetChannelDraft()
    }

    func duplicateChannel(at index: Int) {
        guard index < service.channels.count else { return }
        let original = service.channels[index]
        let copy = InputChannel(
            label: original.label + " (Copy)",
            source: original.source,
            vocalProfile: original.vocalProfile
        )
        service.channels.insert(copy, at: index + 1)
    }

    func removeChannel(at offsets: IndexSet) {
        service.channels.remove(atOffsets: offsets)
    }

    func startEditingChannel(at index: Int) {
        guard index < service.channels.count else { return }
        let channel = service.channels[index]
        draftChannelSource = channel.source
        draftChannelLabel = channel.label
        draftVocalProfile = channel.vocalProfile ?? VocalProfile()
        selectedChannelCategory = channel.source.category
        editingChannelIndex = index
        showAddChannel = true
    }

    func resetChannelDraft() {
        draftChannelLabel = ""
        draftChannelSource = .leadVocal
        draftVocalProfile = VocalProfile()
        editingChannelIndex = nil
        showAddChannel = false
    }

    // ── Song Actions ──

    func addSong() {
        let song = SetlistSong(
            title: draftSongTitle.isEmpty ? "Song \(service.setlist.count + 1)" : draftSongTitle,
            key: draftSongKey,
            bpm: draftSongBPM,
            intensity: draftSongIntensity
        )
        service.setlist.append(song)
        resetSongDraft()
    }

    func updateSong() {
        guard let index = editingSongIndex, index < service.setlist.count else { return }
        let updated = SetlistSong(
            id: service.setlist[index].id,
            title: draftSongTitle.isEmpty ? "Song \(index + 1)" : draftSongTitle,
            key: draftSongKey,
            bpm: draftSongBPM,
            intensity: draftSongIntensity
        )
        service.setlist[index] = updated
        resetSongDraft()
    }

    func duplicateSong(at index: Int) {
        guard index < service.setlist.count else { return }
        let original = service.setlist[index]
        let copy = SetlistSong(
            title: original.title + " (Copy)",
            key: original.key,
            bpm: original.bpm,
            intensity: original.intensity
        )
        service.setlist.insert(copy, at: index + 1)
    }

    func removeSong(at offsets: IndexSet) {
        service.setlist.remove(atOffsets: offsets)
    }

    func startEditingSong(at index: Int) {
        guard index < service.setlist.count else { return }
        let song = service.setlist[index]
        draftSongTitle = song.title
        draftSongKey = song.key
        draftSongIntensity = song.intensity
        draftSongBPM = song.bpm
        editingSongIndex = index
        showAddSong = true
    }

    func resetSongDraft() {
        draftSongTitle = ""
        draftSongKey = .G
        draftSongIntensity = .medium
        draftSongBPM = nil
        editingSongIndex = nil
        showAddSong = false
    }

    func generateRecommendation() {
        isGenerating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            self.recommendation = self.engine.generateRecommendation(for: self.service)
            self.isGenerating = false
        }
    }
}

/// Setup wizard steps.
enum SetupStep: Int, CaseIterable, Identifiable {
    case basics     = 0
    case channels   = 1
    case setlist    = 2
    case review     = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .basics:   return "Service Setup"
        case .channels: return "Input List"
        case .setlist:  return "Setlist"
        case .review:   return "Review & Generate"
        }
    }

    var icon: String {
        switch self {
        case .basics:   return "slider.horizontal.3"
        case .channels: return "list.bullet.rectangle"
        case .setlist:  return "music.note.list"
        case .review:   return "waveform.badge.magnifyingglass"
        }
    }
}


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

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    StepIndicatorBar(currentStep: vm.currentStep, progress: vm.stepProgress)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    TabView(selection: $vm.currentStep) {
                        BasicsStepView(vm: vm)
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
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                vm.applyDefaults(from: store.userPreferences)
            }
        }
    }
}


// MARK: - ─── Step Indicator ───────────────────────────────────────────────

struct StepIndicatorBar: View {
    let currentStep: SetupStep
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BoothColors.divider)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BoothColors.accent)
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 3)

            HStack {
                ForEach(SetupStep.allCases) { step in
                    Button { } label: {
                        VStack(spacing: 2) {
                            Image(systemName: step.icon)
                                .font(.system(size: 14, weight: step == currentStep ? .bold : .regular))
                                .foregroundStyle(step == currentStep ? BoothColors.accent : BoothColors.textMuted)
                            Text(step.title)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(step == currentStep ? BoothColors.textPrimary : BoothColors.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 8)
    }
}


// MARK: - ─── Icon Picker Component ───────────────────────────────────────

/// Reusable icon-based picker for compact selection grids.
/// Replaces segmented controls that overflow on small screens.
struct IconPicker<T: Hashable>: View {
    let items: [(value: T, icon: String, label: String)]
    @Binding var selection: T
    var columns: Int = 0

    var body: some View {
        if columns > 0 {
            gridLayout
        } else {
            rowLayout
        }
    }

    private var rowLayout: some View {
        HStack(spacing: 8) {
            ForEach(items.indices, id: \.self) { i in
                iconButton(for: items[i])
            }
        }
    }

    private var gridLayout: some View {
        let rows = stride(from: 0, to: items.count, by: columns).map { start in
            Array(items[start..<min(start + columns, items.count)])
        }
        return VStack(spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        iconButton(for: rows[rowIndex][colIndex])
                    }
                    // Fill remaining space if row is incomplete
                    if rows[rowIndex].count < columns {
                        ForEach(0..<(columns - rows[rowIndex].count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func iconButton(for item: (value: T, icon: String, label: String)) -> some View {
        let isSelected = selection == item.value as T
        return Button {
            selection = item.value
        } label: {
            VStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? BoothColors.accent : BoothColors.textMuted)
                Text(item.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? BoothColors.textPrimary : BoothColors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? BoothColors.accent.opacity(0.15) : BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? BoothColors.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - ─── Step 1: Basics ──────────────────────────────────────────────

struct BasicsStepView: View {
    @ObservedObject var vm: ServiceSetupViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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

                SectionCard(title: "Your Experience") {
                    IconPicker(
                        items: [
                            (value: ExperienceLevel.beginner, icon: "lightbulb.fill", label: "Beginner"),
                            (value: ExperienceLevel.intermediate, icon: "slider.horizontal.3", label: "Intermediate"),
                            (value: ExperienceLevel.advanced, icon: "waveform", label: "Advanced")
                        ],
                        selection: $vm.service.experienceLevel
                    )

                    Text(vm.service.experienceLevel.description)
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
                }

                if !store.savedInputs.isEmpty {
                    Button {
                        showSavedInputs = true
                    } label: {
                        Label("Library", systemImage: "tray.full.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.accentWarm)
                    }
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


struct ChannelRow: View {
    let channel: InputChannel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: channel.source.category.systemIcon)
                .font(.system(size: 16))
                .foregroundStyle(BoothColors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)

                Text(channel.source.localizedName)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
            }

            Spacer()

            if channel.source.isLineLevel {
                Text("LINE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accentWarm)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BoothColors.accentWarm.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Text("MIC")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BoothColors.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .padding(.vertical, 4)
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
                }

                Button {
                    vm.resetSongDraft()
                    vm.showAddSong = true
                } label: {
                    Label("Add Song", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BoothColors.accent)
                }
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

struct SongRow: View {
    let index: Int
    let song: SetlistSong

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                Text(song.intensity.localizedName)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
            }

            Spacer()

            Text(song.key.localizedName)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(BoothColors.accent)
                .frame(width: 32, height: 32)
                .background(BoothColors.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            if let bpm = song.bpm {
                Text("\(bpm)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
                + Text(" bpm")
                    .font(.system(size: 9))
                    .foregroundStyle(BoothColors.textMuted)
            }
        }
        .padding(.vertical, 4)
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
                    SummaryRow(label: "Detail Level", value: vm.service.experienceLevel.localizedName)
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

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(BoothColors.textPrimary)
        }
        .padding(.vertical, 2)
    }
}


// MARK: - ─── Step Navigation Bar ─────────────────────────────────────────

struct StepNavigationBar: View {
    @ObservedObject var vm: ServiceSetupViewModel

    var body: some View {
        HStack {
            if vm.currentStep != .basics {
                Button {
                    if let prev = SetupStep(rawValue: vm.currentStep.rawValue - 1) {
                        vm.currentStep = prev
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textSecondary)
                }
            }

            Spacer()

            if vm.currentStep != .review {
                Button {
                    if let next = SetupStep(rawValue: vm.currentStep.rawValue + 1) {
                        vm.currentStep = next
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BoothColors.accent)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(BoothColors.surface)
    }
}


// MARK: - ─── Reusable Components ─────────────────────────────────────────

/// Dark-themed section card container.
struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.accent)
                .tracking(1.5)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BoothColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Styled text field for dark UI.
struct BoothTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(BoothColors.textSecondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundStyle(BoothColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

/// Compact info badge for displaying metadata.
struct InfoBadge: View {
    let label: String
    let value: String
    var color: Color = BoothColors.accent

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(BoothColors.textMuted)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

/// Empty state placeholder.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(BoothColors.textMuted)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BoothColors.textSecondary)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview {
    InputEntryView(store: ServiceStore(), pcoManager: PlanningCenterManager())
}
