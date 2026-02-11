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
import OSLog

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
        configureWatchConnectivity()
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
        // Safe unwrap — guards against nil vocal profile
        for channel in channels {
            guard let profile = channel.vocalProfile else { continue }
            let isDuplicate = savedVocalists.contains { existing in
                existing.name == channel.label
            }
            if !isDuplicate {
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
        WatchSessionManager.shared.sendPreferences(
            targetDB: preference.targetDB,
            flaggingMode: preference.flaggingMode,
            themeID: userPreferences.colorTheme.rawValue,
            calibrationOffset: preference.calibrationOffset
        )
    }

    // MARK: - SPL Session Reports

    func saveReport(_ report: SPLSessionReport) {
        savedReports.insert(report, at: 0)  // Most recent first
        persist(savedReports, to: reportsFile)
        WatchSessionManager.shared.sendReport(report)
    }

    func deleteReport(id: UUID) {
        savedReports.removeAll { $0.id == id }
        persist(savedReports, to: reportsFile)
    }

    /// Stop the SPL meter and automatically generate + save a session report.
    /// Returns the report if one was generated (for display in the calling view).
    @discardableResult
    func stopMonitoringAndSaveReport() -> SPLSessionReport? {
        let report = splMeter.generateSessionReport(flaggingMode: splPreference.flaggingMode)
        if let report {
            saveReport(report)
        }
        splMeter.stop()

        // Send a final "stopped" snapshot to the Watch so it clears its UI
        let stoppedSnapshot = SPLSnapshot(
            currentDB: 0,
            peakDB: 0,
            averageDB: 0,
            alertState: .safe,
            isRunning: false
        )
        WatchSessionManager.shared.sendSPLSnapshot(stoppedSnapshot, force: true)
        return report
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

    // MARK: - ─── Data Management ──────────────────────────────────────────────

    /// Total count of all user-created data items.
    var totalDataCount: Int {
        savedServices.count + savedVocalists.count + savedInputs.count +
        savedSnapshots.count + savedReports.count + venues.count + consoleProfiles.count
    }

    /// Clear all user data and reset to defaults. Returns the store to a truly empty state.
    /// Does NOT re-create default venue/room/console — the user will be guided through
    /// Quick Setup on next launch to configure fresh defaults.
    func clearAllData() {
        savedServices = []
        savedVocalists = []
        savedInputs = []
        savedSnapshots = []
        savedReports = []
        venues = []
        consoleProfiles = []
        splPreference = SPLPreference()
        userPreferences = UserPreferences()

        // Remove all JSON files
        let files = [servicesFile, vocalistsFile, inputsFile, snapshotsFile,
                     preferencesFile, reportsFile, userPreferencesFile, venuesFile, consolesFile]
        for file in files {
            let url = documentsURL.appendingPathComponent(file)
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                Logger.persistence.warning("Failed to remove \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        splMeter.updateAlertThresholds(preference: splPreference)
    }

    // MARK: - ─── Data Migration ──────────────────────────────────────────────

    /// Migrate from flat data model to hierarchical (Venue/Room/Console).
    /// Runs once on first launch after update. Safe to call multiple times.
    /// Skips if onboarding hasn't completed — lets Quick Setup create defaults
    /// with the user's chosen mixer, room size, and detail level instead.
    private func migrateIfNeeded() {
        // Already migrated if venues file exists
        let venuesURL = documentsURL.appendingPathComponent(venuesFile)
        guard !FileManager.default.fileExists(atPath: venuesURL.path) else { return }

        // If onboarding hasn't been completed, let onboarding create defaults instead
        // of creating them here with generic UserPreferences defaults
        guard UserDefaults.standard.bool(forKey: "hasSeenOnboarding") else { return }

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

    // MARK: - ─── Watch Connectivity ──────────────────────────────────────────

    /// Wire up SPLMeter → WatchSessionManager data flow and Watch → iPhone commands.
    private func configureWatchConnectivity() {
        let watchManager = WatchSessionManager.shared

        // Forward SPL updates to Watch
        splMeter.onSPLUpdate = { snapshot in
            watchManager.sendSPLSnapshot(snapshot)
        }

        // Handle Watch start command
        watchManager.onStartCommand = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.splMeter.requestPermission()
                self.splMeter.start()
            }
        }

        // Handle Watch stop command
        watchManager.onStopCommand = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.stopMonitoringAndSaveReport()
            }
        }

        // Handle Watch target dB update (Crown adjustment)
        watchManager.onTargetDBUpdate = { [weak self] newTarget in
            guard let self else { return }
            Task { @MainActor in
                let updated = SPLPreference(
                    targetDB: newTarget,
                    flaggingMode: self.splPreference.flaggingMode,
                    calibrationOffset: self.splPreference.calibrationOffset
                )
                self.splPreference = updated
                self.splMeter.updateAlertThresholds(preference: updated)
                self.persist(updated, to: self.preferencesFile)
            }
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
            Logger.persistence.error("Failed to persist \(filename): \(error.localizedDescription)")
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
            Logger.persistence.error("Failed to load \(filename): \(error.localizedDescription)")
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
