import Foundation
import Darwin

/// Non-blocking Unix Domain Socket (`AF_UNIX`) server enabling real-time streaming IPC with `sayx`.
///
/// External clients, background processes, or scripts can connect to `/tmp/sayx.sock`
/// and stream text into `sayx`. `SocketServer` synthesizes speech continuously through CoreAudio
/// and writes JSON telemetry events (`buffer_update`) back over the socket for precise buffer pacing.
public final class SocketServer: @unchecked Sendable {
    
    private let socketPath: String
    private let dispatcher: EngineDispatcher
    private let defaultVoice: String
    private let teePath: String?
    private let speed: Float
    private let pitch: Float
    
    private var isRunning = false
    private var serverFd: Int32 = -1
    private var collectedTeeSamples: [Float] = []
    private let teeLock = NSLock()
    
    public init(
        socketPath: String = "/tmp/sayx.sock",
        dispatcher: EngineDispatcher,
        defaultVoice: String = "heart",
        teePath: String? = nil,
        speed: Float = 1.0,
        pitch: Float = 0.0
    ) {
        self.socketPath = socketPath
        self.dispatcher = dispatcher
        self.defaultVoice = defaultVoice
        self.teePath = teePath
        self.speed = speed
        self.pitch = pitch
    }
    
    /// Starts the socket server and blocks the current task, serving incoming client connections.
    public func start() async throws {
        // 1. Clean up stale socket file if it already exists
        unlink(socketPath)
        
        // 2. Create AF_UNIX stream socket
        serverFd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverFd >= 0 else {
            throw NSError(domain: "SocketServer", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to create socket: \(String(cString: strerror(errno)))"])
        }
        
        // 3. Bind address
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        
        let pathBytes = socketPath.utf8CString
        guard pathBytes.count <= MemoryLayout.size(ofValue: addr.sun_path) else {
            throw NSError(domain: "SocketServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Socket path is too long: \(socketPath)"])
        }
        
        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: pathBytes.count) { dest in
                _ = pathBytes.withUnsafeBufferPointer { src in
                    memcpy(dest, src.baseAddress!, pathBytes.count)
                }
            }
        }
        
        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                Darwin.bind(serverFd, saPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        guard bindResult == 0 else {
            throw NSError(domain: "SocketServer", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to bind socket at \(socketPath): \(String(cString: strerror(errno)))"])
        }
        
        // 4. Start listening
        guard Darwin.listen(serverFd, 5) == 0 else {
            throw NSError(domain: "SocketServer", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to listen on socket: \(String(cString: strerror(errno)))"])
        }
        
        print("sayx daemon listening on: \(socketPath)")
        if let tee = teePath {
            print("Master audio recording enabled: \(tee)")
        }
        print("Ready for streaming connections. Press Ctrl+C to stop.")
        
        // 5. Initialize default engine and audio streamer
        try await dispatcher.initializeDefault()
        
        let streamer = try AudioStreamer(
            sampleRate: Double(dispatcher.sampleRate),
            speed: speed,
            pitch: pitch
        ) { [weak self] samples in
            guard let self = self, self.teePath != nil else { return }
            self.teeLock.lock()
            self.collectedTeeSamples.append(contentsOf: samples)
            self.teeLock.unlock()
        }
        
        isRunning = true
        
        // 6. Main accept loop
        while isRunning {
            var clientAddr = sockaddr_un()
            var clientAddrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
            
            let clientFd = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                    Darwin.accept(serverFd, saPtr, &clientAddrLen)
                }
            }
            
            if clientFd < 0 {
                if !isRunning { break }
                continue
            }
            
            // Handle client session
            await handleClient(fd: clientFd, streamer: streamer)
        }
        
        streamer.stop()
        
        // Write master recording if requested
        if let tee = teePath, !collectedTeeSamples.isEmpty {
            var finalSamples = collectedTeeSamples
            if abs(speed - 1.0) > 1e-4 || abs(pitch) > 1e-4 {
                finalSamples = (try? AudioEffects.applyTimePitch(
                    samples: collectedTeeSamples,
                    sampleRate: Double(dispatcher.sampleRate),
                    speed: speed,
                    pitch: pitch
                )) ?? collectedTeeSamples
            }
            _ = try? WavWriter.write(
                samples: finalSamples,
                sampleRate: Double(dispatcher.sampleRate),
                toPath: tee
            )
            print("Master recording saved to: \(tee)")
        }
        
        unlink(socketPath)
    }
    
    private func handleClient(fd: Int32, streamer: AudioStreamer) async {
        defer { Darwin.close(fd) }
        
        sendTelemetry(
            to: fd,
            event: "connected",
            queuedSeconds: streamer.queuedSeconds,
            state: streamer.isPlaying ? "playing" : "idle"
        )
        
        var buffer = [UInt8](repeating: 0, count: 4096)
        var pendingString = ""
        var activeVoice = defaultVoice
        
        while isRunning {
            let bytesRead = Darwin.read(fd, &buffer, buffer.count)
            if bytesRead <= 0 {
                // Client disconnected
                break
            }
            
            if let chunk = String(bytes: buffer[0..<bytesRead], encoding: .utf8) {
                pendingString += chunk
                
                // Process line-by-line
                while let newlineIndex = pendingString.firstIndex(of: "\n") {
                    let line = String(pendingString[..<newlineIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                    pendingString.removeSubrange(...newlineIndex)
                    
                    if !line.isEmpty {
                        await processLine(line, activeVoice: &activeVoice, streamer: streamer, clientFd: fd)
                    }
                }
            }
        }
        
        sendTelemetry(
            to: fd,
            event: "idle",
            queuedSeconds: streamer.queuedSeconds,
            state: streamer.isPlaying ? "playing" : "idle"
        )
    }
    
    private func processLine(
        _ line: String,
        activeVoice: inout String,
        streamer: AudioStreamer,
        clientFd: Int32
    ) async {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let sentences = SentenceSplitter.split(trimmed)
        
        for rawSentence in sentences {
            // Check for voice tag in this specific sentence chunk (e.g. [v:bella])
            let (tagVoice, cleanSentence) = SentenceSplitter.extractVoiceTag(from: rawSentence)
            if let tag = tagVoice {
                activeVoice = tag
            }
            
            guard !cleanSentence.isEmpty else { continue }
            
            // Backpressure: pause if more than ~6 buffers (~25s) are queued
            while streamer.inFlightBuffers >= 6 {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            
            sendTelemetry(
                to: clientFd,
                event: "sentence_start",
                queuedSeconds: streamer.queuedSeconds,
                state: "playing",
                voice: activeVoice,
                text: cleanSentence
            )
            
            if let samples = try? await dispatcher.synthesize(text: cleanSentence, voice: activeVoice) {
                streamer.playChunk(samples: samples)
            }
            
            sendTelemetry(
                to: clientFd,
                event: "buffer_update",
                queuedSeconds: streamer.queuedSeconds,
                state: "playing",
                voice: activeVoice
            )
        }
    }
    
    private func sendTelemetry(
        to fd: Int32,
        event: String,
        queuedSeconds: Double,
        state: String,
        voice: String? = nil,
        text: String? = nil
    ) {
        let telemetry = TelemetryEvent(
            event: event,
            queuedSeconds: queuedSeconds,
            state: state,
            voice: voice,
            text: text
        )
        let jsonLine = telemetry.toJSONLine()
        jsonLine.withCString { ptr in
            _ = Darwin.write(fd, ptr, strlen(ptr))
        }
    }
    
    public func stop() {
        isRunning = false
        if serverFd >= 0 {
            Darwin.close(serverFd)
            serverFd = -1
        }
        unlink(socketPath)
    }
}
