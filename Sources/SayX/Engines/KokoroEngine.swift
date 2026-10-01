import Foundation
import FluidAudio

/// Kokoro-82M TTS engine accelerated by the 16-core Apple Neural Engine (ANE) via CoreML.
///
/// Features:
///  - 25x Real-Time batch synthesis speed
///  - Sub-200ms Time-To-First-Audio latency
///  - 54 natural voice profiles across 9 languages
///  - G2P phonemizer support (IPA inspection & direct synthesis)
public final class KokoroEngine: TTSEngine, @unchecked Sendable {
    
    public let id = "kokoro"
    public let sampleRate = KokoroAneConstants.sampleRate // 24,000 Hz
    
    private var manager: KokoroAneManager?
    private let defaultVoice: String
    private let variant: KokoroAneVariant
    
    public init(defaultVoice: String = "af_heart", variant: KokoroAneVariant = .english) {
        self.defaultVoice = defaultVoice
        self.variant = variant
    }
    
    public func initialize() async throws {
        guard manager == nil else { return }
        let mgr = KokoroAneManager(variant: variant, defaultVoice: defaultVoice)
        try await mgr.initialize()
        self.manager = mgr
    }
    
    private func getManager() async throws -> KokoroAneManager {
        if let mgr = manager { return mgr }
        try await initialize()
        guard let mgr = manager else {
            throw NSError(domain: "KokoroEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Kokoro manager"])
        }
        return mgr
    }
    
    public func synthesize(text: String, voice: String) async throws -> [Float] {
        let mgr = try await getManager()
        let result = try await mgr.synthesizeDetailed(text: text, voice: voice, speed: 1.0)
        return result.samples
    }
    
    /// Synthesize speech directly from pre-computed IPA phonemes (bypasses G2P)
    public func synthesizeFromPhonemes(_ phonemes: String, voice: String) async throws -> [Float] {
        let mgr = try await getManager()
        let result = try await mgr.synthesizeFromPhonemesDetailed(phonemes, voice: voice, speed: 1.0)
        return result.samples
    }
    
    /// Generates the International Phonetic Alphabet (IPA) tokens for the provided text
    public func phonemes(for text: String) async throws -> String {
        let mgr = try await getManager()
        return try await mgr.phonemes(for: text)
    }
}
