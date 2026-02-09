// ============================================================================
// PCOModels.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Network Layer
// Purpose: Codable model structs for Planning Center Online JSON:API 1.0
//          responses. Covers service types, plans, plan items (songs), songs,
//          and team members. Used by PCOClient for deserialization.
// ============================================================================

import Foundation


// MARK: - ─── JSON:API Envelope ───────────────────────────────────────────

/// Generic JSON:API response wrapper.
struct PCOResponse<T: Decodable>: Decodable {
    let data: [PCOResource<T>]
    let included: [PCOIncluded]?
    let meta: PCOMeta?

    enum CodingKeys: String, CodingKey {
        case data, included, meta
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([PCOResource<T>].self, forKey: .data)
        included = try container.decodeIfPresent([PCOIncluded].self, forKey: .included)
        meta = try container.decodeIfPresent(PCOMeta.self, forKey: .meta)
    }
}

/// Single-resource JSON:API response.
struct PCOSingleResponse<T: Decodable>: Decodable {
    let data: PCOResource<T>
}

struct PCOResource<T: Decodable>: Decodable, Identifiable {
    let id: String
    let type: String
    let attributes: T
}

struct PCOIncluded: Decodable {
    let id: String
    let type: String
    let attributes: [String: AnyCodable]?
}

struct PCOMeta: Decodable {
    let totalCount: Int?
    let count: Int?
    let next: PCOMetaLink?

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case count
        case next
    }
}

struct PCOMetaLink: Decodable {
    let offset: Int?
}


// MARK: - ─── Service Type ────────────────────────────────────────────────

/// A PCO "Service Type" (e.g., "Sunday AM Worship", "Wednesday Night").
struct PCOServiceTypeAttributes: Decodable {
    let name: String
    let frequency: String?
    let lastPlanFrom: String?

    enum CodingKeys: String, CodingKey {
        case name, frequency
        case lastPlanFrom = "last_plan_from"
    }
}


// MARK: - ─── Plan ────────────────────────────────────────────────────────

/// A PCO "Plan" (a specific service occurrence with a date).
struct PCOPlanAttributes: Decodable {
    let title: String?
    let seriesTitle: String?
    let dates: String?
    let sortDate: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case title
        case seriesTitle = "series_title"
        case dates
        case sortDate = "sort_date"
        case createdAt = "created_at"
    }
}


// MARK: - ─── Plan Item (Song in Service) ─────────────────────────────────

/// A PCO "Plan Item" — a song or other element in the service order.
struct PCOPlanItemAttributes: Decodable {
    let title: String?
    let itemType: String?       // "song", "header", "media", "item"
    let length: Int?            // Duration in seconds
    let description: String?
    let songId: String?
    let keyName: String?        // Musical key assigned at the plan item level (e.g., "G", "Ab")
    let arrangementName: String?  // Name of the selected arrangement
    let arrangementSequence: String?  // Arrangement section sequence

    enum CodingKeys: String, CodingKey {
        case title
        case itemType = "item_type"
        case length, description
        case songId = "song_id"
        case keyName = "key_name"
        case arrangementName = "arrangement_name"
        case arrangementSequence = "arrangement_sequence"
    }
}


// MARK: - ─── Song ────────────────────────────────────────────────────────

/// A PCO "Song" — the master song record with default key.
struct PCOSongAttributes: Decodable {
    let title: String
    let author: String?
    let copyright: String?
    let ccliNumber: Int?

    enum CodingKeys: String, CodingKey {
        case title, author, copyright
        case ccliNumber = "ccli_number"
    }
}


// MARK: - ─── Song Arrangement ────────────────────────────────────────────

/// A PCO "Arrangement" — specific version of a song with key + BPM.
struct PCOArrangementAttributes: Decodable {
    let name: String?
    let bpm: Double?
    let length: Int?         // Duration in seconds
    let meterNumerator: Int?
    let meterDenominator: Int?
    let keyName: String?     // Musical key of this arrangement (e.g., "G", "Eb")

    enum CodingKeys: String, CodingKey {
        case name, bpm, length
        case meterNumerator = "meter_numerator"
        case meterDenominator = "meter_denominator"
        case keyName = "key_name"
    }
}


// MARK: - ─── Team Member ─────────────────────────────────────────────────

/// A PCO "Plan Person" — a team member assigned to a service plan.
struct PCOTeamMemberAttributes: Decodable {
    let name: String?
    let status: String?          // "C" = confirmed, "U" = unconfirmed, "D" = declined
    let teamPositionName: String?

    enum CodingKeys: String, CodingKey {
        case name, status
        case teamPositionName = "team_position_name"
    }
}


// MARK: - ─── Key for Plan Item ───────────────────────────────────────────

/// Represents a song's key as extracted from PCO (arrangement or plan item).
struct PCOSongKey: Decodable {
    let name: String?   // e.g., "Ab", "F#m", "Eb"
}


// MARK: - ─── Folder ─────────────────────────────────────────────────────

/// A PCO "Folder" — organizes service types into campus/location groups.
/// Attributes per PCO API: name, created_at, updated_at, container.
struct PCOFolderAttributes: Decodable {
    let name: String
    let container: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case name
        case container
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Unified item for displaying folders and service types in a mixed list.
enum PCOFolderItem: Identifiable {
    case folder(PCOResource<PCOFolderAttributes>)
    case serviceType(PCOResource<PCOServiceTypeAttributes>)

    var id: String {
        switch self {
        case .folder(let resource):      return "folder-\(resource.id)"
        case .serviceType(let resource): return "stype-\(resource.id)"
        }
    }

    var name: String {
        switch self {
        case .folder(let resource):      return resource.attributes.name
        case .serviceType(let resource): return resource.attributes.name
        }
    }
}


// MARK: - ─── Position Category ──────────────────────────────────────────

/// Classifies a PCO team position for import filtering.
enum PCOPositionCategory: String, Codable, CaseIterable {
    case audio      = "Audio"
    case production = "Production"
    case drums      = "Drums"
    case unknown    = "Unknown"
}


// MARK: - ─── Team Import Item ───────────────────────────────────────────

/// A processed team member ready for import preview. Created from raw PCO
/// team data with position-based classification and source mapping applied.
struct PCOTeamImportItem: Identifiable, Equatable {
    let id: UUID
    let personName: String
    let positionName: String
    let positionCategory: PCOPositionCategory
    var channelLabel: String
    var source: InputSource
    var isIncluded: Bool

    init(
        id: UUID = UUID(),
        personName: String,
        positionName: String,
        positionCategory: PCOPositionCategory,
        channelLabel: String,
        source: InputSource,
        isIncluded: Bool = true
    ) {
        self.id = id
        self.personName = personName
        self.positionName = positionName
        self.positionCategory = positionCategory
        self.channelLabel = channelLabel
        self.source = source
        self.isIncluded = isIncluded
    }
}


// MARK: - ─── Drum Kit Template ──────────────────────────────────────────

/// Predefined drum channel configurations for expanding a single "DRUMS"
/// team position into multiple mixer channels.
enum DrumKitTemplate: String, CaseIterable, Identifiable, Codable {
    case basic3    = "Basic 3-Mic"
    case standard5 = "Standard 5-Mic"
    case full7     = "Full 7-Mic"
    case custom    = "Custom"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .basic3:    return "3.circle.fill"
        case .standard5: return "5.circle.fill"
        case .full7:     return "7.circle.fill"
        case .custom:    return "slider.horizontal.3"
        }
    }

    /// Default channels for this template.
    var channels: [(label: String, source: InputSource)] {
        switch self {
        case .basic3:
            return [
                ("Kick", .kickDrum),
                ("Snare", .snareDrum),
                ("OH", .overheadL),
            ]
        case .standard5:
            return [
                ("Kick", .kickDrum),
                ("Snare", .snareDrum),
                ("Hi-Hat", .hiHat),
                ("OH L", .overheadL),
                ("OH R", .overheadR),
            ]
        case .full7:
            return [
                ("Kick", .kickDrum),
                ("Snare", .snareDrum),
                ("Hi-Hat", .hiHat),
                ("Tom 1", .tomHigh),
                ("Tom 2", .tomFloor),
                ("OH L", .overheadL),
                ("OH R", .overheadR),
            ]
        case .custom:
            // Custom returns the standard5 as a starting point
            return DrumKitTemplate.standard5.channels
        }
    }

    /// All available drum sources for custom selection.
    static let allDrumSources: [(label: String, source: InputSource)] = [
        ("Kick", .kickDrum),
        ("Snare", .snareDrum),
        ("Hi-Hat", .hiHat),
        ("Tom (High)", .tomHigh),
        ("Tom (Mid)", .tomMid),
        ("Tom (Floor)", .tomFloor),
        ("OH L", .overheadL),
        ("OH R", .overheadR),
        ("Cajón", .cajon),
    ]
}


// MARK: - ─── AnyCodable Helper ───────────────────────────────────────────

/// Minimal type-erased Codable wrapper for parsing arbitrary JSON:API
/// included resource attributes without knowing the exact shape.
struct AnyCodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            value = ""
        }
    }
}
