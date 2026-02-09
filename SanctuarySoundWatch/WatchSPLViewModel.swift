// ============================================================================
// WatchSPLViewModel.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: MVVM ViewModel Layer
// Purpose: Manages SPL state on the Watch. Receives snapshots from iPhone via
//          WatchSessionReceiver, publishes UI state, sends start/stop commands,
//          persists reports/preferences locally, and fires haptics on alerts.
// ============================================================================

import Foundation
import SwiftUI
import WatchKit


// MARK: - ─── Watch SPL ViewModel ────────────────────────────────────────────

@MainActor
final class WatchSPLViewModel: ObservableObject {

    // ── Published SPL State ──
    @Published private(set) var currentDB: Double = 0.0
    @Published private(set) var peakDB: Double = 0.0
    @Published private(set) var averageDB: Double = 0.0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var alertStateCodable: SPLAlertStateCodable = .safe
    @Published private(set) var isPhoneReachable: Bool = false

    // ── Preferences ──
    @Published var targetDB: Double = 90.0
    @Published var flaggingModeName: String = "Balanced"

    // ── Reports ──
    @Published private(set) var reports: [SPLSessionReport] = []

    // ── Crown Adjustment ──
    @Published var crownTargetDB: Double = 90.0
    private var crownDebounceTask: Task<Void, Never>?

    // ── Session Receiver ──
    let sessionReceiver = WatchSessionReceiver()

    // ── Haptic Tracking ──
    private var previousAlertRaw: String = "safe"

    // MARK: - Init

    init() {
        loadLocalData()
        configureReceiver()
    }

    // MARK: - Commands

    /// Toggle monitoring — sends start or stop command to iPhone.
    func toggleMonitoring() {
        if isRunning {
            sessionReceiver.sendCommand(WCMessageKey.commandStop)
        } else {
            sessionReceiver.sendCommand(WCMessageKey.commandStart)
        }
    }

    // MARK: - ─── Ring Gauge Computations ──────────────────────────────────────

    /// Ring fill fraction: 0.0 at 40 dB floor, 1.0 at target dB. Can exceed 1.0 when over target.
    var ringFillFraction: Double {
        let floor = 40.0
        let range = max(targetDB - floor, 1.0)
        return min(max(currentDB - floor, 0), range + 20) / range
    }

    /// Ring color based on current alert state: green (safe), amber (warning), red (alert).
    var ringColor: Color {
        switch alertStateCodable.rawValue {
        case "alert":
            return WatchColors.accentDanger
        case "warning":
            return WatchColors.accentWarm
        default:
            return WatchColors.accent
        }
    }

    // MARK: - ─── Crown Target Adjustment ────────────────────────────────────────

    /// Called by the view when crownTargetDB changes via Digital Crown rotation.
    /// Debounces 500ms before committing the value and syncing to iPhone.
    func onCrownTargetChanged() {
        crownDebounceTask?.cancel()
        crownDebounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled, let self else { return }
            self.commitCrownTarget()
        }
    }

    private func commitCrownTarget() {
        let clamped = min(max(crownTargetDB, 70.0), 100.0)
        crownTargetDB = clamped
        targetDB = clamped
        UserDefaults.standard.set(clamped, forKey: "watchTargetDB")
        sessionReceiver.sendPreferenceUpdate(targetDB: clamped)
    }

    // MARK: - Receiver Configuration

    private func configureReceiver() {
        sessionReceiver.onSnapshotReceived = { [weak self] snapshot in
            Task { @MainActor in
                self?.handleSnapshot(snapshot)
            }
        }

        sessionReceiver.onPreferencesReceived = { [weak self] context in
            Task { @MainActor in
                self?.handlePreferences(context)
            }
        }

        sessionReceiver.onReportReceived = { [weak self] report in
            Task { @MainActor in
                self?.handleReport(report)
            }
        }

        sessionReceiver.onReachabilityChanged = { [weak self] reachable in
            Task { @MainActor in
                self?.isPhoneReachable = reachable
            }
        }

        sessionReceiver.activate()
    }

    // MARK: - Snapshot Handling

    private func handleSnapshot(_ snapshot: SPLSnapshot) {
        currentDB = snapshot.currentDB
        peakDB = snapshot.peakDB
        averageDB = snapshot.averageDB
        isRunning = snapshot.isRunning

        let newAlert = snapshot.alertState
        fireHapticsIfNeeded(previousRaw: previousAlertRaw, newRaw: newAlert.rawValue)
        alertStateCodable = newAlert
        previousAlertRaw = newAlert.rawValue
    }

    // MARK: - Preferences Handling

    private func handlePreferences(_ context: [String: Any]) {
        if let target = context[WCMessageKey.targetDB] as? Double {
            targetDB = target
            crownTargetDB = target
            UserDefaults.standard.set(target, forKey: "watchTargetDB")
        }
        if let mode = context[WCMessageKey.flaggingMode] as? String {
            flaggingModeName = mode
            UserDefaults.standard.set(mode, forKey: "watchFlaggingMode")
        }
        if let theme = context[WCMessageKey.themeID] as? String {
            UserDefaults.standard.set(theme, forKey: "watchThemeID")
        }
    }

    // MARK: - Report Handling

    private func handleReport(_ report: SPLSessionReport) {
        reports.insert(report, at: 0)
        // Keep max 20 reports on Watch
        if reports.count > 20 {
            reports = Array(reports.prefix(20))
        }
        persistReports()
    }

    // MARK: - Haptics

    private func fireHapticsIfNeeded(previousRaw: String, newRaw: String) {
        guard previousRaw != newRaw else { return }

        switch newRaw {
        case "warning":
            WKInterfaceDevice.current().play(.notification)
        case "alert":
            WKInterfaceDevice.current().play(.failure)
        case "safe" where previousRaw != "safe":
            WKInterfaceDevice.current().play(.success)
        default:
            break
        }
    }

    // MARK: - Local Persistence

    private func loadLocalData() {
        targetDB = UserDefaults.standard.double(forKey: "watchTargetDB")
        if targetDB == 0 { targetDB = 90.0 }

        crownTargetDB = targetDB

        flaggingModeName = UserDefaults.standard.string(forKey: "watchFlaggingMode") ?? "Balanced"

        if let data = UserDefaults.standard.data(forKey: "watchReports") {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            reports = (try? decoder.decode([SPLSessionReport].self, from: data)) ?? []
        }
    }

    private func persistReports() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(reports) {
            UserDefaults.standard.set(data, forKey: "watchReports")
        }
    }
}
