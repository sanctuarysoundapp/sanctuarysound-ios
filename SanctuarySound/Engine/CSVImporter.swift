// ============================================================================
// CSVImporter.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: MVVM Business Logic Layer
// Purpose: Parses CSV exports from Allen & Heath Avantis Director software
//          into a MixerSnapshot for delta analysis.
// Format: A&H Director CSV with [Version], [Channels], [Outputs] sections.
// ============================================================================

import Foundation

// MARK: - ─── CSV Importer ────────────────────────────────────────────────────

/// Parses Allen & Heath Director CSV exports into a MixerSnapshot.
/// Handles the sectioned CSV format: [Version], [Channels], [Outputs], etc.
final class CSVImporter {

    // MARK: - Errors

    enum ImportError: LocalizedError {
        case emptyFile
        case noChannelsSection
        case noHeaderRow
        case malformedRow(line: Int, detail: String)

        var errorDescription: String? {
            switch self {
            case .emptyFile:
                return "The CSV file is empty."
            case .noChannelsSection:
                return "No [Channels] section found in the CSV."
            case .noHeaderRow:
                return "No column header row found in the [Channels] section."
            case .malformedRow(let line, let detail):
                return "Malformed data at line \(line): \(detail)"
            }
        }
    }

    // MARK: - Public API

    /// Import a CSV string from Avantis Director into a MixerSnapshot.
    ///
    /// - Parameters:
    ///   - csvString: The raw CSV content.
    ///   - mixer: The mixer model to tag the snapshot with.
    ///   - snapshotName: Display name for the snapshot.
    /// - Returns: A `MixerSnapshot` containing all parsed channels.
    func importCSV(
        _ csvString: String,
        mixer: MixerModel = .allenHeathAvantis,
        snapshotName: String = "Imported Snapshot"
    ) throws -> MixerSnapshot {

        let lines = csvString.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }

        guard !lines.isEmpty else { throw ImportError.emptyFile }

        // Find the [Channels] section
        let channelsContent = try extractSection(named: "Channels", from: lines)

        guard !channelsContent.isEmpty else { throw ImportError.noChannelsSection }

        // First row of the section is the header
        let header = parseCSVRow(channelsContent[0])
        guard !header.isEmpty else { throw ImportError.noHeaderRow }

        // Build column index map
        let columnMap = buildColumnMap(header: header)

        // Parse each channel row
        var channels: [ChannelSnapshot] = []
        for rowIndex in 1..<channelsContent.count {
            let row = channelsContent[rowIndex]
            if row.isEmpty { continue }

            let fields = parseCSVRow(row)
            if fields.isEmpty { continue }

            let channel = parseChannelRow(
                fields: fields,
                columnMap: columnMap,
                rowIndex: rowIndex
            )
            channels.append(channel)
        }

        return MixerSnapshot(
            name: snapshotName,
            mixer: mixer,
            channels: channels
        )
    }

    /// Import from a file URL.
    func importFromURL(_ url: URL, mixer: MixerModel = .allenHeathAvantis) throws -> MixerSnapshot {
        let csvString = try String(contentsOf: url, encoding: .utf8)
        let name = url.deletingPathExtension().lastPathComponent
        return try importCSV(csvString, mixer: mixer, snapshotName: name)
    }


    // MARK: - Section Extraction

    /// Extract lines belonging to a named [Section] from the CSV.
    private func extractSection(named sectionName: String, from lines: [String]) throws -> [String] {
        let sectionHeader = "[\(sectionName)]"
        var inSection = false
        var sectionLines: [String] = []

        for line in lines {
            if line.lowercased() == sectionHeader.lowercased() {
                inSection = true
                continue
            }

            if inSection {
                // A new section header ends the current section
                if line.hasPrefix("[") && line.hasSuffix("]") {
                    break
                }
                sectionLines.append(line)
            }
        }

        if !inSection { throw ImportError.noChannelsSection }
        return sectionLines
    }


    // MARK: - CSV Row Parsing

    /// Parse a single CSV row, handling quoted fields with commas.
    private func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }

        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }


    // MARK: - Column Mapping

    /// Map column header names to their index positions.
    /// A&H Director CSV headers can vary; we match flexibly.
    private func buildColumnMap(header: [String]) -> [CSVColumn: Int] {
        var map: [CSVColumn: Int] = [:]
        let normalized = header.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        for (index, col) in normalized.enumerated() {
            if col.contains("ch") && (col.contains("num") || col.contains("#") || col == "ch") {
                map[.channelNumber] = index
            } else if col.contains("name") || col.contains("label") {
                if map[.name] == nil { map[.name] = index }
            } else if col.contains("gain") && !col.contains("makeup") {
                map[.gain] = index
            } else if col.contains("fader") || col.contains("level") {
                if map[.fader] == nil { map[.fader] = index }
            } else if col.contains("hpf") && col.contains("freq") {
                map[.hpfFrequency] = index
            } else if col.contains("hpf") && (col.contains("on") || col.contains("enable")) {
                map[.hpfEnabled] = index
            } else if col.contains("48v") || col.contains("phantom") {
                map[.phantom] = index
            } else if col.contains("pad") {
                map[.pad] = index
            } else if col.contains("comp") && col.contains("thr") {
                map[.compThreshold] = index
            } else if col.contains("comp") && col.contains("ratio") {
                map[.compRatio] = index
            } else if col.contains("comp") && col.contains("att") {
                map[.compAttack] = index
            } else if col.contains("comp") && col.contains("rel") {
                map[.compRelease] = index
            }

            // EQ bands — look for patterns like "eq1freq", "eq1gain", "eq1q"
            for band in 1...4 {
                if col.contains("eq\(band)") || col.contains("eq \(band)") || col.contains("band\(band)") {
                    if col.contains("freq") {
                        map[.eqFreq(band)] = index
                    } else if col.contains("gain") || col.contains("level") {
                        map[.eqGain(band)] = index
                    } else if col.contains("q") || col.contains("width") || col.contains("bw") {
                        map[.eqQ(band)] = index
                    }
                }
            }
        }

        // Fallback: if no explicit channel number column, use index 0
        if map[.channelNumber] == nil {
            map[.channelNumber] = 0
        }

        return map
    }


    // MARK: - Channel Parsing

    /// Parse a single row into a ChannelSnapshot.
    private func parseChannelRow(
        fields: [String],
        columnMap: [CSVColumn: Int],
        rowIndex: Int
    ) -> ChannelSnapshot {

        func field(_ col: CSVColumn) -> String? {
            guard let idx = columnMap[col], idx < fields.count else { return nil }
            let val = fields[idx]
            return val.isEmpty ? nil : val
        }

        func doubleField(_ col: CSVColumn) -> Double? {
            guard let str = field(col) else { return nil }
            return Double(str)
        }

        func boolField(_ col: CSVColumn) -> Bool {
            guard let str = field(col)?.lowercased() else { return false }
            return str == "on" || str == "1" || str == "true" || str == "yes"
        }

        let channelNumber = Int(field(.channelNumber) ?? "\(rowIndex)") ?? rowIndex
        let name = field(.name) ?? "Ch \(channelNumber)"

        // Parse EQ bands
        var eqBands: [SnapshotEQBand] = []
        for band in 1...4 {
            if let freq = doubleField(.eqFreq(band)) {
                let gain = doubleField(.eqGain(band)) ?? 0.0
                let q = doubleField(.eqQ(band)) ?? 1.0
                eqBands.append(SnapshotEQBand(
                    frequency: freq,
                    gainDB: gain,
                    q: q,
                    enabled: gain != 0.0
                ))
            }
        }

        return ChannelSnapshot(
            channelNumber: channelNumber,
            name: name,
            gainDB: doubleField(.gain),
            faderDB: doubleField(.fader),
            hpfFrequency: doubleField(.hpfFrequency),
            hpfEnabled: boolField(.hpfEnabled),
            eqBands: eqBands,
            compThresholdDB: doubleField(.compThreshold),
            compRatio: doubleField(.compRatio),
            compAttackMS: doubleField(.compAttack),
            compReleaseMS: doubleField(.compRelease),
            phantomPower: boolField(.phantom),
            padEnabled: boolField(.pad)
        )
    }
}


// MARK: - ─── Column Key ──────────────────────────────────────────────────────

/// Hashable key for CSV column identification.
enum CSVColumn: Hashable {
    case channelNumber
    case name
    case gain
    case fader
    case hpfFrequency
    case hpfEnabled
    case phantom
    case pad
    case compThreshold
    case compRatio
    case compAttack
    case compRelease
    case eqFreq(Int)
    case eqGain(Int)
    case eqQ(Int)
}
