import Foundation
import FluidAudio

/// Dynamic multi-engine dispatcher coordinating speech synthesis across:
///  - Kokoro-82M (Apple Neural Engine INT4)
///  - PocketTTS (Kyutai FlowLM + Mimi GPU/CPU)
///  - Supertonic-3 (Flow-Matching Diffusion on Apple Neural Engine)
///
/// An actor that lazily initializes engines only when a voice requiring that engine is requested.
/// Automatically harmonizes sample rates (24 kHz <-> 44.1 kHz) via high-speed CoreAudio resampling
/// when multiple engines are mixed in the same dialogue stream.
public actor EngineDispatcher {
    
    public nonisolated let sampleRate: Int
    
    private let defaultVoice: String
    private let explicitEngine: String?
    private let explicitLang: String?
    private let steps: Int
    
    private var kokoroEngine: KokoroEngine?
    private var pocketEngine: PocketEngine?
    private var supertonicEngine: SupertonicEngine?
    
    public init(
        defaultVoice: String = "heart",
        explicitEngine: String? = nil,
        explicitLang: String? = nil,
        steps: Int = 5
    ) {
        let initialVoice: String
        if explicitEngine?.lowercased() == "pocket" && (defaultVoice == "heart" || defaultVoice.isEmpty) {
            initialVoice = "alba"
        } else if explicitEngine?.lowercased() == "supertonic" && (defaultVoice == "heart" || defaultVoice.isEmpty) {
            initialVoice = "m1"
        } else {
            initialVoice = defaultVoice
        }
        self.defaultVoice = initialVoice
        self.explicitEngine = explicitEngine
        self.explicitLang = explicitLang
        self.steps = steps
        
        let initialResolved = VoiceRegistry.resolve(
            query: initialVoice,
            explicitEngine: explicitEngine,
            explicitLang: explicitLang
        )
        switch initialResolved {
        case .supertonic:
            self.sampleRate = 44_100
        case .kokoro, .pocket:
            self.sampleRate = 24_000
        }
    }
    
    /// Preloads the engine needed for the default voice so the first audio chunk has minimal latency.
    public func initializeDefault() async throws {
        _ = try await getEngineTarget(for: defaultVoice)
    }
    
    /// Synthesizes text to Float32 audio samples, routing dynamically to the appropriate engine.
    /// Resamples across sample rates if mixed engines are invoked, and applies SIMD peak normalization.
    public func synthesize(text: String, voice: String, overrideLang: String? = nil) async throws -> [Float] {
        let target = try await getEngineTarget(for: voice, overrideLang: overrideLang)
        var samples: [Float]
        
        if let sup = target.engine as? SupertonicEngine {
            let lang = target.language ?? "en"
            samples = try await sup.synthesize(
                text: text,
                voice: target.voice,
                language: lang,
                steps: steps,
                customStyleURL: target.customURL
            )
        } else {
            samples = try await target.engine.synthesize(text: text, voice: target.voice)
        }
        
        // Harmonize sample rates if this engine chunk differs from the session's stream rate
        if target.engine.sampleRate != self.sampleRate {
            samples = try AudioNormalizer.resample(
                samples: samples,
                fromRate: Double(target.engine.sampleRate),
                toRate: Double(self.sampleRate)
            )
        }
        
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
        
        if engine.sampleRate != self.sampleRate {
            samples = try AudioNormalizer.resample(
                samples: samples,
                fromRate: Double(engine.sampleRate),
                toRate: Double(self.sampleRate)
            )
        }
        
        AudioNormalizer.peakNormalize(&samples)
        return samples
    }
    
    // MARK: - Private Engine Resolution
    
    private struct ResolvedEngineTarget {
        let engine: any TTSEngine
        let voice: String
        let customURL: URL?
        let language: String?
    }
    
    private func getEngineTarget(for query: String, overrideLang: String? = nil) async throws -> ResolvedEngineTarget {
        let effectiveLang = overrideLang ?? explicitLang
        let resolved = VoiceRegistry.resolve(
            query: query,
            explicitEngine: explicitEngine,
            explicitLang: effectiveLang
        )
        
        switch resolved {
        case .kokoro(let canonicalVoice, let variant):
            let engine = try await getKokoroEngine(canonicalVoice: canonicalVoice, variant: variant)
            return ResolvedEngineTarget(engine: engine, voice: canonicalVoice, customURL: nil, language: nil)
            
        case .pocket(let voiceName, _, let lang):
            let engine = try await getPocketEngine(defaultVoice: voiceName, language: lang)
            return ResolvedEngineTarget(engine: engine, voice: voiceName, customURL: nil, language: lang.rawValue)
            
        case .supertonic(let voiceStyleName, _, let customURL, let language):
            let engine = try await getSupertonicEngine(defaultVoice: voiceStyleName, language: language)
            return ResolvedEngineTarget(engine: engine, voice: voiceStyleName, customURL: customURL, language: language)
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
    
    private func getSupertonicEngine(defaultVoice: String, language: String) async throws -> SupertonicEngine {
        if let existing = supertonicEngine {
            return existing
        }
        let engine = SupertonicEngine(defaultVoice: defaultVoice, defaultLanguage: language, defaultSteps: steps)
        try await engine.initialize()
        supertonicEngine = engine
        return engine
    }
}
