// ============================================================================
// WatchSessionManager.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Connectivity Layer (iOS only)
// Purpose: Manages WatchConnectivity session on the iPhone side. Sends real-time
//          SPL snapshots (~10Hz), preference updates, and completed session reports
//          to the Apple Watch companion app. Receives start/stop commands from Watch.
// ============================================================================

import Foundation
import WatchConnectivity


// MARK: - ─── Watch Session Manager ──────────────────────────────────────────

/// Manages the WCSession on the iPhone side for communicating with the
/// Apple Watch companion app. Singleton — activated once at app launch.
@MainActor
final class WatchSessionManager: NSObject, ObservableObject {

    static let shared = WatchSessionManager()

    // ── Published State ──
    @Published private(set) var isWatchReachable = false
    @Published private(set) var isWatchPaired = false

    // ── Callbacks ──
    /// Called when the Watch sends a start command.
    var onStartCommand: (() -> Void)?
    /// Called when the Watch sends a stop command.
    var onStopCommand: (() -> Void)?

    // ── Throttle ──
    private var lastSendTime: Date = .distantPast
    private let sendInterval: TimeInterval = 0.1  // 10Hz

    private var session: WCSession?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Activation

    /// Activate the WCSession. Call once at app launch.
    func activate() {
        guard WCSession.isSupported() else { return }
        let wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        self.session = wcSession
    }

    // MARK: - Send SPL Snapshot

    /// Send an SPL snapshot to the Watch. Throttled to ~10Hz.
    func sendSPLSnapshot(_ snapshot: SPLSnapshot) {
        guard let session = session,
              session.isReachable else { return }

        let now = Date()
        guard now.timeIntervalSince(lastSendTime) >= sendInterval else { return }
        lastSendTime = now

        let message = snapshot.toDictionary()
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    // MARK: - Send Preferences

    /// Send preferences to the Watch via application context (survives background).
    func sendPreferences(targetDB: Double, flaggingMode: SPLFlaggingMode, themeID: String, calibrationOffset: Double?) {
        guard let session = session,
              session.activationState == .activated else { return }

        var context: [String: Any] = [
            WCMessageKey.targetDB: targetDB,
            WCMessageKey.flaggingMode: flaggingMode.rawValue,
            WCMessageKey.themeID: themeID
        ]
        if let offset = calibrationOffset {
            context[WCMessageKey.calibrationOffset] = offset
        }

        try? session.updateApplicationContext(context)
    }

    // MARK: - Send Report

    /// Transfer a completed session report to the Watch.
    func sendReport(_ report: SPLSessionReport) {
        guard let session = session,
              session.activationState == .activated else { return }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(report) else { return }

        session.transferUserInfo([
            WCMessageKey.reportData: data
        ])
    }
}


// MARK: - ─── WCSessionDelegate ──────────────────────────────────────────────

extension WatchSessionManager: WCSessionDelegate {

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            self.isWatchPaired = session.isPaired
            self.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // No-op — required for iOS
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate for session switching
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchReachable = session.isReachable
        }
    }

    /// Receive messages from Watch (start/stop commands).
    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard let type = message[WCMessageKey.messageType] as? String,
              type == WCMessageKey.typeCommand,
              let command = message[WCMessageKey.command] as? String
        else {
            replyHandler(["status": "unknown"])
            return
        }

        Task { @MainActor in
            switch command {
            case WCMessageKey.commandStart:
                self.onStartCommand?()
                replyHandler(["status": "started"])
            case WCMessageKey.commandStop:
                self.onStopCommand?()
                replyHandler(["status": "stopped"])
            default:
                replyHandler(["status": "unknown"])
            }
        }
    }
}
