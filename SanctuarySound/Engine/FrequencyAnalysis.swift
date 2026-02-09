// ============================================================================
// FrequencyAnalysis.swift
// SanctuarySound — Virtual Audio Director for House of Worship
// ============================================================================
// Architecture: Pure Engine (Stateless)
// Purpose: DSP utility functions for frequency-domain analysis. Provides
//          ISO 1/3-octave band mapping, FFT helpers, Hann windowing, and
//          magnitude-to-dB conversion. Used by EQAnalyzer and RT60Analyzer.
// ============================================================================

import Accelerate
import Foundation


// MARK: - ─── ISO 1/3-Octave Band Definitions ────────────────────────────────

/// Standard ISO 1/3-octave center frequencies (31 bands, 20 Hz – 20 kHz).
/// Used for RTA (Real-Time Analyzer) display.
enum FrequencyBands {

    /// 31 ISO 1/3-octave center frequencies in Hz.
    static let centers: [Double] = [
        20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160,
        200, 250, 315, 400, 500, 630, 800, 1000, 1250, 1600,
        2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000,
        20000
    ]

    /// Short display labels for axis rendering (shows subset for readability).
    static let displayLabels: [String] = [
        "20", "25", "31", "40", "50", "63", "80", "100", "125", "160",
        "200", "250", "315", "400", "500", "630", "800", "1k", "1.25k", "1.6k",
        "2k", "2.5k", "3.15k", "4k", "5k", "6.3k", "8k", "10k", "12.5k", "16k",
        "20k"
    ]

    /// Major tick labels (shown on axis; others hidden to prevent clutter).
    static let majorTickIndices: Set<Int> = [
        0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 23, 26, 29, 30
    ]

    /// Number of bands.
    static let count: Int = 31

    /// Lower edge of a 1/3-octave band: center / 2^(1/6).
    static func lowerEdge(for centerFrequency: Double) -> Double {
        centerFrequency / pow(2.0, 1.0 / 6.0)
    }

    /// Upper edge of a 1/3-octave band: center * 2^(1/6).
    static func upperEdge(for centerFrequency: Double) -> Double {
        centerFrequency * pow(2.0, 1.0 / 6.0)
    }
}


// MARK: - ─── FFT Processor ───────────────────────────────────────────────────

/// Stateless FFT processor using Accelerate/vDSP.
/// Converts a time-domain audio buffer into 1/3-octave band magnitudes.
struct FFTProcessor {

    /// Recommended buffer size for RTA analysis.
    /// 4096 samples at 44.1 kHz → ~10.77 Hz resolution, ~93 ms latency.
    static let recommendedBufferSize: Int = 4096

    /// Minimum valid magnitude in dB (noise floor).
    static let noiseFloorDB: Double = -80.0

    // MARK: - Hann Window

    /// Generate a Hann window of the given length.
    /// - Parameter length: Number of samples.
    /// - Returns: Array of window coefficients.
    static func hannWindow(length: Int) -> [Float] {
        var window = [Float](repeating: 0, count: length)
        vDSP_hann_window(&window, vDSP_Length(length), Int32(vDSP_HANN_NORM))
        return window
    }

    /// Apply a window function to a signal buffer (element-wise multiply).
    /// - Parameters:
    ///   - signal: Input samples (modified in place).
    ///   - window: Window coefficients (same length as signal).
    static func applyWindow(signal: inout [Float], window: [Float]) {
        precondition(signal.count == window.count, "Signal and window must have equal length")
        vDSP_vmul(signal, 1, window, 1, &signal, 1, vDSP_Length(signal.count))
    }

    // MARK: - FFT

    /// Compute magnitude spectrum from a real-valued time-domain signal.
    /// - Parameters:
    ///   - samples: Input audio samples (must be power-of-2 length).
    ///   - applyHannWindow: Whether to apply Hann windowing before FFT.
    /// - Returns: Array of magnitudes (length = samples.count / 2), in linear scale.
    static func magnitudeSpectrum(from samples: [Float], applyHannWindow: Bool = true) -> [Float] {
        let n = samples.count
        guard n > 0, n & (n - 1) == 0 else { return [] } // Must be power of 2

        let log2n = vDSP_Length(log2(Double(n)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return []
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        // Apply window if requested
        var windowed = samples
        if applyHannWindow {
            let window = hannWindow(length: n)
            applyWindow(signal: &windowed, window: window)
        }

        // Pack into split complex format
        let halfN = n / 2
        var realPart = [Float](repeating: 0, count: halfN)
        var imagPart = [Float](repeating: 0, count: halfN)

        // Convert real input to split complex (even/odd interleave)
        windowed.withUnsafeBufferPointer { ptr in
            ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: halfN) { complexPtr in
                realPart.withUnsafeMutableBufferPointer { realBuf in
                    imagPart.withUnsafeMutableBufferPointer { imagBuf in
                        var split = DSPSplitComplex(realp: realBuf.baseAddress!, imagp: imagBuf.baseAddress!)
                        vDSP_ctoz(complexPtr, 2, &split, 1, vDSP_Length(halfN))
                    }
                }
            }
        }

        // Perform FFT
        var magnitudes = [Float](repeating: 0, count: halfN)
        realPart.withUnsafeMutableBufferPointer { realBuf in
            imagPart.withUnsafeMutableBufferPointer { imagBuf in
                var split = DSPSplitComplex(realp: realBuf.baseAddress!, imagp: imagBuf.baseAddress!)
                vDSP_fft_zrip(fftSetup, &split, 1, log2n, FFTDirection(FFT_FORWARD))

                // Scale (vDSP FFT result is scaled by 2)
                var scale: Float = 1.0 / Float(2 * n)
                vDSP_vsmul(realBuf.baseAddress!, 1, &scale, realBuf.baseAddress!, 1, vDSP_Length(halfN))
                vDSP_vsmul(imagBuf.baseAddress!, 1, &scale, imagBuf.baseAddress!, 1, vDSP_Length(halfN))

                // Compute magnitudes: sqrt(real² + imag²)
                vDSP_zvabs(&split, 1, &magnitudes, 1, vDSP_Length(halfN))
            }
        }

        return magnitudes
    }

    /// Convert a linear magnitude spectrum to dB scale.
    /// - Parameter magnitudes: Linear magnitude values.
    /// - Returns: Array of dB values (clamped to noiseFloorDB minimum).
    static func magnitudesToDB(_ magnitudes: [Float]) -> [Double] {
        magnitudes.map { mag in
            if mag <= 0 { return noiseFloorDB }
            let db = 20.0 * log10(Double(mag))
            return max(db, noiseFloorDB)
        }
    }

    // MARK: - Band Mapping

    /// Map FFT magnitude bins into 1/3-octave bands.
    /// - Parameters:
    ///   - magnitudes: Linear FFT magnitude spectrum.
    ///   - sampleRate: Audio sample rate in Hz.
    /// - Returns: Array of 31 dB values, one per 1/3-octave band.
    static func mapToBands(magnitudes: [Float], sampleRate: Double) -> [Double] {
        let binCount = magnitudes.count
        let frequencyResolution = sampleRate / Double(binCount * 2) // Hz per bin

        var bandLevels = [Double](repeating: FFTProcessor.noiseFloorDB, count: FrequencyBands.count)

        for (bandIndex, center) in FrequencyBands.centers.enumerated() {
            let lowerFreq = FrequencyBands.lowerEdge(for: center)
            let upperFreq = FrequencyBands.upperEdge(for: center)

            let lowerBin = max(1, Int(floor(lowerFreq / frequencyResolution)))
            let upperBin = min(binCount - 1, Int(ceil(upperFreq / frequencyResolution)))

            guard lowerBin <= upperBin else {
                bandLevels[bandIndex] = noiseFloorDB
                continue
            }

            // RMS of magnitudes within band
            var sumOfSquares: Double = 0
            var count = 0
            for bin in lowerBin...upperBin {
                let mag = Double(magnitudes[bin])
                sumOfSquares += mag * mag
                count += 1
            }

            if count > 0 {
                let rms = sqrt(sumOfSquares / Double(count))
                if rms > 0 {
                    bandLevels[bandIndex] = max(20.0 * log10(rms), noiseFloorDB)
                }
            }
        }

        return bandLevels
    }
}


// MARK: - ─── Peak Hold ───────────────────────────────────────────────────────

/// Tracks peak-hold values with configurable decay.
struct PeakHoldTracker {

    /// Current peak-hold values per band (in dB).
    private(set) var peaks: [Double]

    /// Decay rate in dB per update cycle.
    let decayRateDB: Double

    /// Initialize with the number of bands and decay rate.
    /// - Parameters:
    ///   - bandCount: Number of frequency bands.
    ///   - decayRateDB: How many dB peaks decay per update (positive value).
    init(bandCount: Int = FrequencyBands.count, decayRateDB: Double = 0.5) {
        self.peaks = [Double](repeating: FFTProcessor.noiseFloorDB, count: bandCount)
        self.decayRateDB = decayRateDB
    }

    /// Update peaks with new band levels. Peaks rise instantly, decay gradually.
    /// - Parameter levels: Current band levels in dB.
    /// - Returns: New PeakHoldTracker with updated peaks.
    func updated(with levels: [Double]) -> PeakHoldTracker {
        precondition(levels.count == peaks.count, "Level count must match band count")

        let newPeaks = zip(peaks, levels).map { (currentPeak, currentLevel) -> Double in
            if currentLevel >= currentPeak {
                return currentLevel // New peak
            } else {
                return max(currentPeak - decayRateDB, currentLevel) // Decay toward current
            }
        }

        var updated = self
        updated.peaks = newPeaks
        return updated
    }

    /// Reset all peaks to noise floor.
    /// - Returns: New PeakHoldTracker with reset peaks.
    func reset() -> PeakHoldTracker {
        var updated = self
        updated.peaks = [Double](repeating: FFTProcessor.noiseFloorDB, count: peaks.count)
        return updated
    }
}


// MARK: - ─── EQ Snapshot ─────────────────────────────────────────────────────

/// A frozen capture of the frequency spectrum at a point in time.
struct EQSnapshot: Codable, Identifiable {
    let id: UUID
    let date: Date
    let bandLevels: [Double]   // 31 dB values
    let peakLevels: [Double]   // 31 peak-hold dB values
    let name: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        bandLevels: [Double],
        peakLevels: [Double],
        name: String = ""
    ) {
        self.id = id
        self.date = date
        self.bandLevels = bandLevels
        self.peakLevels = peakLevels
        self.name = name
    }
}
