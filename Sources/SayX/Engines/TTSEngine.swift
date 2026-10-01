import Foundation

/// Common abstraction for speech synthesis backends in sayx.
///
/// Any TTS model (Kokoro on ANE, PocketTTS on FlowLM+Mimi, Chatterbox on Metal)
/// conforms to this protocol so `sayx` can switch engines without modifying
/// the audio streaming, file writing, or socket server layers.
public protocol TTSEngine: Sendable {
    
    /// Unique engine identifier: e.g. "kokoro", "pocket"
    var id: String { get }
    
    /// Native audio output sample rate in Hz (e.g. 24,000)
    var sampleRate: Int { get }
    
    /// Preload model weights and initialize CoreML hardware compute graphs
    func initialize() async throws
    
    /// Synthesize speech from text using the specified canonical voice name or preset
    func synthesize(text: String, voice: String) async throws -> [Float]
}
