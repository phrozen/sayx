import Foundation
import FluidAudio

/// Helper utility for encoding 32-bit Float PCM samples into standard 16-bit linear PCM WAV files.
public enum WavWriter {
    
    /// Converts an array of Float32 audio samples into standard WAV binary data.
    ///
    /// - Parameters:
    ///   - samples: Raw audio samples normalized between -1.0 and +1.0.
    ///   - sampleRate: Sample rate in Hz (e.g. 24000).
    ///   - normalize: Whether to peak-normalize the audio (default: false).
    /// - Returns: Complete WAV file binary Data with standard 44-byte RIFF/WAVE header.
    public static func data(
        from samples: [Float],
        sampleRate: Double = 24000.0,
        normalize: Bool = false
    ) throws -> Data {
        return try AudioWAV.data(
            from: samples,
            sampleRate: sampleRate,
            normalize: normalize
        )
    }
    
    /// Writes audio samples directly to a target file path on disk.
    ///
    /// Automatically handles tilde expansion (`~/output.wav`) and creates parent directories if needed.
    public static func write(
        samples: [Float],
        sampleRate: Double = 24000.0,
        toPath rawPath: String,
        normalize: Bool = false
    ) throws -> URL {
        let expandedPath = (rawPath as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)
        
        let wavData = try data(from: samples, sampleRate: sampleRate, normalize: normalize)
        
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try wavData.write(to: url)
        return url
    }
}
