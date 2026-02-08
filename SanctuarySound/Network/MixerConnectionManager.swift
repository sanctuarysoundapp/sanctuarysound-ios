// ============================================================================
// MixerConnectionManager.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Network Layer
// Purpose: Manages the TCP/MIDI connection to A&H consoles (Avantis, SQ).
//          Handles connection lifecycle, auto-reconnect with exponential
//          backoff, MIDI stream parsing, and live channel state updates.
//          Read-only for beta — no methods to push settings to the mixer.
// ============================================================================

import Foundation
import Network
import SwiftUI


// MARK: - ─── Mixer Connection Manager ─────────────────────────────────────

@MainActor
final class MixerConnectionManager: ObservableObject {

    // ── Published State ──

    @Published private(set) var status: ConnectionStatus = .disconnected
    @Published private(set) var liveSnapshot: MixerSnapshot
    @Published private(set) var lastError: String?
    @Published private(set) var channelCount: Int = 0

    // ── Configuration ──

    private(set) var host: String = ""
    private(set) var port: UInt16 = 51325
    private(set) var profile: (any MixerMIDIProfile)?

    // ── Internal State ──

    private var connection: NWConnection?
    private let parser = MIDIStreamParser()
    private let assembler = NRPNAssembler()
    private var reconnectAttempt = 0
    private var reconnectTask: Task<Void, Never>?
    private let maxReconnectAttempts = 10
    private let maxReconnectDelay: TimeInterval = 30

    // ── Channel Data ──

    private var channelData: [Int: ChannelSnapshot] = [:]


    // MARK: - Init

    init() {
        self.liveSnapshot = MixerSnapshot(
            name: "Live Connection",
            importedAt: Date(),
            mixer: .allenHeathAvantis,
            channels: []
        )
    }


    // MARK: - ─── Public API ──────────────────────────────────────────────────

    /// Connect to a mixer at the given host and port.
    func connect(host: String, port: UInt16, mixerModel: MixerModel) {
        disconnect()

        self.host = host
        self.port = port
        self.profile = Self.profile(for: mixerModel)
        self.reconnectAttempt = 0

        guard profile != nil else {
            status = .error("Unsupported mixer: \(mixerModel.rawValue)")
            return
        }

        liveSnapshot = MixerSnapshot(
            name: "Live — \(mixerModel.shortName)",
            importedAt: Date(),
            mixer: mixerModel,
            channels: []
        )
        channelData.removeAll()

        establishConnection()
    }

    /// Disconnect from the current mixer.
    func disconnect() {
        reconnectTask?.cancel()
        reconnectTask = nil
        connection?.cancel()
        connection = nil
        parser.reset()
        assembler.reset()
        status = .disconnected
        lastError = nil
    }

    /// Build a MixerSnapshot from the current live data for saving.
    func saveCurrentSnapshot(name: String) -> MixerSnapshot {
        let channels = channelData.sorted { $0.key < $1.key }.map { $0.value }
        return MixerSnapshot(
            name: name,
            importedAt: Date(),
            mixer: profile?.mixerModel ?? .allenHeathAvantis,
            channels: channels
        )
    }


    // MARK: - ─── Connection Lifecycle ────────────────────────────────────────

    private func establishConnection() {
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!
        let params = NWParameters.tcp

        status = .connecting

        let conn = NWConnection(host: nwHost, port: nwPort, using: params)
        self.connection = conn

        conn.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                self?.handleConnectionState(state)
            }
        }

        conn.start(queue: .global(qos: .userInitiated))
    }

    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            status = .connected
            lastError = nil
            reconnectAttempt = 0
            startReceiving()
            requestFullSnapshot()

        case .failed(let error):
            let msg = error.localizedDescription
            lastError = msg
            connection?.cancel()
            connection = nil
            scheduleReconnect()

        case .waiting(let error):
            lastError = error.localizedDescription
            status = .connecting

        case .cancelled:
            if case .disconnected = status {
                // User-initiated disconnect — don't reconnect
            } else {
                scheduleReconnect()
            }

        default:
            break
        }
    }

    private func scheduleReconnect() {
        guard reconnectAttempt < maxReconnectAttempts else {
            status = .error("Connection failed after \(maxReconnectAttempts) attempts")
            return
        }

        reconnectAttempt += 1
        status = .reconnecting(attempt: reconnectAttempt)

        // Exponential backoff: 1s, 2s, 4s, 8s, ... capped at maxReconnectDelay
        let delay = min(pow(2.0, Double(reconnectAttempt - 1)), maxReconnectDelay)

        reconnectTask = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            parser.reset()
            assembler.reset()
            establishConnection()
        }
    }


    // MARK: - ─── Receiving Data ──────────────────────────────────────────────

    private func startReceiving() {
        guard let conn = connection else { return }

        conn.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            Task { @MainActor in
                if let data, !data.isEmpty {
                    self?.processReceivedData(data)
                }

                if isComplete {
                    self?.connection?.cancel()
                    self?.scheduleReconnect()
                } else if let error {
                    self?.lastError = error.localizedDescription
                    self?.connection?.cancel()
                    self?.scheduleReconnect()
                } else {
                    self?.startReceiving()
                }
            }
        }
    }

    private func processReceivedData(_ data: Data) {
        let messages = parser.parse(data: data)

        for message in messages {
            if let nrpn = assembler.process(message: message) {
                handleNRPN(nrpn)
            }
        }
    }


    // MARK: - ─── NRPN Handling ───────────────────────────────────────────────

    private func handleNRPN(_ nrpn: NRPNMessage) {
        guard let profile else { return }

        guard let (channel, paramType) = profile.decodeParameter(nrpn: nrpn) else {
            return
        }

        let value = profile.convertValue(raw: nrpn.value, parameter: paramType)

        // Get or create channel snapshot
        var snapshot = channelData[channel] ?? ChannelSnapshot(
            channelNumber: channel + 1,
            name: "Ch \(channel + 1)"
        )

        switch paramType {
        case .gain:
            snapshot.gainDB = value
        case .fader:
            snapshot.faderDB = value
        case .hpfFrequency:
            snapshot.hpfFrequency = value
        case .hpfEnable:
            snapshot.hpfEnabled = value > 0
        case .phantom:
            snapshot.phantomPower = value > 0
        case .pad:
            snapshot.padEnabled = value > 0
        case .compThreshold:
            snapshot.compThresholdDB = value
        case .compRatio:
            snapshot.compRatio = value
        case .compAttack:
            snapshot.compAttackMS = value
        case .compRelease:
            snapshot.compReleaseMS = value
        case .eqFrequency(let band):
            ensureEQBands(&snapshot, count: band + 1)
            snapshot.eqBands[band].frequency = value
        case .eqGain(let band):
            ensureEQBands(&snapshot, count: band + 1)
            snapshot.eqBands[band].gainDB = value
        case .eqQ(let band):
            ensureEQBands(&snapshot, count: band + 1)
            snapshot.eqBands[band].q = value
        case .eqEnable(let band):
            ensureEQBands(&snapshot, count: band + 1)
            snapshot.eqBands[band].enabled = value > 0
        case .mute, .channelName, .unknown:
            break
        }

        channelData[channel] = snapshot
        channelCount = channelData.count

        // Update live snapshot periodically
        updateLiveSnapshot()
    }

    private func ensureEQBands(_ snapshot: inout ChannelSnapshot, count: Int) {
        while snapshot.eqBands.count < count {
            snapshot.eqBands.append(SnapshotEQBand(
                frequency: 1000.0,
                gainDB: 0.0,
                q: 1.0,
                enabled: true
            ))
        }
    }

    private func updateLiveSnapshot() {
        let channels = channelData.sorted { $0.key < $1.key }.map { $0.value }
        liveSnapshot = MixerSnapshot(
            id: liveSnapshot.id,
            name: liveSnapshot.name,
            importedAt: Date(),
            mixer: profile?.mixerModel ?? .allenHeathAvantis,
            channels: channels
        )
    }


    // MARK: - ─── Full Snapshot Request ───────────────────────────────────────

    /// Poll all channels to get the full mixer state on initial connection.
    private func requestFullSnapshot() {
        guard let profile, let connection else { return }

        let maxCh = profile.maxInputChannels

        // Build all poll messages for all channels
        var allMessages: [NRPNMessage] = []
        for ch in 0..<maxCh {
            allMessages.append(contentsOf: profile.buildChannelPollMessages(channel: ch))
        }

        // Encode and send in batches to avoid flooding
        let batchSize = 50
        let batches = stride(from: 0, to: allMessages.count, by: batchSize).map {
            Array(allMessages[$0..<min($0 + batchSize, allMessages.count)])
        }

        Task {
            for batch in batches {
                guard self.status.isConnected else { break }
                let data = NRPNEncoder.encode(messages: batch)
                connection.send(content: data, completion: .contentProcessed { _ in })
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }


    // MARK: - ─── Scene Phase Handling ────────────────────────────────────────

    /// Call when app enters background — disconnect to free TCP slot.
    func handleBackgrounding() {
        guard status.isConnected else { return }
        disconnect()
    }

    /// Call when app returns to foreground — reconnect if was previously connected.
    func handleForegrounding() {
        guard case .disconnected = status,
              !host.isEmpty,
              let profile else { return }
        connect(host: host, port: port, mixerModel: profile.mixerModel)
    }


    // MARK: - ─── Helpers ─────────────────────────────────────────────────────

    /// Returns the appropriate MIDI profile for a given mixer model.
    static func profile(for mixer: MixerModel) -> (any MixerMIDIProfile)? {
        switch mixer {
        case .allenHeathAvantis, .allenHeathDLive:
            return AvantisMIDIProfile()
        case .allenHeathSQ:
            return SQMIDIProfile()
        default:
            return nil
        }
    }

    /// Whether the given mixer model supports TCP/MIDI connection.
    static func supportsTCPMIDI(_ mixer: MixerModel) -> Bool {
        profile(for: mixer) != nil
    }
}
