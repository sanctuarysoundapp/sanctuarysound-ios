// ============================================================================
// AvantisMIDIProfile.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Network Layer
// Purpose: Allen & Heath Avantis MIDI TCP profile. Maps NRPN parameter
//          addresses to channel parameters using the Avantis MIDI TCP
//          Protocol V1.0 specification. Port 51325 (unsecured).
// ============================================================================

import Foundation


// MARK: - ─── Avantis MIDI Profile ─────────────────────────────────────────

struct AvantisMIDIProfile: MixerMIDIProfile {

    let mixerModel: MixerModel = .allenHeathAvantis
    let defaultPort: UInt16 = 51325
    let maxInputChannels: Int = 64
    let eqBandCount: Int = 4

    // ── NRPN Parameter Address Ranges ──
    // Avantis uses NRPN MSB to identify parameter category and LSB for channel/band.
    // These are based on the A&H Avantis MIDI TCP Protocol documentation.

    private enum ParamMSB: UInt8 {
        case gain          = 0x40  // 64 — Input gain
        case pad           = 0x41  // 65 — Pad on/off
        case phantom       = 0x42  // 66 — 48V phantom power
        case hpfFrequency  = 0x43  // 67 — HPF frequency
        case hpfEnable     = 0x44  // 68 — HPF on/off
        case eqFrequency   = 0x50  // 80 — PEQ frequency (bands 0-3)
        case eqGain        = 0x51  // 81 — PEQ gain
        case eqQ           = 0x52  // 82 — PEQ Q factor
        case eqEnable      = 0x53  // 83 — PEQ band enable
        case compThreshold = 0x58  // 88 — Compressor threshold
        case compRatio     = 0x59  // 89 — Compressor ratio
        case compAttack    = 0x5A  // 90 — Compressor attack
        case compRelease   = 0x5B  // 91 — Compressor release
        case fader         = 0x60  // 96 — Fader position
        case mute          = 0x61  // 97 — Mute on/off
    }

    /// Number of channels per EQ band offset in the LSB address space.
    private let channelsPerEQOffset = 64


    // MARK: - Decode

    func decodeParameter(nrpn: NRPNMessage) -> (channel: Int, parameter: ParameterType)? {
        guard let paramCategory = ParamMSB(rawValue: nrpn.parameterMSB) else {
            return (Int(nrpn.parameterLSB), .unknown(msb: nrpn.parameterMSB, lsb: nrpn.parameterLSB))
        }

        let lsb = Int(nrpn.parameterLSB)

        switch paramCategory {
        case .gain:
            return (lsb, .gain)
        case .pad:
            return (lsb, .pad)
        case .phantom:
            return (lsb, .phantom)
        case .hpfFrequency:
            return (lsb, .hpfFrequency)
        case .hpfEnable:
            return (lsb, .hpfEnable)
        case .fader:
            return (lsb, .fader)
        case .mute:
            return (lsb, .mute)
        case .compThreshold:
            return (lsb, .compThreshold)
        case .compRatio:
            return (lsb, .compRatio)
        case .compAttack:
            return (lsb, .compAttack)
        case .compRelease:
            return (lsb, .compRelease)
        case .eqFrequency:
            let band = lsb / channelsPerEQOffset
            let channel = lsb % channelsPerEQOffset
            return (channel, .eqFrequency(band: band))
        case .eqGain:
            let band = lsb / channelsPerEQOffset
            let channel = lsb % channelsPerEQOffset
            return (channel, .eqGain(band: band))
        case .eqQ:
            let band = lsb / channelsPerEQOffset
            let channel = lsb % channelsPerEQOffset
            return (channel, .eqQ(band: band))
        case .eqEnable:
            let band = lsb / channelsPerEQOffset
            let channel = lsb % channelsPerEQOffset
            return (channel, .eqEnable(band: band))
        }
    }


    // MARK: - Value Conversion

    func convertValue(raw: UInt16, parameter: ParameterType) -> Double {
        switch parameter {
        case .gain:
            // Avantis gain: 0-16383 maps to 5-60 dB
            return 5.0 + (Double(raw) / 16383.0) * 55.0

        case .fader:
            // Fader: 0-16383 maps to -inf to +10 dB
            // 0 = -inf, ~12288 = 0 dB (unity), 16383 = +10 dB
            if raw == 0 { return -120.0 }
            return -120.0 + (Double(raw) / 16383.0) * 130.0

        case .hpfFrequency:
            // HPF: 0-16383 maps logarithmically to 20-2000 Hz
            let normalized = Double(raw) / 16383.0
            return 20.0 * pow(100.0, normalized)

        case .compThreshold:
            // Threshold: 0-16383 maps to -46 to 18 dB
            return -46.0 + (Double(raw) / 16383.0) * 64.0

        case .compRatio:
            // Ratio: 0-16383 maps to 1:1 through inf:1
            // Common stops: 1, 1.5, 2, 3, 4, 6, 8, 10, 20, inf
            let normalized = Double(raw) / 16383.0
            if normalized >= 0.99 { return 100.0 }
            return 1.0 + normalized * 19.0

        case .compAttack:
            // Attack: 0-16383 maps logarithmically to 0.02-300 ms
            let normalized = Double(raw) / 16383.0
            return 0.02 * pow(15000.0, normalized)

        case .compRelease:
            // Release: 0-16383 maps logarithmically to 5-2000 ms
            let normalized = Double(raw) / 16383.0
            return 5.0 * pow(400.0, normalized)

        case .eqFrequency:
            // EQ freq: 0-16383 maps logarithmically to 20-20000 Hz
            let normalized = Double(raw) / 16383.0
            return 20.0 * pow(1000.0, normalized)

        case .eqGain:
            // EQ gain: 0-16383 maps to -15 to +15 dB, center = 0
            return -15.0 + (Double(raw) / 16383.0) * 30.0

        case .eqQ:
            // Q factor: 0-16383 maps logarithmically to 0.3-20
            let normalized = Double(raw) / 16383.0
            return 0.3 * pow(66.67, normalized)

        case .pad, .phantom, .hpfEnable, .mute, .eqEnable:
            // Boolean: 0 = off, >0 = on
            return raw > 0 ? 1.0 : 0.0

        case .channelName, .unknown:
            return Double(raw)
        }
    }


    // MARK: - Poll Messages

    func buildChannelPollMessages(channel: Int) -> [NRPNMessage] {
        guard channel < maxInputChannels else { return [] }
        let ch: UInt8 = 0  // MIDI channel 0 for control messages
        let lsb = UInt8(channel)

        var messages: [NRPNMessage] = []

        // Request each parameter — sending value 0x7F/0x7F as a "query"
        let paramMSBs: [UInt8] = [
            ParamMSB.gain.rawValue,
            ParamMSB.pad.rawValue,
            ParamMSB.phantom.rawValue,
            ParamMSB.hpfFrequency.rawValue,
            ParamMSB.hpfEnable.rawValue,
            ParamMSB.fader.rawValue,
            ParamMSB.mute.rawValue,
            ParamMSB.compThreshold.rawValue,
            ParamMSB.compRatio.rawValue,
            ParamMSB.compAttack.rawValue,
            ParamMSB.compRelease.rawValue,
        ]

        for msb in paramMSBs {
            messages.append(NRPNMessage(
                channel: ch,
                parameterMSB: msb,
                parameterLSB: lsb,
                valueMSB: 0x7F,
                valueLSB: 0x7F
            ))
        }

        // EQ bands (4 bands)
        for band in 0..<eqBandCount {
            let eqLSB = UInt8(band * channelsPerEQOffset + channel)
            for eqMSB in [ParamMSB.eqFrequency, .eqGain, .eqQ, .eqEnable] {
                messages.append(NRPNMessage(
                    channel: ch,
                    parameterMSB: eqMSB.rawValue,
                    parameterLSB: eqLSB,
                    valueMSB: 0x7F,
                    valueLSB: 0x7F
                ))
            }
        }

        return messages
    }
}
