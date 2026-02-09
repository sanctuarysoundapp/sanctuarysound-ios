// ============================================================================
// RT60Calculator.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Pure Engine (Stateless)
// Purpose: DSP functions for RT60 reverberation time measurement. Implements
//          Schroeder backward integration and linear regression on the energy
//          decay curve to extract T60 from an impulse response recording.
// ============================================================================

import Accelerate
import Foundation


// MARK: - ─── RT60 Calculator ─────────────────────────────────────────────────

/// Pure stateless functions for computing RT60 from recorded audio.
enum RT60Calculator {

    /// Minimum SNR (dB) required for a reliable RT60 measurement.
    static let minimumReliableSNR: Double = 30.0

    /// Decay evaluation range: fit line from -5 dB to -35 dB on the EDC.
    /// This avoids the direct sound (0 to -5 dB) and the noise floor (below -35 dB).
    static let fitRangeUpperDB: Double = -5.0
    static let fitRangeLowerDB: Double = -35.0

    // MARK: - Noise Floor

    /// Estimate noise floor from a pre-impulse segment.
    /// - Parameter samples: Audio samples captured before the impulse.
    /// - Returns: Noise floor level in dB (relative to full scale).
    static func noiseFloor(from samples: [Float]) -> Double {
        guard !samples.isEmpty else { return -80.0 }

        var sumOfSquares: Float = 0
        vDSP_svesq(samples, 1, &sumOfSquares, vDSP_Length(samples.count))
        let rms = sqrt(sumOfSquares / Float(samples.count))

        guard rms > 0 else { return -80.0 }
        return 20.0 * log10(Double(rms))
    }

    // MARK: - Impulse Detection

    /// Find the index of the impulse (clap) in the recording.
    /// The impulse is detected as the first sample exceeding the threshold.
    /// - Parameters:
    ///   - samples: Full recording buffer.
    ///   - thresholdDB: Minimum amplitude above noise floor to count as impulse.
    ///   - noiseFloorDB: Pre-measured noise floor in dB.
    /// - Returns: Sample index of the impulse, or nil if not found.
    static func findImpulse(
        in samples: [Float],
        thresholdDB: Double = 20.0,
        noiseFloorDB: Double
    ) -> Int? {
        let thresholdLinear = Float(pow(10.0, (noiseFloorDB + thresholdDB) / 20.0))

        for (index, sample) in samples.enumerated() {
            if abs(sample) > thresholdLinear {
                return index
            }
        }

        return nil
    }

    // MARK: - Signal-to-Noise Ratio

    /// Calculate SNR from impulse peak and noise floor.
    /// - Parameters:
    ///   - peakDB: Peak level of the impulse in dB.
    ///   - noiseFloorDB: Noise floor level in dB.
    /// - Returns: SNR in dB.
    static func signalToNoiseRatio(peakDB: Double, noiseFloorDB: Double) -> Double {
        peakDB - noiseFloorDB
    }

    // MARK: - Schroeder Backward Integration

    /// Compute the Energy Decay Curve (EDC) using Schroeder backward integration.
    /// EDC(t) = ∫[t→∞] h²(τ) dτ
    /// - Parameter impulseResponse: Squared impulse response samples.
    /// - Returns: EDC in dB, normalized so EDC[0] = 0 dB.
    static func energyDecayCurve(from impulseResponse: [Float]) -> [Double] {
        let count = impulseResponse.count
        guard count > 0 else { return [] }

        // Square the impulse response
        var squared = [Float](repeating: 0, count: count)
        vDSP_vsq(impulseResponse, 1, &squared, 1, vDSP_Length(count))

        // Backward cumulative sum (Schroeder integration)
        var edc = [Double](repeating: 0, count: count)
        var runningSum: Double = 0

        for i in stride(from: count - 1, through: 0, by: -1) {
            runningSum += Double(squared[i])
            edc[i] = runningSum
        }

        // Normalize to 0 dB at start
        let maxEnergy = edc[0]
        guard maxEnergy > 0 else { return [Double](repeating: -80.0, count: count) }

        return edc.map { energy in
            guard energy > 0 else { return -80.0 }
            return 10.0 * log10(energy / maxEnergy)
        }
    }

    // MARK: - Linear Regression

    /// Perform linear regression on a set of (x, y) points.
    /// Returns (slope, intercept) where y = slope * x + intercept.
    /// - Parameters:
    ///   - x: Independent variable values.
    ///   - y: Dependent variable values.
    /// - Returns: (slope, intercept) tuple, or nil if regression fails.
    static func linearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double)? {
        let n = x.count
        guard n == y.count, n >= 2 else { return nil }

        let nd = Double(n)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).reduce(0) { $0 + $1.0 * $1.1 }
        let sumX2 = x.reduce(0) { $0 + $1 * $1 }

        let denominator = nd * sumX2 - sumX * sumX
        guard abs(denominator) > 1e-10 else { return nil }

        let slope = (nd * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / nd

        return (slope, intercept)
    }

    // MARK: - RT60 Extraction

    /// Extract RT60 from an energy decay curve.
    /// Fits a line to the -5 dB to -35 dB region and extrapolates to -60 dB.
    /// - Parameters:
    ///   - edcDB: Energy decay curve in dB (normalized, EDC[0] = 0 dB).
    ///   - sampleRate: Sample rate of the recording in Hz.
    /// - Returns: RT60 in seconds, or nil if measurement is invalid.
    static func extractRT60(from edcDB: [Double], sampleRate: Double) -> Double? {
        guard !edcDB.isEmpty, sampleRate > 0 else { return nil }

        // Collect points within the fitting range
        var xPoints: [Double] = [] // time in seconds
        var yPoints: [Double] = [] // dB

        for (index, db) in edcDB.enumerated() {
            if db <= fitRangeUpperDB && db >= fitRangeLowerDB {
                let timeSec = Double(index) / sampleRate
                xPoints.append(timeSec)
                yPoints.append(db)
            }
        }

        // Need sufficient data points for a reliable fit
        guard xPoints.count >= 10 else { return nil }

        guard let regression = linearRegression(x: xPoints, y: yPoints) else {
            return nil
        }

        // RT60 = time for 60 dB of decay
        // slope is in dB/second (negative for decay)
        guard regression.slope < -0.1 else { return nil } // Must be decaying

        let rt60 = -60.0 / regression.slope

        // Sanity check: RT60 should be between 0.1s and 10s for any real room
        guard rt60 >= 0.1, rt60 <= 10.0 else { return nil }

        return rt60
    }

    // MARK: - Room Classification

    /// Classify a room based on its measured RT60.
    /// - Parameter rt60: Measured reverberation time in seconds.
    /// - Returns: Human-readable room classification string.
    static func classify(rt60: Double) -> String {
        switch rt60 {
        case ..<0.5:
            return "Very Dry"
        case 0.5..<0.8:
            return "Dry"
        case 0.8..<1.2:
            return "Moderate"
        case 1.2..<1.8:
            return "Reverberant"
        default:
            return "Very Reverberant"
        }
    }

    /// Provide actionable advice based on RT60 measurement.
    /// - Parameter rt60: Measured reverberation time in seconds.
    /// - Returns: Short advice string for the volunteer.
    static func advice(for rt60: Double) -> String {
        switch rt60 {
        case ..<0.5:
            return "Your room is very controlled. Great for speech clarity. You can use longer reverb effects if desired."
        case 0.5..<0.8:
            return "Excellent for worship. Speech is clear and music has natural warmth without excessive buildup."
        case 0.8..<1.2:
            return "Good balance. Watch for low-mid buildup around 200-400 Hz. Consider subtle HPF on vocals."
        case 1.2..<1.8:
            return "Reverberant room. Use tighter EQ cuts in the low-mids. Keep effects reverb short to avoid wash."
        default:
            return "Very reverberant. Prioritize speech clarity. Use aggressive HPF, tight compression, and minimal effects."
        }
    }

    // MARK: - Complete Measurement

    /// Perform a complete RT60 measurement from a recorded audio buffer.
    /// - Parameters:
    ///   - recording: Full audio recording (pre-noise + impulse + decay).
    ///   - preNoiseSamples: Number of samples used for noise floor estimation.
    ///   - sampleRate: Audio sample rate in Hz.
    /// - Returns: RT60Measurement result, or nil if measurement failed.
    static func measure(
        recording: [Float],
        preNoiseSamples: Int,
        sampleRate: Double
    ) -> RT60Measurement? {
        guard recording.count > preNoiseSamples + 1000 else { return nil }

        // Step 1: Measure noise floor from pre-impulse segment
        let noiseSegment = Array(recording[0..<preNoiseSamples])
        let noiseDB = noiseFloor(from: noiseSegment)

        // Step 2: Find the impulse
        let postNoise = Array(recording[preNoiseSamples...])
        guard let impulseOffset = findImpulse(in: postNoise, noiseFloorDB: noiseDB) else {
            return nil
        }
        let impulseIndex = preNoiseSamples + impulseOffset

        // Step 3: Extract decay segment (from impulse to end)
        guard impulseIndex < recording.count - 100 else { return nil }
        let decaySegment = Array(recording[impulseIndex...])

        // Step 4: Find peak level
        var peakValue: Float = 0
        vDSP_maxmgv(decaySegment, 1, &peakValue, vDSP_Length(decaySegment.count))
        let peakDB = peakValue > 0 ? 20.0 * log10(Double(peakValue)) : -80.0

        // Step 5: Calculate SNR
        let snr = signalToNoiseRatio(peakDB: peakDB, noiseFloorDB: noiseDB)

        // Step 6: Compute EDC
        let edcDB = energyDecayCurve(from: decaySegment)

        // Step 7: Extract RT60
        guard let rt60 = extractRT60(from: edcDB, sampleRate: sampleRate) else {
            return nil
        }

        return RT60Measurement(
            rt60Seconds: rt60,
            noiseFloorDB: noiseDB,
            snrDB: snr,
            isReliable: snr >= minimumReliableSNR,
            roomClassification: classify(rt60: rt60)
        )
    }
}


// MARK: - ─── RT60 Measurement Model ──────────────────────────────────────────

/// Result of an RT60 measurement session.
struct RT60Measurement: Codable, Identifiable {
    let id: UUID
    let date: Date
    let rt60Seconds: Double
    let noiseFloorDB: Double
    let snrDB: Double
    let isReliable: Bool
    let roomClassification: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        rt60Seconds: Double,
        noiseFloorDB: Double,
        snrDB: Double,
        isReliable: Bool,
        roomClassification: String
    ) {
        self.id = id
        self.date = date
        self.rt60Seconds = rt60Seconds
        self.noiseFloorDB = noiseFloorDB
        self.snrDB = snrDB
        self.isReliable = isReliable
        self.roomClassification = roomClassification
    }
}
