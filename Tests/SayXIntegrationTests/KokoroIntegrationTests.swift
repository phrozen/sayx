import Foundation
import Testing
@testable import SayXCore

@Suite("Kokoro ANE Integration Tests", .serialized)
struct KokoroIntegrationTests {
    
    @Test("Synthesizes speech on Apple Neural Engine via Kokoro-82M")
    func testKokoroSynthesis() async throws {
        let engine = KokoroEngine(defaultVoice: "af_heart", variant: .english)
        try await engine.initialize()
        
        let samples = try await engine.synthesize(text: "Kokoro Apple Neural Engine integration test.", voice: "af_heart")
        
        #expect(!samples.isEmpty)
        #expect(engine.sampleRate == 24000)
        #expect(samples.count > 12000) // At least 0.5s of audio
        #expect(samples.contains { abs($0) > 0.01 }) // Non-silent
    }
    
    @Test("Synthesizes directly from pre-computed IPA phonemes")
    func testKokoroPhonemesSynthesis() async throws {
        let engine = KokoroEngine(defaultVoice: "af_heart", variant: .english)
        try await engine.initialize()
        
        let phonemes = try await engine.phonemes(for: "Hello")
        #expect(!phonemes.isEmpty)
        
        let samples = try await engine.synthesizeFromPhonemes(phonemes, voice: "af_heart")
        #expect(!samples.isEmpty)
        #expect(samples.contains { abs($0) > 0.01 })
    }
}
