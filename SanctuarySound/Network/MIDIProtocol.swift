// ============================================================================
// MIDIProtocol.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Network Layer
// Purpose: Parses raw TCP byte streams into discrete MIDI messages and
//          assembles NRPN sequences. Handles running status, multi-byte
//          messages, and System Exclusive boundaries. Also provides encoding
//          for building outgoing NRPN request messages.
// ============================================================================

import Foundation


// MARK: - ─── MIDI Stream Parser ───────────────────────────────────────────

/// Parses a continuous TCP byte stream into discrete MIDI messages.
/// Handles MIDI running status where the status byte is omitted for
/// consecutive messages of the same type.
final class MIDIStreamParser {

    private var buffer: [UInt8] = []
    private var lastStatus: UInt8 = 0

    /// Feed raw bytes from the TCP stream. Returns any complete MIDI messages.
    func parse(data: Data) -> [MIDIMessage] {
        var messages: [MIDIMessage] = []
        for byte in data {
            if let msg = processByte(byte) {
                messages.append(msg)
            }
        }
        return messages
    }

    /// Reset parser state (e.g., on reconnect).
    func reset() {
        buffer.removeAll()
        lastStatus = 0
    }

    private func processByte(_ byte: UInt8) -> MIDIMessage? {
        // System real-time messages (0xF8-0xFF) — single byte, don't affect running status
        if byte >= 0xF8 {
            return nil
        }

        // Status byte (bit 7 set)
        if byte & 0x80 != 0 {
            // System exclusive — skip until end
            if byte == 0xF0 {
                buffer = [byte]
                lastStatus = 0
                return nil
            }
            if byte == 0xF7 {
                buffer.removeAll()
                return nil
            }

            // System common — reset running status
            if byte >= 0xF0 {
                lastStatus = 0
                buffer.removeAll()
                return nil
            }

            // Channel message status byte
            lastStatus = byte
            buffer = [byte]
            return nil
        }

        // Data byte (bit 7 clear)

        // Running status — reuse last status byte
        if buffer.isEmpty && lastStatus != 0 {
            buffer = [lastStatus]
        }

        guard !buffer.isEmpty else { return nil }

        buffer.append(byte)

        let status = buffer[0]
        let command = status & 0xF0

        // Messages with 2 data bytes
        let twoByteCommands: [UInt8] = [0x80, 0x90, 0xA0, 0xB0, 0xE0]
        if twoByteCommands.contains(command) && buffer.count == 3 {
            let msg = MIDIMessage(status: buffer[0], data1: buffer[1], data2: buffer[2])
            buffer = [status] // Keep for running status
            buffer.removeAll()
            return msg
        }

        // Messages with 1 data byte
        let oneByteCommands: [UInt8] = [0xC0, 0xD0]
        if oneByteCommands.contains(command) && buffer.count == 2 {
            let msg = MIDIMessage(status: buffer[0], data1: buffer[1], data2: 0)
            buffer.removeAll()
            return msg
        }

        return nil
    }
}


// MARK: - ─── NRPN Assembler ──────────────────────────────────────────────

/// Assembles individual CC messages into complete NRPN sequences.
/// An NRPN sequence is: CC#99 (param MSB), CC#98 (param LSB),
/// CC#6 (value MSB), CC#38 (value LSB).
final class NRPNAssembler {

    private struct PendingNRPN {
        var paramMSB: UInt8?
        var paramLSB: UInt8?
        var valueMSB: UInt8?
        var valueLSB: UInt8?
        var channel: UInt8 = 0
    }

    /// Per-channel pending NRPN state.
    private var pending: [UInt8: PendingNRPN] = [:]

    /// Process a MIDI message. Returns a completed NRPN if the sequence is finished.
    func process(message: MIDIMessage) -> NRPNMessage? {
        guard message.isControlChange else { return nil }

        let ch = message.channel
        var state = pending[ch] ?? PendingNRPN(channel: ch)

        switch message.controlNumber {
        case MIDIControlNumber.nrpnMSB.rawValue:
            // Start of new NRPN sequence
            state = PendingNRPN(channel: ch)
            state.paramMSB = message.controlValue

        case MIDIControlNumber.nrpnLSB.rawValue:
            state.paramLSB = message.controlValue

        case MIDIControlNumber.dataEntryMSB.rawValue:
            state.valueMSB = message.controlValue

        case MIDIControlNumber.dataEntryLSB.rawValue:
            state.valueLSB = message.controlValue

            // Check if NRPN sequence is complete
            if let pMSB = state.paramMSB,
               let pLSB = state.paramLSB,
               let vMSB = state.valueMSB,
               let vLSB = state.valueLSB {
                pending[ch] = nil
                return NRPNMessage(
                    channel: ch,
                    parameterMSB: pMSB,
                    parameterLSB: pLSB,
                    valueMSB: vMSB,
                    valueLSB: vLSB
                )
            }

        default:
            // Non-NRPN CC — reset state for this channel
            pending[ch] = nil
            return nil
        }

        pending[ch] = state
        return nil
    }

    /// Reset all pending state (e.g., on reconnect).
    func reset() {
        pending.removeAll()
    }
}


// MARK: - ─── NRPN Encoder ────────────────────────────────────────────────

/// Encodes NRPN messages into raw bytes for TCP transmission.
enum NRPNEncoder {

    /// Encode a single NRPN message into 4 CC messages (12 bytes total).
    static func encode(nrpn: NRPNMessage) -> Data {
        let channel = nrpn.channel & 0x0F
        let ccStatus = 0xB0 | channel

        var bytes: [UInt8] = []

        // CC#99 — NRPN Parameter MSB
        bytes.append(ccStatus)
        bytes.append(MIDIControlNumber.nrpnMSB.rawValue)
        bytes.append(nrpn.parameterMSB & 0x7F)

        // CC#98 — NRPN Parameter LSB
        bytes.append(ccStatus)
        bytes.append(MIDIControlNumber.nrpnLSB.rawValue)
        bytes.append(nrpn.parameterLSB & 0x7F)

        // CC#6 — Data Entry MSB
        bytes.append(ccStatus)
        bytes.append(MIDIControlNumber.dataEntryMSB.rawValue)
        bytes.append(nrpn.valueMSB & 0x7F)

        // CC#38 — Data Entry LSB
        bytes.append(ccStatus)
        bytes.append(MIDIControlNumber.dataEntryLSB.rawValue)
        bytes.append(nrpn.valueLSB & 0x7F)

        return Data(bytes)
    }

    /// Encode multiple NRPN messages into a single data payload.
    static func encode(messages: [NRPNMessage]) -> Data {
        var data = Data()
        for nrpn in messages {
            data.append(encode(nrpn: nrpn))
        }
        return data
    }
}
