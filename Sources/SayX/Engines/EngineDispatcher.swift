import Foundation
import FluidAudio

/// Dynamic multi-engine dispatcher coordinating speech synthesis across Kokoro (ANE) and PocketTTS (FlowLM).
///
/// An actor that lazily initializes engines only when a voice requiring that engine is requested.
/// Allows seamless mixing of Kokoro voices (54 built-in), PocketTTS studio voices (24 built-in),
/// and custom cloned voices in the same session or audio stream.
public actor EngineDispatcher {
    
    public nonisolated let sampleRate: Int = 24_000
    
    private let defaultVoice: String
    private let explicitEngine: String?
    private let explicitLang: String?
    
    private var kokoroEngine: KokoroEngine?
    private var pocketEngine: PocketEngine?
    
    public init(
        defaultVoice: String = "heart",
        explicitEngine: String? = nil,
        explicitLang: String? = nil
    ) {
        if explicitEngine?.lowercased() == "pocket" && (defaultVoice == "heart" || defaultVoice.isEmpty) {
            self.defaultVoice = "alba"
        } else {
            self.defaultVoice = defaultVoice
        }
        self.explicitEngine = explicitEngine
        self.explicitLang = explicitLang
    }
    
    /// Preloads the engine needed for the default voice so the first audio chunk has minimal latency.
    public func initializeDefault() async throws {
        _ = try await getEngine(for: defaultVoice)
    }
    
    /// Synthesizes text to Float32 audio samples, routing dynamically to the appropriate engine.
    /// Applies SIMD peak normalization (-1.0 dBFS) for broadcast-level consistency across all engines.
    public func synthesize(text: String, voice: String) async throws -> [Float] {
        let (engine, targetVoice) = try await getEngine(for: voice)
        var samples = try await engine.synthesize(text: text, voice: targetVoice)
        AudioNormalizer.peakNormalize(&samples)
        return samples
    }
    
    /// Generates phonemes using Kokoro's G2P model.
    public func phonemes(for text: String) async throws -> String {
        let engine = try await getKokoroEngine(canonicalVoice: "af_heart", variant: .english)
        return try await engine.phonemes(for: text)
    }
    
    /// Synthesizes directly from IPA phonemes using Kokoro on ANE.
    public func synthesizeFromPhonemes(_ ipa: String, voice: String) async throws -> [Float] {
        let canonicalVoice = VoiceRegistry.resolveKokoroVoice(voice)
        let variant = VoiceRegistry.resolveKokoroVariant(for: canonicalVoice)
        let engine = try await getKokoroEngine(canonicalVoice: canonicalVoice, variant: variant)
        var samples = try await engine.synthesizeFromPhonemes(ipa, voice: canonicalVoice)
        AudioNormalizer.peakNormalize(&samples)
        return samples
    }
    
    // MARK: - Private Engine Resolution
    
    private func getEngine(for query: String) async throws -> (engine: any TTSEngine, voice: String) {
        let resolved = VoiceRegistry.resolve(
            query: query,
            explicitEngine: explicitEngine,
            explicitLang: explicitLang
        )
        
        switch resolved {
        case .kokoro(let canonicalVoice, let variant):
            let engine = try await getKokoroEngine(canonicalVoice: canonicalVoice, variant: variant)
            return (engine, canonicalVoice)
            
        case .pocket(let voiceName, _, let lang):
            let engine = try await getPocketEngine(defaultVoice: voiceName, language: lang)
            return (engine, voiceName)
        }
    }
    
    private func getKokoroEngine(canonicalVoice: String, variant: KokoroAneVariant) async throws -> KokoroEngine {
        if let existing = kokoroEngine {
            return existing
        }
        let engine = KokoroEngine(defaultVoice: canonicalVoice, variant: variant)
        try await engine.initialize()
        kokoroEngine = engine
        return engine
    }
    
    private func getPocketEngine(defaultVoice: String, language: PocketTtsLanguage) async throws -> PocketEngine {
        if let existing = pocketEngine {
            return existing
        }
        let engine = PocketEngine(language: language, defaultVoice: defaultVoice)
        try await engine.initialize()
        pocketEngine = engine
        return engine
    }
}
