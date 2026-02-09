// ============================================================================
// InputLibraryView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Inputs tab — manage saved inputs and vocalist profiles with tags,
//          notes, and mic model metadata. Auto-populated from service creation.
//          Phase 4: Full build with detail/edit sheets, tag system, CRUD.
// ============================================================================

import SwiftUI
import TipKit


// MARK: - ─── Input Library View ──────────────────────────────────────────────

struct InputLibraryView: View {
    @ObservedObject var store: ServiceStore
    @State private var searchText = ""
    @State private var selectedCategory: InputFilterCategory = .all
    @State private var selectedInput: SavedInput?
    @State private var selectedVocalist: SavedVocalist?
    @State private var showAddInput = false
    @State private var showAddVocalist = false
    @State private var deleteConfirmInput: SavedInput?
    @State private var deleteConfirmVocalist: SavedVocalist?

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                if store.savedInputs.isEmpty && store.savedVocalists.isEmpty {
                    emptyState
                } else {
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
            }
            .navigationTitle("Inputs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedInput) { input in
                InputDetailSheet(store: store, input: input)
            }
            .sheet(item: $selectedVocalist) { vocalist in
                VocalistDetailSheet(store: store, vocalist: vocalist)
            }
            .sheet(isPresented: $showAddInput) {
                AddInputSheet(store: store)
            }
            .sheet(isPresented: $showAddVocalist) {
                AddVocalistSheet(store: store)
            }
            .alert("Delete Input", isPresented: .init(
                get: { deleteConfirmInput != nil },
                set: { if !$0 { deleteConfirmInput = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let input = deleteConfirmInput {
                        withAnimation { store.deleteInput(id: input.id) }
                    }
                }
                Button("Cancel", role: .cancel) { deleteConfirmInput = nil }
            } message: {
                Text("This will remove the input from your library.")
            }
            .alert("Delete Vocalist", isPresented: .init(
                get: { deleteConfirmVocalist != nil },
                set: { if !$0 { deleteConfirmVocalist = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let vocalist = deleteConfirmVocalist {
                        withAnimation { store.deleteVocalist(id: vocalist.id) }
                    }
                }
                Button("Cancel", role: .cancel) { deleteConfirmVocalist = nil }
            } message: {
                Text("This will remove the vocalist profile.")
            }
        }
    }


    // MARK: - ─── Empty State ──────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 16) {
            TipView(InputLibraryTip())
                .tipBackground(BoothColors.surface)
                .padding(.horizontal, 24)

            Image(systemName: "pianokeys")
                .font(.system(size: 48))
                .foregroundStyle(BoothColors.textMuted)

            Text("Your input library is empty")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BoothColors.textPrimary)

            Text("Inputs and vocalist profiles are saved automatically when you create services. You can also add them manually.")
                .font(.system(size: 14))
                .foregroundStyle(BoothColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 12) {
                Button {
                    showAddInput = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Input")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .frame(height: 44)
                    .padding(.horizontal, 20)
                    .foregroundStyle(BoothColors.background)
                    .background(BoothColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    showAddVocalist = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                        Text("Add Vocalist")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .frame(height: 44)
                    .padding(.horizontal, 20)
                    .foregroundStyle(BoothColors.textSecondary)
                    .background(BoothColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    // MARK: - ─── Filter Bar ──────────────────────────────────────────────────

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
                    .accessibilityLabel("Search inputs")
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(BoothColors.textMuted)
                    }
                    .accessibilityLabel("Clear search")
                }
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
        .accessibilityLabel("Filter: \(category.label)")
        .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
    }


    // MARK: - ─── Vocalists Section ───────────────────────────────────────────

    private var vocalistsSection: some View {
        SectionCard(title: "Vocalist Profiles (\(store.savedVocalists.count))") {
            if store.savedVocalists.isEmpty {
                emptySubState(
                    icon: "person.wave.2",
                    text: "No vocalist profiles yet."
                )
            } else {
                ForEach(filteredVocalists) { vocalist in
                    vocalistRow(vocalist)
                }
            }

            Button {
                showAddVocalist = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                    Text("Add Vocalist")
                }
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .foregroundStyle(BoothColors.textSecondary)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityLabel("Add Vocalist")
            .accessibilityHint("Opens form to create a new vocalist profile")
        }
    }

    private func vocalistRow(_ vocalist: SavedVocalist) -> some View {
        Button {
            selectedVocalist = vocalist
        } label: {
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
                Text(micTypeShort(vocalist.preferredMic))
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(BoothColors.textMuted)
            }
            .padding(10)
            .background(BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(vocalist.name), \(vocalist.range.localizedName), \(vocalist.style.localizedName)")
        .accessibilityHint("Opens vocalist details")
        .contextMenu {
            Button(role: .destructive) {
                deleteConfirmVocalist = vocalist
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }


    // MARK: - ─── Inputs Section ──────────────────────────────────────────────

    private var inputsSection: some View {
        SectionCard(title: "Input Library (\(store.savedInputs.count))") {
            if store.savedInputs.isEmpty {
                emptySubState(
                    icon: "pianokeys",
                    text: "Your input library builds automatically when you create services."
                )
            } else {
                ForEach(filteredInputs) { input in
                    inputRow(input)
                }
            }

            Button {
                showAddInput = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle")
                    Text("Add Input")
                }
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .foregroundStyle(BoothColors.textSecondary)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .accessibilityLabel("Add Input")
            .accessibilityHint("Opens form to create a new input")
        }
    }

    private func inputRow(_ input: SavedInput) -> some View {
        Button {
            selectedInput = input
        } label: {
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

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(BoothColors.textMuted)
                }

                // Tags (if any)
                if !input.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(input.tags, id: \.self) { tag in
                                tagPill(tag)
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
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(input.name), \(input.source.localizedName), \(input.source.isLineLevel ? "line level" : "microphone")")
        .accessibilityHint("Opens input details")
        .contextMenu {
            Button(role: .destructive) {
                deleteConfirmInput = input
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }


    // MARK: - ─── Shared Components ───────────────────────────────────────────

    private func tagPill(_ tag: String) -> some View {
        Text(tag)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(BoothColors.accent.opacity(0.8))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(BoothColors.accent.opacity(0.1))
            .clipShape(Capsule())
    }

    private func emptySubState(icon: String, text: String) -> some View {
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

    private func micTypeShort(_ mic: MicType) -> String {
        mic.localizedName.components(separatedBy: " ").first ?? ""
    }


    // MARK: - ─── Filtering ───────────────────────────────────────────────────

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


// MARK: - ─── Tag Suggestions ─────────────────────────────────────────────────

/// Predefined tag suggestions per input category.
enum TagSuggestions {
    static let vocals = ["lead", "backing", "choir", "worship-leader"]
    static let instruments = ["electric", "acoustic", "di", "amp"]
    static let drums = ["kick", "snare", "overhead", "tom", "hi-hat"]
    static let general = ["stereo-pair", "backup", "guest", "portable"]

    static func suggestions(for category: InputCategory) -> [String] {
        switch category {
        case .vocals, .speech: return vocals
        case .guitars:         return instruments
        case .keys:            return instruments
        case .drums:           return drums
        case .playback:        return general
        case .orchestral:      return general
        }
    }
}


// MARK: - ─── Input Detail Sheet ──────────────────────────────────────────────

struct InputDetailSheet: View {
    @ObservedObject var store: ServiceStore
    let input: SavedInput
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var notes: String
    @State private var micModel: String
    @State private var tags: [String]
    @State private var newTag = ""

    init(store: ServiceStore, input: SavedInput) {
        self.store = store
        self.input = input
        _name = State(initialValue: input.name)
        _notes = State(initialValue: input.notes)
        _micModel = State(initialValue: input.micModel ?? "")
        _tags = State(initialValue: input.tags)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // ── Input Info ──
                        SectionCard(title: "Input Details") {
                            BoothTextField(label: "Name", text: $name, placeholder: "Lead Vocal")

                            HStack(spacing: 12) {
                                InfoBadge(label: "Source", value: input.source.localizedName)
                                InfoBadge(label: "Type", value: input.source.isLineLevel ? "LINE" : "MIC")
                                InfoBadge(label: "Category", value: input.source.category.localizedName)
                            }

                            BoothTextField(label: "Mic Model (optional)", text: $micModel, placeholder: "Shure SM58")
                            BoothTextField(label: "Notes", text: $notes, placeholder: "Any notes about this input...")

                            if let lastUsed = input.lastUsed {
                                HStack {
                                    Text("Last used:")
                                        .font(.system(size: 11))
                                        .foregroundStyle(BoothColors.textMuted)
                                    Text(formatDate(lastUsed))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(BoothColors.textSecondary)
                                }
                            }
                        }

                        // ── Tags ──
                        SectionCard(title: "Tags (\(tags.count))") {
                            // Current tags
                            if !tags.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text(tag)
                                                .font(.system(size: 11, weight: .medium))
                                            Button {
                                                tags.removeAll { $0 == tag }
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 8, weight: .bold))
                                            }
                                            .accessibilityLabel("Remove tag \(tag)")
                                        }
                                        .foregroundStyle(BoothColors.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(BoothColors.accent.opacity(0.12))
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            // Add tag
                            HStack(spacing: 8) {
                                TextField("Add tag...", text: $newTag)
                                    .font(.system(size: 13))
                                    .foregroundStyle(BoothColors.textPrimary)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .onSubmit { addTag() }
                                    .accessibilityLabel("Add tag")
                                Button {
                                    addTag()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(newTag.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                                }
                                .disabled(newTag.isEmpty)
                                .accessibilityLabel("Add tag")
                                .accessibilityHint("Adds the entered text as a tag")
                            }
                            .padding(8)
                            .background(BoothColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            // Suggestions
                            let suggestions = TagSuggestions.suggestions(for: input.source.category)
                                .filter { !tags.contains($0) }
                            if !suggestions.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Suggestions")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(BoothColors.textMuted)
                                    FlowLayout(spacing: 4) {
                                        ForEach(suggestions, id: \.self) { suggestion in
                                            Button {
                                                tags.append(suggestion)
                                            } label: {
                                                Text(suggestion)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(BoothColors.textSecondary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(BoothColors.surfaceElevated)
                                                    .clipShape(Capsule())
                                            }
                                            .accessibilityLabel("Add \(suggestion) tag")
                                        }
                                    }
                                }
                            }
                        }

                        // ── Vocal Profile (if vocal) ──
                        if let profile = input.vocalProfile {
                            SectionCard(title: "Vocal Profile") {
                                HStack(spacing: 12) {
                                    InfoBadge(label: "Range", value: profile.range.localizedName)
                                    InfoBadge(label: "Style", value: profile.style.localizedName)
                                    InfoBadge(label: "Mic", value: profile.micType.localizedName.components(separatedBy: " ").first ?? "")
                                }
                            }
                        }

                        // ── Save ──
                        Button {
                            save()
                        } label: {
                            Text("Save Changes")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(name.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func addTag() {
        let cleaned = newTag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !tags.contains(cleaned) else { return }
        tags.append(cleaned)
        newTag = ""
    }

    private func save() {
        var updated = input
        updated.name = name
        updated.notes = notes
        updated.micModel = micModel.isEmpty ? nil : micModel
        updated.tags = tags
        store.saveInput(updated)
        dismiss()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}


// MARK: - ─── Vocalist Detail Sheet ───────────────────────────────────────────

struct VocalistDetailSheet: View {
    @ObservedObject var store: ServiceStore
    let vocalist: SavedVocalist
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var range: VocalRange
    @State private var style: VocalStyle
    @State private var preferredMic: MicType
    @State private var notes: String

    init(store: ServiceStore, vocalist: SavedVocalist) {
        self.store = store
        self.vocalist = vocalist
        _name = State(initialValue: vocalist.name)
        _range = State(initialValue: vocalist.range)
        _style = State(initialValue: vocalist.style)
        _preferredMic = State(initialValue: vocalist.preferredMic)
        _notes = State(initialValue: vocalist.notes)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "Vocalist Details") {
                            BoothTextField(label: "Name", text: $name, placeholder: "Sarah")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("VOCAL RANGE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Range", selection: $range) {
                                    ForEach(VocalRange.allCases) { r in
                                        Text(r.localizedName).tag(r)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("VOCAL STYLE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Style", selection: $style) {
                                    ForEach(VocalStyle.allCases) { s in
                                        Text(s.localizedName).tag(s)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("PREFERRED MIC")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Mic", selection: $preferredMic) {
                                    ForEach(MicType.allCases) { mic in
                                        Text(mic.localizedName).tag(mic)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            BoothTextField(label: "Notes", text: $notes, placeholder: "Belts hard on choruses...")
                        }

                        // ── Linked Inputs ──
                        let linkedInputs = store.savedInputs.filter { $0.name == vocalist.name }
                        if !linkedInputs.isEmpty {
                            SectionCard(title: "Linked Inputs (\(linkedInputs.count))") {
                                ForEach(linkedInputs) { input in
                                    HStack(spacing: 8) {
                                        Image(systemName: input.source.category.systemIcon)
                                            .font(.system(size: 12))
                                            .foregroundStyle(BoothColors.accent)
                                        Text(input.name)
                                            .font(.system(size: 12))
                                            .foregroundStyle(BoothColors.textSecondary)
                                        Spacer()
                                        Text(input.source.localizedName)
                                            .font(.system(size: 10))
                                            .foregroundStyle(BoothColors.textMuted)
                                    }
                                }
                            }
                        }

                        Button {
                            save()
                        } label: {
                            Text("Save Changes")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(name.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Vocalist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func save() {
        var updated = vocalist
        updated.name = name
        updated.range = range
        updated.style = style
        updated.preferredMic = preferredMic
        updated.notes = notes
        store.saveVocalist(updated)
        dismiss()
    }
}


// MARK: - ─── Add Input Sheet ─────────────────────────────────────────────────

struct AddInputSheet: View {
    @ObservedObject var store: ServiceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var source: InputSource = .leadVocal
    @State private var micModel = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "New Input") {
                            BoothTextField(label: "Name", text: $name, placeholder: "Lead Vocal")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("INPUT SOURCE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Source", selection: $source) {
                                    ForEach(InputSource.allCases) { src in
                                        Text(src.localizedName).tag(src)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            BoothTextField(label: "Mic Model (optional)", text: $micModel, placeholder: "Shure SM58")
                            BoothTextField(label: "Notes (optional)", text: $notes, placeholder: "Any notes...")
                        }

                        Button {
                            save()
                        } label: {
                            Text("Add Input")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(name.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func save() {
        let input = SavedInput(
            name: name,
            source: source,
            notes: notes,
            micModel: micModel.isEmpty ? nil : micModel,
            lastUsed: Date()
        )
        store.saveInput(input)
        dismiss()
    }
}


// MARK: - ─── Add Vocalist Sheet ──────────────────────────────────────────────

struct AddVocalistSheet: View {
    @ObservedObject var store: ServiceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var range: VocalRange = .alto
    @State private var style: VocalStyle = .contemporary
    @State private var preferredMic: MicType = .dynamicCardioid
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        SectionCard(title: "New Vocalist") {
                            BoothTextField(label: "Name", text: $name, placeholder: "Sarah")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("VOCAL RANGE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Range", selection: $range) {
                                    ForEach(VocalRange.allCases) { r in
                                        Text(r.localizedName).tag(r)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("VOCAL STYLE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Style", selection: $style) {
                                    ForEach(VocalStyle.allCases) { s in
                                        Text(s.localizedName).tag(s)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("PREFERRED MIC")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(BoothColors.textMuted)
                                    .tracking(1)
                                Picker("Mic", selection: $preferredMic) {
                                    ForEach(MicType.allCases) { mic in
                                        Text(mic.localizedName).tag(mic)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(BoothColors.accent)
                            }

                            BoothTextField(label: "Notes (optional)", text: $notes, placeholder: "Belts hard on choruses...")
                        }

                        Button {
                            save()
                        } label: {
                            Text("Add Vocalist")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundStyle(BoothColors.background)
                                .background(name.isEmpty ? BoothColors.textMuted : BoothColors.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(name.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Vocalist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoothColors.textSecondary)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func save() {
        let vocalist = SavedVocalist(
            name: name,
            range: range,
            style: style,
            preferredMic: preferredMic,
            notes: notes
        )
        store.saveVocalist(vocalist)
        dismiss()
    }
}


// MARK: - ─── Flow Layout ─────────────────────────────────────────────────────

/// Simple horizontal flow layout that wraps items to next line when out of space.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = flowLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = flowLayout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func flowLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
