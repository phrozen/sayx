import Foundation
import FluidAudio

/// Voice definition structure representing a voice ID, its short/friendly alias, and a description.
public struct VoiceInfo: Sendable {
    public let id: String
    public let alias: String
    public let description: String
    
    public init(id: String, alias: String, description: String) {
        self.id = id
        self.alias = alias
        self.description = description
    }
}

/// Resolved target engine and parameters for a voice query.
public enum ResolvedVoice: Sendable {
    case kokoro(canonicalVoice: String, variant: KokoroAneVariant)
    case pocket(voiceName: String, isCloned: Bool, language: PocketTtsLanguage)
    case supertonic(voiceStyleName: String, isCustom: Bool, customURL: URL?, language: String)
}

/// Registry of all 54 Kokoro-82M voices and custom cloned presets.
public enum VoiceRegistry {
    
    /// Full catalog of built-in Kokoro voices grouped by language and dialect.
    public static let kokoroVoices: [VoiceInfo] = [
        // American English - Female
        VoiceInfo(id: "af_heart",   alias: "heart",   description: "American Female (Default, Grade A)"),
        VoiceInfo(id: "af_bella",   alias: "bella",   description: "American Female (Grade A-)"),
        VoiceInfo(id: "af_nicole",  alias: "nicole",  description: "American Female (Grade B-)"),
        VoiceInfo(id: "af_aoede",   alias: "aoede",   description: "American Female"),
        VoiceInfo(id: "af_kore",    alias: "kore",    description: "American Female"),
        VoiceInfo(id: "af_sarah",   alias: "sarah",   description: "American Female"),
        VoiceInfo(id: "af_alloy",   alias: "alloy",   description: "American Female"),
        VoiceInfo(id: "af_nova",    alias: "nova",    description: "American Female"),
        VoiceInfo(id: "af_sky",     alias: "sky",     description: "American Female"),
        VoiceInfo(id: "af_jessica", alias: "jessica", description: "American Female"),
        VoiceInfo(id: "af_river",   alias: "river",   description: "American Female"),
        
        // American English - Male
        VoiceInfo(id: "am_adam",    alias: "adam",    description: "American Male"),
        VoiceInfo(id: "am_michael", alias: "michael", description: "American Male"),
        VoiceInfo(id: "am_fenrir",  alias: "fenrir",  description: "American Male"),
        VoiceInfo(id: "am_puck",    alias: "puck",    description: "American Male"),
        VoiceInfo(id: "am_echo",    alias: "echo",    description: "American Male"),
        VoiceInfo(id: "am_eric",    alias: "eric",    description: "American Male"),
        VoiceInfo(id: "am_liam",    alias: "liam",    description: "American Male"),
        VoiceInfo(id: "am_onyx",    alias: "onyx",    description: "American Male"),
        VoiceInfo(id: "am_santa",   alias: "santa",   description: "American Male"),
        
        // British English - Female
        VoiceInfo(id: "bf_emma",     alias: "emma",     description: "British Female (Grade B-)"),
        VoiceInfo(id: "bf_isabella", alias: "isabella", description: "British Female"),
        VoiceInfo(id: "bf_alice",    alias: "alice",    description: "British Female"),
        VoiceInfo(id: "bf_lily",     alias: "lily",     description: "British Female"),
        
        // British English - Male
        VoiceInfo(id: "bm_george", alias: "george", description: "British Male"),
        VoiceInfo(id: "bm_fable",  alias: "fable",  description: "British Male"),
        VoiceInfo(id: "bm_daniel", alias: "daniel", description: "British Male"),
        VoiceInfo(id: "bm_lewis",  alias: "lewis",  description: "British Male"),
        
        // Japanese
        VoiceInfo(id: "jf_alpha",      alias: "jf_alpha",      description: "Japanese Female"),
        VoiceInfo(id: "jf_gongitsune", alias: "gongitsune", description: "Japanese Female"),
        VoiceInfo(id: "jf_nezumi",     alias: "nezumi",     description: "Japanese Female"),
        VoiceInfo(id: "jf_tebukuro",   alias: "tebukuro",   description: "Japanese Female"),
        VoiceInfo(id: "jm_kumo",       alias: "kumo",       description: "Japanese Male"),
        
        // Mandarin Chinese
        VoiceInfo(id: "zf_xiaobei",  alias: "xiaobei",  description: "Mandarin Female"),
        VoiceInfo(id: "zf_xiaoni",   alias: "xiaoni",   description: "Mandarin Female"),
        VoiceInfo(id: "zf_xiaoxiao", alias: "xiaoxiao", description: "Mandarin Female"),
        VoiceInfo(id: "zf_xiaoyi",   alias: "xiaoyi",   description: "Mandarin Female"),
        VoiceInfo(id: "zm_yunjian",  alias: "yunjian",  description: "Mandarin Male"),
        VoiceInfo(id: "zm_yunxi",    alias: "yunxi",    description: "Mandarin Male"),
        VoiceInfo(id: "zm_yunxia",   alias: "yunxia",   description: "Mandarin Male"),
        VoiceInfo(id: "zm_yunyang",  alias: "yunyang",  description: "Mandarin Male"),
        
        // Spanish
        VoiceInfo(id: "ef_dora",  alias: "ef_dora",  description: "Spanish Female"),
        VoiceInfo(id: "em_alex",  alias: "em_alex",  description: "Spanish Male"),
        VoiceInfo(id: "em_santa", alias: "em_santa", description: "Spanish Male"),
        
        // French
        VoiceInfo(id: "ff_siwis", alias: "siwis", description: "French Female"),
        
        // Hindi
        VoiceInfo(id: "hf_alpha", alias: "hf_alpha", description: "Hindi Female"),
        VoiceInfo(id: "hf_beta",  alias: "hf_beta",  description: "Hindi Female"),
        VoiceInfo(id: "hm_omega", alias: "omega",    description: "Hindi Male"),
        VoiceInfo(id: "hm_psi",   alias: "psi",      description: "Hindi Male"),
        
        // Italian
        VoiceInfo(id: "if_sara",   alias: "sara",   description: "Italian Female"),
        VoiceInfo(id: "im_nicola", alias: "nicola", description: "Italian Male"),
        
        // Brazilian Portuguese
        VoiceInfo(id: "pf_dora",  alias: "pf_dora",  description: "Portuguese Female"),
        VoiceInfo(id: "pm_alex",  alias: "pm_alex",  description: "Portuguese Male"),
        VoiceInfo(id: "pm_santa", alias: "pm_santa", description: "Portuguese Male"),
    ]
    
    /// Full catalog of built-in PocketTTS studio character voices (Kyutai FlowLM).
    public static let pocketVoices: [VoiceInfo] = [
        // Female Cast
        VoiceInfo(id: "alba",           alias: "alba",           description: "PocketTTS Female (Default)"),
        VoiceInfo(id: "anna",           alias: "anna",           description: "PocketTTS Female"),
        VoiceInfo(id: "azelma",         alias: "azelma",         description: "PocketTTS Female (Les Mis)"),
        VoiceInfo(id: "caro_davy",      alias: "caro_davy",      description: "PocketTTS Female"),
        VoiceInfo(id: "cosette",        alias: "cosette",        description: "PocketTTS Female (Les Mis)"),
        VoiceInfo(id: "eponine",        alias: "eponine",        description: "PocketTTS Female (Les Mis)"),
        VoiceInfo(id: "estelle",        alias: "estelle",        description: "PocketTTS Female"),
        VoiceInfo(id: "eve",            alias: "eve",            description: "PocketTTS Female"),
        VoiceInfo(id: "fantine",        alias: "fantine",        description: "PocketTTS Female (Les Mis)"),
        VoiceInfo(id: "jane",           alias: "jane",           description: "PocketTTS Female"),
        VoiceInfo(id: "lola",           alias: "lola",           description: "PocketTTS Female"),
        VoiceInfo(id: "mary",           alias: "mary",           description: "PocketTTS Female"),
        VoiceInfo(id: "vera",           alias: "vera",           description: "PocketTTS Female"),
        
        // Male Cast
        VoiceInfo(id: "charles",        alias: "charles",        description: "PocketTTS Male"),
        VoiceInfo(id: "giovanni",       alias: "giovanni",       description: "PocketTTS Male"),
        VoiceInfo(id: "javert",         alias: "javert",         description: "PocketTTS Male (Les Mis)"),
        VoiceInfo(id: "jean",           alias: "jean",           description: "PocketTTS Male (Les Mis)"),
        VoiceInfo(id: "juergen",        alias: "juergen",        description: "PocketTTS Male"),
        VoiceInfo(id: "marius",         alias: "marius",         description: "PocketTTS Male (Les Mis)"),
        VoiceInfo(id: "paul",           alias: "paul",           description: "PocketTTS Male"),
        VoiceInfo(id: "rafael",         alias: "rafael",         description: "PocketTTS Male"),
        VoiceInfo(id: "bill_boerst",    alias: "bill_boerst",    description: "PocketTTS Male"),
        VoiceInfo(id: "peter_yearsley", alias: "peter_yearsley", description: "PocketTTS Male"),
        VoiceInfo(id: "stuart_bell",    alias: "stuart_bell",    description: "PocketTTS Male"),
    ]
    
    /// Full catalog of built-in Supertonic-3 character voice styles (Flow-Matching Diffusion on ANE).
    public static let supertonicVoices: [VoiceInfo] = [
        VoiceInfo(id: "m1", alias: "m-narrator",   description: "Supertonic Male 1 (Default, Clear Narrator)"),
        VoiceInfo(id: "m2", alias: "m-casual",     description: "Supertonic Male 2 (Conversational)"),
        VoiceInfo(id: "m3", alias: "m-dramatic",   description: "Supertonic Male 3 (Resonant / Dramatic)"),
        VoiceInfo(id: "m4", alias: "m-deep",       description: "Supertonic Male 4 (Deep / Authoritative)"),
        VoiceInfo(id: "m5", alias: "m-energetic",  description: "Supertonic Male 5 (Dynamic / Energetic)"),
        VoiceInfo(id: "f1", alias: "f-studio",     description: "Supertonic Female 1 (Default, Studio Anchor)"),
        VoiceInfo(id: "f2", alias: "f-casual",     description: "Supertonic Female 2 (Warm Conversational)"),
        VoiceInfo(id: "f3", alias: "f-warm",       description: "Supertonic Female 3 (Gentle / Narrative)"),
        VoiceInfo(id: "f4", alias: "f-expressive", description: "Supertonic Female 4 (Bright / Expressive)"),
        VoiceInfo(id: "f5", alias: "f-calm",       description: "Supertonic Female 5 (Calm / Melodic)")
    ]
    
    /// Maps friendly semantic aliases (e.g. m-narrator, studio) to Supertonic character IDs.
    public static func resolveSupertonicAlias(_ query: String) -> String? {
        let cleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        switch cleaned {
        case "m1", "m-1", "m_1", "m-narrator", "m_narrator", "narrator": return "m1"
        case "m2", "m-2", "m_2", "m-casual", "m_casual": return "m2"
        case "m3", "m-3", "m_3", "m-dramatic", "m_dramatic": return "m3"
        case "m4", "m-4", "m_4", "m-deep", "m_deep": return "m4"
        case "m5", "m-5", "m_5", "m-energetic", "m_energetic": return "m5"
        case "f1", "f-1", "f_1", "f-studio", "f_studio", "studio": return "f1"
        case "f2", "f-2", "f_2", "f-casual", "f_casual": return "f2"
        case "f3", "f-3", "f_3", "f-warm", "f_warm": return "f3"
        case "f4", "f-4", "f_4", "f-expressive", "f_expressive": return "f4"
        case "f5", "f-5", "f_5", "f-calm", "f_calm": return "f5"
        default: return nil
        }
    }
    
    /// Checks if a voice query matches any built-in, aliased, or custom Supertonic voice style.
    public static func isSupertonicVoice(_ query: String) -> Bool {
        let cleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if resolveSupertonicAlias(cleaned) != nil { return true }
        if cleaned.hasSuffix(".json") { return true }
        if VoicePreset.findSupertonicStyle(named: cleaned) != nil { return true }
        return false
    }
    
    /// Resolves an incoming voice name and returns the appropriate engine and configuration.
    public static func resolve(
        query: String,
        explicitEngine: String? = nil,
        explicitLang: String? = nil
    ) -> ResolvedVoice {
        let cleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Check if user explicitly requested an engine
        if let engine = explicitEngine?.lowercased() {
            if engine == "supertonic" {
                let lang = SupertonicEngine.resolveLanguageCode(explicitLang ?? "en")
                if cleaned.hasSuffix(".json") {
                    let url = URL(fileURLWithPath: cleaned)
                    let styleName = url.deletingPathExtension().lastPathComponent
                    return .supertonic(voiceStyleName: styleName, isCustom: true, customURL: url, language: lang)
                }
                if let customURL = VoicePreset.findSupertonicStyle(named: cleaned) {
                    return .supertonic(voiceStyleName: cleaned, isCustom: true, customURL: customURL, language: lang)
                }
                let voice = resolveSupertonicAlias(cleaned) ?? (cleaned.isEmpty || cleaned == "heart" ? "m1" : cleaned)
                return .supertonic(voiceStyleName: voice, isCustom: false, customURL: nil, language: lang)
            }
            if engine == "pocket" {
                let lang = VoiceCloner.resolveLanguage(explicitLang ?? "english")
                let voice = (cleaned.isEmpty || cleaned == "heart") ? "alba" : cleaned
                let isCloned = VoicePreset.exists(named: voice)
                return .pocket(voiceName: voice, isCloned: isCloned, language: lang)
            }
            if engine == "kokoro" {
                let canonical = resolveKokoroVoice(cleaned.isEmpty ? "heart" : cleaned)
                let variant = resolveKokoroVariant(for: canonical)
                return .kokoro(canonicalVoice: canonical, variant: variant)
            }
        }
        
        // 2. Check if query is a direct JSON file path for Supertonic style
        if cleaned.hasSuffix(".json") {
            let url = URL(fileURLWithPath: cleaned)
            let lang = SupertonicEngine.resolveLanguageCode(explicitLang ?? "en")
            return .supertonic(voiceStyleName: url.deletingPathExtension().lastPathComponent, isCustom: true, customURL: url, language: lang)
        }
        
        // 3. Check if query matches a custom Supertonic style preset
        if let customStyleURL = VoicePreset.findSupertonicStyle(named: cleaned) {
            let lang = SupertonicEngine.resolveLanguageCode(explicitLang ?? "en")
            return .supertonic(voiceStyleName: cleaned, isCustom: true, customURL: customStyleURL, language: lang)
        }
        
        // 4. Check if query matches a built-in Supertonic voice or friendly alias
        if let supertonicAlias = resolveSupertonicAlias(cleaned) {
            let lang = SupertonicEngine.resolveLanguageCode(explicitLang ?? "en")
            return .supertonic(voiceStyleName: supertonicAlias, isCustom: false, customURL: nil, language: lang)
        }
        
        // 5. Check if query matches a custom cloned PocketTTS voice preset
        if VoicePreset.exists(named: cleaned) && VoicePreset.loadPocketVoice(named: cleaned) != nil {
            let lang = VoiceCloner.resolveLanguage(explicitLang ?? "english")
            return .pocket(voiceName: cleaned, isCloned: true, language: lang)
        }
        
        // 6. Check if query matches a built-in PocketTTS voice
        if let pocketMatch = pocketVoices.first(where: { $0.id == cleaned || $0.alias == cleaned }) {
            let lang = VoiceCloner.resolveLanguage(explicitLang ?? "english")
            return .pocket(voiceName: pocketMatch.id, isCloned: false, language: lang)
        }
        
        // 7. Otherwise default to Kokoro (54 built-in voices)
        let canonicalVoice = resolveKokoroVoice(cleaned)
        let variant = resolveKokoroVariant(for: canonicalVoice)
        return .kokoro(canonicalVoice: canonicalVoice, variant: variant)
    }
    
    /// Checks if a voice query matches any built-in or cloned PocketTTS voice.
    public static func isPocketVoice(_ query: String) -> Bool {
        let cleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if VoicePreset.exists(named: cleaned) { return true }
        return pocketVoices.contains { $0.id == cleaned || $0.alias == cleaned }
    }
    
    /// Maps aliases or partial names to Kokoro canonical voice IDs.
    public static func resolveKokoroVoice(_ query: String) -> String {
        let cleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let match = kokoroVoices.first(where: { $0.id.lowercased() == cleaned || $0.alias.lowercased() == cleaned }) {
            return match.id
        }
        
        // Prefix matching
        if let match = kokoroVoices.first(where: { $0.alias.lowercased().hasPrefix(cleaned) }) {
            return match.id
        }
        
        return "af_heart"
    }
    
    /// Resolves the Kokoro CoreML bundle variant needed for a canonical voice ID.
    public static func resolveKokoroVariant(for canonicalVoice: String) -> KokoroAneVariant {
        if canonicalVoice.hasPrefix("zf_") || canonicalVoice.hasPrefix("zm_") {
            return .mandarin
        } else if canonicalVoice.hasPrefix("jf_") || canonicalVoice.hasPrefix("jm_") {
            return .japanese
        } else if canonicalVoice.hasPrefix("ef_") || canonicalVoice.hasPrefix("em_") {
            return .spanish
        } else if canonicalVoice.hasPrefix("ff_") {
            return .french
        } else {
            return .english
        }
    }
}
