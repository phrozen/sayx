import Foundation
import Accelerate
import Testing
@testable import SayXCore

@Suite("AudioNormalizer Unit Tests")
struct AudioNormalizerTests {
    
    @Test("Peak normalizes quiet audio to target ceiling")
    func testPeakNormalizeQuiet() {
        var quietSamples: [Float] = [0.0, 0.05, 0.10, 0.05, 0.0, -0.05, -0.10, -0.05]
        let targetPeak: Float = 0.891
        AudioNormalizer.peakNormalize(&quietSamples, targetPeak: targetPeak)
        
        var maxMag: Float = 0
        vDSP_maxmgv(quietSamples, 1, &maxMag, vDSP_Length(quietSamples.count))
        #expect(abs(maxMag - targetPeak) < 1e-4)
    }
    
    @Test("Peak normalizes hot audio down to target ceiling")
    func testPeakNormalizeHot() {
        var hotSamples: [Float] = [0.0, 0.75, 1.50, 0.75, 0.0, -0.75, -1.50, -0.75]
        let targetPeak: Float = 0.891
        AudioNormalizer.peakNormalize(&hotSamples, targetPeak: targetPeak)
        
        var maxMag: Float = 0
        vDSP_maxmgv(hotSamples, 1, &maxMag, vDSP_Length(hotSamples.count))
        #expect(abs(maxMag - targetPeak) < 1e-4)
        #expect(maxMag <= 0.892)
    }
    
    @Test("Handles pure silence without crash, division by zero, or NaNs")
    func testPeakNormalizeSilence() {
        var silence: [Float] = [0.0, 0.0, 0.0, 0.0]
        AudioNormalizer.peakNormalize(&silence)
        #expect(silence.allSatisfy { !$0.isNaN && !$0.isInfinite && $0 == 0.0 })
    }
    
    @Test("RMS normalization respects peak limiter ceiling")
    func testRMSNormalizeWithCeiling() {
        var impulse: [Float] = [0.01, 0.01, 0.01, 0.90, 0.01, 0.01, -0.90, 0.01]
        let ceiling: Float = 0.94
        AudioNormalizer.rmsNormalize(&impulse, targetRMS: 0.20, peakCeiling: ceiling)
        
        var maxMag: Float = 0
        vDSP_maxmgv(impulse, 1, &maxMag, vDSP_Length(impulse.count))
        #expect(maxMag <= ceiling + 1e-4)
    }
    
    @Test("Resampling fast path returns identical array when sample rates match")
    func testResampleSameRate() throws {
        let original: [Float] = [0.1, 0.2, 0.3, 0.4, 0.5]
        let result = try AudioNormalizer.resample(samples: original, fromRate: 24000, toRate: 24000)
        #expect(result == original)
    }
    
    @Test("Resamples 24 kHz to 44.1 kHz with accurate frame ratio")
    func testResample24kTo44k() throws {
        let sampleCount = 2400
        var sine24k = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            sine24k[i] = sin(Float(i) * 2.0 * .pi * 440.0 / 24000.0) * 0.5
        }
        
        let upsampled = try AudioNormalizer.resample(samples: sine24k, fromRate: 24000, toRate: 44100)
        let ratio = Double(upsampled.count) / Double(sine24k.count)
        let expectedRatio = 44100.0 / 24000.0 // 1.8375
        
        #expect(upsampled.allSatisfy { !$0.isNaN && !$0.isInfinite })
        #expect(abs(ratio - expectedRatio) < 0.05)
    }
    
    @Test("Resamples 44.1 kHz to 24 kHz with accurate frame ratio")
    func testResample44kTo24k() throws {
        let sampleCount44k = 4410
        var sine44k = [Float](repeating: 0, count: sampleCount44k)
        for i in 0..<sampleCount44k {
            sine44k[i] = sin(Float(i) * 2.0 * .pi * 440.0 / 44100.0) * 0.5
        }
        
        let downsampled = try AudioNormalizer.resample(samples: sine44k, fromRate: 44100, toRate: 24000)
        let ratio = Double(downsampled.count) / Double(sine44k.count)
        let expectedRatio = 24000.0 / 44100.0 // 0.5442
        
        #expect(downsampled.allSatisfy { !$0.isNaN && !$0.isInfinite })
        #expect(abs(ratio - expectedRatio) < 0.05)
    }
}
