import Foundation
import FluidAudio

/// Metadata record stored in `voice.json` for custom cloned voice presets.
public struct VoiceMetadata: Codable, Sendable {
    public let name: String
    public let engine: String         // e.g. "pocket"
    public let language: String       // e.g. "english", "spanish"
    public let createdAt: String
    public let sourceFile: String?
    
    public init(name: String, engine: String, language: String, createdAt: String, sourceFile: String? = nil) {
        self.name = name
        self.engine = engine
        self.language = language
        self.createdAt = createdAt
        self.sourceFile = sourceFile
    }
}

/// Manages persistence, discovery, and loading of custom voice presets stored in `~/.cache/sayx/voices/`.
public enum VoicePreset {
    
    /// Root directory for all custom cloned voices: `~/.cache/sayx/voices/`
    public static var voicesDirectory: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".cache/sayx/voices", isDirectory: true)
    }
    
    /// Returns the directory URL for a specific named voice preset
    public static func directory(for voiceName: String) -> URL {
        return voicesDirectory.appendingPathComponent(voiceName.lowercased(), isDirectory: true)
    }
    
    /// Checks if a cloned voice preset with the given name exists on disk
    public static func exists(named voiceName: String) -> Bool {
        let dir = directory(for: voiceName)
        let binFile = dir.appendingPathComponent("pocket_voice.bin")
        if FileManager.default.fileExists(atPath: binFile.path) {
            return true
        }
        return findSupertonicStyle(named: voiceName) != nil
    }
    
    /// Searches for a custom Supertonic style JSON in `~/.cache/sayx/voices/<name>/style.json` or `<name>.json`
    public static func findSupertonicStyle(named voiceName: String) -> URL? {
        let dir = directory(for: voiceName)
        let styleInDir = dir.appendingPathComponent("style.json")
        if FileManager.default.fileExists(atPath: styleInDir.path) {
            return styleInDir
        }
        let styleDirect = voicesDirectory.appendingPathComponent("\(voiceName.lowercased()).json")
        if FileManager.default.fileExists(atPath: styleDirect.path) {
            return styleDirect
        }
        return nil
    }
    
    /// Loads a saved PocketTTS voice conditioning preset from disk, if available.
    public static func loadPocketVoice(named voiceName: String) -> PocketTtsVoiceData? {
        let dir = directory(for: voiceName)
        let binFile = dir.appendingPathComponent("pocket_voice.bin")
        guard FileManager.default.fileExists(atPath: binFile.path) else { return nil }
        
        do {
            return try PocketTtsVoiceCloner.loadVoice(from: binFile)
        } catch {
            fputs("Warning: Failed to load cloned voice '\(voiceName)': \(error.localizedDescription)\n", stderr)
            return nil
        }
    }
    
    /// Saves a newly cloned PocketTTS voice profile and metadata to `~/.cache/sayx/voices/<name>/`
    public static func savePocketVoice(
        name: String,
        voiceData: PocketTtsVoiceData,
        language: String = "english",
        sourcePath: String? = nil
    ) throws {
        let dir = directory(for: name)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        
        // 1. Save binary voice conditioning embedding
        let binFile = dir.appendingPathComponent("pocket_voice.bin")
        try PocketTtsVoiceCloner.saveVoice(voiceData, to: binFile)
        
        // 2. Save metadata JSON
        let isoFormatter = ISO8601DateFormatter()
        let metadata = VoiceMetadata(
            name: name.lowercased(),
            engine: "pocket",
            language: language,
            createdAt: isoFormatter.string(from: Date()),
            sourceFile: sourcePath
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(metadata)
        let jsonFile = dir.appendingPathComponent("voice.json")
        try jsonData.write(to: jsonFile)
    }
    
    /// Lists all installed custom voice presets
    public static func listPresets() -> [VoiceMetadata] {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: voicesDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }
        
        var results: [VoiceMetadata] = []
        let decoder = JSONDecoder()
        
        for item in items {
            let jsonFile = item.appendingPathComponent("voice.json")
            let styleFile = item.appendingPathComponent("style.json")
            if let data = try? Data(contentsOf: jsonFile),
               let meta = try? decoder.decode(VoiceMetadata.self, from: data) {
                results.append(meta)
            } else if FileManager.default.fileExists(atPath: styleFile.path) {
                results.append(VoiceMetadata(
                    name: item.lastPathComponent,
                    engine: "supertonic",
                    language: "31 langs",
                    createdAt: "local style"
                ))
            } else if item.pathExtension == "json" && item.lastPathComponent != "voice.json" {
                let name = item.deletingPathExtension().lastPathComponent
                results.append(VoiceMetadata(
                    name: name,
                    engine: "supertonic",
                    language: "31 langs",
                    createdAt: "local style"
                ))
            } else if exists(named: item.lastPathComponent) {
                // Fallback if voice.json is missing
                results.append(VoiceMetadata(
                    name: item.lastPathComponent,
                    engine: "pocket",
                    language: "unknown",
                    createdAt: "unknown"
                ))
            }
        }
        
        return results.sorted { $0.name < $1.name }
    }
    
    /// Deletes a voice preset from disk
    public static func delete(named voiceName: String) throws {
        let dir = directory(for: voiceName)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }
}
