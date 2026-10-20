import Foundation
import Testing
@testable import SayXCore

@Suite("TelemetryEvent Unit Tests")
struct TelemetryEventTests {
    
    @Test("Serializes to valid single-line JSON ending with newline")
    func testTelemetryJSONSerialization() throws {
        let event = TelemetryEvent(
            event: "sentence_start",
            queuedSeconds: 3.14159,
            state: "playing",
            voice: "m1",
            text: "Hello testing"
        )
        
        let line = event.toJSONLine()
        #expect(line.hasSuffix("\n"))
        
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let data = Data(trimmed.utf8)
        let decoded = try JSONDecoder().decode(TelemetryEvent.self, from: data)
        
        #expect(decoded.event == "sentence_start")
        #expect(decoded.state == "playing")
        #expect(decoded.voice == "m1")
        #expect(decoded.text == "Hello testing")
        #expect(decoded.queuedSeconds == 3.14) // Rounded to 2 decimal places
    }
}
