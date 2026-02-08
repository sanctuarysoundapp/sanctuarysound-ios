// ============================================================================
// MIDIMessageTypes.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Network Layer
// Purpose: Core MIDI message types for Allen & Heath TCP/MIDI protocol.
//          Defines message structures, NRPN parameters, and value conversions
//          used by both Avantis and SQ consoles on port 51325.
// ============================================================================

import Foundation


// MARK: - ─── MIDI Commands ────────────────────────────────────────────────

/// Standard MIDI status byte commands (upper nibble).
enum MIDICommand: UInt8 {
    case noteOff         = 0x80
    case noteOn          = 0x90
    case polyPressure    = 0xA0
    case controlChange   = 0xB0
    case programChange   = 0xC0
    case channelPressure = 0xD0
    case pitchBend       = 0xE0
    case system          = 0xF0
}


// MARK: - ─── MIDI Control Change Numbers ──────────────────────────────────

/// Well-known CC numbers used in A&H NRPN sequences.
enum MIDIControlNumber: UInt8 {
    case nrpnMSB     = 99   // CC#99 — NRPN parameter MSB
    case nrpnLSB     = 98   // CC#98 — NRPN parameter LSB
    case dataEntryMSB = 6   // CC#6  — Data Entry MSB
    case dataEntryLSB = 38  // CC#38 — Data Entry LSB
    case allNotesOff  = 123
}


// MARK: - ─── MIDI Message ─────────────────────────────────────────────────

/// A decoded MIDI message from the TCP stream.
struct MIDIMessage: Equatable {
    let status: UInt8
    let data1: UInt8
    let data2: UInt8

    var command: MIDICommand? {
        MIDICommand(rawValue: status & 0xF0)
    }

    var channel: UInt8 {
        status & 0x0F
    }

    var isControlChange: Bool {
        command == .controlChange
    }

    var controlNumber: UInt8 { data1 }
    var controlValue: UInt8 { data2 }
}


// MARK: - ─── NRPN Message ─────────────────────────────────────────────────

/// A fully assembled NRPN (Non-Registered Parameter Number) message.
/// A&H consoles use NRPN sequences to address specific channel parameters.
/// Sequence: CC#99 (paramMSB), CC#98 (paramLSB), CC#6 (valueMSB), CC#38 (valueLSB)
struct NRPNMessage: Equatable {
    let channel: UInt8
    let parameterMSB: UInt8
    let parameterLSB: UInt8
    let valueMSB: UInt8
    let valueLSB: UInt8

    /// Combined 14-bit parameter address.
    var parameter: UInt16 {
        (UInt16(parameterMSB) << 7) | UInt16(parameterLSB)
    }

    /// Combined 14-bit value.
    var value: UInt16 {
        (UInt16(valueMSB) << 7) | UInt16(valueLSB)
    }
}


// MARK: - ─── Parameter Types ──────────────────────────────────────────────

/// The type of mixer channel parameter an NRPN message addresses.
enum ParameterType: Equatable {
    case gain
    case pad
    case phantom
    case hpfFrequency
    case hpfEnable
    case fader
    case mute
    case channelName
    case eqFrequency(band: Int)
    case eqGain(band: Int)
    case eqQ(band: Int)
    case eqEnable(band: Int)
    case compThreshold
    case compRatio
    case compAttack
    case compRelease
    case unknown(msb: UInt8, lsb: UInt8)
}


// MARK: - ─── Connection Status ────────────────────────────────────────────

/// Represents the current state of the TCP/MIDI mixer connection.
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(attempt: Int)
    case error(String)

    var displayText: String {
        switch self {
        case .disconnected:                return "Disconnected"
        case .connecting:                  return "Connecting..."
        case .connected:                   return "Connected"
        case .reconnecting(let attempt):   return "Reconnecting (\(attempt))..."
        case .error(let msg):              return "Error: \(msg)"
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}


// MARK: - ─── Mixer MIDI Profile Protocol ──────────────────────────────────

/// Defines how a specific mixer model maps NRPN addresses to channel parameters.
/// Each A&H console family has different NRPN address layouts.
protocol MixerMIDIProfile {
    /// The mixer model this profile supports.
    var mixerModel: MixerModel { get }

    /// Default TCP port for MIDI communication.
    var defaultPort: UInt16 { get }

    /// Maximum number of input channels.
    var maxInputChannels: Int { get }

    /// Number of parametric EQ bands per channel.
    var eqBandCount: Int { get }

    /// Decode an NRPN message into a channel number and parameter type.
    func decodeParameter(nrpn: NRPNMessage) -> (channel: Int, parameter: ParameterType)?

    /// Convert a raw NRPN 14-bit value to engineering units for a given parameter type.
    func convertValue(raw: UInt16, parameter: ParameterType) -> Double

    /// Build NRPN messages to request the full state of a single channel.
    func buildChannelPollMessages(channel: Int) -> [NRPNMessage]
}
