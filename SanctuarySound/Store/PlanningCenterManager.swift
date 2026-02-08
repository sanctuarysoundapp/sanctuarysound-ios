// ============================================================================
// PlanningCenterManager.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Store Layer
// Purpose: Orchestrates the PCO workflow: connect → pick service type →
//          pick plan → import setlist/team. Converts PCO data models to
//          SanctuarySound domain types (SetlistSong, InputChannel).
// ============================================================================

import Foundation


// MARK: - ─── Planning Center Manager ─────────────────────────────────────

@MainActor
final class PlanningCenterManager: ObservableObject {

    @Published private(set) var serviceTypes: [PCOResource<PCOServiceTypeAttributes>] = []
    @Published private(set) var plans: [PCOResource<PCOPlanAttributes>] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    let client: PCOClient

    init(client: PCOClient? = nil) {
        self.client = client ?? PCOClient()
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
                var key = parseMusicalKey(attrs.key)
                var bpm: Int = 120

                // Try to fetch arrangement for BPM and key if not on the plan item
                if let songID = attrs.songId {
                    if let arrangement = try? await client.fetchArrangements(songID: songID).first {
                        if let arrangementBPM = arrangement.attributes.bpm {
                            bpm = Int(arrangementBPM)
                        }
                    }
                }

                // Default to C if no key found
                if key == nil {
                    key = .C
                }

                songs.append(SetlistSong(title: title, key: key!, bpm: bpm))
            }

            return songs
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }


    // MARK: - ─── Import Team Roster ──────────────────────────────────────────

    /// Import team members from a PCO plan as InputChannel values.
    func importTeamRoster(serviceTypeID: String, planID: String) async -> [InputChannel] {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let members = try await client.fetchTeamMembers(
                serviceTypeID: serviceTypeID,
                planID: planID
            )

            var channels: [InputChannel] = []

            for member in members {
                let attrs = member.attributes

                // Only import confirmed or unconfirmed members
                guard attrs.status == "C" || attrs.status == "U" else { continue }

                let name = attrs.name ?? "Unknown"
                let position = attrs.teamPositionName ?? ""
                let source = mapPositionToSource(position)

                channels.append(InputChannel(
                    label: name,
                    source: source
                ))
            }

            return channels
        } catch {
            self.error = error.localizedDescription
            return []
        }
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
    private func mapPositionToSource(_ position: String) -> InputSource {
        let lower = position.lowercased()

        // Vocal positions
        if lower.contains("lead vocal") || lower.contains("worship leader") {
            return .leadVocal
        }
        if lower.contains("vocal") || lower.contains("bgv") || lower.contains("backup") || lower.contains("backing") || lower.contains("singer") {
            return .backingVocal
        }

        // Instrument positions
        if lower.contains("electric guitar") || lower.contains("e. guitar") {
            return .electricGtrModeler
        }
        if lower.contains("acoustic guitar") || lower.contains("a. guitar") {
            return .acousticGtrDI
        }
        if lower.contains("bass") {
            return .bassGtrDI
        }
        if lower.contains("keyboard") || lower.contains("keys") || lower.contains("piano") || lower.contains("synth") {
            return .digitalPiano
        }
        if lower.contains("drum") {
            return .kickDrum
        }

        // Production / other
        if lower.contains("track") || lower.contains("click") || lower.contains("playback") {
            return .tracksLeft
        }

        // Fallback — treat as backing vocal (most common unspecified position)
        return .backingVocal
    }
}
