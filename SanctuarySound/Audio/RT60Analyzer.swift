// ============================================================================
// RT60Analyzer.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Audio Utility
// Purpose: Manages the RT60 measurement flow — noise floor sampling, clap
//          detection, decay recording, and RT60 calculation. Publishes phase
//          state for the UI wizard and stores measurement results.
// ============================================================================

import AVFoundation
import Combine


// MARK: - ─── Measurement Phase ───────────────────────────────────────────────

/// Phases of the RT60 measurement process.
enum RT60MeasurementPhase {
    /// Idle — ready to begin.
    case idle
    /// Sampling ambient noise floor (pre-clap silence).
    case measuringNoiseFloor
    /// Listening for the clap/impulse.
    case listeningForImpulse
    /// Impulse detected, recording decay.
    case recordingDecay
    /// Processing the recording.
    case processing
    /// Measurement complete — result available.
    case result(RT60Measurement)
    /// Measurement failed with reason.
    case failed(String)

    var isActive: Bool {
        switch self {
        case .idle, .result, .failed: return false
        default: return true
        }
    }
}


// MARK: - ─── RT60 Analyzer ───────────────────────────────────────────────────

/// Manages the RT60 measurement workflow using the iPhone microphone.
@MainActor
final class RT60Analyzer: ObservableObject {

    // ── Published State ──
    @Published private(set) var phase: RT60MeasurementPhase = .idle
    @Published private(set) var permissionGranted: Bool = false
    @Published private(set) var savedMeasurements: [RT60Measurement] = []

    // ── Internal ──
    private var audioEngine: AVAudioEngine?
    private var recordingBuffer: [Float] = []
    private var noiseFloorSamples: [Float] = []
    private var sampleRate: Double = 44100.0

    // ── Configuration ──
    /// Duration of noise floor sampling (seconds).
    private let noiseFloorDuration: TimeInterval = 1.5
    /// Maximum recording duration after impulse (seconds).
    private let maxDecayDuration: TimeInterval = 4.0
    /// Total max recording buffer (noise + wait + decay).
    private let maxBufferDuration: TimeInterval = 10.0

    // ── Timing ──
    private var recordingStartTime: Date?
    private var impulseDetectedTime: Date?
    private var noiseFloorDB: Double = -80.0


    // MARK: - ─── Public API ──────────────────────────────────────────────────

    /// Request microphone permission.
    func requestPermission() async {
        if #available(iOS 17, *) {
            let granted = await AVAudioApplication.requestRecordPermission()
            permissionGranted = granted
        }
    }

    /// Begin the RT60 measurement process.
    func startMeasurement() {
        guard permissionGranted else { return }
        guard !phase.isActive else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            sampleRate = format.sampleRate

            // Pre-allocate buffer
            let maxSamples = Int(maxBufferDuration * sampleRate)
            recordingBuffer = []
            recordingBuffer.reserveCapacity(maxSamples)
            noiseFloorSamples = []
            impulseDetectedTime = nil

            inputNode.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: format
            ) { [weak self] buffer, _ in
                self?.processBuffer(buffer)
            }

            try engine.start()
            self.audioEngine = engine
            recordingStartTime = Date()
            phase = .measuringNoiseFloor

        } catch {
            phase = .failed("Could not start audio engine")
        }
    }

    /// Cancel an in-progress measurement.
    func cancelMeasurement() {
        stopEngine()
        phase = .idle
    }

    /// Reset to idle state after viewing results.
    func reset() {
        phase = .idle
    }

    /// Delete a saved measurement.
    func deleteMeasurement(id: UUID) {
        savedMeasurements.removeAll { $0.id == id }
    }


    // MARK: - ─── Buffer Processing ───────────────────────────────────────────

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let frameCount = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))

        Task { @MainActor in
            self.handleSamples(samples)
        }
    }

    private func handleSamples(_ samples: [Float]) {
        guard let startTime = recordingStartTime else { return }
        let elapsed = Date().timeIntervalSince(startTime)

        switch phase {
        case .measuringNoiseFloor:
            noiseFloorSamples.append(contentsOf: samples)

            if elapsed >= noiseFloorDuration {
                // Calculate noise floor
                noiseFloorDB = RT60Calculator.noiseFloor(from: noiseFloorSamples)
                phase = .listeningForImpulse
                // Start recording from here for impulse + decay
                recordingBuffer = []
            }

        case .listeningForImpulse:
            recordingBuffer.append(contentsOf: samples)

            // Check for impulse in this chunk
            let thresholdLinear = Float(pow(10.0, (noiseFloorDB + 20.0) / 20.0))
            let hasImpulse = samples.contains { abs($0) > thresholdLinear }

            if hasImpulse {
                impulseDetectedTime = Date()
                phase = .recordingDecay
            }

            // Timeout if no impulse after 6 seconds of listening
            if elapsed > noiseFloorDuration + 6.0 {
                stopEngine()
                phase = .failed("No clap detected. Try clapping louder or moving closer to the phone.")
            }

        case .recordingDecay:
            recordingBuffer.append(contentsOf: samples)

            // Record for the configured decay duration after impulse
            if let impulseTime = impulseDetectedTime {
                let decayElapsed = Date().timeIntervalSince(impulseTime)
                if decayElapsed >= maxDecayDuration {
                    stopEngine()
                    processRecording()
                }
            }

        default:
            break
        }

        // Safety: prevent infinite recording
        if elapsed > maxBufferDuration {
            stopEngine()
            if phase.isActive {
                phase = .failed("Recording timed out.")
            }
        }
    }


    // MARK: - ─── Processing ──────────────────────────────────────────────────

    private func processRecording() {
        phase = .processing

        let preNoiseSampleCount = noiseFloorSamples.count

        // Build the full buffer: noise samples + recording buffer
        var fullRecording = noiseFloorSamples
        fullRecording.append(contentsOf: recordingBuffer)

        guard let measurement = RT60Calculator.measure(
            recording: fullRecording,
            preNoiseSamples: preNoiseSampleCount,
            sampleRate: sampleRate
        ) else {
            phase = .failed("Could not calculate RT60. The decay may have been too short or the room too noisy.")
            return
        }

        savedMeasurements.insert(measurement, at: 0)
        phase = .result(measurement)
    }


    // MARK: - ─── Engine Management ───────────────────────────────────────────

    private func stopEngine() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
