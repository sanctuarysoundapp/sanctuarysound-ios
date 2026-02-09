// ============================================================================
// ConsoleProfile.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Data Layer
// Purpose: Stored console configurations for the Consoles tab.
//          Links a MixerModel to connection details and venue/room.
// ============================================================================

import Foundation


// MARK: - ─── Console Connection Type ─────────────────────────────────────────

/// How the app communicates with a physical console.
enum ConsoleConnectionType: String, Codable, CaseIterable, Identifiable {
    case tcpMIDI = "TCP/MIDI"
    case csvOnly = "CSV Import Only"

    var id: String { rawValue }

    var localizedName: String {
        String(localized: String.LocalizationValue(rawValue))
    }
}


// MARK: - ─── Console Profile ─────────────────────────────────────────────────

/// A saved console configuration in the user's console library.
struct ConsoleProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var model: MixerModel
    var ipAddress: String?
    var port: Int
    var connectionType: ConsoleConnectionType
    var linkedVenueID: UUID?
    var linkedRoomID: UUID?
    var notes: String?
    let dateAdded: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        model: MixerModel = .allenHeathAvantis,
        ipAddress: String? = nil,
        port: Int = 51325,
        connectionType: ConsoleConnectionType = .tcpMIDI,
        linkedVenueID: UUID? = nil,
        linkedRoomID: UUID? = nil,
        notes: String? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.model = model
        self.ipAddress = ipAddress
        self.port = port
        self.connectionType = connectionType
        self.linkedVenueID = linkedVenueID
        self.linkedRoomID = linkedRoomID
        self.notes = notes
        self.dateAdded = dateAdded
    }
}
