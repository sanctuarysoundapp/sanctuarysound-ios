// ============================================================================
// SPLMeter.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Audio Utility
// Purpose: Measures SPL using the iPhone's built-in microphone via
//          AVAudioEngine. Used for calibrating the SPL offset between
//          mixer output level (dBFS) and room SPL at mix position.
// Accuracy: iPhone mic is reasonably accurate for relative measurements.
//           Absolute accuracy is ~±3 dB without device-specific calibration.
// ============================================================================

import AVFoundation
import Combine

// MARK: - ─── SPL Meter ──────────────────────────────────────────────────────

/// Measures sound pressure level using the iPhone microphone.
/// Publishes real-time dB readings via Combine.
@MainActor
final class SPLMeter: ObservableObject {

    // ── Published State ──
    @Published private(set) var currentDB: Double = 0.0
    @Published private(set) var peakDB: Double = 0.0
    @Published private(set) var averageDB: Double = 0.0
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var permissionGranted: Bool = false
    @Published private(set) var alertState: SPLAlertState = .safe

    // ── Alert Tracking ──
    private var targetDB: Double = 90.0
    private var flagThresholdDB: Double = 5.0
    private var breachStartTime: Date?
    private var safeStartTime: Date?
    private let breachDebounce: TimeInterval = 1.5  // Must breach for 1.5s to trigger
    private let safeDebounce: TimeInterval = 3.0    // Must be safe for 3s to clear

    // ── Breach Logging ──
    @Published private(set) var breachEvents: [SPLBreachEvent] = []
    private var currentBreachStart: Date?
    private var currentBreachPeak: Double = 0.0
    private var sessionStartTime: Date?
    private var sessionReadingSum: Double = 0.0
    private var sessionReadingCount: Int = 0

    // ── Watch Connectivity Hook ──
    /// Called on every SPL update (~50Hz). WatchSessionManager throttles to 10Hz.
    var onSPLUpdate: ((SPLSnapshot) -> Void)?

    // ── Internal ──
    private var audioEngine: AVAudioEngine?
    private var recentReadings: [Double] = []
    private let maxReadings = 100  // ~2 seconds at 50 readings/sec

    /// iPhone mic reference offset.
    /// The iPhone mic measures in dBFS. To approximate dB SPL:
    /// SPL ≈ dBFS + referenceOffset
    /// This is a rough factory calibration; the calibration flow refines it.
    private let referenceOffset: Double = 90.0  // Approximate: 0 dBFS ≈ ~90 dB SPL on iPhone

    // MARK: - Public API

    /// Request microphone permission.
    func requestPermission() async {
        if #available(iOS 17, *) {
            let granted = await AVAudioApplication.requestRecordPermission()
            permissionGranted = granted
        }
    }

    /// Start measuring SPL.
    func start() {
        guard permissionGranted else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.processBuffer(buffer)
            }

            try engine.start()
            self.audioEngine = engine
            isRunning = true
            recentReadings = []
            peakDB = 0.0

            // Start a new monitoring session
            sessionStartTime = Date()
            sessionReadingSum = 0.0
            sessionReadingCount = 0
            breachEvents = []
            currentBreachStart = nil
            currentBreachPeak = 0.0

        } catch {
            isRunning = false
        }
    }

    /// Stop measuring.
    func stop() {
        // Close any open breach event before stopping
        finalizeCurrentBreach()

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRunning = false

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    /// Reset peak and average readings.
    func resetPeak() {
        peakDB = 0.0
        recentReadings = []
        averageDB = 0.0
    }

    /// Update the alert thresholds from user's SPL preference.
    /// Call whenever SPLPreference changes.
    func updateAlertThresholds(preference: SPLPreference) {
        targetDB = preference.targetDB
        flagThresholdDB = preference.flagThresholdDB
    }

    /// Calculate the calibration offset given a known reference SPL.
    /// Call this while playing a reference signal and measuring with a known SPL meter.
    /// - Parameter knownSPL: The actual SPL as read by a reference meter.
    /// - Returns: The calibration offset to store in SPLPreference.
    func calculateCalibrationOffset(knownSPL: Double) -> Double {
        // offset = knownSPL - currentDB_raw (before offset)
        // So that: SPL = dBFS_reading + offset = knownSPL
        let rawReading = currentDB - referenceOffset
        return knownSPL - rawReading
    }


    // MARK: - Buffer Processing

    /// Called on the audio render thread — must be nonisolated so the
    /// installTap closure can invoke it synchronously. All @MainActor
    /// property updates are dispatched via Task.
    nonisolated private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frames = Int(buffer.frameLength)
        let samples = channelData[0]

        // Calculate RMS level
        var sumOfSquares: Float = 0
        for i in 0..<frames {
            sumOfSquares += samples[i] * samples[i]
        }
        let rms = sqrt(sumOfSquares / Float(frames))

        // Convert to dB (relative to full scale)
        let dbFS: Double
        if rms > 0 {
            dbFS = 20.0 * log10(Double(rms))
        } else {
            dbFS = -160.0
        }

        // Convert to approximate SPL
        let refOffset = 90.0  // referenceOffset value (can't access actor property here)
        let spl = max(dbFS + refOffset, 0)

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.currentDB = spl

            if spl > self.peakDB {
                self.peakDB = spl
            }

            // Running average
            self.recentReadings.append(spl)
            if self.recentReadings.count > self.maxReadings {
                self.recentReadings.removeFirst()
            }
            self.averageDB = self.recentReadings.reduce(0, +) / Double(self.recentReadings.count)

            // ── Session tracking for report ──
            self.sessionReadingSum += spl
            self.sessionReadingCount += 1

            // ── Alert State Evaluation + Breach Logging ──
            self.evaluateAlertState(spl: spl)

            // ── Notify Watch Connectivity ──
            let snapshot = SPLSnapshot(
                currentDB: spl,
                peakDB: self.peakDB,
                averageDB: self.averageDB,
                alertState: SPLAlertStateCodable(from: self.alertState),
                isRunning: self.isRunning
            )
            self.onSPLUpdate?(snapshot)
        }
    }


    // MARK: - Alert State Evaluation

    /// Evaluates SPL against thresholds with debounce to prevent flickering.
    /// Breach must persist for `breachDebounce` seconds to trigger alert.
    /// SPL must stay safe for `safeDebounce` seconds to clear alert.
    /// Also tracks breach events for the session report.
    private func evaluateAlertState(spl: Double) {
        let overTarget = spl - targetDB
        let overThreshold = spl - (targetDB + flagThresholdDB)
        let now = Date()

        if overTarget > 0 {
            // ── Over target (warning or danger) ──
            safeStartTime = nil
            if breachStartTime == nil { breachStartTime = now }

            // Track breach peak and start
            if currentBreachStart == nil { currentBreachStart = now }
            if spl > currentBreachPeak { currentBreachPeak = spl }

            if now.timeIntervalSince(breachStartTime!) >= breachDebounce {
                if overThreshold > 0 {
                    alertState = .alert(
                        currentDB: Int(spl),
                        overBy: Int(overTarget)
                    )
                } else {
                    alertState = .warning(
                        currentDB: Int(spl),
                        overBy: Int(overTarget)
                    )
                }
            }

        } else {
            // ── Below target (safe zone) ──
            breachStartTime = nil

            // Finalize breach event if one was in progress
            finalizeCurrentBreach()

            // Only clear alert if we've been safe long enough
            if alertState.isActive {
                if safeStartTime == nil { safeStartTime = now }

                if now.timeIntervalSince(safeStartTime!) >= safeDebounce {
                    alertState = .safe
                    safeStartTime = nil
                }
            } else {
                safeStartTime = nil
            }
        }
    }


    // MARK: - Breach Logging

    /// Closes the current breach event and records it.
    private func finalizeCurrentBreach() {
        guard let start = currentBreachStart else { return }

        let event = SPLBreachEvent(
            startTime: start,
            endTime: Date(),
            peakDB: currentBreachPeak,
            targetDB: targetDB,
            thresholdDB: flagThresholdDB
        )

        // Only log breaches that lasted at least 1 second (filter noise)
        if event.durationSeconds >= 1.0 {
            breachEvents.append(event)
        }

        currentBreachStart = nil
        currentBreachPeak = 0.0
    }

    /// Generates a session report summarizing SPL behavior during monitoring.
    /// Call after stopping the meter.
    func generateSessionReport(flaggingMode: SPLFlaggingMode) -> SPLSessionReport? {
        guard let sessionStart = sessionStartTime else { return nil }
        guard sessionReadingCount > 0 else { return nil }

        let sessionEnd = Date()
        let overallAvg = sessionReadingSum / Double(sessionReadingCount)
        let totalSeconds = sessionEnd.timeIntervalSince(sessionStart)

        return SPLSessionReport(
            sessionStart: sessionStart,
            sessionEnd: sessionEnd,
            targetDB: targetDB,
            flaggingMode: flaggingMode,
            breachEvents: breachEvents,
            overallPeakDB: peakDB,
            overallAverageDB: overallAvg,
            totalMonitoringSeconds: totalSeconds
        )
    }
}
