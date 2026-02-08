// ============================================================================
// SQMIDIProfile.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Network Layer
// Purpose: Allen & Heath SQ Series MIDI TCP profile. Maps NRPN parameter
//          addresses to channel parameters using the SQ MIDI Protocol
//          specification. Port 51325 (unsecured). Different NRPN addresses
//          from Avantis despite both being A&H consoles.
// ============================================================================

import Foundation


// MARK: - ─── SQ MIDI Profile ──────────────────────────────────────────────

struct SQMIDIProfile: MixerMIDIProfile {

    let mixerModel: MixerModel = .allenHeathSQ
    let defaultPort: UInt16 = 51325
    let maxInputChannels: Int = 48
    let eqBandCount: Int = 4

    // ── NRPN Parameter Address Ranges ──
    // SQ uses different MSB offsets than Avantis for the same parameter types.
    // Based on A&H SQ MIDI Protocol documentation.

    private enum ParamMSB: UInt8 {
        case gain          = 0x30  // 48 — Input gain
        case pad           = 0x31  // 49 — Pad on/off
        case phantom       = 0x32  // 50 — 48V phantom power
        case hpfFrequency  = 0x33  // 51 — HPF frequency
        case hpfEnable     = 0x34  // 52 — HPF on/off
        case eqFrequency   = 0x38  // 56 — PEQ frequency (bands 0-3)
        case eqGain        = 0x39  // 57 — PEQ gain
        case eqQ           = 0x3A  // 58 — PEQ Q factor
        case eqEnable      = 0x3B  // 59 — PEQ band enable
        case compThreshold = 0x3C  // 60 — Compressor threshold
        case compRatio     = 0x3D  // 61 — Compressor ratio
        case compAttack    = 0x3E  // 62 — Compressor attack
        case compRelease   = 0x3F  // 63 — Compressor release
        case fader         = 0x48  // 72 — Fader position
        case mute          = 0x49  // 73 — Mute on/off
    }

    private let channelsPerEQOffset = 48


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
        // SQ uses the same value ranges as Avantis for most parameters,
        // but with SQ-specific gain range (0-60 dB instead of 5-60 dB).
        switch parameter {
        case .gain:
            // SQ gain: 0-16383 maps to 0-60 dB
            return (Double(raw) / 16383.0) * 60.0

        case .fader:
            if raw == 0 { return -120.0 }
            return -120.0 + (Double(raw) / 16383.0) * 130.0

        case .hpfFrequency:
            let normalized = Double(raw) / 16383.0
            return 20.0 * pow(100.0, normalized)

        case .compThreshold:
            return -46.0 + (Double(raw) / 16383.0) * 64.0

        case .compRatio:
            let normalized = Double(raw) / 16383.0
            if normalized >= 0.99 { return 100.0 }
            return 1.0 + normalized * 19.0

        case .compAttack:
            let normalized = Double(raw) / 16383.0
            return 0.02 * pow(15000.0, normalized)

        case .compRelease:
            let normalized = Double(raw) / 16383.0
            return 5.0 * pow(400.0, normalized)

        case .eqFrequency:
            let normalized = Double(raw) / 16383.0
            return 20.0 * pow(1000.0, normalized)

        case .eqGain:
            return -15.0 + (Double(raw) / 16383.0) * 30.0

        case .eqQ:
            let normalized = Double(raw) / 16383.0
            return 0.3 * pow(66.67, normalized)

        case .pad, .phantom, .hpfEnable, .mute, .eqEnable:
            return raw > 0 ? 1.0 : 0.0

        case .channelName, .unknown:
            return Double(raw)
        }
    }


    // MARK: - Poll Messages

    func buildChannelPollMessages(channel: Int) -> [NRPNMessage] {
        guard channel < maxInputChannels else { return [] }
        let ch: UInt8 = 0
        let lsb = UInt8(channel)

        var messages: [NRPNMessage] = []

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
