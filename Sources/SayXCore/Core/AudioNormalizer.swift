import Foundation
import Accelerate
import AVFoundation

/// High-performance, vectorized audio normalization using Apple's Accelerate framework (`vDSP`).
///
/// Ensures consistent broadcast loudness across all voices and engines:
/// - In-memory SIMD peak and RMS normalization executed in microseconds.
/// - File-based reference audio normalization for voice cloning.
/// - Headroom protection against digital-to-analog converter (DAC) clipping.
public enum AudioNormalizer {
    
    /// Target peak linear amplitude corresponding to -1.0 dBFS (leaving headroom against DAC inter-sample clipping).
    public static let defaultTargetPeak: Float = 0.891250938 // 10^(-1.0 / 20)
    
    /// Target RMS linear amplitude for natural broadcast speech (~ -18.0 dBFS).
    public static let defaultTargetRMS: Float = 0.125892541 // 10^(-18.0 / 20)
    
    /// Maximum allowed peak ceiling during RMS normalization to prevent digital clipping (-0.5 dBFS).
    public static let defaultPeakCeiling: Float = 0.944060876 // 10^(-0.5 / 20)
    
    /// Peak normalizes an in-memory array of Float32 audio samples in place.
    ///
    /// Runs via Apple Silicon Accelerate NEON SIMD in microseconds with zero memory allocations.
    /// - Parameters:
    ///   - samples: Float32 audio samples to normalize.
    ///   - targetPeak: Linear peak amplitude to scale to (default: -1.0 dBFS = 0.891).
    public static func peakNormalize(_ samples: inout [Float], targetPeak: Float = defaultTargetPeak) {
        guard !samples.isEmpty else { return }
        
        var maxMag: Float = 0
        vDSP_maxmgv(samples, 1, &maxMag, vDSP_Length(samples.count))
        
        // Avoid division by zero or amplifying pure silence / baseline noise floor
        guard maxMag > 1e-4 else { return }
        
        var gain = targetPeak / maxMag
        vDSP_vsmul(samples, 1, &gain, &samples, 1, vDSP_Length(samples.count))
    }
    
    /// RMS loudness normalizes an in-memory array of Float32 audio samples with a peak limiter.
    ///
    /// - Parameters:
    ///   - samples: Float32 audio samples to normalize.
    ///   - targetRMS: Desired average RMS energy level (default: -18 dBFS).
    ///   - peakCeiling: Maximum allowed peak amplitude (default: -0.5 dBFS).
    public static func rmsNormalize(
        _ samples: inout [Float],
        targetRMS: Float = defaultTargetRMS,
        peakCeiling: Float = defaultPeakCeiling
    ) {
        guard !samples.isEmpty else { return }
        
        var currentRMS: Float = 0
        vDSP_rmsqv(samples, 1, &currentRMS, vDSP_Length(samples.count))
        guard currentRMS > 1e-4 else { return }
        
        var maxMag: Float = 0
        vDSP_maxmgv(samples, 1, &maxMag, vDSP_Length(samples.count))
        
        // Calculate desired gain based on target RMS
        var gain = targetRMS / currentRMS
        
        // Safeguard: Ensure gain doesn't cause any sample to exceed peakCeiling
        if maxMag * gain > peakCeiling {
            gain = peakCeiling / maxMag
        }
        
        vDSP_vsmul(samples, 1, &gain, &samples, 1, vDSP_Length(samples.count))
    }
    
    /// Resamples an in-memory array of Float32 audio samples from `fromRate` to `toRate`.
    ///
    /// Fast-path returns the original array directly if sample rates match.
    /// Otherwise converts via CoreAudio's `AVAudioConverter` in microseconds.
    public static func resample(
        samples: [Float],
        fromRate: Double,
        toRate: Double
    ) throws -> [Float] {
        guard !samples.isEmpty else { return [] }
        if abs(fromRate - toRate) < 1.0 {
            return samples
        }
        
        guard let sourceFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: fromRate,
            channels: 1,
            interleaved: false
        ),
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: toRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(
                domain: "AudioNormalizer",
                code: 10,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create CoreAudio formats for resampling (\(fromRate) -> \(toRate))"]
            )
        }
        
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw NSError(
                domain: "AudioNormalizer",
                code: 11,
                userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AVAudioConverter for \(fromRate) -> \(toRate)"]
            )
        }
        
        let frameCount = AVAudioFrameCount(samples.count)
        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioNormalizer", code: 12, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate source buffer"])
        }
        sourceBuffer.frameLength = frameCount
        if let channelData = sourceBuffer.floatChannelData {
            samples.withUnsafeBufferPointer { ptr in
                if let base = ptr.baseAddress {
                    memcpy(channelData[0], base, samples.count * MemoryLayout<Float>.stride)
                }
            }
        }
        
        let ratio = toRate / fromRate
        let destCapacity = AVAudioFrameCount(Double(frameCount) * ratio + 1024)
        guard let destBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: destCapacity) else {
            throw NSError(domain: "AudioNormalizer", code: 13, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate destination buffer"])
        }
        
        var error: NSError?
        var allRead = false
        converter.convert(to: destBuffer, error: &error) { _, outStatus in
            if allRead {
                outStatus.pointee = .noDataNow
                return nil
            }
            allRead = true
            outStatus.pointee = .haveData
            return sourceBuffer
        }
        if let err = error { throw err }
        
        guard let channelData = destBuffer.floatChannelData else {
            throw NSError(domain: "AudioNormalizer", code: 14, userInfo: [NSLocalizedDescriptionKey: "Invalid converted channel data"])
        }
        
        return Array(UnsafeBufferPointer(start: channelData[0], count: Int(destBuffer.frameLength)))
    }
    
    /// Reads an audio file (WAV, MP3, M4A, etc.), converts to 24kHz mono Float32,
    /// peak-normalizes it to -1.0 dBFS, and writes a normalized WAV file to destination.
    public static func normalizeAudioFile(at sourceURL: URL, to destinationURL: URL) throws {
        let sourceFile = try AVAudioFile(forReading: sourceURL)
        let sourceFormat = sourceFile.processingFormat
        let frameCount = AVAudioFrameCount(sourceFile.length)
        
        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioNormalizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate audio buffer"])
        }
        try sourceFile.read(into: sourceBuffer)
        
        // Target format: 24kHz mono Float32
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 1, interleaved: false) else {
            throw NSError(domain: "AudioNormalizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create target audio format"])
        }
        
        let normalizedSamples: [Float]
        if sourceFormat == targetFormat {
            guard let channelData = sourceBuffer.floatChannelData else {
                throw NSError(domain: "AudioNormalizer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid channel data"])
            }
            var samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(sourceBuffer.frameLength)))
            peakNormalize(&samples)
            normalizedSamples = samples
        } else {
            guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
                throw NSError(domain: "AudioNormalizer", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AVAudioConverter"])
            }
            let ratio = 24000.0 / sourceFormat.sampleRate
            let destCapacity = AVAudioFrameCount(Double(frameCount) * ratio + 1024)
            guard let destBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: destCapacity) else {
                throw NSError(domain: "AudioNormalizer", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate resampled buffer"])
            }
            
            var error: NSError?
            var allRead = false
            converter.convert(to: destBuffer, error: &error) { _, outStatus in
                if allRead {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                allRead = true
                outStatus.pointee = .haveData
                return sourceBuffer
            }
            if let err = error { throw err }
            
            guard let channelData = destBuffer.floatChannelData else {
                throw NSError(domain: "AudioNormalizer", code: 6, userInfo: [NSLocalizedDescriptionKey: "Invalid converted channel data"])
            }
            var samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(destBuffer.frameLength)))
            peakNormalize(&samples)
            normalizedSamples = samples
        }
        
        // Write to destination WAV file
        _ = try WavWriter.write(samples: normalizedSamples, sampleRate: 24000, toPath: destinationURL.path)
    }
}
