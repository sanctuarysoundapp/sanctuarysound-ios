// ============================================================================
// FrequencyAnalysisTests.swift
// SanctuarySound Tests
// ============================================================================
// Purpose: Unit tests for FrequencyAnalysis.swift and RT60Calculator.swift
//          DSP functions. Tests are pure — no audio hardware required.
// ============================================================================

import XCTest
@testable import SanctuarySound


// MARK: - ─── Frequency Band Tests ────────────────────────────────────────────

final class FrequencyBandTests: XCTestCase {

    func testBandCountIs31() {
        XCTAssertEqual(FrequencyBands.count, 31)
        XCTAssertEqual(FrequencyBands.centers.count, 31)
        XCTAssertEqual(FrequencyBands.displayLabels.count, 31)
    }

    func testBandCentersAreAscending() {
        for i in 1..<FrequencyBands.centers.count {
            XCTAssertGreaterThan(
                FrequencyBands.centers[i],
                FrequencyBands.centers[i - 1],
                "Band centers must be ascending at index \(i)"
            )
        }
    }

    func testBandRangeCovers20HzTo20kHz() {
        XCTAssertEqual(FrequencyBands.centers.first, 20.0)
        XCTAssertEqual(FrequencyBands.centers.last, 20000.0)
    }

    func testBandEdgesSymmetric() {
        let center = 1000.0
        let lower = FrequencyBands.lowerEdge(for: center)
        let upper = FrequencyBands.upperEdge(for: center)

        // 1/3-octave band: upper/lower ratio = 2^(1/3) ≈ 1.2599
        let ratio = upper / lower
        XCTAssertEqual(ratio, pow(2.0, 1.0 / 3.0), accuracy: 0.001)

        // Center should be geometric mean of edges
        let geometricMean = sqrt(lower * upper)
        XCTAssertEqual(geometricMean, center, accuracy: 0.01)
    }

    func testBandsDoNotOverlapExcessively() {
        for i in 0..<FrequencyBands.centers.count - 1 {
            let upperEdgeOfCurrent = FrequencyBands.upperEdge(for: FrequencyBands.centers[i])
            let lowerEdgeOfNext = FrequencyBands.lowerEdge(for: FrequencyBands.centers[i + 1])
            // Adjacent bands should be close but not have a large gap
            XCTAssertLessThan(
                abs(upperEdgeOfCurrent - lowerEdgeOfNext) / lowerEdgeOfNext,
                0.15,
                "Band gap too large between index \(i) and \(i + 1)"
            )
        }
    }
}


// MARK: - ─── FFT Processor Tests ─────────────────────────────────────────────

final class FFTProcessorTests: XCTestCase {

    func testHannWindowLength() {
        let window = FFTProcessor.hannWindow(length: 4096)
        XCTAssertEqual(window.count, 4096)
    }

    func testHannWindowEdgesNearZero() {
        let window = FFTProcessor.hannWindow(length: 1024)
        // Hann window starts and ends near zero
        XCTAssertLessThan(abs(window[0]), 0.01)
        XCTAssertLessThan(abs(window[1023]), 0.01)
    }

    func testHannWindowPeakInMiddle() {
        let window = FFTProcessor.hannWindow(length: 1024)
        // Peak should be near center (vDSP_HANN_NORM may scale for energy preservation)
        let maxVal = window.max()!
        XCTAssertGreaterThan(maxVal, 0.9, "Hann window peak should be significant")
        let maxIndex = window.firstIndex(of: maxVal)!
        // Peak should be near the center of the window
        XCTAssertTrue(abs(maxIndex - 512) <= 2, "Peak should be near center, got index \(maxIndex)")
    }

    func testApplyWindowMultiplies() {
        var signal: [Float] = [1.0, 1.0, 1.0, 1.0]
        let window: [Float] = [0.5, 1.0, 1.0, 0.5]
        FFTProcessor.applyWindow(signal: &signal, window: window)
        XCTAssertEqual(signal[0], 0.5, accuracy: 0.001)
        XCTAssertEqual(signal[1], 1.0, accuracy: 0.001)
        XCTAssertEqual(signal[3], 0.5, accuracy: 0.001)
    }

    func testMagnitudeSpectrumRequiresPowerOfTwo() {
        // Non-power-of-2 should return empty
        let result = FFTProcessor.magnitudeSpectrum(from: [Float](repeating: 0, count: 100))
        XCTAssertTrue(result.isEmpty)
    }

    func testMagnitudeSpectrumSilenceReturnsLowValues() {
        let silence = [Float](repeating: 0, count: 4096)
        let magnitudes = FFTProcessor.magnitudeSpectrum(from: silence)
        XCTAssertEqual(magnitudes.count, 2048) // N/2 bins

        // All magnitudes should be zero or very small
        for mag in magnitudes {
            XCTAssertLessThan(mag, 0.001)
        }
    }

    func testMagnitudeSpectrumSineWavePeaksAtCorrectBin() {
        // Generate 440 Hz sine wave at 44100 sample rate
        let sampleRate: Double = 44100
        let frequency: Double = 440.0
        let n = 4096
        var samples = [Float](repeating: 0, count: n)

        for i in 0..<n {
            samples[i] = Float(sin(2.0 * Double.pi * frequency * Double(i) / sampleRate))
        }

        let magnitudes = FFTProcessor.magnitudeSpectrum(from: samples, applyHannWindow: false)

        // Expected bin for 440 Hz: 440 / (44100/4096) ≈ 40.87 → bin 41
        let expectedBin = Int(round(frequency / (sampleRate / Double(n))))

        // Find the peak bin
        var peakBin = 0
        var peakValue: Float = 0
        for (i, mag) in magnitudes.enumerated() {
            if mag > peakValue {
                peakValue = mag
                peakBin = i
            }
        }

        XCTAssertEqual(peakBin, expectedBin, accuracy: 1,
                       "440 Hz peak should be near bin \(expectedBin), found at \(peakBin)")
    }

    func testMagnitudesToDB() {
        let magnitudes: [Float] = [1.0, 0.1, 0.01, 0.001, 0]
        let dbValues = FFTProcessor.magnitudesToDB(magnitudes)

        XCTAssertEqual(dbValues[0], 0.0, accuracy: 0.1)     // 1.0 → 0 dB
        XCTAssertEqual(dbValues[1], -20.0, accuracy: 0.1)    // 0.1 → -20 dB
        XCTAssertEqual(dbValues[2], -40.0, accuracy: 0.1)    // 0.01 → -40 dB
        XCTAssertEqual(dbValues[3], -60.0, accuracy: 0.1)    // 0.001 → -60 dB
        XCTAssertEqual(dbValues[4], FFTProcessor.noiseFloorDB) // 0 → noise floor
    }

    func testMapToBandsProduces31Values() {
        let magnitudes = [Float](repeating: 0.001, count: 2048)
        let bands = FFTProcessor.mapToBands(magnitudes: magnitudes, sampleRate: 44100)
        XCTAssertEqual(bands.count, 31)
    }

    func testMapToBandsSineWaveAppearsInCorrectBand() {
        // Generate 1000 Hz sine wave
        let sampleRate: Double = 44100
        let frequency: Double = 1000.0
        let n = 4096
        var samples = [Float](repeating: 0, count: n)

        for i in 0..<n {
            samples[i] = Float(sin(2.0 * Double.pi * frequency * Double(i) / sampleRate))
        }

        let magnitudes = FFTProcessor.magnitudeSpectrum(from: samples, applyHannWindow: false)
        let bands = FFTProcessor.mapToBands(magnitudes: magnitudes, sampleRate: sampleRate)

        // 1000 Hz is band index 17 (center = 1000 Hz)
        let band1kIndex = FrequencyBands.centers.firstIndex(of: 1000.0)!

        // The 1kHz band should have the highest level
        let maxBandIndex = bands.enumerated().max(by: { $0.element < $1.element })!.offset
        XCTAssertEqual(maxBandIndex, band1kIndex,
                       "1 kHz signal should peak in the 1 kHz band (index \(band1kIndex)), got \(maxBandIndex)")
    }
}


// MARK: - ─── Peak Hold Tracker Tests ─────────────────────────────────────────

final class PeakHoldTrackerTests: XCTestCase {

    func testInitialPeaksAtNoiseFloor() {
        let tracker = PeakHoldTracker()
        XCTAssertEqual(tracker.peaks.count, 31)
        for peak in tracker.peaks {
            XCTAssertEqual(peak, FFTProcessor.noiseFloorDB)
        }
    }

    func testPeakRisesInstantly() {
        let tracker = PeakHoldTracker(bandCount: 3)
        let levels = [-30.0, -20.0, -10.0]
        let updated = tracker.updated(with: levels)
        XCTAssertEqual(updated.peaks, levels)
    }

    func testPeakDecaysGradually() {
        let tracker = PeakHoldTracker(bandCount: 1, decayRateDB: 1.0)
        let high = tracker.updated(with: [-10.0])
        let decayed = high.updated(with: [-80.0]) // Drop to noise floor

        // Should have decayed by 1 dB, not jumped to -80
        XCTAssertEqual(decayed.peaks[0], -11.0, accuracy: 0.01)
    }

    func testPeakDoesNotDecayBelowCurrentLevel() {
        let tracker = PeakHoldTracker(bandCount: 1, decayRateDB: 10.0)
        let high = tracker.updated(with: [-20.0])
        let decayed = high.updated(with: [-25.0])

        // Decay would go to -30, but current level is -25, so stops at -25
        XCTAssertEqual(decayed.peaks[0], -25.0, accuracy: 0.01)
    }

    func testResetClearsPeaks() {
        let tracker = PeakHoldTracker(bandCount: 3)
        let updated = tracker.updated(with: [-10.0, -20.0, -30.0])
        let reset = updated.reset()
        for peak in reset.peaks {
            XCTAssertEqual(peak, FFTProcessor.noiseFloorDB)
        }
    }
}


// MARK: - ─── RT60 Calculator Tests ───────────────────────────────────────────

final class RT60CalculatorTests: XCTestCase {

    func testNoiseFloorOfSilence() {
        let silence = [Float](repeating: 0, count: 1000)
        let nf = RT60Calculator.noiseFloor(from: silence)
        XCTAssertEqual(nf, -80.0)
    }

    func testNoiseFloorOfKnownSignal() {
        // RMS of 0.1 → 20*log10(0.1) = -20 dB
        let samples = [Float](repeating: 0.1, count: 1000)
        let nf = RT60Calculator.noiseFloor(from: samples)
        XCTAssertEqual(nf, -20.0, accuracy: 1.0)
    }

    func testFindImpulseDetectsLoudPeak() {
        var samples = [Float](repeating: 0.001, count: 1000)
        samples[500] = 0.8 // Impulse at sample 500
        let index = RT60Calculator.findImpulse(in: samples, noiseFloorDB: -60.0)
        XCTAssertNotNil(index)
        XCTAssertEqual(index!, 500)
    }

    func testFindImpulseReturnsNilForQuietSignal() {
        let quiet = [Float](repeating: 0.001, count: 1000)
        let index = RT60Calculator.findImpulse(in: quiet, noiseFloorDB: -40.0)
        XCTAssertNil(index)
    }

    func testSNRCalculation() {
        let snr = RT60Calculator.signalToNoiseRatio(peakDB: -10.0, noiseFloorDB: -50.0)
        XCTAssertEqual(snr, 40.0)
    }

    func testLinearRegressionOnPerfectLine() {
        // y = -2x + 0
        let x = [0.0, 1.0, 2.0, 3.0, 4.0]
        let y = [0.0, -2.0, -4.0, -6.0, -8.0]
        let result = RT60Calculator.linearRegression(x: x, y: y)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.slope, -2.0, accuracy: 0.001)
        XCTAssertEqual(result!.intercept, 0.0, accuracy: 0.001)
    }

    func testLinearRegressionNeedsMinimumPoints() {
        let result = RT60Calculator.linearRegression(x: [1.0], y: [2.0])
        XCTAssertNil(result)
    }

    func testEDCOfExponentialDecay() {
        // Create a simple exponential decay impulse response
        let sampleRate: Double = 44100
        let n = 44100 // 1 second
        var impulse = [Float](repeating: 0, count: n)
        for i in 0..<n {
            // Decay with time constant such that RT60 ≈ 1.0s
            let t = Double(i) / sampleRate
            impulse[i] = Float(exp(-6.908 * t)) // ln(1000)/T60 = 6.908 for T60=1s
        }

        let edc = RT60Calculator.energyDecayCurve(from: impulse)
        XCTAssertEqual(edc.count, n)

        // EDC should start at 0 dB
        XCTAssertEqual(edc[0], 0.0, accuracy: 0.1)

        // EDC should decay
        XCTAssertLessThan(edc[n / 2], edc[0])
    }

    func testExtractRT60FromKnownDecay() {
        // Generate a decay with known RT60 of ~1.0 second
        let sampleRate: Double = 44100
        let seconds: Double = 3.0
        let n = Int(sampleRate * seconds)
        var impulse = [Float](repeating: 0, count: n)

        let targetRT60: Double = 1.0
        let decayRate = 6.908 / targetRT60 // ln(1000) / RT60

        for i in 0..<n {
            let t = Double(i) / sampleRate
            impulse[i] = Float(exp(-decayRate * t))
        }

        let edc = RT60Calculator.energyDecayCurve(from: impulse)
        let measuredRT60 = RT60Calculator.extractRT60(from: edc, sampleRate: sampleRate)

        XCTAssertNotNil(measuredRT60)
        XCTAssertEqual(measuredRT60!, targetRT60, accuracy: 0.15,
                       "Measured RT60 should be close to \(targetRT60)s")
    }

    func testClassification() {
        XCTAssertEqual(RT60Calculator.classify(rt60: 0.3), "Very Dry")
        XCTAssertEqual(RT60Calculator.classify(rt60: 0.6), "Dry")
        XCTAssertEqual(RT60Calculator.classify(rt60: 1.0), "Moderate")
        XCTAssertEqual(RT60Calculator.classify(rt60: 1.5), "Reverberant")
        XCTAssertEqual(RT60Calculator.classify(rt60: 2.5), "Very Reverberant")
    }

    func testAdviceReturnsNonEmpty() {
        for rt60 in [0.3, 0.6, 1.0, 1.5, 2.5] {
            let advice = RT60Calculator.advice(for: rt60)
            XCTAssertFalse(advice.isEmpty, "Advice for RT60=\(rt60) should not be empty")
        }
    }
}


// MARK: - ─── EQ Snapshot Tests ───────────────────────────────────────────────

final class EQSnapshotTests: XCTestCase {

    func testSnapshotCodable() throws {
        let snapshot = EQSnapshot(
            bandLevels: Array(repeating: -30.0, count: 31),
            peakLevels: Array(repeating: -25.0, count: 31),
            name: "Test Capture"
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(EQSnapshot.self, from: data)

        XCTAssertEqual(decoded.id, snapshot.id)
        XCTAssertEqual(decoded.name, "Test Capture")
        XCTAssertEqual(decoded.bandLevels.count, 31)
        XCTAssertEqual(decoded.peakLevels.count, 31)
    }
}


// MARK: - ─── RT60 Measurement Model Tests ────────────────────────────────────

final class RT60MeasurementTests: XCTestCase {

    func testMeasurementCodable() throws {
        let measurement = RT60Measurement(
            rt60Seconds: 1.4,
            noiseFloorDB: -50.0,
            snrDB: 40.0,
            isReliable: true,
            roomClassification: "Reverberant"
        )

        let data = try JSONEncoder().encode(measurement)
        let decoded = try JSONDecoder().decode(RT60Measurement.self, from: data)

        XCTAssertEqual(decoded.id, measurement.id)
        XCTAssertEqual(decoded.rt60Seconds, 1.4)
        XCTAssertEqual(decoded.roomClassification, "Reverberant")
        XCTAssertTrue(decoded.isReliable)
    }
}
