import Foundation

/// Structured telemetry event emitted back over the Unix Domain Socket to pacing clients.
public struct TelemetryEvent: Codable, Sendable {
    public let event: String            // "buffer_update", "sentence_start", "sentence_done", "idle"
    public let queuedSeconds: Double    // Duration of audio currently queued in the hardware buffer
    public let state: String            // "playing", "idle"
    public let voice: String?
    public let text: String?
    public let timestamp: Double
    
    public init(
        event: String,
        queuedSeconds: Double,
        state: String,
        voice: String? = nil,
        text: String? = nil
    ) {
        self.event = event
        self.queuedSeconds = (queuedSeconds * 100).rounded() / 100 // 2 decimal places
        self.state = state
        self.voice = voice
        self.text = text
        self.timestamp = Date().timeIntervalSince1970
    }
    
    /// Serializes event as a single-line JSON string ending with a newline
    public func toJSONLine() -> String {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self),
           let json = String(data: data, encoding: .utf8) {
            return json + "\n"
        }
        return "{\"event\":\"\(event)\",\"queuedSeconds\":\(queuedSeconds),\"state\":\"\(state)\"}\n"
    }
}
