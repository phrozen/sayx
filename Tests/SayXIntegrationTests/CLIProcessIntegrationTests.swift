import Foundation
import Testing
@testable import SayXCore

@Suite("CLI Process Integration Tests", .serialized)
struct CLIProcessIntegrationTests {
    
    @Test("Executes full TTS pipeline via SayXRunner to output WAV file")
    func testSayXRunnerExportWav() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let outURL = tempDir.appendingPathComponent("cli_runner_test_\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: outURL) }
        
        let args = ["-v", "heart", "Runner integration test.", "-o", outURL.path]
        await SayXRunner.run(arguments: args)
        
        #expect(FileManager.default.fileExists(atPath: outURL.path))
        let data = try Data(contentsOf: outURL)
        #expect(data.count > 1000)
        
        let riff = String(data: data[0..<4], encoding: .ascii)
        #expect(riff == "RIFF")
    }
    
    @Test("Executes Supertonic-3 TTS pipeline via SayXRunner to 44.1 kHz WAV file")
    func testSayXRunnerSupertonicExport() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        let outURL = tempDir.appendingPathComponent("cli_supertonic_test_\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: outURL) }
        
        let args = ["-e", "supertonic", "-v", "m1", "--steps", "3", "Supertonic runner test.", "-o", outURL.path]
        await SayXRunner.run(arguments: args)
        
        #expect(FileManager.default.fileExists(atPath: outURL.path))
        let data = try Data(contentsOf: outURL)
        #expect(data.count > 1000)
        
        let sampleRate = data[24..<28].withUnsafeBytes { $0.load(as: UInt32.self) }
        #expect(sampleRate == 44100)
    }
}
