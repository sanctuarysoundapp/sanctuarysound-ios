// ============================================================================
// ServiceSetupViewModel.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM ViewModel Layer
// Purpose: Drives the InputEntryView service setup wizard with reactive state
//          management. Owns the SoundEngine and manages the 4-step flow state.
// ============================================================================

import SwiftUI

// MARK: - ─── Setup Step ──────────────────────────────────────────────────

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


// MARK: - ─── View Model ──────────────────────────────────────────────────

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
        service.detailLevel = prefs.defaultDetailLevel
        service.bandComposition = prefs.defaultBandComposition
        service.drumConfig = prefs.defaultDrumConfig
        service.room = RoomProfile(size: prefs.defaultRoomSize, surface: prefs.defaultRoomSurface)
    }

    /// Pre-fill service from a full PCO import (plan name, date, songs, channels, venue).
    func applyPCOServiceImport(
        _ pcoImport: PCOFullServiceImport,
        venues: [Venue],
        consoles: [ConsoleProfile],
        prefs: UserPreferences
    ) {
        // Pre-fill plan name and date
        service.name = pcoImport.name
        service.date = pcoImport.date

        // Merge imported songs and channels
        service.setlist = pcoImport.songs
        service.channels = pcoImport.channels

        // Venue assignment from PCO folder match
        if let venueID = pcoImport.venueID {
            service.venueID = venueID

            // Auto-select first room in matched venue
            if let venue = venues.first(where: { $0.id == venueID }),
               let firstRoom = venue.rooms.first {
                service.roomID = firstRoom.id
                service.room = firstRoom.roomProfile
                if let mixer = firstRoom.defaultMixer {
                    service.mixer = mixer
                }
            }

            // Console auto-link: find console linked to this venue
            if let console = consoles.first(where: { $0.linkedVenueID == venueID }) {
                service.consoleProfileID = console.id
                service.mixer = console.model
            }
        } else if venues.count == 1, let singleVenue = venues.first {
            // Fallback: single saved venue → auto-assign
            service.venueID = singleVenue.id
            if let firstRoom = singleVenue.rooms.first {
                service.roomID = firstRoom.id
                service.room = firstRoom.roomProfile
            }
        }

        // Apply user defaults for anything not set by PCO
        service.detailLevel = prefs.defaultDetailLevel
        service.bandComposition = prefs.defaultBandComposition
        service.drumConfig = prefs.defaultDrumConfig

        // Navigate to basics step so user can review
        currentStep = .basics
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
