// ============================================================================
// MixerConnectionView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Interface for connecting to A&H mixers via TCP/MIDI. Shows
//          connection status, IP entry, live channel state, and provides
//          a "Save Snapshot" action to persist the live reading for analysis.
//          Read-only for beta — displays mixer state but doesn't push settings.
// ============================================================================

import SwiftUI


// MARK: - ─── Mixer Connection View ────────────────────────────────────────

struct MixerConnectionView: View {
    @ObservedObject var connectionManager: MixerConnectionManager
    @ObservedObject var store: ServiceStore

    @State private var hostInput: String = ""
    @State private var portInput: String = "51325"
    @State private var selectedMixer: MixerModel = .allenHeathAvantis
    @State private var showingSaveSheet = false
    @State private var snapshotName: String = ""

    private var supportedMixers: [MixerModel] {
        MixerModel.allCases.filter { MixerConnectionManager.supportsTCPMIDI($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        connectionSection
                        statusSection

                        if connectionManager.status.isConnected {
                            channelListSection
                            saveSnapshotSection
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Live Mixer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
        }
    }


    // MARK: - ─── Connection Section ──────────────────────────────────────────

    private var connectionSection: some View {
        SectionCard(title: "Connection") {
            // ── Mixer Selection ──
            HStack {
                Text("Console")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                Spacer()
                Picker("Console", selection: $selectedMixer) {
                    ForEach(supportedMixers) { mixer in
                        Text(mixer.shortName).tag(mixer)
                    }
                }
                .pickerStyle(.menu)
                .tint(BoothColors.accent)
                .disabled(connectionManager.status.isConnected)
            }

            // ── IP Address ──
            HStack(spacing: 12) {
                Text("IP Address")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                Spacer()
                TextField("192.168.1.x", text: $hostInput)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(BoothColors.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
                    .keyboardType(.decimalPad)
                    .disabled(connectionManager.status.isConnected)
                    .frame(maxWidth: 160)
            }

            // ── Port ──
            HStack(spacing: 12) {
                Text("Port")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                Spacer()
                TextField("51325", text: $portInput)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(BoothColors.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .disabled(connectionManager.status.isConnected)
                    .frame(maxWidth: 80)
            }

            // ── Connect/Disconnect Button ──
            connectButton
        }
    }

    private var connectButton: some View {
        Button {
            if connectionManager.status.isConnected {
                connectionManager.disconnect()
            } else {
                let portNum = UInt16(portInput) ?? 51325
                connectionManager.connect(
                    host: hostInput,
                    port: portNum,
                    mixerModel: selectedMixer
                )
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: connectionManager.status.isConnected
                      ? "cable.connector.horizontal"
                      : "cable.connector")
                Text(connectionManager.status.isConnected ? "Disconnect" : "Connect")
            }
            .font(.system(size: 14, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .foregroundStyle(connectionManager.status.isConnected
                             ? BoothColors.accentDanger
                             : BoothColors.background)
            .background(connectionManager.status.isConnected
                        ? BoothColors.surfaceElevated
                        : BoothColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(hostInput.isEmpty && !connectionManager.status.isConnected)
    }


    // MARK: - ─── Status Section ──────────────────────────────────────────────

    private var statusSection: some View {
        SectionCard(title: "Status") {
            HStack(spacing: 12) {
                // Status LED
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: statusColor.opacity(0.6), radius: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(connectionManager.status.displayText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(BoothColors.textPrimary)

                    if let error = connectionManager.lastError {
                        Text(error)
                            .font(.system(size: 11))
                            .foregroundStyle(BoothColors.accentDanger)
                    }
                }

                Spacer()

                if connectionManager.status.isConnected {
                    Text("\(connectionManager.channelCount) ch")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(BoothColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    private var statusColor: Color {
        switch connectionManager.status {
        case .connected:       return BoothColors.accent
        case .connecting:      return BoothColors.accentWarm
        case .reconnecting:    return BoothColors.accentWarm
        case .disconnected:    return BoothColors.textMuted
        case .error:           return BoothColors.accentDanger
        }
    }


    // MARK: - ─── Channel List ────────────────────────────────────────────────

    private var channelListSection: some View {
        SectionCard(title: "Live Channels") {
            if connectionManager.liveSnapshot.channels.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .font(.system(size: 24))
                            .foregroundStyle(BoothColors.textMuted)
                        Text("Reading mixer state...")
                            .font(.system(size: 12))
                            .foregroundStyle(BoothColors.textSecondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(connectionManager.liveSnapshot.channels) { channel in
                    liveChannelRow(channel)
                }
            }
        }
    }

    private func liveChannelRow(_ channel: ChannelSnapshot) -> some View {
        VStack(spacing: 8) {
            // Channel header
            HStack {
                Text("Ch \(channel.channelNumber)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BoothColors.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                Text(channel.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)

                Spacer()

                if channel.phantomPower == true {
                    Text("48V")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(BoothColors.accentWarm)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(BoothColors.accentWarm.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
            }

            // Parameter values
            HStack(spacing: 16) {
                paramBadge(label: "GAIN", value: channel.gainDB, unit: "dB", decimals: 1)
                paramBadge(label: "FADER", value: channel.faderDB, unit: "dB", decimals: 1)
                paramBadge(label: "HPF", value: channel.hpfFrequency, unit: "Hz", decimals: 0)
                Spacer()
            }
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func paramBadge(label: String, value: Double?, unit: String, decimals: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)

            if let value {
                Text("\(value, specifier: "%.\(decimals)f") \(unit)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(BoothColors.textPrimary)
            } else {
                Text("—")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
            }
        }
    }


    // MARK: - ─── Save Snapshot ───────────────────────────────────────────────

    private var saveSnapshotSection: some View {
        SectionCard(title: "Actions") {
            Button {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, h:mm a"
                snapshotName = "Live — \(dateFormatter.string(from: Date()))"
                showingSaveSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Snapshot")
                }
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text("Save the current mixer state for offline analysis and comparison against engine recommendations.")
                .font(.system(size: 11))
                .foregroundStyle(BoothColors.textSecondary)
                .lineSpacing(2)
        }
        .alert("Save Snapshot", isPresented: $showingSaveSheet) {
            TextField("Snapshot name", text: $snapshotName)
            Button("Save") {
                let snapshot = connectionManager.saveCurrentSnapshot(name: snapshotName)
                store.saveSnapshot(snapshot)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Name this snapshot for later reference.")
        }
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("Mixer Connection") {
    MixerConnectionView(
        connectionManager: MixerConnectionManager(),
        store: ServiceStore()
    )
}
