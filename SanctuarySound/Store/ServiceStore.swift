// ============================================================================
// ServiceStore.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Persistence Layer
// Purpose: Lightweight JSON-based persistence for services, vocalist profiles,
//          saved inputs (all channel types), mixer snapshots, SPL preferences,
//          venues, rooms, and console profiles.
//          Uses the app's Documents directory. SwiftData deferred to v2.
// ============================================================================

import Foundation

// MARK: - ─── Service Store ──────────────────────────────────────────────────

/// Persists app data to the Documents directory as JSON files.
/// Thread-safe via @MainActor for SwiftUI binding.
@MainActor
final class ServiceStore: ObservableObject {

    // ── Published Collections ──
    @Published private(set) var savedServices: [WorshipService] = []
    @Published private(set) var savedVocalists: [SavedVocalist] = []
    @Published private(set) var savedInputs: [SavedInput] = []
    @Published private(set) var savedSnapshots: [MixerSnapshot] = []
    @Published var splPreference: SPLPreference = SPLPreference()
    @Published private(set) var savedReports: [SPLSessionReport] = []
    @Published var userPreferences: UserPreferences = UserPreferences()
    @Published private(set) var venues: [Venue] = []
    @Published private(set) var consoleProfiles: [ConsoleProfile] = []

    // ── Shared SPL Meter (cross-tab access for alert banner) ──
    let splMeter = SPLMeter()

    // ── File Paths ──
    private let servicesFile = "services.json"
    private let vocalistsFile = "vocalists.json"
    private let inputsFile = "inputs.json"
    private let snapshotsFile = "snapshots.json"
    private let preferencesFile = "preferences.json"
    private let reportsFile = "spl_reports.json"
    private let userPreferencesFile = "user_preferences.json"
    private let venuesFile = "venues.json"
    private let consolesFile = "console_profiles.json"

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Init

    init() {
        loadAll()
        migrateIfNeeded()
        splMeter.updateAlertThresholds(preference: splPreference)
    }

    // MARK: - Services

    func saveService(_ service: WorshipService) {
        if let index = savedServices.firstIndex(where: { $0.id == service.id }) {
            savedServices[index] = service
        } else {
            savedServices.append(service)
        }
        persist(savedServices, to: servicesFile)
    }

    func deleteService(id: UUID) {
        savedServices.removeAll { $0.id == id }
        persist(savedServices, to: servicesFile)
    }

    // MARK: - Vocalists

    func saveVocalist(_ vocalist: SavedVocalist) {
        if let index = savedVocalists.firstIndex(where: { $0.id == vocalist.id }) {
            savedVocalists[index] = vocalist
        } else {
            savedVocalists.append(vocalist)
        }
        persist(savedVocalists, to: vocalistsFile)
    }

    func deleteVocalist(id: UUID) {
        savedVocalists.removeAll { $0.id == id }
        persist(savedVocalists, to: vocalistsFile)
    }

    // MARK: - Saved Inputs

    func saveInput(_ input: SavedInput) {
        if let index = savedInputs.firstIndex(where: { $0.id == input.id }) {
            savedInputs[index] = input
        } else {
            savedInputs.append(input)
        }
        persist(savedInputs, to: inputsFile)
    }

    func deleteInput(id: UUID) {
        savedInputs.removeAll { $0.id == id }
        persist(savedInputs, to: inputsFile)
    }

    /// Auto-save all channels from a completed service as reusable inputs.
    /// Skips duplicates by matching name + source combination.
    func autoSaveInputs(from channels: [InputChannel]) {
        for channel in channels where channel.isActive {
            let isDuplicate = savedInputs.contains { existing in
                existing.name == channel.label && existing.source == channel.source
            }
            if !isDuplicate {
                let input = SavedInput(
                    name: channel.label,
                    source: channel.source,
                    vocalProfile: channel.vocalProfile
                )
                savedInputs.append(input)
            }
        }
        persist(savedInputs, to: inputsFile)
    }

    /// Auto-save vocalist profiles from channels that have vocal data.
    func autoSaveVocalists(from channels: [InputChannel]) {
        for channel in channels where channel.vocalProfile != nil {
            let isDuplicate = savedVocalists.contains { existing in
                existing.name == channel.label
            }
            if !isDuplicate {
                let profile = channel.vocalProfile!
                let vocalist = SavedVocalist(
                    name: channel.label,
                    range: profile.range,
                    style: profile.style,
                    preferredMic: profile.micType
                )
                savedVocalists.append(vocalist)
            }
        }
        persist(savedVocalists, to: vocalistsFile)
    }

    // MARK: - Snapshots

    func saveSnapshot(_ snapshot: MixerSnapshot) {
        if let index = savedSnapshots.firstIndex(where: { $0.id == snapshot.id }) {
            savedSnapshots[index] = snapshot
        } else {
            savedSnapshots.append(snapshot)
        }
        persist(savedSnapshots, to: snapshotsFile)
    }

    func deleteSnapshot(id: UUID) {
        savedSnapshots.removeAll { $0.id == id }
        persist(savedSnapshots, to: snapshotsFile)
    }

    // MARK: - SPL Preference

    func updateSPLPreference(_ preference: SPLPreference) {
        splPreference = preference
        splMeter.updateAlertThresholds(preference: preference)
        persist(splPreference, to: preferencesFile)
    }

    // MARK: - SPL Session Reports

    func saveReport(_ report: SPLSessionReport) {
        savedReports.insert(report, at: 0)  // Most recent first
        persist(savedReports, to: reportsFile)
    }

    func deleteReport(id: UUID) {
        savedReports.removeAll { $0.id == id }
        persist(savedReports, to: reportsFile)
    }

    /// Stop the SPL meter and automatically generate + save a session report.
    func stopMonitoringAndSaveReport() {
        if let report = splMeter.generateSessionReport(flaggingMode: splPreference.flaggingMode) {
            saveReport(report)
        }
        splMeter.stop()
    }

    // MARK: - User Preferences

    func updatePreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
        persist(userPreferences, to: userPreferencesFile)
    }

    // MARK: - ─── Venues ──────────────────────────────────────────────────────

    func saveVenue(_ venue: Venue) {
        if let index = venues.firstIndex(where: { $0.id == venue.id }) {
            venues[index] = venue
        } else {
            venues.append(venue)
        }
        persist(venues, to: venuesFile)
    }

    func deleteVenue(id: UUID) {
        venues.removeAll { $0.id == id }
        persist(venues, to: venuesFile)
    }

    /// Find a venue by ID.
    func venue(for id: UUID) -> Venue? {
        venues.first { $0.id == id }
    }

    /// Find a room by ID across all venues.
    func room(for id: UUID) -> Room? {
        for venue in venues {
            if let room = venue.rooms.first(where: { $0.id == id }) {
                return room
            }
        }
        return nil
    }

    /// Add a room to a venue.
    func addRoom(_ room: Room, toVenueID venueID: UUID) {
        guard let index = venues.firstIndex(where: { $0.id == venueID }) else { return }
        var venue = venues[index]
        venue.rooms.append(room)
        venues[index] = venue
        persist(venues, to: venuesFile)
    }

    /// Update a room within its venue.
    func updateRoom(_ room: Room, inVenueID venueID: UUID) {
        guard let venueIndex = venues.firstIndex(where: { $0.id == venueID }) else { return }
        var venue = venues[venueIndex]
        guard let roomIndex = venue.rooms.firstIndex(where: { $0.id == room.id }) else { return }
        venue.rooms[roomIndex] = room
        venues[venueIndex] = venue
        persist(venues, to: venuesFile)
    }

    /// Delete a room from a venue.
    func deleteRoom(id: UUID, fromVenueID venueID: UUID) {
        guard let venueIndex = venues.firstIndex(where: { $0.id == venueID }) else { return }
        var venue = venues[venueIndex]
        venue.rooms.removeAll { $0.id == id }
        venues[venueIndex] = venue
        persist(venues, to: venuesFile)
    }

    // MARK: - ─── Console Profiles ────────────────────────────────────────────

    func saveConsoleProfile(_ profile: ConsoleProfile) {
        if let index = consoleProfiles.firstIndex(where: { $0.id == profile.id }) {
            consoleProfiles[index] = profile
        } else {
            consoleProfiles.append(profile)
        }
        persist(consoleProfiles, to: consolesFile)
    }

    func deleteConsoleProfile(id: UUID) {
        consoleProfiles.removeAll { $0.id == id }
        persist(consoleProfiles, to: consolesFile)
    }

    /// Find a console profile by ID.
    func consoleProfile(for id: UUID) -> ConsoleProfile? {
        consoleProfiles.first { $0.id == id }
    }

    // MARK: - ─── Data Migration ──────────────────────────────────────────────

    /// Migrate from flat data model to hierarchical (Venue/Room/Console).
    /// Runs once on first launch after update. Safe to call multiple times.
    private func migrateIfNeeded() {
        // Already migrated if venues file exists
        let venuesURL = documentsURL.appendingPathComponent(venuesFile)
        guard !FileManager.default.fileExists(atPath: venuesURL.path) else { return }

        // Create default venue with one room from user preferences
        let defaultRoom = Room(
            name: "Main Room",
            roomSize: userPreferences.defaultRoomSize,
            roomSurface: userPreferences.defaultRoomSurface,
            defaultMixer: userPreferences.defaultMixer
        )

        let defaultVenue = Venue(
            name: "My Church",
            rooms: [defaultRoom]
        )

        venues = [defaultVenue]

        // Link existing services to the default venue/room
        var updated = false
        for i in savedServices.indices {
            if savedServices[i].venueID == nil {
                savedServices[i].venueID = defaultVenue.id
                savedServices[i].roomID = defaultRoom.id
                updated = true
            }
        }

        // Create a default console profile from user preferences
        let defaultConsole = ConsoleProfile(
            name: userPreferences.defaultMixer.shortName,
            model: userPreferences.defaultMixer,
            linkedVenueID: defaultVenue.id,
            linkedRoomID: defaultRoom.id
        )
        consoleProfiles = [defaultConsole]

        // Persist all
        persist(venues, to: venuesFile)
        persist(consoleProfiles, to: consolesFile)
        if updated {
            persist(savedServices, to: servicesFile)
        }
    }

    // MARK: - Persistence Helpers

    private func persist<T: Encodable>(_ data: T, to filename: String) {
        let url = documentsURL.appendingPathComponent(filename)
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url, options: .atomic)
        } catch {
            // Silent failure for MVP — production should log this
        }
    }

    private func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
        let url = documentsURL.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            return nil
        }
    }

    private func loadAll() {
        savedServices = load([WorshipService].self, from: servicesFile) ?? []
        savedVocalists = load([SavedVocalist].self, from: vocalistsFile) ?? []
        savedInputs = load([SavedInput].self, from: inputsFile) ?? []
        savedSnapshots = load([MixerSnapshot].self, from: snapshotsFile) ?? []
        splPreference = load(SPLPreference.self, from: preferencesFile) ?? SPLPreference()
        savedReports = load([SPLSessionReport].self, from: reportsFile) ?? []
        userPreferences = load(UserPreferences.self, from: userPreferencesFile) ?? UserPreferences()
        venues = load([Venue].self, from: venuesFile) ?? []
        consoleProfiles = load([ConsoleProfile].self, from: consolesFile) ?? []
    }
}
