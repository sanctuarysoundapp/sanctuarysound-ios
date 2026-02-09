// ============================================================================
// DrumKitTemplatePicker.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Template picker for drum kit channel expansion during PCO import.
//          Offers Basic 3-mic, Standard 5-mic, Full 7-mic, and Custom options.
//          Custom mode shows a checkbox list of all available drum sources.
// ============================================================================

import SwiftUI


// MARK: - ─── Drum Kit Template Picker ──────────────────────────────────

struct DrumKitTemplatePicker: View {
    let currentTemplate: DrumKitTemplate
    let onSelect: (DrumKitTemplate, [(label: String, source: InputSource)]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTemplate: DrumKitTemplate
    @State private var customSelections: Set<Int> = []

    init(
        currentTemplate: DrumKitTemplate,
        onSelect: @escaping (DrumKitTemplate, [(label: String, source: InputSource)]) -> Void
    ) {
        self.currentTemplate = currentTemplate
        self.onSelect = onSelect
        self._selectedTemplate = State(initialValue: currentTemplate)

        // Initialize custom selections from standard5 defaults
        let defaultIndices = Set(DrumKitTemplate.standard5.channels.compactMap { channel in
            DrumKitTemplate.allDrumSources.firstIndex(where: { $0.source == channel.source })
        })
        self._customSelections = State(initialValue: defaultIndices)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BoothColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Template cards
                        ForEach(DrumKitTemplate.allCases, id: \.id) { template in
                            templateCard(template)
                        }

                        // Custom source list (shown when Custom is selected)
                        if selectedTemplate == .custom {
                            customSourceList
                        }

                        // Confirm button
                        Button {
                            let channels = resolvedChannels
                            onSelect(selectedTemplate, channels)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Use \(resolvedChannels.count) Channels")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .foregroundStyle(BoothColors.background)
                            .background(BoothColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Drum Kit Template")
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


    // MARK: - ─── Template Card ──────────────────────────────────────────────

    private func templateCard(_ template: DrumKitTemplate) -> some View {
        Button {
            selectedTemplate = template
        } label: {
            HStack(spacing: 12) {
                Image(systemName: template.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(selectedTemplate == template ? BoothColors.accent : BoothColors.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BoothColors.textPrimary)

                    if template != .custom {
                        Text(template.channels.map(\.label).joined(separator: ", "))
                            .font(.system(size: 11))
                            .foregroundStyle(BoothColors.textSecondary)
                            .lineLimit(2)
                    } else {
                        Text("Choose individual drum channels")
                            .font(.system(size: 11))
                            .foregroundStyle(BoothColors.textSecondary)
                    }
                }

                Spacer()

                if selectedTemplate == template {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(BoothColors.accent)
                }
            }
            .padding(14)
            .background(BoothColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        selectedTemplate == template ? BoothColors.accent : Color.clear,
                        lineWidth: 2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }


    // MARK: - ─── Custom Source List ──────────────────────────────────────────

    private var customSourceList: some View {
        VStack(spacing: 0) {
            ForEach(Array(DrumKitTemplate.allDrumSources.enumerated()), id: \.offset) { index, source in
                Button {
                    if customSelections.contains(index) {
                        customSelections.remove(index)
                    } else {
                        customSelections.insert(index)
                    }
                } label: {
                    HStack {
                        Image(systemName: customSelections.contains(index) ? "checkmark.square.fill" : "square")
                            .font(.system(size: 16))
                            .foregroundStyle(
                                customSelections.contains(index) ? BoothColors.accent : BoothColors.textMuted
                            )

                        Text(source.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(BoothColors.textPrimary)

                        Spacer()

                        Text(source.source.localizedName)
                            .font(.system(size: 11))
                            .foregroundStyle(BoothColors.textSecondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                }

                if index < DrumKitTemplate.allDrumSources.count - 1 {
                    Divider()
                        .background(BoothColors.divider)
                }
            }
        }
        .background(BoothColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }


    // MARK: - ─── Resolved Channels ──────────────────────────────────────────

    private var resolvedChannels: [(label: String, source: InputSource)] {
        if selectedTemplate == .custom {
            return customSelections.sorted().compactMap { index in
                guard index < DrumKitTemplate.allDrumSources.count else { return nil }
                return DrumKitTemplate.allDrumSources[index]
            }
        }
        return selectedTemplate.channels
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("Drum Kit Template Picker") {
    DrumKitTemplatePicker(
        currentTemplate: .standard5,
        onSelect: { _, _ in }
    )
}
