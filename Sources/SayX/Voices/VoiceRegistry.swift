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
    
    /// Resolves an incoming voice name and returns the appropriate engine and configuration.
    public static func resolve(
        query: String,
        explicitEngine: String? = nil,
        explicitLang: String? = nil
    ) -> ResolvedVoice {
        let cleaned = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Check if user explicitly requested an engine
        if let engine = explicitEngine?.lowercased() {
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
        
        // 2. Check if query matches a custom cloned voice preset
        if VoicePreset.exists(named: cleaned) {
            let lang = VoiceCloner.resolveLanguage(explicitLang ?? "english")
            return .pocket(voiceName: cleaned, isCloned: true, language: lang)
        }
        
        // 3. Check if query matches a built-in PocketTTS voice
        if let pocketMatch = pocketVoices.first(where: { $0.id == cleaned || $0.alias == cleaned }) {
            let lang = VoiceCloner.resolveLanguage(explicitLang ?? "english")
            return .pocket(voiceName: pocketMatch.id, isCloned: false, language: lang)
        }
        
        // 4. Otherwise default to Kokoro (54 built-in voices)
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
