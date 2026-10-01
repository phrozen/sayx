import Foundation
import FluidAudio

/// Orchestrates on-device voice cloning from reference audio files using the PocketTTS Mimi encoder.
public enum VoiceCloner {
    
    /// Maps user language strings ("en", "es", "spanish", "english") to PocketTtsLanguage enum.
    public static func resolveLanguage(_ raw: String) -> PocketTtsLanguage {
        switch raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "es", "es-mx", "es-es", "spanish":
            return .spanish
        case "fr", "french":
            return .french24L
        case "de", "german":
            return .german
        case "it", "italian":
            return .italian
        case "pt", "pt-br", "portuguese":
            return .portuguese
        default:
            return .english
        }
    }
    
    /// Clones a voice from a reference audio file and saves the preset to disk.
    ///
    /// - Parameters:
    ///   - audioPath: Path to input audio file (WAV, MP3, M4A, etc.).
    ///   - name: Custom voice preset name (e.g. "brooke", "carlos").
    ///   - rawLanguage: Language code (e.g. "en", "es").
    public static func cloneVoice(
        audioPath: String,
        name: String,
        rawLanguage: String = "english"
    ) async throws {
        let expandedPath = (audioPath as NSString).expandingTildeInPath
        let audioURL = URL(fileURLWithPath: expandedPath)
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw NSError(
                domain: "VoiceCloner",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Audio sample file not found at: \(audioURL.path)"]
            )
        }
        
        let sanitizedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedName.isEmpty else {
            throw NSError(
                domain: "VoiceCloner",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Voice name cannot be empty"]
            )
        }
        
        let language = resolveLanguage(rawLanguage)
        print("Cloning voice '\(sanitizedName)' from \(audioURL.lastPathComponent)...")
        print("  Engine: PocketTTS (Mimi Neural Audio Codec)")
        print("  Target Language: \(language.rawValue)")
        
        // Normalize reference audio to standard broadcast loudness before encoding
        let tempDir = FileManager.default.temporaryDirectory
        let normalizedURL = tempDir.appendingPathComponent("sayx_ref_\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: normalizedURL) }
        
        try AudioNormalizer.normalizeAudioFile(at: audioURL, to: normalizedURL)
        
        // Initialize PocketTTS engine for cloning
        let engine = PocketEngine(language: language)
        let voiceData = try await engine.cloneVoice(from: normalizedURL)
        
        // Save preset to ~/.cache/sayx/voices/<name>/
        try VoicePreset.savePocketVoice(
            name: sanitizedName,
            voiceData: voiceData,
            language: language.rawValue,
            sourcePath: audioURL.path
        )
        
        let presetDir = VoicePreset.directory(for: sanitizedName)
        print("Voice preset '\(sanitizedName)' created successfully.")
        print("  Saved to: \(presetDir.path)")
        print("  Usage: sayx -v \(sanitizedName) \"Hello from cloned voice!\"")
    }
}
