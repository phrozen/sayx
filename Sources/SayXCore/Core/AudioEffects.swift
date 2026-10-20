import Foundation
import AVFoundation

/// CoreAudio DSP audio effects engine using Apple's `AVAudioUnitTimePitch`.
///
/// Enables pitch-invariant time-stretching (speed control) and pitch modulation:
/// - Pure Apple CoreAudio phase-vocoder DSP implementation with zero external dependencies.
/// - Offline manual rendering for file export (`-o file.wav`) at >50x real-time speed.
/// - Preserves natural vocal harmonics without robotic frequency distortion or chipmunk artifacts.
public enum AudioEffects {
    
    /// Applies pitch-invariant time-stretching and/or pitch shifting to raw PCM samples.
    ///
    /// - Parameters:
    ///   - samples: Raw Float32 PCM audio samples.
    ///   - sampleRate: Sample rate in Hz (default: 24,000 Hz).
    ///   - speed: Playback speed multiplier (e.g. 1.25 for 25% faster; range: 0.03 to 32.0; default: 1.0).
    ///   - pitch: Pitch shift in cents (-2400 to +2400; 100 cents = 1 semitone, 1200 cents = 1 octave; default: 0.0).
    /// - Returns: Time-stretched and pitch-shifted Float32 PCM audio samples.
    public static func applyTimePitch(
        samples: [Float],
        sampleRate: Double = 24000.0,
        speed: Float = 1.0,
        pitch: Float = 0.0
    ) throws -> [Float] {
        guard !samples.isEmpty else { return [] }
        
        // Fast path: No DSP needed if speed is 1.0 and pitch is 0
        if abs(speed - 1.0) < 1e-4 && abs(pitch) < 1e-4 {
            return samples
        }
        
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(
                domain: "AudioEffects",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create CoreAudio format for \(sampleRate) Hz"]
            )
        }
        
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let timePitch = AVAudioUnitTimePitch()
        
        // Clamp parameters to CoreAudio valid limits
        let clampedSpeed = max(1.0 / 32.0, min(32.0, speed))
        let clampedPitch = max(-2400.0, min(2400.0, pitch))
        
        timePitch.rate = clampedSpeed
        timePitch.pitch = clampedPitch
        
        // Assemble audio graph: Player -> TimePitch -> MainMixer
        engine.attach(player)
        engine.attach(timePitch)
        engine.connect(player, to: timePitch, format: format)
        engine.connect(timePitch, to: engine.mainMixerNode, format: format)
        
        // Populate input buffer
        let inputFrames = AVAudioFrameCount(samples.count)
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: inputFrames) else {
            throw NSError(
                domain: "AudioEffects",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to allocate input buffer for \(inputFrames) frames"]
            )
        }
        inputBuffer.frameLength = inputFrames
        if let channelData = inputBuffer.floatChannelData {
            samples.withUnsafeBufferPointer { ptr in
                if let base = ptr.baseAddress {
                    memcpy(channelData[0], base, samples.count * MemoryLayout<Float>.stride)
                }
            }
        }
        
        // Configure offline manual rendering mode
        let maxFrames: AVAudioFrameCount = 4096
        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: maxFrames)
        try engine.start()
        
        player.scheduleBuffer(inputBuffer, at: nil, options: [])
        player.play()
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: maxFrames) else {
            throw NSError(
                domain: "AudioEffects",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to allocate offline output buffer"]
            )
        }
        
        // Expected output frames = inputFrames / speed (+ small filter latency tail)
        let latencyFrames = min(1024, Int(sampleRate * 0.03))
        let estimatedOutputFrames = Int(Double(inputFrames) / Double(clampedSpeed)) + latencyFrames
        var result: [Float] = []
        result.reserveCapacity(estimatedOutputFrames)
        
        while result.count < estimatedOutputFrames {
            let framesToRender = min(maxFrames, AVAudioFrameCount(estimatedOutputFrames - result.count))
            let status = try engine.renderOffline(framesToRender, to: outputBuffer)
            
            switch status {
            case .success:
                let framesRendered = Int(outputBuffer.frameLength)
                if framesRendered == 0 { break }
                if let data = outputBuffer.floatChannelData {
                    result.append(contentsOf: UnsafeBufferPointer(start: data[0], count: framesRendered))
                }
            case .insufficientDataFromInputNode:
                // Finished consuming player buffer
                break
            case .cannotDoInCurrentContext, .error:
                break
            @unknown default:
                break
            }
            
            if status == .insufficientDataFromInputNode {
                break
            }
        }
        
        player.stop()
        engine.stop()
        
        return result
    }
}
