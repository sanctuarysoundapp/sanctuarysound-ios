// ============================================================================
// HomeView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Main tab-based navigation hub with 5 user-centric tabs:
//          Services, Inputs, Consoles, Tools, Settings.
//          Includes cross-tab SPL alert banner and CSV import sheet.
// ============================================================================

import SwiftUI
import UniformTypeIdentifiers

// MARK: - ─── Home View ──────────────────────────────────────────────────────

struct HomeView: View {
    @ObservedObject var store: ServiceStore
    @StateObject private var mixerConnection = MixerConnectionManager()
    @StateObject private var pcoManager = PlanningCenterManager()
    @State private var selectedTab: AppTab = .services
    @State private var bannerHapticTrigger = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                ServicesView(store: store, pcoManager: pcoManager)
                    .tabItem {
                        Label("Services", systemImage: "music.note.list")
                    }
                    .tag(AppTab.services)

                InputLibraryView(store: store)
                    .tabItem {
                        Label("Inputs", systemImage: "pianokeys")
                    }
                    .tag(AppTab.inputs)

                ConsolesView(store: store, connectionManager: mixerConnection)
                    .tabItem {
                        Label("Consoles", systemImage: "slider.horizontal.below.rectangle")
                    }
                    .tag(AppTab.consoles)

                ToolsView(store: store, splPreference: $store.splPreference)
                    .tabItem {
                        Label("Tools", systemImage: "wrench.and.screwdriver")
                    }
                    .tag(AppTab.tools)

                SettingsView(store: store, pcoManager: pcoManager)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(AppTab.settings)
            }
            .tint(BoothColors.accent)

            // ── Cross-Tab SPL Alert Banner ──
            // Visible on ALL tabs (except Tools) when threshold is breached
            if selectedTab != .tools && store.splMeter.alertState.isActive {
                SPLAlertBanner(
                    alertState: store.splMeter.alertState,
                    onTap: { selectedTab = .tools }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: store.splMeter.alertState) { _, newState in
            if selectedTab != .tools && newState.isActive {
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


// MARK: - ─── App Tab ────────────────────────────────────────────────────────

enum AppTab: String {
    case services
    case inputs
    case consoles
    case tools
    case settings
}


// MARK: - ─── SPL Alert Banner ────────────────────────────────────────────────

/// Persistent banner shown across all tabs when SPL exceeds threshold.
/// Tapping navigates to the Tools tab (SPL Meter).
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(labelText), \(messageText)")
        .accessibilityHint("Tap to view SPL monitor")
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
                            .accessibilityLabel("Choose CSV file")
                            .accessibilityHint("Opens a file picker to select a CSV export from your mixer software")

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
                                .accessibilityLabel("CSV content")
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
                        .accessibilityLabel("Import CSV")
                        .accessibilityHint("Parses the CSV content and imports mixer settings")
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
