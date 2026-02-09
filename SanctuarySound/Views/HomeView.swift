// ============================================================================
// HomeView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Main tab-based navigation hub providing access to all app features:
//          Service Setup, Import & Analysis, SPL Monitor, and Saved Data.
// ============================================================================

import SwiftUI
import UniformTypeIdentifiers

// MARK: - ─── Home View ──────────────────────────────────────────────────────

struct HomeView: View {
    @StateObject private var store = ServiceStore()
    @StateObject private var mixerConnection = MixerConnectionManager()
    @StateObject private var pcoManager = PlanningCenterManager()
    @State private var selectedTab: AppTab = .setup
    @State private var bannerHapticTrigger = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                // ── Tab 1: Service Setup ──
                InputEntryView(store: store, pcoManager: pcoManager)
                    .tabItem {
                        Label("Setup", systemImage: "slider.horizontal.3")
                    }
                    .tag(AppTab.setup)

                // ── Tab 2: Import & Analysis ──
                ImportAnalysisView(store: store)
                    .tabItem {
                        Label("Analysis", systemImage: "waveform.badge.magnifyingglass")
                    }
                    .tag(AppTab.analysis)

                // ── Tab 3: SPL Monitor ──
                SPLCalibrationView(
                    store: store,
                    splPreference: $store.splPreference,
                    onSave: { pref in store.updateSPLPreference(pref) }
                )
                .tabItem {
                    Label("SPL", systemImage: "speaker.wave.2.fill")
                }
                .tag(AppTab.spl)

                // ── Tab 4: Mixer ──
                MixerConnectionView(
                    connectionManager: mixerConnection,
                    store: store
                )
                .tabItem {
                    Label("Mixer", systemImage: "cable.connector.horizontal")
                }
                .tag(AppTab.mixer)

                // ── Tab 5: Saved Data ──
                SavedDataView(store: store)
                    .tabItem {
                        Label("Saved", systemImage: "folder.fill")
                    }
                    .tag(AppTab.saved)
            }
            .tint(BoothColors.accent)

            // ── Cross-Tab SPL Alert Banner ──
            // Visible on ALL tabs when SPL meter is running and threshold is breached
            if selectedTab != .spl && store.splMeter.alertState.isActive {
                SPLAlertBanner(
                    alertState: store.splMeter.alertState,
                    onTap: { selectedTab = .spl }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: store.splMeter.alertState) { _, newState in
            // Haptic on non-SPL tabs when alert triggers
            if selectedTab != .spl && newState.isActive {
                bannerHapticTrigger.toggle()
            }
        }
        .sensoryFeedback(.warning, trigger: bannerHapticTrigger)
        .animation(.easeInOut(duration: 0.3), value: store.splMeter.alertState.isActive)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                mixerConnection.handleBackgrounding()
            case .active:
                mixerConnection.handleForegrounding()
            default:
                break
            }
        }
    }
}

enum AppTab: String {
    case setup
    case analysis
    case spl
    case mixer
    case saved
}


// MARK: - ─── SPL Alert Banner ────────────────────────────────────────────────

/// Persistent banner shown across all tabs when SPL exceeds threshold.
/// Tapping navigates to the SPL Monitor tab.
private struct SPLAlertBanner: View {
    let alertState: SPLAlertState
    var onTap: () -> Void

    @State private var isPulsing = false

    private var isDanger: Bool { alertState.isDanger }

    private var bannerColor: Color {
        isDanger ? BoothColors.accentDanger : BoothColors.accentWarm
    }

    private var icon: String {
        isDanger ? "exclamationmark.triangle.fill" : "speaker.wave.3.fill"
    }

    private var messageText: String {
        switch alertState {
        case .safe:
            return ""
        case .warning(let db, let over):
            return "\(db) dB — \(over) dB over target"
        case .alert(let db, let over):
            return "\(db) dB — \(over) dB over target"
        }
    }

    private var labelText: String {
        isDanger ? "SPL ALERT" : "SPL WARNING"
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)

                VStack(alignment: .leading, spacing: 1) {
                    Text(labelText)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .tracking(1)
                    Text(messageText)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text("VIEW")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(bannerColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: bannerColor.opacity(0.4), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .onAppear {
            if isDanger {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: alertState.isDanger) { _, danger in
            if danger {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                withAnimation(.default) {
                    isPulsing = false
                }
            }
        }
    }
}


// MARK: - ─── Import & Analysis View ─────────────────────────────────────────

struct ImportAnalysisView: View {
    @ObservedObject var store: ServiceStore
    @State private var showCSVImport = false
    @State private var importedSnapshot: MixerSnapshot?
    @State private var analysisResult: MixerAnalysis?
    @State private var importError: String?
    @State private var showDeleteConfirm = false
    @State private var snapshotToDelete: MixerSnapshot?

    // For generating a recommendation to analyze against
    @StateObject private var setupVM = ServiceSetupViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Import Section ──
                        importSection

                        // ── Saved Snapshots ──
                        if !store.savedSnapshots.isEmpty {
                            savedSnapshotsSection
                        }

                        // ── Current Snapshot ──
                        if let snapshot = importedSnapshot {
                            snapshotDetailSection(snapshot)
                        }

                        // ── Run Analysis ──
                        if importedSnapshot != nil {
                            analysisActionSection
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Import & Analyze")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCSVImport) {
                CSVImportSheet(
                    onImport: { snapshot in
                        importedSnapshot = snapshot
                        store.saveSnapshot(snapshot)
                    }
                )
            }
            .sheet(item: $analysisResult) { analysis in
                AnalysisView(analysis: analysis)
            }
            .alert("Delete Snapshot", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let snapshot = snapshotToDelete {
                        withAnimation {
                            // Clear selection if deleting the active snapshot
                            if importedSnapshot?.id == snapshot.id {
                                importedSnapshot = nil
                            }
                            store.deleteSnapshot(id: snapshot.id)
                        }
                        snapshotToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    snapshotToDelete = nil
                }
            } message: {
                Text("This will permanently remove the snapshot. This cannot be undone.")
            }
        }
    }


    // MARK: - Import Section

    private var importSection: some View {
        SectionCard(title: "Import Mixer State") {
            Text("Import a CSV export from Allen & Heath Director to compare your current mix against engine recommendations.")
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textSecondary)

            Button {
                showCSVImport = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                    Text("Import CSV File")
                }
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Manual entry option
            Button {
                importedSnapshot = createDemoSnapshot()
                store.saveSnapshot(importedSnapshot!)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                    Text("Use Demo Snapshot (Testing)")
                }
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .foregroundStyle(BoothColors.textSecondary)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if let error = importError {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.accentDanger)
            }
        }
    }


    // MARK: - Saved Snapshots Section

    private var savedSnapshotsSection: some View {
        SectionCard(title: "Saved Snapshots (\(store.savedSnapshots.count))") {
            ForEach(store.savedSnapshots) { snapshot in
                HStack(spacing: 10) {
                    // ── Snapshot Card (tappable to select) ──
                    Button {
                        importedSnapshot = snapshot
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(snapshot.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(BoothColors.textPrimary)
                                Text("\(snapshot.channels.count) channels — \(snapshot.mixer.shortName)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(BoothColors.textSecondary)
                            }
                            Spacer()
                            if importedSnapshot?.id == snapshot.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(BoothColors.accent)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            importedSnapshot?.id == snapshot.id
                                ? BoothColors.accent.opacity(0.08)
                                : BoothColors.surfaceElevated
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    // ── Delete Button (outside the card) ──
                    Button(role: .destructive) {
                        snapshotToDelete = snapshot
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(BoothColors.accentDanger.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .background(BoothColors.accentDanger.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .contextMenu {
                    Button(role: .destructive) {
                        snapshotToDelete = snapshot
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Snapshot", systemImage: "trash")
                    }
                }
            }
        }
    }


    // MARK: - Snapshot Detail

    private func snapshotDetailSection(_ snapshot: MixerSnapshot) -> some View {
        SectionCard(title: "Active Snapshot: \(snapshot.name)") {
            HStack(spacing: 12) {
                InfoBadge(label: "Channels", value: "\(snapshot.channels.count)")
                InfoBadge(label: "Mixer", value: snapshot.mixer.shortName)
                InfoBadge(label: "Imported", value: formatDate(snapshot.importedAt))
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(snapshot.channels.prefix(6)) { channel in
                    HStack {
                        Text("Ch \(channel.channelNumber)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(BoothColors.textMuted)
                            .frame(width: 36, alignment: .leading)
                        Text(channel.name)
                            .font(.system(size: 12))
                            .foregroundStyle(BoothColors.textPrimary)
                        Spacer()
                        if let gain = channel.gainDB {
                            Text("\(Int(gain)) dB")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(BoothColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 2)
                }

                if snapshot.channels.count > 6 {
                    Text("+ \(snapshot.channels.count - 6) more channels")
                        .font(.system(size: 11))
                        .foregroundStyle(BoothColors.textMuted)
                }
            }
        }
    }


    // MARK: - Analysis Action

    private var analysisActionSection: some View {
        SectionCard(title: "Run Analysis") {
            if setupVM.service.channels.isEmpty {
                Text("No service configured on the Setup tab — analysis will auto-match snapshot channels to recommended sources.")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.accentWarm)
            } else {
                Text("Compare your imported snapshot against engine recommendations for your configured service.")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textSecondary)
            }

            Button {
                runAnalysis()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Analyze Current Mix")
                }
                .font(.system(size: 14, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(BoothColors.background)
                .background(BoothColors.accentWarm)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }


    // MARK: - Analysis Logic

    private func runAnalysis() {
        guard let snapshot = importedSnapshot else { return }

        // Use the current service from the setup VM.
        // If no channels are configured yet, build a default service
        // from the snapshot channel names for a meaningful analysis.
        let service: WorshipService
        if setupVM.service.channels.isEmpty {
            // Auto-generate channels from snapshot names for analysis
            let channels = snapshot.channels.compactMap { ch -> InputChannel? in
                guard let source = guessInputSource(from: ch.name) else { return nil }
                return InputChannel(label: ch.name, source: source)
            }
            service = WorshipService(
                name: "Analysis Service",
                mixer: snapshot.mixer,
                channels: channels,
                setlist: setupVM.service.setlist.isEmpty
                    ? [SetlistSong(title: "Default", key: .G)]
                    : setupVM.service.setlist,
                experienceLevel: .advanced
            )
        } else {
            service = setupVM.service
        }

        let engine = SoundEngine()
        let recommendation = engine.generateRecommendation(for: service)

        // Build channel mapping from snapshot channel names -> InputSource
        var channelMapping: [Int: InputSource] = [:]
        for channel in snapshot.channels {
            if let matched = guessInputSource(from: channel.name) {
                channelMapping[channel.channelNumber] = matched
            }
        }

        let analysisEngine = AnalysisEngine()
        analysisResult = analysisEngine.analyze(
            snapshot: snapshot,
            recommendation: recommendation,
            channelMapping: channelMapping,
            splPreference: store.splPreference
        )
    }


    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// Best-effort matching of channel name to InputSource.
    private func guessInputSource(from name: String) -> InputSource? {
        let lowered = name.lowercased()

        if lowered.contains("kick") { return .kickDrum }
        if lowered.contains("snare") { return .snareDrum }
        if lowered.contains("hat") || lowered.contains("hh") { return .hiHat }
        if lowered.contains("oh") && lowered.contains("l") { return .overheadL }
        if lowered.contains("oh") && lowered.contains("r") { return .overheadR }
        if lowered.contains("overhead") { return .overheadL }
        if lowered.contains("tom") {
            if lowered.contains("floor") || lowered.contains("fl") { return .tomFloor }
            if lowered.contains("hi") { return .tomHigh }
            return .tomMid
        }
        if lowered.contains("lead") && lowered.contains("voc") { return .leadVocal }
        if lowered.contains("bv") || lowered.contains("back") { return .backingVocal }
        if lowered.contains("voc") || lowered.contains("vocal") { return .leadVocal }
        if lowered.contains("keys") || lowered.contains("piano") || lowered.contains("kb") { return .digitalPiano }
        if lowered.contains("e.gtr") || lowered.contains("elec") && lowered.contains("gtr") { return .electricGtrModeler }
        if lowered.contains("a.gtr") || lowered.contains("acou") && lowered.contains("gtr") { return .acousticGtrDI }
        if lowered.contains("bass") { return .bassGtrDI }
        if lowered.contains("track") { return .tracksLeft }
        if lowered.contains("click") { return .clickTrack }
        if lowered.contains("pastor") || lowered.contains("speak") { return .pastorHandheld }

        return nil
    }

    /// Creates a demo snapshot matching John's Feb 8 setup for testing.
    private func createDemoSnapshot() -> MixerSnapshot {
        let channels: [ChannelSnapshot] = [
            ChannelSnapshot(channelNumber: 1, name: "Lead Vocal M", gainDB: 48, faderDB: 0, hpfFrequency: 100, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 2, name: "Lead Vocal F", gainDB: 50, faderDB: 0, hpfFrequency: 100, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 3, name: "BV Female 1", gainDB: 55, faderDB: -3, hpfFrequency: 120, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 4, name: "BV Female 2", gainDB: 55, faderDB: -3, hpfFrequency: 120, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 5, name: "BV Female 3", gainDB: 55, faderDB: -3, hpfFrequency: 120, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 6, name: "BV Male", gainDB: 55, faderDB: -3, hpfFrequency: 120, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 7, name: "Keys L", gainDB: 14, faderDB: 0, hpfFrequency: 60, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 8, name: "Keys R", gainDB: 14, faderDB: 0, hpfFrequency: 60, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 9, name: "E.Gtr 1", gainDB: 14, faderDB: -2, hpfFrequency: 80, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 10, name: "E.Gtr 2", gainDB: 14, faderDB: -2, hpfFrequency: 80, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 11, name: "A.Gtr", gainDB: 24, faderDB: -2, hpfFrequency: 80, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 12, name: "Bass DI", gainDB: 14, faderDB: 0, hpfFrequency: 35, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 13, name: "Kick", gainDB: 42, faderDB: -3, hpfFrequency: 30, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 14, name: "Snare", gainDB: 42, faderDB: -3, hpfFrequency: 100, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 15, name: "HiHat", gainDB: 30, faderDB: -5, hpfFrequency: 200, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 16, name: "Tom Hi", gainDB: 38, faderDB: -3, hpfFrequency: 100, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 17, name: "Tom Mid", gainDB: 38, faderDB: -3, hpfFrequency: 80, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 18, name: "Tom Floor", gainDB: 38, faderDB: -3, hpfFrequency: 60, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 19, name: "OH L", gainDB: 32, faderDB: -5, hpfFrequency: 100, hpfEnabled: true),
            ChannelSnapshot(channelNumber: 20, name: "OH R", gainDB: 32, faderDB: -5, hpfFrequency: 100, hpfEnabled: true),
        ]

        return MixerSnapshot(
            name: "Feb 8 Demo",
            mixer: .allenHeathAvantis,
            channels: channels
        )
    }
}


// MARK: - ─── CSV Import Sheet ───────────────────────────────────────────────

struct CSVImportSheet: View {
    var onImport: (MixerSnapshot) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var csvText: String = ""
    @State private var importError: String?
    @State private var showDocumentPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Import Options") {
                            // File picker
                            Button {
                                showDocumentPicker = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.fill")
                                    Text("Choose CSV File")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .foregroundStyle(BoothColors.background)
                                .background(BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Text("or paste CSV content below")
                                .font(.system(size: 11))
                                .foregroundStyle(BoothColors.textMuted)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        SectionCard(title: "CSV Content") {
                            TextEditor(text: $csvText)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(BoothColors.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(BoothColors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        if let error = importError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundStyle(BoothColors.accentDanger)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BoothColors.accentDanger.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Button {
                            importCSVText()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.doc")
                                Text("Import")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .foregroundStyle(BoothColors.background)
                            .background(csvText.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(csvText.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.commaSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private func importCSVText() {
        let importer = CSVImporter()
        do {
            let snapshot = try importer.importCSV(csvText)
            onImport(snapshot)
            dismiss()
        } catch {
            importError = error.localizedDescription
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importError = "Could not access the selected file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let importer = CSVImporter()
            do {
                let snapshot = try importer.importFromURL(url)
                onImport(snapshot)
                dismiss()
            } catch {
                importError = error.localizedDescription
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}


// MARK: - ─── Saved Item Action Bar ──────────────────────────────────────────

/// Compact action bar for saved items — provides a Remove button.
private struct SavedItemActionBar: View {
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            Button(role: .destructive) {
                onDelete()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                    Text("Remove")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(BoothColors.accentDanger)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }
}


// MARK: - ─── Saved Data View ────────────────────────────────────────────────

struct SavedDataView: View {
    @ObservedObject var store: ServiceStore

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Saved Inputs ──
                        savedInputsSection

                        // ── Saved Vocalists ──
                        vocalistsSection

                        // ── Saved Services ──
                        servicesSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Saved Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var savedInputsSection: some View {
        SectionCard(title: "Input Library (\(store.savedInputs.count))") {
            if store.savedInputs.isEmpty {
                Text("No saved inputs yet. Inputs are saved automatically when you generate recommendations.")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textMuted)
            } else {
                ForEach(store.savedInputs) { input in
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: input.source.category.systemIcon)
                                .font(.system(size: 14))
                                .foregroundStyle(BoothColors.accent)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(input.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(BoothColors.textPrimary)
                                Text(input.source.localizedName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(BoothColors.textSecondary)
                            }
                            Spacer()
                            Text(input.source.isLineLevel ? "LINE" : "MIC")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(input.source.isLineLevel ? BoothColors.accentWarm : BoothColors.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background((input.source.isLineLevel ? BoothColors.accentWarm : BoothColors.accent).opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .padding(10)

                        // ── Action bar ──
                        SavedItemActionBar {
                            store.deleteInput(id: input.id)
                        }
                    }
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var vocalistsSection: some View {
        SectionCard(title: "Vocalist Profiles (\(store.savedVocalists.count))") {
            if store.savedVocalists.isEmpty {
                Text("No saved vocalist profiles yet. Add vocalists during service setup.")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textMuted)
            } else {
                ForEach(store.savedVocalists) { vocalist in
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vocalist.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(BoothColors.textPrimary)
                                Text("\(vocalist.range.localizedName) — \(vocalist.style.localizedName)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(BoothColors.textSecondary)
                            }
                            Spacer()
                            Text(vocalist.preferredMic.localizedName.components(separatedBy: " ").first ?? "")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(BoothColors.textMuted)
                        }
                        .padding(10)

                        SavedItemActionBar {
                            store.deleteVocalist(id: vocalist.id)
                        }
                    }
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var servicesSection: some View {
        SectionCard(title: "Past Services (\(store.savedServices.count))") {
            if store.savedServices.isEmpty {
                Text("No saved services yet. Services are saved when you generate recommendations.")
                    .font(.system(size: 12))
                    .foregroundStyle(BoothColors.textMuted)
            } else {
                ForEach(store.savedServices) { service in
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(service.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(BoothColors.textPrimary)
                                HStack(spacing: 6) {
                                    Text("\(service.channels.count) ch")
                                    Text("·")
                                    Text(service.mixer.shortName)
                                    Text("·")
                                    Text("\(service.setlist.count) songs")
                                }
                                .font(.system(size: 11))
                                .foregroundStyle(BoothColors.textSecondary)
                            }
                            Spacer()
                            Text(formatDate(service.date))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(BoothColors.textMuted)
                        }
                        .padding(10)

                        SavedItemActionBar {
                            store.deleteService(id: service.id)
                        }
                    }
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
