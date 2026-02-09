// ============================================================================
// SharedComponents.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Views/Components — Reusable UI primitives
// Purpose: Shared view components used across multiple screens. Dark-themed,
//          high-contrast designs optimized for sound booth environments.
// ============================================================================

import SwiftUI


// MARK: - ─── Section Card ────────────────────────────────────────────────

/// Dark-themed section card container.
struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.accent)
                .tracking(1.5)

            VStack(alignment: .leading, spacing: 10) {
                content
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BoothColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


// MARK: - ─── Booth Text Field ────────────────────────────────────────────

/// Styled text field for dark UI.
struct BoothTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(BoothColors.textSecondary)

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundStyle(BoothColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(BoothColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}


// MARK: - ─── Info Badge ──────────────────────────────────────────────────

/// Compact info badge for displaying metadata.
struct InfoBadge: View {
    let label: String
    let value: String
    var color: Color = BoothColors.accent

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(BoothColors.textMuted)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}


// MARK: - ─── Empty State View ────────────────────────────────────────────

/// Empty state placeholder.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(BoothColors.textMuted)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BoothColors.textSecondary)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - ─── Summary Row ─────────────────────────────────────────────────

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(BoothColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(BoothColors.textPrimary)
        }
        .padding(.vertical, 2)
    }
}


// MARK: - ─── Channel Row ─────────────────────────────────────────────────

struct ChannelRow: View {
    let channel: InputChannel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: channel.source.category.systemIcon)
                .font(.system(size: 16))
                .foregroundStyle(BoothColors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)

                Text(channel.source.localizedName)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
            }

            Spacer()

            if channel.source.isLineLevel {
                Text("LINE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accentWarm)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BoothColors.accentWarm.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Text("MIC")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(BoothColors.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BoothColors.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .padding(.vertical, 4)
    }
}


// MARK: - ─── Song Row ────────────────────────────────────────────────────

struct SongRow: View {
    let index: Int
    let song: SetlistSong

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(BoothColors.textMuted)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BoothColors.textPrimary)
                Text(song.intensity.localizedName)
                    .font(.system(size: 11))
                    .foregroundStyle(BoothColors.textSecondary)
            }

            Spacer()

            Text(song.key.localizedName)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(BoothColors.accent)
                .frame(width: 32, height: 32)
                .background(BoothColors.accent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            if let bpm = song.bpm {
                Text("\(bpm)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(BoothColors.textMuted)
                + Text(" bpm")
                    .font(.system(size: 9))
                    .foregroundStyle(BoothColors.textMuted)
            }
        }
        .padding(.vertical, 4)
    }
}


// MARK: - ─── Icon Picker ─────────────────────────────────────────────────

/// Reusable icon-based picker for compact selection grids.
/// Replaces segmented controls that overflow on small screens.
struct IconPicker<T: Hashable>: View {
    let items: [(value: T, icon: String, label: String)]
    @Binding var selection: T
    var columns: Int = 0

    var body: some View {
        if columns > 0 {
            gridLayout
        } else {
            rowLayout
        }
    }

    private var rowLayout: some View {
        HStack(spacing: 8) {
            ForEach(items.indices, id: \.self) { i in
                iconButton(for: items[i])
            }
        }
    }

    private var gridLayout: some View {
        let rows = stride(from: 0, to: items.count, by: columns).map { start in
            Array(items[start..<min(start + columns, items.count)])
        }
        return VStack(spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 8) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        iconButton(for: rows[rowIndex][colIndex])
                    }
                    // Fill remaining space if row is incomplete
                    if rows[rowIndex].count < columns {
                        ForEach(0..<(columns - rows[rowIndex].count), id: \.self) { _ in
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func iconButton(for item: (value: T, icon: String, label: String)) -> some View {
        let isSelected = selection == item.value as T
        return Button {
            selection = item.value
        } label: {
            VStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? BoothColors.accent : BoothColors.textMuted)
                Text(item.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? BoothColors.textPrimary : BoothColors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? BoothColors.accent.opacity(0.15) : BoothColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? BoothColors.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
