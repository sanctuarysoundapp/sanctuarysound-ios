// ============================================================================
// PCOImportSheet.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Sheet UI for importing setlists, team rosters, and full services
//          from Planning Center Online. Workflow: Connect → Browse Folders →
//          Pick Service Type → Pick Plan → Preview → Confirm Import.
//          Supports folder-based navigation matching PCO's org hierarchy
//          (campuses → nested folders → service types → plans).
// ============================================================================

import SwiftUI


// MARK: - ─── Import Mode ─────────────────────────────────────────────────

enum PCOImportMode {
    case setlist
    case team
    case fullService
}


// MARK: - ─── Song Import Item ────────────────────────────────────────────

/// Wrapper around SetlistSong for the import preview, adding selection state.
/// Keeps `isIncluded` scoped to the import flow — SetlistSong stays a pure domain model.
struct PCOSongImportItem: Identifiable {
    let id: UUID
    let song: SetlistSong
    var isIncluded: Bool

    init(id: UUID = UUID(), song: SetlistSong, isIncluded: Bool = true) {
        self.id = id
        self.song = song
        self.isIncluded = isIncluded
    }
}


// MARK: - ─── Full Service Import Data ───────────────────────────────────

struct PCOFullServiceImport {
    let name: String
    let date: Date
    let songs: [SetlistSong]
    let channels: [InputChannel]
    let venueID: UUID?
}


// MARK: - ─── PCO Import Sheet ────────────────────────────────────────────

struct PCOImportSheet: View {
    @ObservedObject var manager: PlanningCenterManager
    let mode: PCOImportMode
    let venues: [Venue]
    let drumTemplate: DrumKitTemplate
    let onImportSetlist: ([SetlistSong]) -> Void
    let onImportTeam: ([InputChannel]) -> Void
    let onImportService: ((PCOFullServiceImport) -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedServiceTypeID: String?
    @State private var selectedPlanID: String?
    @State private var selectedPlanAttributes: PCOPlanAttributes?
    @State private var importedSongItems: [PCOSongImportItem] = []
    @State private var importedTeamItems: [PCOTeamImportItem] = []
    @State private var matchedVenueID: UUID?
    @State private var step: ImportStep = .folder
    @State private var showDrumPicker = false
    @State private var activeDrumTemplate: DrumKitTemplate

    init(
        manager: PlanningCenterManager,
        mode: PCOImportMode,
        venues: [Venue] = [],
        drumTemplate: DrumKitTemplate = .standard5,
        onImportSetlist: @escaping ([SetlistSong]) -> Void = { _ in },
        onImportTeam: @escaping ([InputChannel]) -> Void = { _ in },
        onImportService: ((PCOFullServiceImport) -> Void)? = nil
    ) {
        self.manager = manager
        self.mode = mode
        self.venues = venues
        self.drumTemplate = drumTemplate
        self.onImportSetlist = onImportSetlist
        self.onImportTeam = onImportTeam
        self.onImportService = onImportService
        self._activeDrumTemplate = State(initialValue: drumTemplate)
    }

    private enum ImportStep {
        case folder
        case serviceType
        case plan
        case preview
    }

    private var includedSongs: [SetlistSong] {
        importedSongItems.filter(\.isIncluded).map(\.song)
    }

    private var includedSongCount: Int {
        importedSongItems.filter(\.isIncluded).count
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
                        case .folder:
                            folderBrowser
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
            .sheet(isPresented: $showDrumPicker) {
                DrumKitTemplatePicker(
                    currentTemplate: activeDrumTemplate
                ) { template, channels in
                    activeDrumTemplate = template
                    // Re-expand drum items with new template
                    reExpandDrums(template: template, channels: channels)
                }
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .setlist:     return "Import Setlist"
        case .team:        return "Import Team"
        case .fullService: return "Import Service"
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

            Text("Sign in with your Planning Center account to import \(importDescription) directly.")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task {
                    try? await manager.client.authenticate()
                    if manager.client.isAuthenticated {
                        await manager.loadTopLevelFolders()
                        // If no folders exist, skip to service types
                        if manager.folders.isEmpty && !manager.serviceTypes.isEmpty {
                            step = .serviceType
                        }
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

    private var importDescription: String {
        switch mode {
        case .setlist:     return "setlists"
        case .team:        return "team rosters"
        case .fullService: return "service plans"
        }
    }


    // MARK: - ─── Folder Browser ─────────────────────────────────────────────

    private var folderBrowser: some View {
        VStack(spacing: 0) {
            if manager.isLoading {
                loadingView
            } else if manager.folderItems.isEmpty && manager.serviceTypes.isEmpty {
                emptyView(message: "No folders or service types found")
            } else if manager.folders.isEmpty && !manager.serviceTypes.isEmpty {
                // No folders — show flat service type list
                serviceTypeList
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        // Breadcrumb bar
                        if !manager.folderBreadcrumbs.isEmpty {
                            breadcrumbBar
                        }

                        // Folder items (mixed folders + service types)
                        ForEach(manager.folderItems) { item in
                            switch item {
                            case .folder(let folder):
                                folderRow(folder)
                            case .serviceType(let serviceType):
                                serviceTypeRow(serviceType)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if manager.folderItems.isEmpty && manager.serviceTypes.isEmpty {
                Task {
                    await manager.loadTopLevelFolders()
                    // If no folders, skip to service type step
                    if manager.folders.isEmpty && !manager.serviceTypes.isEmpty {
                        step = .serviceType
                    }
                }
            }
        }
    }


    // MARK: - ─── Breadcrumb Bar ─────────────────────────────────────────────

    private var breadcrumbBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Root
                Button {
                    Task { await manager.navigateToRoot() }
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.accent)
                }

                ForEach(Array(manager.folderBreadcrumbs.enumerated()), id: \.offset) { index, crumb in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(BoothColors.textMuted)

                    if index < manager.folderBreadcrumbs.count - 1 {
                        Button {
                            Task { await manager.navigateBackToFolder(index: index) }
                        } label: {
                            Text(crumb.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(BoothColors.accent)
                        }
                    } else {
                        Text(crumb.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(BoothColors.textPrimary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }


    // MARK: - ─── Folder Row ─────────────────────────────────────────────────

    private func folderRow(_ folder: PCOResource<PCOFolderAttributes>) -> some View {
        Button {
            Task {
                await manager.loadFolderContents(
                    folderID: folder.id,
                    folderName: folder.attributes.name
                )
            }
        } label: {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.accent)
                    .frame(width: 24)

                Text(folder.attributes.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)

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


    // MARK: - ─── Service Type Row ───────────────────────────────────────────

    private func serviceTypeRow(_ serviceType: PCOResource<PCOServiceTypeAttributes>) -> some View {
        Button {
            selectedServiceTypeID = serviceType.id
            Task {
                await manager.loadPlans(serviceTypeID: serviceType.id)
                step = .plan
            }
        } label: {
            HStack {
                Image(systemName: "music.note.list")
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.textSecondary)
                    .frame(width: 24)

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


    // MARK: - ─── Service Type List (Flat Fallback) ──────────────────────────

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
                            serviceTypeRow(serviceType)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if manager.serviceTypes.isEmpty && manager.folders.isEmpty {
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
                            if !manager.folderBreadcrumbs.isEmpty {
                                step = .folder
                            } else {
                                step = .serviceType
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(BoothColors.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                        ForEach(manager.plans) { plan in
                            Button {
                                selectedPlanID = plan.id
                                selectedPlanAttributes = plan.attributes
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

                        // Venue match badge
                        if let venueID = matchedVenueID,
                           let venue = venues.first(where: { $0.id == venueID }) {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                Text("Venue: \(venue.name)")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(BoothColors.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(BoothColors.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Songs preview (setlist or fullService)
                        if mode == .setlist || mode == .fullService {
                            setlistPreview
                        }

                        // Team preview (team or fullService)
                        if mode == .team || mode == .fullService {
                            PCOTeamImportPreviewView(
                                items: $importedTeamItems,
                                drumTemplate: activeDrumTemplate,
                                onChangeDrumTemplate: { showDrumPicker = true },
                                onImport: { channels in
                                    if mode == .fullService {
                                        let serviceImport = buildFullServiceImport(channels: channels)
                                        onImportService?(serviceImport)
                                    } else {
                                        onImportTeam(channels)
                                    }
                                    dismiss()
                                }
                            )
                        }

                        // Setlist-only import button
                        if mode == .setlist && !importedSongItems.isEmpty {
                            Button {
                                onImportSetlist(includedSongs)
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Import \(includedSongCount) Songs")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(includedSongCount > 0 ? BoothColors.accent : BoothColors.textMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .disabled(includedSongCount == 0)
                        }

                        // Full service import button (songs only — team has its own button)
                        if mode == .fullService && importedTeamItems.isEmpty && !importedSongItems.isEmpty {
                            Button {
                                let serviceImport = buildFullServiceImport(channels: [])
                                onImportService?(serviceImport)
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Import Service (\(includedSongCount) Songs)")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(includedSongCount > 0 ? BoothColors.accent : BoothColors.textMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .disabled(includedSongCount == 0)
                        }
                    }
                    .padding()
                }
            }
        }
    }


    // MARK: - ─── Setlist Preview ────────────────────────────────────────────

    private var setlistPreview: some View {
        SectionCard(title: "Songs to Import") {
            if importedSongItems.isEmpty {
                emptyInline(message: "No songs found in this plan")
            } else {
                ForEach(Array(importedSongItems.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 10) {
                        // Include toggle (matches team import checkbox style)
                        Button {
                            importedSongItems[index].isIncluded.toggle()
                        } label: {
                            Image(systemName: item.isIncluded ? "checkmark.square.fill" : "square")
                                .font(.system(size: 16))
                                .foregroundStyle(
                                    item.isIncluded ? BoothColors.accent : BoothColors.textMuted
                                )
                        }

                        Text(item.song.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(
                                item.isIncluded ? BoothColors.textPrimary : BoothColors.textMuted
                            )

                        Spacer()

                        Text(item.song.key.localizedName)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                item.isIncluded ? BoothColors.accent : BoothColors.textMuted
                            )
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                (item.isIncluded ? BoothColors.accent : BoothColors.textMuted)
                                    .opacity(0.15)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 3))

                        Text(item.song.bpm.map { "\($0) BPM" } ?? "— BPM")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(
                                item.isIncluded ? BoothColors.textSecondary : BoothColors.textMuted
                            )
                    }
                    .padding(.vertical, 4)
                    .opacity(item.isIncluded ? 1.0 : 0.5)
                }
            }
        }
    }


    // MARK: - ─── Import Actions ─────────────────────────────────────────────

    private func performImport(planID: String) async {
        guard let serviceTypeID = selectedServiceTypeID else { return }

        switch mode {
        case .setlist:
            let songs = await manager.importSetlist(
                serviceTypeID: serviceTypeID,
                planID: planID
            )
            importedSongItems = songs.map { PCOSongImportItem(song: $0) }

        case .team:
            importedTeamItems = await manager.importTeamRoster(
                serviceTypeID: serviceTypeID,
                planID: planID,
                drumTemplate: activeDrumTemplate
            )

        case .fullService:
            // Fetch both in parallel
            async let fetchedSongs = manager.importSetlist(
                serviceTypeID: serviceTypeID,
                planID: planID
            )
            async let team = manager.importTeamRoster(
                serviceTypeID: serviceTypeID,
                planID: planID,
                drumTemplate: activeDrumTemplate
            )

            let songs = await fetchedSongs
            importedSongItems = songs.map { PCOSongImportItem(song: $0) }
            importedTeamItems = await team
        }

        // Match venue from folder breadcrumbs
        matchedVenueID = manager.matchVenueFromBreadcrumbs(venues: venues)

        step = .preview
    }

    private func buildFullServiceImport(channels: [InputChannel]) -> PCOFullServiceImport {
        let planName = selectedPlanAttributes?.title
            ?? selectedPlanAttributes?.dates
            ?? "Imported Service"
        let planDate = manager.parsePlanDate(selectedPlanAttributes?.sortDate)

        return PCOFullServiceImport(
            name: planName,
            date: planDate,
            songs: includedSongs,
            channels: channels,
            venueID: matchedVenueID
        )
    }

    private func reExpandDrums(
        template: DrumKitTemplate,
        channels: [(label: String, source: InputSource)]
    ) {
        // Find the person name from existing drum items
        let drumPerson = importedTeamItems
            .first(where: { $0.positionCategory == .drums })?.personName ?? ""
        let drumPosition = importedTeamItems
            .first(where: { $0.positionCategory == .drums })?.positionName ?? ""

        // Remove existing drum items
        importedTeamItems.removeAll(where: { $0.positionCategory == .drums })

        // Add new drum items from template
        let newDrumItems = channels.map { channel in
            PCOTeamImportItem(
                personName: drumPerson,
                positionName: drumPosition,
                positionCategory: .drums,
                channelLabel: channel.label,
                source: channel.source,
                isIncluded: true
            )
        }
        importedTeamItems.append(contentsOf: newDrumItems)
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
