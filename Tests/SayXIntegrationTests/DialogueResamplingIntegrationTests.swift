import Foundation
import Testing
@testable import SayXCore

@Suite("Dialogue Resampling Integration Tests", .serialized)
struct DialogueResamplingIntegrationTests {
    
    @Test("Harmonizes mixed Kokoro (24k) and Supertonic (44.1k) in a single session")
    func testKokoroToSupertonicDialogue() async throws {
        let dispatcher = EngineDispatcher(defaultVoice: "heart", steps: 3)
        #expect(dispatcher.sampleRate == 24000)
        
        let chunk1 = try await dispatcher.synthesize(text: "Hello from Kokoro.", voice: "heart")
        let chunk2 = try await dispatcher.synthesize(text: "And reply from Supertonic.", voice: "m1")
        
        #expect(!chunk1.isEmpty)
        #expect(!chunk2.isEmpty)
        #expect(chunk1.contains { abs($0) > 0.01 })
        #expect(chunk2.contains { abs($0) > 0.01 })
    }
    
    @Test("Harmonizes mixed Supertonic (44.1k) and Kokoro (24k) when session begins with Supertonic")
    func testSupertonicToKokoroDialogue() async throws {
        let dispatcher = EngineDispatcher(defaultVoice: "m1", steps: 3)
        #expect(dispatcher.sampleRate == 44100)
        
        let chunk1 = try await dispatcher.synthesize(text: "Supertonic starts at forty-four kilohertz.", voice: "m1")
        let chunk2 = try await dispatcher.synthesize(text: "Kokoro resampled up.", voice: "heart")
        
        #expect(!chunk1.isEmpty)
        #expect(!chunk2.isEmpty)
        #expect(chunk1.contains { abs($0) > 0.01 })
        #expect(chunk2.contains { abs($0) > 0.01 })
    }
}
