// ============================================================================
// PCOTeamImportPreviewView.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM View Layer
// Purpose: Editable checklist preview for PCO team import. Groups items by
//          category (Vocals, Instruments, Drums, Production) with toggleable
//          include/exclude, editable labels, and source type pickers.
//          Production roles are collapsed and excluded by default.
// ============================================================================

import SwiftUI


// MARK: - ─── PCO Team Import Preview ───────────────────────────────────

struct PCOTeamImportPreviewView: View {
    @Binding var items: [PCOTeamImportItem]
    let drumTemplate: DrumKitTemplate
    let onChangeDrumTemplate: () -> Void
    let onImport: ([InputChannel]) -> Void

    @State private var showProduction = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Vocals section
                if !vocalItems.isEmpty {
                    importSection(
                        title: "Vocals",
                        icon: "mic.fill",
                        indices: vocalIndices
                    )
                }

                // Instruments section
                if !instrumentItems.isEmpty {
                    importSection(
                        title: "Instruments",
                        icon: "guitars.fill",
                        indices: instrumentIndices
                    )
                }

                // Drums section
                if !drumItems.isEmpty {
                    drumSection
                }

                // Production section (collapsed)
                if !productionItems.isEmpty {
                    productionSection
                }

                // Import button
                importButton
            }
            .padding()
        }
    }


    // MARK: - ─── Category Filters ───────────────────────────────────────────

    private var vocalItems: [PCOTeamImportItem] {
        items.filter { $0.positionCategory == .audio && isVocalSource($0.source) }
    }

    private var instrumentItems: [PCOTeamImportItem] {
        items.filter { $0.positionCategory == .audio && !isVocalSource($0.source) }
    }

    private var drumItems: [PCOTeamImportItem] {
        items.filter { $0.positionCategory == .drums }
    }

    private var productionItems: [PCOTeamImportItem] {
        items.filter { $0.positionCategory == .production }
    }

    private var vocalIndices: [Int] {
        items.indices.filter { items[$0].positionCategory == .audio && isVocalSource(items[$0].source) }
    }

    private var instrumentIndices: [Int] {
        items.indices.filter { items[$0].positionCategory == .audio && !isVocalSource(items[$0].source) }
    }

    private var drumIndices: [Int] {
        items.indices.filter { items[$0].positionCategory == .drums }
    }

    private var productionIndices: [Int] {
        items.indices.filter { items[$0].positionCategory == .production }
    }

    private func isVocalSource(_ source: InputSource) -> Bool {
        source == .leadVocal || source == .backingVocal
    }

    /// Returns all InputSource values in the same category as the given source.
    /// Used for the source type picker menu — vocals see vocal options, guitars see guitar options, etc.
    private func sourcesForCategory(_ source: InputSource) -> [InputSource] {
        let category = source.category
        return InputSource.allCases.filter { $0.category == category }
    }

    private var includedCount: Int {
        items.filter(\.isIncluded).count
    }


    // MARK: - ─── Import Section ─────────────────────────────────────────────

    private func importSection(
        title: String,
        icon: String,
        indices: [Int]
    ) -> some View {
        SectionCard(title: title) {
            ForEach(indices, id: \.self) { index in
                importRow(index: index)
            }
        }
    }


    // MARK: - ─── Import Row ─────────────────────────────────────────────────

    private func importRow(index: Int) -> some View {
        HStack(spacing: 10) {
            // Include toggle
            Button {
                items[index].isIncluded.toggle()
            } label: {
                Image(systemName: items[index].isIncluded ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        items[index].isIncluded ? BoothColors.accent : BoothColors.textMuted
                    )
            }

            // Channel label
            Text(items[index].channelLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    items[index].isIncluded ? BoothColors.textPrimary : BoothColors.textMuted
                )

            Spacer()

            // Source badge — tappable menu picker for changing source type
            Menu {
                ForEach(sourcesForCategory(items[index].source)) { source in
                    Button {
                        items[index].source = source
                    } label: {
                        if source == items[index].source {
                            Label(source.localizedName, systemImage: "checkmark")
                        } else {
                            Text(source.localizedName)
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Text(items[index].source.localizedName)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 7, weight: .bold))
                }
                .foregroundStyle(
                    items[index].isIncluded ? BoothColors.accent : BoothColors.textMuted
                )
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    (items[index].isIncluded ? BoothColors.accent : BoothColors.textMuted)
                        .opacity(0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            // Person name (muted)
            if !items[index].personName.isEmpty && items[index].personName != items[index].channelLabel {
                Text(items[index].personName)
                    .font(.system(size: 10))
                    .foregroundStyle(BoothColors.textMuted)
                    .lineLimit(1)
                    .frame(maxWidth: 80, alignment: .trailing)
            }
        }
        .padding(.vertical, 4)
        .opacity(items[index].isIncluded ? 1.0 : 0.5)
    }


    // MARK: - ─── Drum Section ───────────────────────────────────────────────

    private var drumSection: some View {
        SectionCard(title: "Drums") {
            // Template info + change button
            HStack {
                Image(systemName: drumTemplate.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(BoothColors.accent)

                Text(drumTemplate.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)

                Spacer()

                Button {
                    onChangeDrumTemplate()
                } label: {
                    Text("Change Template")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BoothColors.accent)
                }
            }
            .padding(.bottom, 4)

            ForEach(drumIndices, id: \.self) { index in
                importRow(index: index)
            }
        }
    }


    // MARK: - ─── Production Section ─────────────────────────────────────────

    private var productionSection: some View {
        SectionCard(title: "Production") {
            Button {
                showProduction.toggle()
            } label: {
                HStack {
                    Image(systemName: showProduction ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                    Text(showProduction ? "Hide \(productionItems.count) excluded" : "Show \(productionItems.count) excluded")
                        .font(.system(size: 12))
                    Spacer()
                }
                .foregroundStyle(BoothColors.textMuted)
            }

            if showProduction {
                ForEach(productionIndices, id: \.self) { index in
                    importRow(index: index)
                }
            }
        }
    }


    // MARK: - ─── Import Button ──────────────────────────────────────────────

    private var importButton: some View {
        Button {
            let channels = items
                .filter(\.isIncluded)
                .map { InputChannel(label: $0.channelLabel, source: $0.source) }
            onImport(channels)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                Text("Import \(includedCount) Channels")
            }
            .font(.system(size: 14, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundStyle(BoothColors.background)
            .background(includedCount > 0 ? BoothColors.accent : BoothColors.textMuted)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(includedCount == 0)
    }
}


// MARK: - ─── Preview ─────────────────────────────────────────────────────

#Preview("Team Import Preview") {
    struct PreviewWrapper: View {
        @State var items: [PCOTeamImportItem] = [
            PCOTeamImportItem(personName: "John", positionName: "VOX 1", positionCategory: .audio, channelLabel: "VOX 1", source: .backingVocal),
            PCOTeamImportItem(personName: "Sarah", positionName: "VOX 2", positionCategory: .audio, channelLabel: "VOX 2", source: .backingVocal),
            PCOTeamImportItem(personName: "Mike", positionName: "EG Lead", positionCategory: .audio, channelLabel: "EG Lead", source: .electricGtrModeler),
            PCOTeamImportItem(personName: "Chase", positionName: "DRUMS", positionCategory: .drums, channelLabel: "Kick", source: .kickDrum),
            PCOTeamImportItem(personName: "Chase", positionName: "DRUMS", positionCategory: .drums, channelLabel: "Snare", source: .snareDrum),
            PCOTeamImportItem(personName: "Tim", positionName: "FOH Sound", positionCategory: .production, channelLabel: "FOH Sound", source: .backingVocal, isIncluded: false),
        ]

        var body: some View {
            NavigationStack {
                ZStack {
                    BoothColors.background.ignoresSafeArea()
                    PCOTeamImportPreviewView(
                        items: $items,
                        drumTemplate: .standard5,
                        onChangeDrumTemplate: {},
                        onImport: { _ in }
                    )
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    return PreviewWrapper()
}
