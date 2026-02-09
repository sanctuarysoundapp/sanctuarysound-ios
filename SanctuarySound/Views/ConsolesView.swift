// ============================================================================
// ConsolesView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Consoles tab — manage console library, TCP/MIDI connections,
//          CSV import, and delta analysis. Merges former Analysis + Mixer tabs.
// ============================================================================

import SwiftUI


// MARK: - ─── Consoles View ───────────────────────────────────────────────────

struct ConsolesView: View {
    @ObservedObject var store: ServiceStore
    @ObservedObject var connectionManager: MixerConnectionManager

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Console Library ──
                        consoleLibrarySection

                        // ── Snapshots ──
                        snapshotsSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Consoles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }


    // MARK: - Console Library

    private var consoleLibrarySection: some View {
        SectionCard(title: "My Consoles (\(store.consoleProfiles.count))") {
            if store.consoleProfiles.isEmpty {
                emptyConsoleState
            } else {
                ForEach(store.consoleProfiles) { profile in
                    consoleRow(profile)
                }
            }

            Button {
                // TODO: Add console sheet
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Console")
                }
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .foregroundStyle(BoothColors.textSecondary)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var emptyConsoleState: some View {
        VStack(spacing: 8) {
            Image(systemName: "slider.horizontal.below.rectangle")
                .font(.system(size: 28))
                .foregroundStyle(BoothColors.textMuted)
            Text("No consoles configured yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(BoothColors.textMuted)
            Text("Add your mixer to import settings or connect live")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private func consoleRow(_ profile: ConsoleProfile) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(profile.name.isEmpty ? profile.model.shortName : profile.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(BoothColors.textPrimary)

                    connectionBadge(for: profile)
                }

                HStack(spacing: 6) {
                    Text(profile.model.localizedName)
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textSecondary)
                    if let ip = profile.ipAddress, !ip.isEmpty {
                        Text("\u{00B7}")
                            .foregroundStyle(BoothColors.textMuted)
                        Text(ip)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(BoothColors.textMuted)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textMuted)
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func connectionBadge(for profile: ConsoleProfile) -> some View {
        Group {
            switch profile.connectionType {
            case .tcpMIDI:
                Text("TCP")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accent)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(BoothColors.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            case .csvOnly:
                Text("CSV")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accentWarm)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(BoothColors.accentWarm.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
    }


    // MARK: - Snapshots

    private var snapshotsSection: some View {
        SectionCard(title: "Mixer Snapshots (\(store.savedSnapshots.count))") {
            if store.savedSnapshots.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "camera.metering.unknown")
                        .font(.system(size: 28))
                        .foregroundStyle(BoothColors.textMuted)
                    Text("No snapshots yet. Import a CSV or save from a live connection.")
                        .font(.system(size: 12))
                        .foregroundStyle(BoothColors.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            } else {
                ForEach(store.savedSnapshots) { snapshot in
                    snapshotRow(snapshot)
                }
            }
        }
    }

    private func snapshotRow(_ snapshot: MixerSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                Text("\(snapshot.channels.count) channels \u{00B7} \(snapshot.mixer.shortName)")
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
            }
            Spacer()
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
