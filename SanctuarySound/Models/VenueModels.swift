// ============================================================================
// VenueModels.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Data Layer
// Purpose: Venue and Room models for multi-location support.
//          A Venue contains one or more Rooms, each with acoustics and console.
// ============================================================================

import Foundation


// MARK: - ─── Venue ───────────────────────────────────────────────────────────

/// A physical location where services are held (e.g., "Main Campus", "North Building").
struct Venue: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var address: String?
    var rooms: [Room]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "My Church",
        address: String? = nil,
        rooms: [Room] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.rooms = rooms.isEmpty ? [Room()] : rooms
        self.createdAt = createdAt
    }
}


// MARK: - ─── Room ────────────────────────────────────────────────────────────

/// A specific worship space within a venue (e.g., "Sanctuary", "Youth Room").
struct Room: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var roomSize: RoomSize
    var roomSurface: RoomSurface
    var defaultMixer: MixerModel?
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String = "Main Room",
        roomSize: RoomSize = .medium,
        roomSurface: RoomSurface = .mixed,
        defaultMixer: MixerModel? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.roomSize = roomSize
        self.roomSurface = roomSurface
        self.defaultMixer = defaultMixer
        self.notes = notes
    }

    /// Converts this room's acoustics to a RoomProfile for the SoundEngine.
    var roomProfile: RoomProfile {
        RoomProfile(size: roomSize, surface: roomSurface)
    }
}
