// ============================================================================
// WatchComplicationProvider.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: WidgetKit Extension
// Purpose: Provides watch face complications showing current SPL level.
//          Supports circular gauge, corner text, and rectangular formats.
//          Updated via transferCurrentComplicationUserInfo() on significant
//          state changes (alert transitions or >=5 dB delta, ~50/day limit).
// ============================================================================

import WidgetKit
import SwiftUI


// MARK: - ─── Complication Entry ─────────────────────────────────────────────

struct SPLComplicationEntry: TimelineEntry {
    let date: Date
    let currentDB: Int
    let alertState: String  // "safe", "warning", "alert"
    let targetDB: Int
    let isRunning: Bool
}


// MARK: - ─── Timeline Provider ──────────────────────────────────────────────

struct SPLComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> SPLComplicationEntry {
        SPLComplicationEntry(
            date: Date(),
            currentDB: 85,
            alertState: "safe",
            targetDB: 90,
            isRunning: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SPLComplicationEntry) -> Void) {
        let entry = SPLComplicationEntry(
            date: Date(),
            currentDB: UserDefaults.standard.integer(forKey: "complicationDB"),
            alertState: UserDefaults.standard.string(forKey: "complicationAlert") ?? "safe",
            targetDB: Int(UserDefaults.standard.double(forKey: "watchTargetDB")),
            isRunning: UserDefaults.standard.bool(forKey: "complicationRunning")
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SPLComplicationEntry>) -> Void) {
        let entry = SPLComplicationEntry(
            date: Date(),
            currentDB: UserDefaults.standard.integer(forKey: "complicationDB"),
            alertState: UserDefaults.standard.string(forKey: "complicationAlert") ?? "safe",
            targetDB: Int(UserDefaults.standard.double(forKey: "watchTargetDB")),
            isRunning: UserDefaults.standard.bool(forKey: "complicationRunning")
        )
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        completion(timeline)
    }
}


// MARK: - ─── Circular Gauge Complication ────────────────────────────────────

struct SPLCircularView: View {
    let entry: SPLComplicationEntry

    var body: some View {
        Gauge(value: Double(entry.currentDB), in: 40...110) {
            Text("dB")
                .font(.system(size: 8))
        } currentValueLabel: {
            Text("\(entry.currentDB)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(gaugeColor)
        }
        .gaugeStyle(.circular)
        .tint(gaugeGradient)
    }

    private var gaugeColor: Color {
        switch entry.alertState {
        case "alert": return .red
        case "warning": return .orange
        default: return .green
        }
    }

    private var gaugeGradient: Gradient {
        Gradient(colors: [.green, .yellow, .orange, .red])
    }
}


// MARK: - ─── Corner Text Complication ───────────────────────────────────────

struct SPLCornerView: View {
    let entry: SPLComplicationEntry

    var body: some View {
        Text("\(entry.currentDB)")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(entry.isRunning ? .green : .gray)
    }
}


// MARK: - ─── Rectangular Complication ───────────────────────────────────────

struct SPLRectangularView: View {
    let entry: SPLComplicationEntry

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.isRunning ? "waveform" : "waveform.slash")
                .font(.system(size: 14))
                .foregroundStyle(entry.isRunning ? .green : .gray)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(entry.currentDB) dB")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("Target: \(entry.targetDB)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}


// MARK: - ─── Widget Configuration ───────────────────────────────────────────

@main
struct SPLComplicationWidget: Widget {
    let kind = "SPLComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SPLComplicationProvider()
        ) { entry in
            SPLCircularView(entry: entry)
        }
        .configurationDisplayName("SPL Meter")
        .description("Current sound level at your mix position.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular
        ])
    }
}
