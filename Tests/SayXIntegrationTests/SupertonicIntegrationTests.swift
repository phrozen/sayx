import Foundation
import Testing
@testable import SayXCore

@Suite("Supertonic ANE Integration Tests", .serialized)
struct SupertonicIntegrationTests {
    
    @Test("Synthesizes 44.1 kHz studio speech via Supertonic-3 on ANE")
    func testSupertonicSynthesis() async throws {
        let engine = SupertonicEngine(defaultVoice: "m1", defaultLanguage: "en", defaultSteps: 3)
        try await engine.initialize()
        
        let samples = try await engine.synthesize(text: "Supertonic studio audio hardware test.", voice: "m1")
        
        #expect(!samples.isEmpty)
        #expect(engine.sampleRate == 44100)
        #expect(samples.count > 22050) // At least 0.5s of audio
        #expect(samples.contains { abs($0) > 0.01 }) // Non-silent
    }
    
    @Test("Synthesizes in Spanish with language override")
    func testSupertonicSpanishSynthesis() async throws {
        let engine = SupertonicEngine(defaultVoice: "m1", defaultLanguage: "en", defaultSteps: 3)
        try await engine.initialize()
        
        let samples = try await engine.synthesize(
            text: "Hola mundo, prueba de audio.",
            voice: "m1",
            language: "es",
            steps: 3
        )
        
        #expect(!samples.isEmpty)
        #expect(engine.sampleRate == 44100)
        #expect(samples.contains { abs($0) > 0.01 })
    }
}
