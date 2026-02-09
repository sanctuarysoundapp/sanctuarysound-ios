// ============================================================================
// WatchSessionReceiver.swift
// SanctuarySound Watch — SPL Monitor Companion
// ============================================================================
// Architecture: Connectivity Layer (watchOS only)
// Purpose: WCSessionDelegate on the Watch side. Receives SPL snapshots,
//          preferences, and reports from the iPhone. Sends start/stop commands.
// ============================================================================

import Foundation
import WatchConnectivity


// MARK: - ─── Watch Session Receiver ─────────────────────────────────────────

/// Manages the WCSession on the Watch side.
final class WatchSessionReceiver: NSObject, ObservableObject {

    // ── Callbacks ──
    var onSnapshotReceived: ((SPLSnapshot) -> Void)?
    var onPreferencesReceived: (([String: Any]) -> Void)?
    var onReportReceived: ((SPLSessionReport) -> Void)?
    var onReachabilityChanged: ((Bool) -> Void)?

    private var session: WCSession?

    // MARK: - Activation

    /// Activate the WCSession on the Watch.
    func activate() {
        guard WCSession.isSupported() else { return }
        let wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        self.session = wcSession
    }

    // MARK: - Send Commands

    /// Send a command to the iPhone (e.g., "start" or "stop").
    func sendCommand(_ command: String) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            WCMessageKey.messageType: WCMessageKey.typeCommand,
            WCMessageKey.command: command
        ]

        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }
}


// MARK: - ─── WCSessionDelegate ──────────────────────────────────────────────

extension WatchSessionReceiver: WCSessionDelegate {

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.onReachabilityChanged?(session.isReachable)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.onReachabilityChanged?(session.isReachable)
        }
    }

    /// Receive real-time SPL snapshots from iPhone.
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let type = message[WCMessageKey.messageType] as? String else { return }

        if type == WCMessageKey.typeSPLSnapshot {
            guard let snapshot = SPLSnapshot.from(dictionary: message) else { return }
            DispatchQueue.main.async {
                self.onSnapshotReceived?(snapshot)
            }
        }
    }

    /// Receive preferences via application context.
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.onPreferencesReceived?(applicationContext)
        }
    }

    /// Receive completed session reports via user info transfer.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let reportData = userInfo[WCMessageKey.reportData] as? Data else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let report = try? decoder.decode(SPLSessionReport.self, from: reportData) else { return }

        DispatchQueue.main.async {
            self.onReportReceived?(report)
        }
    }
}
