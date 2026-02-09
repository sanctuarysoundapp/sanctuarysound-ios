// ============================================================================
// EQAnalyzer.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Audio Utility
// Purpose: Real-time 1/3-octave frequency analyzer using the iPhone mic.
//          Captures audio via AVAudioEngine, computes FFT via Accelerate,
//          and publishes 31-band spectrum data for the RTA display.
//          Shares mic permission with SPLMeter but cannot run simultaneously.
// ============================================================================

import AVFoundation
import Combine


// MARK: - ─── EQ Analyzer ─────────────────────────────────────────────────────

/// Real-time 1/3-octave frequency analyzer using the iPhone microphone.
/// Publishes band levels and peak-hold values via Combine for the RTA display.
@MainActor
final class EQAnalyzer: ObservableObject {

    // ── Published State ──
    @Published private(set) var bandLevels: [Double] = Array(repeating: FFTProcessor.noiseFloorDB, count: FrequencyBands.count)
    @Published private(set) var peakLevels: [Double] = Array(repeating: FFTProcessor.noiseFloorDB, count: FrequencyBands.count)
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var permissionGranted: Bool = false

    // ── Snapshots ──
    @Published private(set) var savedSnapshots: [EQSnapshot] = []

    // ── Internal ──
    private var audioEngine: AVAudioEngine?
    private var peakTracker = PeakHoldTracker()
    private var hannWindow: [Float]?
    private var sampleRate: Double = 44100.0

    // ── Smoothing ──
    /// Exponential moving average factor (0–1). Higher = more responsive, lower = smoother.
    private let smoothingFactor: Double = 0.3
    private var smoothedLevels: [Double] = Array(repeating: FFTProcessor.noiseFloorDB, count: FrequencyBands.count)


    // MARK: - ─── Public API ──────────────────────────────────────────────────

    /// Request microphone permission.
    func requestPermission() async {
        if #available(iOS 17, *) {
            let granted = await AVAudioApplication.requestRecordPermission()
            permissionGranted = granted
        }
    }

    /// Start the frequency analyzer.
    func start() {
        guard permissionGranted else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            sampleRate = format.sampleRate

            // Pre-compute Hann window for the buffer size
            let bufferSize = FFTProcessor.recommendedBufferSize
            hannWindow = FFTProcessor.hannWindow(length: bufferSize)

            inputNode.installTap(
                onBus: 0,
                bufferSize: AVAudioFrameCount(bufferSize),
                format: format
            ) { [weak self] buffer, _ in
                self?.processBuffer(buffer)
            }

            try engine.start()
            self.audioEngine = engine
            isRunning = true

            // Reset state
            peakTracker = PeakHoldTracker()
            smoothedLevels = Array(repeating: FFTProcessor.noiseFloorDB, count: FrequencyBands.count)

        } catch {
            isRunning = false
        }
    }

    /// Stop the frequency analyzer.
    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRunning = false

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    /// Reset peak-hold markers.
    func resetPeaks() {
        peakTracker = peakTracker.reset()
        peakLevels = peakTracker.peaks
    }

    /// Capture the current spectrum as a snapshot.
    /// - Parameter name: User-provided name for the snapshot.
    func captureSnapshot(name: String = "") {
        let snapshotName: String
        if name.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm:ss a"
            snapshotName = "Capture — \(formatter.string(from: Date()))"
        } else {
            snapshotName = name
        }

        let snapshot = EQSnapshot(
            bandLevels: bandLevels,
            peakLevels: peakLevels,
            name: snapshotName
        )
        savedSnapshots.append(snapshot)
    }

    /// Remove a saved snapshot.
    /// - Parameter id: ID of the snapshot to remove.
    func deleteSnapshot(id: UUID) {
        savedSnapshots.removeAll { $0.id == id }
    }


    // MARK: - ─── Buffer Processing ───────────────────────────────────────────

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameCount = Int(buffer.frameLength)
        let bufferSize = FFTProcessor.recommendedBufferSize

        // Ensure we have enough samples for FFT
        guard frameCount >= bufferSize else { return }

        // Extract samples
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: bufferSize))

        // Compute FFT magnitude spectrum
        let magnitudes = FFTProcessor.magnitudeSpectrum(from: samples)
        guard !magnitudes.isEmpty else { return }

        // Map to 1/3-octave bands
        let currentSampleRate = sampleRate
        let newBandLevels = FFTProcessor.mapToBands(magnitudes: magnitudes, sampleRate: currentSampleRate)

        Task { @MainActor in
            // Exponential smoothing
            for i in 0..<FrequencyBands.count {
                self.smoothedLevels[i] = self.smoothingFactor * newBandLevels[i]
                    + (1.0 - self.smoothingFactor) * self.smoothedLevels[i]
            }
            self.bandLevels = self.smoothedLevels

            // Update peak hold
            self.peakTracker = self.peakTracker.updated(with: self.smoothedLevels)
            self.peakLevels = self.peakTracker.peaks
        }
    }
}
