// ============================================================================
// PlanningCenterManager.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Store Layer
// Purpose: Orchestrates the PCO workflow: connect → browse folders → pick
//          service type → pick plan → import setlist/team. Converts PCO data
//          models to SanctuarySound domain types (SetlistSong, InputChannel).
//          Handles position classification, abbreviation expansion, drum kit
//          expansion, and venue matching from PCO folder breadcrumbs.
// ============================================================================

import Foundation


// MARK: - ─── Planning Center Manager ─────────────────────────────────────

@MainActor
final class PlanningCenterManager: ObservableObject {

    @Published private(set) var serviceTypes: [PCOResource<PCOServiceTypeAttributes>] = []
    @Published private(set) var plans: [PCOResource<PCOPlanAttributes>] = []
    @Published private(set) var folders: [PCOResource<PCOFolderAttributes>] = []
    @Published private(set) var folderItems: [PCOFolderItem] = []
    /// Breadcrumb trail of folders navigated into. Settable for testing.
    @Published var folderBreadcrumbs: [(id: String, name: String)] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    let client: PCOClient

    init(client: PCOClient? = nil) {
        self.client = client ?? PCOClient()
    }


    // MARK: - ─── Fetch Top-Level Folders ───────────────────────────────────────

    /// Load root-level folders (campuses). If the org has no folders,
    /// falls back to loading flat service types.
    func loadTopLevelFolders() async {
        isLoading = true
        error = nil
        folderBreadcrumbs = []

        do {
            let topFolders = try await client.fetchTopLevelFolders()
            if topFolders.isEmpty {
                // Org doesn't use folders — fall back to flat service type list
                folders = []
                folderItems = []
                serviceTypes = try await client.fetchServiceTypes()
            } else {
                folders = topFolders
                folderItems = topFolders.map { .folder($0) }
                serviceTypes = []
            }
        } catch {
            // If folder fetch fails, gracefully fall back to flat list
            do {
                serviceTypes = try await client.fetchServiceTypes()
                folders = []
                folderItems = []
            } catch {
                self.error = error.localizedDescription
            }
        }

        isLoading = false
    }


    // MARK: - ─── Fetch Folder Contents ────────────────────────────────────────

    /// Navigate into a folder — fetch sub-folders and service types, push breadcrumb.
    func loadFolderContents(folderID: String, folderName: String) async {
        isLoading = true
        error = nil

        // Push breadcrumb
        folderBreadcrumbs.append((id: folderID, name: folderName))

        do {
            let contents = try await client.fetchFolderContents(folderID: folderID)

            var items: [PCOFolderItem] = []
            items.append(contentsOf: contents.folders.map { .folder($0) })
            items.append(contentsOf: contents.serviceTypes.map { .serviceType($0) })

            folderItems = items
            serviceTypes = contents.serviceTypes
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }


    // MARK: - ─── Navigate Back ─────────────────────────────────────────────────

    /// Pop breadcrumbs back to a specific index and reload that folder's contents.
    func navigateBackToFolder(index: Int) async {
        guard index >= 0 && index < folderBreadcrumbs.count else {
            // Navigate to root
            folderBreadcrumbs = []
            await loadTopLevelFolders()
            return
        }

        let target = folderBreadcrumbs[index]
        folderBreadcrumbs = Array(folderBreadcrumbs.prefix(index))
        await loadFolderContents(folderID: target.id, folderName: target.name)
    }

    /// Navigate to root level (above all folders).
    func navigateToRoot() async {
        folderBreadcrumbs = []
        await loadTopLevelFolders()
    }


    // MARK: - ─── Venue Matching from Breadcrumbs ──────────────────────────────

    /// Scan folder breadcrumbs against saved venue names to find a match.
    /// Returns the first matching venueID, or nil if no match.
    /// Matching is case-insensitive with trimmed whitespace.
    func matchVenueFromBreadcrumbs(venues: [Venue]) -> UUID? {
        for breadcrumb in folderBreadcrumbs {
            let folderName = breadcrumb.name.trimmingCharacters(in: .whitespaces).lowercased()
            if let match = venues.first(where: {
                $0.name.trimmingCharacters(in: .whitespaces).lowercased() == folderName
            }) {
                return match.id
            }
        }
        return nil
    }


    // MARK: - ─── Fetch Service Types ─────────────────────────────────────────

    func loadServiceTypes() async {
        isLoading = true
        error = nil

        do {
            serviceTypes = try await client.fetchServiceTypes()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }


    // MARK: - ─── Fetch Plans ─────────────────────────────────────────────────

    func loadPlans(serviceTypeID: String) async {
        isLoading = true
        error = nil

        do {
            plans = try await client.fetchPlans(serviceTypeID: serviceTypeID)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }


    // MARK: - ─── Import Setlist ──────────────────────────────────────────────

    /// Import songs from a PCO plan as SetlistSong values.
    func importSetlist(serviceTypeID: String, planID: String) async -> [SetlistSong] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let items = try await client.fetchPlanItems(
                serviceTypeID: serviceTypeID,
                planID: planID
            )

            var songs: [SetlistSong] = []

            for item in items {
                let attrs = item.attributes

                // Only import song-type items
                guard attrs.itemType == "song" else { continue }

                let title = attrs.title ?? "Untitled"

                // Plan item key_name is the primary source (set per-plan)
                var key = parseMusicalKey(attrs.keyName)
                var bpm: Int?

                // Fetch arrangement for BPM and fallback key
                if let songID = attrs.songId {
                    if let arrangement = try? await client.fetchArrangements(songID: songID).first {
                        if let arrangementBPM = arrangement.attributes.bpm {
                            bpm = Int(arrangementBPM)
                        }
                        // Use arrangement key if plan item didn't have one
                        if key == nil {
                            key = parseMusicalKey(arrangement.attributes.keyName)
                        }
                    }
                }

                songs.append(SetlistSong(title: title, key: key ?? .C, bpm: bpm))
            }

            return songs
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }


    // MARK: - ─── Import Team Roster (Smart) ─────────────────────────────────

    /// Import team members from a PCO plan as classified PCOTeamImportItem values.
    /// Production roles are auto-excluded. Drums are expanded via template.
    func importTeamRoster(
        serviceTypeID: String,
        planID: String,
        drumTemplate: DrumKitTemplate = .standard5
    ) async -> [PCOTeamImportItem] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let members = try await client.fetchTeamMembers(
                serviceTypeID: serviceTypeID,
                planID: planID
            )

            return processTeamMembers(
                members.map { $0.attributes },
                drumTemplate: drumTemplate
            )
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }


    // MARK: - ─── Process Team Members ───────────────────────────────────────

    /// Convert raw PCO team member attributes into classified import items.
    /// Uses position names as channel labels (not person names).
    /// Filters out declined members. Expands drum positions into kit channels.
    func processTeamMembers(
        _ members: [PCOTeamMemberAttributes],
        drumTemplate: DrumKitTemplate = .standard5
    ) -> [PCOTeamImportItem] {
        var items: [PCOTeamImportItem] = []

        for member in members {
            // Only import confirmed or unconfirmed members
            guard member.status == "C" || member.status == "U" else { continue }

            let personName = member.name ?? "Unknown"
            let positionName = member.teamPositionName ?? ""
            let category = classifyPosition(positionName)

            switch category {
            case .production:
                // Include but mark as excluded by default
                items.append(PCOTeamImportItem(
                    personName: personName,
                    positionName: positionName,
                    positionCategory: .production,
                    channelLabel: positionName,
                    source: mapPositionToSource(positionName),
                    isIncluded: false
                ))

            case .drums:
                // Expand into multiple drum channels
                let drumItems = expandDrumPosition(
                    personName: personName,
                    positionName: positionName,
                    template: drumTemplate
                )
                items.append(contentsOf: drumItems)

            case .audio, .unknown:
                // Use position name as channel label
                let source = mapPositionToSource(positionName)
                items.append(PCOTeamImportItem(
                    personName: personName,
                    positionName: positionName,
                    positionCategory: .audio,
                    channelLabel: positionName.isEmpty ? personName : positionName,
                    source: source,
                    isIncluded: true
                ))
            }
        }

        return items
    }


    // MARK: - ─── Expand Drum Position ───────────────────────────────────────

    /// Expand a single "DRUMS" team position into multiple channels
    /// based on the selected drum kit template.
    func expandDrumPosition(
        personName: String,
        positionName: String,
        template: DrumKitTemplate
    ) -> [PCOTeamImportItem] {
        template.channels.map { channel in
            PCOTeamImportItem(
                personName: personName,
                positionName: positionName,
                positionCategory: .drums,
                channelLabel: channel.label,
                source: channel.source,
                isIncluded: true
            )
        }
    }


    // MARK: - ─── Position Classification ────────────────────────────────────

    /// Known non-audio production role keywords.
    static let productionPositionKeywords: Set<String> = [
        "foh sound", "foh", "sound engineer", "sound tech",
        "monitor engineer", "monitor tech", "audio tech",
        "lights", "lighting", "lighting tech", "lighting director",
        "lyrics", "lyrics operator", "propresenter", "pro presenter",
        "director", "service director", "worship director",
        "producer", "service producer",
        "camera", "camera operator", "videographer", "video",
        "photography", "photographer", "photo",
        "streaming", "stream", "live stream", "broadcast",
        "stage", "stage manager", "stage hand",
        "hospitality", "greeter", "usher",
        "kids", "children", "nursery",
        "tech director", "td", "production director",
    ]

    /// Classify a PCO team position into a category.
    /// Checks production keywords first, then drum detection, defaults to audio.
    func classifyPosition(_ position: String) -> PCOPositionCategory {
        let lower = position.lowercased().trimmingCharacters(in: .whitespaces)

        guard !lower.isEmpty else { return .unknown }

        // Check production keywords
        for keyword in Self.productionPositionKeywords {
            if lower == keyword || lower.contains(keyword) {
                return .production
            }
        }

        // Check drums
        if lower.contains("drum") || lower.contains("percussion")
            || lower.contains("cajon") || lower.contains("cajón") {
            return .drums
        }

        return .audio
    }


    // MARK: - ─── Abbreviation Expansion ─────────────────────────────────────

    /// Known abbreviations used in PCO position names.
    static let abbreviationExpansions: [String: String] = [
        "eg":  "electric guitar",
        "ag":  "acoustic guitar",
        "bgv": "backing vocal",
        "md":  "worship leader",
    ]

    /// Expand known abbreviations in a position name before source mapping.
    /// Handles standalone abbreviations and abbreviations as prefixes
    /// (e.g., "EG Lead" → "electric guitar Lead").
    func expandAbbreviations(_ position: String) -> String {
        let trimmed = position.trimmingCharacters(in: .whitespaces)
        let lower = trimmed.lowercased()

        for (abbr, expansion) in Self.abbreviationExpansions {
            // Match standalone or prefix (e.g., "EG" or "EG Lead")
            if lower == abbr {
                return expansion
            }
            if lower.hasPrefix(abbr + " ") {
                return expansion + String(trimmed.dropFirst(abbr.count))
            }
        }

        // Handle "VOX" prefix — map to vocal
        if lower == "vox" || lower.hasPrefix("vox ") {
            return "vocal" + String(trimmed.dropFirst(3))
        }

        return trimmed
    }


    // MARK: - ─── Key Parsing ─────────────────────────────────────────────────

    /// Parse a PCO key string (e.g., "Eb", "F#", "Ab", "G") into a MusicalKey.
    func parseMusicalKey(_ keyString: String?) -> MusicalKey? {
        guard let raw = keyString?.trimmingCharacters(in: .whitespaces),
              !raw.isEmpty else { return nil }

        // Normalize: strip "m", "minor", "Major", etc. for now
        let cleaned = raw
            .replacingOccurrences(of: " Major", with: "")
            .replacingOccurrences(of: " minor", with: "")
            .replacingOccurrences(of: " Minor", with: "")
            .replacingOccurrences(of: "minor", with: "")
            .replacingOccurrences(of: "m", with: "")
            .trimmingCharacters(in: .whitespaces)

        let keyMap: [String: MusicalKey] = [
            "C":  .C,
            "C#": .Db, "Db": .Db,
            "D":  .D,
            "D#": .Eb, "Eb": .Eb, "E♭": .Eb,
            "E":  .E,
            "F":  .F,
            "F#": .Gb, "Gb": .Gb,
            "G":  .G,
            "G#": .Ab, "Ab": .Ab, "A♭": .Ab,
            "A":  .A,
            "A#": .Bb, "Bb": .Bb, "B♭": .Bb,
            "B":  .B,
        ]

        return keyMap[cleaned]
    }


    // MARK: - ─── Position Mapping ────────────────────────────────────────────

    /// Map a PCO team position name to an InputSource enum value.
    ///
    /// Expands abbreviations first (EG → electric guitar, AG → acoustic guitar, etc.),
    /// then checks in order: lead vocal → instruments → production → generic vocals → fallback.
    func mapPositionToSource(_ position: String) -> InputSource {
        let expanded = expandAbbreviations(position)
        let lower = expanded.lowercased()

        // 1. Lead vocal / worship leader (most specific vocal match first)
        if lower.contains("lead vocal") || lower.contains("worship leader") {
            return .leadVocal
        }

        // 2. Instrument positions (BEFORE generic vocal check)
        if lower.contains("electric guitar") || lower.contains("e. guitar") || lower.contains("e guitar") {
            return .electricGtrModeler
        }
        if lower.contains("acoustic guitar") || lower.contains("a. guitar") || lower.contains("a guitar") {
            return .acousticGtrDI
        }
        if lower.contains("bass") {
            return .bassGtrDI
        }
        if lower.contains("keyboard") || lower.contains("keys") || lower.contains("piano") || lower.contains("synth") {
            return .digitalPiano
        }
        if lower.contains("drum") || lower.contains("percussion") || lower.contains("cajon") || lower.contains("cajón") {
            return .kickDrum
        }

        // 3. Production / playback
        if lower.contains("track") || lower.contains("click") || lower.contains("playback") {
            return .tracksLeft
        }

        // 4. Generic vocal positions (after instruments)
        if lower.contains("vocal") || lower.contains("bgv") || lower.contains("backup") || lower.contains("backing") || lower.contains("singer") {
            return .backingVocal
        }

        // 5. Fallback — treat as backing vocal (most common unspecified position)
        return .backingVocal
    }


    // MARK: - ─── Date Parsing ───────────────────────────────────────────────

    /// Parse an ISO 8601 date string from a PCO plan's `sortDate` field.
    /// Returns the parsed Date, or current date if parsing fails.
    func parsePlanDate(_ sortDate: String?) -> Date {
        guard let dateString = sortDate, !dateString.isEmpty else {
            return Date()
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try date-only format (e.g., "2026-02-15")
        if let date = AppDateFormatter.isoDateOnly.date(from: dateString) {
            return date
        }

        return Date()
    }
}
