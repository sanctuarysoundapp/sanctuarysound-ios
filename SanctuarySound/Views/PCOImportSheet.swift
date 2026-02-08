// ============================================================================
// PCOImportSheet.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Sheet UI for importing setlists and team rosters from Planning
//          Center Online. Workflow: Connect → Pick Service Type → Pick Plan →
//          Preview → Confirm Import. Accessible from SetlistStepView and
//          ChannelsStepView in the service setup wizard.
// ============================================================================

import SwiftUI


// MARK: - ─── Import Mode ─────────────────────────────────────────────────

enum PCOImportMode {
    case setlist
    case team
}


// MARK: - ─── PCO Import Sheet ────────────────────────────────────────────

struct PCOImportSheet: View {
    @ObservedObject var manager: PlanningCenterManager
    let mode: PCOImportMode
    let onImportSetlist: ([SetlistSong]) -> Void
    let onImportTeam: ([InputChannel]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedServiceTypeID: String?
    @State private var selectedPlanID: String?
    @State private var importedSongs: [SetlistSong] = []
    @State private var importedChannels: [InputChannel] = []
    @State private var step: ImportStep = .serviceType

    private enum ImportStep {
        case serviceType
        case plan
        case preview
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                Group {
                    if !manager.client.isAuthenticated {
                        connectPrompt
                    } else {
                        switch step {
                        case .serviceType:
                            serviceTypeList
                        case .plan:
                            planList
                        case .preview:
                            previewContent
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .setlist: return "Import Setlist"
        case .team:    return "Import Team"
        }
    }


    // MARK: - ─── Connect Prompt ──────────────────────────────────────────────

    private var connectPrompt: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "link.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(BoothColors.accent)

            Text("Connect to Planning Center")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(BoothColors.textPrimary)

            Text("Sign in with your Planning Center account to import \(mode == .setlist ? "setlists" : "team rosters") directly.")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task {
                    try? await manager.client.authenticate()
                    if manager.client.isAuthenticated {
                        await manager.loadServiceTypes()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Connect with Planning Center")
                }
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }


    // MARK: - ─── Service Type List ───────────────────────────────────────────

    private var serviceTypeList: some View {
        VStack(spacing: 0) {
            if manager.isLoading {
                loadingView
            } else if manager.serviceTypes.isEmpty {
                emptyView(message: "No service types found")
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(manager.serviceTypes) { serviceType in
                            Button {
                                selectedServiceTypeID = serviceType.id
                                Task {
                                    await manager.loadPlans(serviceTypeID: serviceType.id)
                                    step = .plan
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(serviceType.attributes.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(BoothColors.textPrimary)
                                        if let freq = serviceType.attributes.frequency {
                                            Text(freq)
                                                .font(.system(size: 11))
                                                .foregroundStyle(BoothColors.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(BoothColors.textMuted)
                                }
                                .padding(14)
                                .background(BoothColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if manager.serviceTypes.isEmpty {
                Task { await manager.loadServiceTypes() }
            }
        }
    }


    // MARK: - ─── Plan List ───────────────────────────────────────────────────

    private var planList: some View {
        VStack(spacing: 0) {
            if manager.isLoading {
                loadingView
            } else if manager.plans.isEmpty {
                emptyView(message: "No plans found")
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        // Back button
                        Button {
                            step = .serviceType
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Service Types")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(BoothColors.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                        ForEach(manager.plans) { plan in
                            Button {
                                selectedPlanID = plan.id
                                Task {
                                    await performImport(planID: plan.id)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(plan.attributes.title ?? plan.attributes.dates ?? "Untitled Plan")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(BoothColors.textPrimary)
                                        if let dates = plan.attributes.dates {
                                            Text(dates)
                                                .font(.system(size: 11))
                                                .foregroundStyle(BoothColors.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 16))
                                        .foregroundStyle(BoothColors.accent)
                                }
                                .padding(14)
                                .background(BoothColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }


    // MARK: - ─── Preview Content ─────────────────────────────────────────────

    private var previewContent: some View {
        VStack(spacing: 0) {
            if manager.isLoading {
                loadingView
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Back button
                        Button {
                            step = .plan
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Plans")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(BoothColors.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        SectionCard(title: mode == .setlist ? "Songs to Import" : "Team to Import") {
                            if mode == .setlist {
                                if importedSongs.isEmpty {
                                    emptyInline(message: "No songs found in this plan")
                                } else {
                                    ForEach(importedSongs) { song in
                                        HStack {
                                            Text(song.title)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(BoothColors.textPrimary)
                                            Spacer()
                                            Text(song.key.localizedName)
                                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                .foregroundStyle(BoothColors.accent)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(BoothColors.accent.opacity(0.15))
                                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                            Text("\(song.bpm ?? 120) BPM")
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundStyle(BoothColors.textSecondary)
                                        }
                                    }
                                }
                            } else {
                                if importedChannels.isEmpty {
                                    emptyInline(message: "No team members found in this plan")
                                } else {
                                    ForEach(importedChannels) { channel in
                                        HStack {
                                            Text(channel.label)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(BoothColors.textPrimary)
                                            Spacer()
                                            Text(channel.source.localizedName)
                                                .font(.system(size: 11))
                                                .foregroundStyle(BoothColors.textSecondary)
                                        }
                                    }
                                }
                            }
                        }

                        // Import button
                        if (mode == .setlist && !importedSongs.isEmpty) ||
                           (mode == .team && !importedChannels.isEmpty) {
                            Button {
                                if mode == .setlist {
                                    onImportSetlist(importedSongs)
                                } else {
                                    onImportTeam(importedChannels)
                                }
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Import \(mode == .setlist ? "\(importedSongs.count) Songs" : "\(importedChannels.count) Team Members")")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }


    // MARK: - ─── Import Action ───────────────────────────────────────────────

    private func performImport(planID: String) async {
        guard let serviceTypeID = selectedServiceTypeID else { return }

        switch mode {
        case .setlist:
            importedSongs = await manager.importSetlist(
                serviceTypeID: serviceTypeID,
                planID: planID
            )
        case .team:
            importedChannels = await manager.importTeamRoster(
                serviceTypeID: serviceTypeID,
                planID: planID
            )
        }

        step = .preview
    }


    // MARK: - ─── Components ──────────────────────────────────────────────────

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .tint(BoothColors.accent)
            Text("Loading...")
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textSecondary)
            Spacer()
        }
    }

    private func emptyView(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(BoothColors.textMuted)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textSecondary)
            Spacer()
        }
    }

    private func emptyInline(message: String) -> some View {
        Text(message)
            .font(.system(size: 12))
            .foregroundStyle(BoothColors.textMuted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 12)
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("PCO Import — Setlist") {
    PCOImportSheet(
        manager: PlanningCenterManager(),
        mode: .setlist,
        onImportSetlist: { _ in },
        onImportTeam: { _ in }
    )
}
