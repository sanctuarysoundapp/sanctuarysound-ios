// ============================================================================
// InputLibrarySheets.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Sheet views for input and vocalist CRUD — extracted from
//          InputLibraryView.swift to keep each file focused and under 800 lines.
// ============================================================================

import SwiftUI


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
        AppDateFormatter.mediumDate.string(from: date)
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
