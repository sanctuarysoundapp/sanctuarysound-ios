// ============================================================================
// InputLibraryView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Inputs tab — manage saved inputs and vocalist profiles with tags,
//          notes, and mic model metadata. Auto-populated from service creation.
// ============================================================================

import SwiftUI


// MARK: - ─── Input Library View ──────────────────────────────────────────────

struct InputLibraryView: View {
    @ObservedObject var store: ServiceStore
    @State private var searchText = ""
    @State private var selectedCategory: InputFilterCategory = .all

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Search + Filter ──
                        filterBar

                        // ── Vocalist Profiles ──
                        vocalistsSection

                        // ── Input Library ──
                        inputsSection
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Inputs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }


    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 10) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.textMuted)
                TextField("Search inputs...", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.textPrimary)
                    .textInputAutocapitalization(.never)
            }
            .padding(10)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Category chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(InputFilterCategory.allCases) { category in
                        categoryChip(category)
                    }
                }
            }
        }
    }

    private func categoryChip(_ category: InputFilterCategory) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Text(category.label)
                .font(.system(size: 12, weight: selectedCategory == category ? .bold : .medium))
                .foregroundStyle(selectedCategory == category ? BoothColors.background : BoothColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == category ? BoothColors.accent : BoothColors.surfaceElevated)
                .clipShape(Capsule())
        }
    }


    // MARK: - Vocalists Section

    private var vocalistsSection: some View {
        SectionCard(title: "Vocalist Profiles (\(store.savedVocalists.count))") {
            if store.savedVocalists.isEmpty {
                emptyState(
                    icon: "person.wave.2",
                    text: "No vocalist profiles yet. Add vocalists during service setup."
                )
            } else {
                ForEach(filteredVocalists) { vocalist in
                    vocalistRow(vocalist)
                }
            }
        }
    }

    private func vocalistRow(_ vocalist: SavedVocalist) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vocalist.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                Text("\(vocalist.range.localizedName) \u{00B7} \(vocalist.style.localizedName)")
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
            }
            Spacer()
            Text(vocalist.preferredMic.localizedName.components(separatedBy: " ").first ?? "")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }


    // MARK: - Inputs Section

    private var inputsSection: some View {
        SectionCard(title: "Input Library (\(store.savedInputs.count))") {
            if store.savedInputs.isEmpty {
                emptyState(
                    icon: "pianokeys",
                    text: "Your input library builds automatically when you create services."
                )
            } else {
                ForEach(filteredInputs) { input in
                    inputRow(input)
                }
            }
        }
    }

    private func inputRow(_ input: SavedInput) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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

            // Tags (if any)
            if !input.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(input.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(BoothColors.accent.opacity(0.8))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(BoothColors.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.leading, 36)
            }
        }
        .padding(10)
        .background(BoothColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }


    // MARK: - Empty State

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(BoothColors.textMuted)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(BoothColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }


    // MARK: - Filtering

    private var filteredInputs: [SavedInput] {
        store.savedInputs.filter { input in
            let matchesSearch = searchText.isEmpty ||
                input.name.localizedCaseInsensitiveContains(searchText) ||
                input.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }

            let matchesCategory: Bool
            if let categories = selectedCategory.matchesCategories {
                matchesCategory = categories.contains(input.source.category)
            } else {
                matchesCategory = true
            }

            return matchesSearch && matchesCategory
        }
    }

    private var filteredVocalists: [SavedVocalist] {
        store.savedVocalists.filter { vocalist in
            searchText.isEmpty ||
                vocalist.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}


// MARK: - ─── Filter Category ─────────────────────────────────────────────────

enum InputFilterCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case vocals = "Vocals"
    case instruments = "Instruments"
    case drums = "Drums"
    case di = "DI/Line"

    var id: String { rawValue }

    var label: String { rawValue }

    /// Returns the InputCategory values this filter matches, or nil for "all".
    var matchesCategories: [InputCategory]? {
        switch self {
        case .all:          return nil
        case .vocals:       return [.vocals, .speech]
        case .instruments:  return [.keys, .guitars, .orchestral]
        case .drums:        return [.drums]
        case .di:           return [.playback]
        }
    }
}
