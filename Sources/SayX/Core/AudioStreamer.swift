import Foundation
import AVFoundation

/// Low-latency, gapless audio streaming player powered by Apple's CoreAudio / AVAudioEngine.
///
/// In a streaming TTS pipeline, audio samples arrive chunk-by-chunk from the neural engine.
/// `AudioStreamer` queues these raw PCM buffers into the hardware audio graph back-to-back
/// with sample-accurate continuity, avoiding pops, clicks, or pauses between sentences.
public final class AudioStreamer: @unchecked Sendable {
    
    // CoreAudio Engine & Nodes
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    private let format: AVAudioFormat
    public let sampleRate: Double
    public let speed: Float
    public let pitch: Float
    
    // Thread safety & synchronization
    private let lock = NSLock()
    private let finishSemaphore = DispatchSemaphore(value: 0)
    
    // Buffer & Sample accounting for telemetry and backpressure
    private var scheduledBuffers = 0
    private var completedBuffers = 0
    private var scheduledSamples: Int64 = 0
    private var completedSamples: Int64 = 0
    private var hasStartedPlayback = false
    private var isFinishedScheduling = false
    
    // Optional live tee accumulator (e.g. for --tee-output file recording)
    private var onSamplesPlayed: (([Float]) -> Void)?
    
    /// Initializes the audio engine configured for 32-bit Float mono audio with time-pitch DSP.
    ///
    /// - Parameters:
    ///   - sampleRate: Output sample rate (default: 24,000 Hz).
    ///   - speed: Playback speed multiplier (default: 1.0).
    ///   - pitch: Pitch shift in cents (-2400 to +2400, default: 0.0).
    ///   - onSamplesPlayed: Optional callback invoked with each chunk (for tee file saving).
    public init(
        sampleRate: Double = 24000.0,
        speed: Float = 1.0,
        pitch: Float = 0.0,
        onSamplesPlayed: (([Float]) -> Void)? = nil
    ) throws {
        self.sampleRate = sampleRate
        self.speed = speed
        self.pitch = pitch
        self.onSamplesPlayed = onSamplesPlayed
        
        // AVAudioFormat specifies the channel count and bit depth of the raw PCM data.
        guard let audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(
                domain: "AudioStreamer",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create CoreAudio AVAudioFormat for \(sampleRate) Hz"]
            )
        }
        self.format = audioFormat
        
        // 1. Attach player node and time-pitch DSP node to audio graph
        engine.attach(player)
        engine.attach(timePitch)
        
        // 2. Configure time-pitch DSP
        let clampedSpeed = max(1.0 / 32.0, min(32.0, speed))
        let clampedPitch = max(-2400.0, min(2400.0, pitch))
        timePitch.rate = clampedSpeed
        timePitch.pitch = clampedPitch
        
        // 3. Connect: Player -> TimePitch -> MainMixer
        engine.connect(player, to: timePitch, format: audioFormat)
        engine.connect(timePitch, to: engine.mainMixerNode, format: audioFormat)
        
        // 4. Start the hardware audio stream
        try engine.start()
    }
    
    /// Returns the number of scheduled audio buffers currently waiting in queue to be played.
    public var inFlightBuffers: Int {
        lock.lock()
        defer { lock.unlock() }
        return scheduledBuffers - completedBuffers
    }
    
    /// Returns the estimated number of wall-clock seconds of audio currently queued in the hardware buffer.
    public var queuedSeconds: Double {
        lock.lock()
        defer { lock.unlock() }
        let remainingSamples = scheduledSamples - completedSamples
        if remainingSamples <= 0 { return 0.0 }
        let nominalSeconds = Double(remainingSamples) / sampleRate
        return nominalSeconds / Double(max(0.05, speed))
    }
    
    /// Returns true if audio is actively playing or queued in the player.
    public var isPlaying: Bool {
        lock.lock()
        defer { lock.unlock() }
        return (scheduledBuffers > completedBuffers) && hasStartedPlayback
    }
    
    /// Schedules a raw array of Float32 audio samples into the continuous playback queue.
    ///
    /// - Parameter samples: Array of 32-bit floating point PCM audio samples (normalized -1.0 to +1.0).
    public func playChunk(samples: [Float]) {
        guard !samples.isEmpty else { return }
        
        // If a tee collector is configured, record samples
        onSamplesPlayed?(samples)
        
        // Allocate a CoreAudio PCM buffer with the required frame capacity
        let frameCount = AVAudioFrameCount(samples.count)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        pcmBuffer.frameLength = frameCount
        
        // Copy samples directly into the buffer's audio memory channel
        if let channelData = pcmBuffer.floatChannelData {
            samples.withUnsafeBufferPointer { srcPointer in
                if let base = srcPointer.baseAddress {
                    memcpy(channelData[0], base, samples.count * MemoryLayout<Float>.stride)
                }
            }
        }
        
        // Increment scheduled count & samples under lock
        let count = Int64(samples.count)
        lock.lock()
        scheduledBuffers += 1
        scheduledSamples += count
        lock.unlock()
        
        // Schedule buffer onto the player node. CoreAudio will invoke the completion handler
        // once this specific buffer finishes rendering out of the speakers.
        player.scheduleBuffer(pcmBuffer) { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            self.completedBuffers += 1
            self.completedSamples += count
            // Check if all scheduled buffers have finished and producer signaled completion
            let isAllDone = self.isFinishedScheduling && (self.completedBuffers >= self.scheduledBuffers)
            self.lock.unlock()
            
            if isAllDone {
                self.finishSemaphore.signal()
            }
        }
        
        // Start playback as soon as the very first buffer is scheduled
        if !hasStartedPlayback {
            player.play()
            hasStartedPlayback = true
        }
    }
    
    /// Signals that all audio chunks have been submitted, and blocks until playback finishes.
    public func finishAndAwaitCompletion() {
        lock.lock()
        isFinishedScheduling = true
        let alreadyFinished = completedBuffers >= scheduledBuffers
        lock.unlock()
        
        // If there was no audio or it already finished playing, tear down immediately
        if alreadyFinished {
            player.stop()
            engine.stop()
            return
        }
        
        // Block the calling thread until the final buffer completion handler fires
        finishSemaphore.wait()
        
        // Allow a small 150ms buffer for hardware audio output drain
        Thread.sleep(forTimeInterval: 0.15)
        player.stop()
        engine.stop()
    }
    
    /// Immediate stop without blocking. Useful for daemon teardown.
    public func stop() {
        lock.lock()
        isFinishedScheduling = true
        player.stop()
        engine.stop()
        lock.unlock()
        finishSemaphore.signal()
    }
}
