import Foundation
import FluidAudio

/// PocketTTS speech synthesis engine (Kyutai FlowLM transformer + Mimi neural audio codec).
///
/// Features:
///  - 100% on-device voice cloning in pure Swift using the Mimi audio encoder
///  - Streaming synthesis in 80ms audio frames (1920 samples at 24 kHz)
///  - Multi-language support: English, Spanish, French, German, Italian, Portuguese
///  - Efficient hybrid hardware placement (Flow decoder on ANE, FlowLM on GPU, Mimi on CPU)
public final class PocketEngine: TTSEngine, @unchecked Sendable {
    
    public let id = "pocket"
    public let sampleRate = 24000
    
    private var manager: PocketTtsManager?
    private let language: PocketTtsLanguage
    private let defaultVoice: String
    
    public init(language: PocketTtsLanguage = .english, defaultVoice: String = "alba") {
        self.language = language
        self.defaultVoice = defaultVoice
    }
    
    public func initialize() async throws {
        guard manager == nil else { return }
        let mgr = PocketTtsManager(
            defaultVoice: defaultVoice,
            language: language,
            precision: .fp16,
            placement: .gpu
        )
        try await mgr.initialize()
        self.manager = mgr
    }
    
    private func getManager() async throws -> PocketTtsManager {
        if let mgr = manager { return mgr }
        try await initialize()
        guard let mgr = manager else {
            throw NSError(
                domain: "PocketEngine",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to initialize PocketTTS manager"]
            )
        }
        return mgr
    }
    
    /// Synthesizes text to Float32 audio samples.
    ///
    /// Automatically checks if `voice` points to a loaded cloned voice preset.
    public func synthesize(text: String, voice: String) async throws -> [Float] {
        let mgr = try await getManager()
        
        // Check if voice is a cloned voice preset loaded in memory or on disk
        if let clonedData = VoicePreset.loadPocketVoice(named: voice) {
            var samples: [Float] = []
            let stream = try await mgr.synthesizeStreaming(text: text, voiceData: clonedData)
            for try await frame in stream {
                samples.append(contentsOf: frame.samples)
            }
            return samples
        } else {
            // Built-in named voice (e.g. "alba")
            var samples: [Float] = []
            let stream = try await mgr.synthesizeStreaming(text: text, voice: voice.isEmpty ? defaultVoice : voice)
            for try await frame in stream {
                samples.append(contentsOf: frame.samples)
            }
            return samples
        }
    }
    
    /// Synthesizes text yielding chunks of Float32 audio frames as they are generated.
    public func synthesizeStream(text: String, voice: String) async throws -> AsyncThrowingStream<[Float], Error> {
        let mgr = try await getManager()
        
        if let clonedData = VoicePreset.loadPocketVoice(named: voice) {
            let frameStream = try await mgr.synthesizeStreaming(text: text, voiceData: clonedData)
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        for try await frame in frameStream {
                            continuation.yield(frame.samples)
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        } else {
            let frameStream = try await mgr.synthesizeStreaming(text: text, voice: voice.isEmpty ? defaultVoice : voice)
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        for try await frame in frameStream {
                            continuation.yield(frame.samples)
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
    
    /// Clones a voice from a reference audio file and returns the extracted conditioning data.
    public func cloneVoice(from audioURL: URL) async throws -> PocketTtsVoiceData {
        let mgr = try await getManager()
        return try await mgr.cloneVoice(from: audioURL)
    }
    
    /// Saves cloned voice data to a binary file.
    public func saveClonedVoice(_ voiceData: PocketTtsVoiceData, to url: URL) async throws {
        let mgr = try await getManager()
        try mgr.saveClonedVoice(voiceData, to: url)
    }
    
    /// Loads a previously saved cloned voice data file.
    public func loadClonedVoice(from url: URL) async throws -> PocketTtsVoiceData {
        let mgr = try await getManager()
        return try mgr.loadClonedVoice(from: url)
    }
}
