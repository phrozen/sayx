import Foundation
import Testing
@testable import SayXCore

@Suite("Socket IPC Integration Tests", .serialized)
struct SocketIPCIntegrationTests {
    
    @Test("Starts Unix domain socket server and exchanges telemetry frames with client")
    func testSocketServerIPC() async throws {
        signal(SIGPIPE, SIG_IGN)
        
        let socketPath = "/tmp/sayx_test_ipc_\(UUID().uuidString.prefix(8)).sock"
        let dispatcher = EngineDispatcher(defaultVoice: "heart", steps: 3)
        let server = SocketServer(socketPath: socketPath, dispatcher: dispatcher)
        
        let serverTask = Task {
            try await server.start()
        }
        
        // Wait for socket to bind and start listening
        var connected = false
        var clientFd: Int32 = -1
        for _ in 0..<50 {
            try await Task.sleep(nanoseconds: 50_000_000)
            if FileManager.default.fileExists(atPath: socketPath) {
                clientFd = socket(AF_UNIX, SOCK_STREAM, 0)
                if clientFd >= 0 {
                    var nosigpipe: Int32 = 1
                    setsockopt(clientFd, SOL_SOCKET, SO_NOSIGPIPE, &nosigpipe, socklen_t(MemoryLayout<Int32>.size))
                    
                    var addr = sockaddr_un()
                    addr.sun_family = sa_family_t(AF_UNIX)
                    let pathBytes = socketPath.utf8CString
                    withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
                        ptr.withMemoryRebound(to: CChar.self, capacity: pathBytes.count) { dest in
                            _ = pathBytes.withUnsafeBufferPointer { src in
                                memcpy(dest, src.baseAddress!, pathBytes.count)
                            }
                        }
                    }
                    let res = withUnsafePointer(to: &addr) { ptr in
                        ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                            Darwin.connect(clientFd, saPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
                        }
                    }
                    if res == 0 {
                        connected = true
                        break
                    } else {
                        Darwin.close(clientFd)
                        clientFd = -1
                    }
                }
            }
        }
        
        #expect(connected, "Client should successfully connect to /tmp/sayx_test_ipc.sock")
        
        if connected && clientFd >= 0 {
            // Read initial telemetry
            var buf = [UInt8](repeating: 0, count: 1024)
            let readBytes = Darwin.read(clientFd, &buf, buf.count)
            #expect(readBytes > 0)
            if readBytes > 0, let received = String(bytes: buf[0..<readBytes], encoding: .utf8) {
                #expect(received.contains("\"event\":\"connected\""))
            }
            
            Darwin.shutdown(clientFd, SHUT_RDWR)
            Darwin.close(clientFd)
        }
        
        server.stop()
        serverTask.cancel()
    }
}
