import Foundation
import FluidAudio

/// Supertonic-3 TTS engine accelerated by the Apple Neural Engine (ANE) via flow-matching diffusion.
///
/// Features:
///  - High-fidelity 44.1 kHz mono Float32 audio output
///  - 31 languages with native Unicode NFKD normalization
///  - Apple Neural Engine fixed-bucket INT4 VectorEstimator (~94% ANE execution)
///  - 10 built-in character voice styles (M1-M5, F1-F5) and custom JSON style loading
public actor SupertonicEngine: TTSEngine {
    
    public nonisolated let id = "supertonic"
    public nonisolated let sampleRate: Int = 44_100
    
    private var manager: Supertonic3Manager?
    private let defaultVoice: String
    private let defaultLanguage: String
    private let defaultSteps: Int
    
    private var styleCache: [String: Supertonic3VoiceStyle] = [:]
    
    public init(
        defaultVoice: String = "m1",
        defaultLanguage: String = "en",
        defaultSteps: Int = Supertonic3Constants.defaultTotalSteps
    ) {
        self.defaultVoice = defaultVoice
        self.defaultLanguage = defaultLanguage
        self.defaultSteps = defaultSteps
    }
    
    public func initialize() async throws {
        guard manager == nil else { return }
        let mgr = try await Supertonic3Manager.downloadAndCreate(
            computeUnits: .cpuAndNeuralEngine,
            vectorEstimator: .aneBucketed(.int4)
        )
        self.manager = mgr
    }
    
    private func getManager() async throws -> Supertonic3Manager {
        if let mgr = manager { return mgr }
        try await initialize()
        guard let mgr = manager else {
            throw NSError(domain: "SupertonicEngine", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Supertonic-3 manager"])
        }
        return mgr
    }
    
    /// Synthesizes text using the configured default language and steps.
    public func synthesize(text: String, voice: String) async throws -> [Float] {
        return try await synthesize(
            text: text,
            voice: voice,
            language: defaultLanguage,
            steps: defaultSteps
        )
    }
    
    /// Synthesizes text with explicit language, voice, and step count.
    public func synthesize(
        text: String,
        voice: String,
        language: String,
        steps: Int = Supertonic3Constants.defaultTotalSteps,
        customStyleURL: URL? = nil
    ) async throws -> [Float] {
        let mgr = try await getManager()
        let style = try await resolveStyle(named: voice, customURL: customStyleURL)
        
        let validLang = Self.resolveLanguageCode(language)
        
        let (samples, _) = try await mgr.synthesize(
            text: text,
            language: validLang,
            style: style,
            totalSteps: steps,
            speed: Supertonic3Constants.defaultSpeed
        )
        return samples
    }
    
    /// Resolves and caches a voice style from a built-in voice enum or custom file.
    public func resolveStyle(named voiceName: String, customURL: URL? = nil) async throws -> Supertonic3VoiceStyle {
        let sanitized = voiceName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let cached = styleCache[sanitized] {
            return cached
        }
        
        let loadedStyle: Supertonic3VoiceStyle
        
        if let url = customURL, FileManager.default.fileExists(atPath: url.path) {
            // 1. Direct custom file URL
            loadedStyle = try Supertonic3VoiceStyle.load(from: url)
        } else if let customPresetURL = VoicePreset.findSupertonicStyle(named: sanitized) {
            // 2. Custom style located in ~/.cache/sayx/voices/<name>/
            loadedStyle = try Supertonic3VoiceStyle.load(from: customPresetURL)
        } else if let builtInVoice = Supertonic3Voice(name: sanitized) {
            // 3. Built-in Supertonic voice style (m1..m5, f1..f5)
            loadedStyle = try await Supertonic3ResourceDownloader.loadVoiceStyle(builtInVoice)
        } else if let mappedAlias = VoiceRegistry.resolveSupertonicAlias(sanitized),
                  let builtInVoice = Supertonic3Voice(name: mappedAlias) {
            // 4. Friendly semantic alias (e.g. m-narrator -> m1)
            loadedStyle = try await Supertonic3ResourceDownloader.loadVoiceStyle(builtInVoice)
        } else {
            // Fallback to default voice (M1)
            loadedStyle = try await Supertonic3ResourceDownloader.loadVoiceStyle(.default)
        }
        
        styleCache[sanitized] = loadedStyle
        return loadedStyle
    }
    
    /// Normalizes language names or codes to Supertonic-3 supported ISO codes.
    public nonisolated static func resolveLanguageCode(_ raw: String) -> String {
        let cleaned = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Exact match in 31 supported languages
        if Supertonic3Constants.availableLanguages.contains(cleaned) {
            return cleaned
        }
        
        // Friendly name mapping
        switch cleaned {
        case "english", "en-us", "en-gb": return "en"
        case "spanish", "es-es", "es-mx": return "es"
        case "korean", "ko-kr": return "ko"
        case "japanese", "ja-jp": return "ja"
        case "french", "fr-fr": return "fr"
        case "german", "de-de": return "de"
        case "italian", "it-it": return "it"
        case "portuguese", "pt-br", "pt-pt": return "pt"
        case "dutch", "nl-nl": return "nl"
        case "polish", "pl-pl": return "pl"
        case "russian", "ru-ru": return "ru"
        case "arabic", "ar-sa": return "ar"
        case "hindi", "hi-in": return "hi"
        case "turkish", "tr-tr": return "tr"
        case "vietnamese", "vi-vn": return "vi"
        case "indonesian", "id-id": return "id"
        case "ukrainian", "uk-ua": return "uk"
        case "swedish", "sv-se": return "sv"
        case "danish", "da-dk": return "da"
        case "finnish", "fi-fi": return "fi"
        case "greek", "el-gr": return "el"
        case "czech", "cs-cz": return "cs"
        case "hungarian", "hu-hu": return "hu"
        case "romanian", "ro-ro": return "ro"
        case "slovak", "sk-sk": return "sk"
        case "slovenian", "sl-si": return "sl"
        case "croatian", "hr-hr": return "hr"
        case "bulgarian", "bg-bg": return "bg"
        case "lithuanian", "lt-lt": return "lt"
        case "latvian", "lv-lv": return "lv"
        case "estonian", "et-ee": return "et"
        default: return "en"
        }
    }
}
