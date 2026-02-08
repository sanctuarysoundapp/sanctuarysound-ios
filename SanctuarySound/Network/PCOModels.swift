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
    let itemType: String?  // "song", "header", "media", "item"
    let length: Int?       // Duration in seconds
    let description: String?
    let songId: String?
    let key: String?       // Musical key if available at plan item level

    enum CodingKeys: String, CodingKey {
        case title
        case itemType = "item_type"
        case length, description
        case songId = "song_id"
        case key
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

    enum CodingKeys: String, CodingKey {
        case name, bpm, length
        case meterNumerator = "meter_numerator"
        case meterDenominator = "meter_denominator"
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
