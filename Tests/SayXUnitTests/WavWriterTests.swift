import Foundation
import Testing
@testable import SayXCore

@Suite("WavWriter Unit Tests")
struct WavWriterTests {
    
    @Test("Writes valid 16-bit PCM WAV file with exact RIFF structure")
    func testWavHeaderAndByteSize() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let outURL = tempDir.appendingPathComponent("wav_writer_test_\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: outURL) }
        
        let sampleCount = 4800
        var samples = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            samples[i] = sin(Float(i) * 2.0 * .pi * 440.0 / 24000.0) * 0.75
        }
        
        _ = try WavWriter.write(samples: samples, sampleRate: 24000, toPath: outURL.path)
        
        let fileData = try Data(contentsOf: outURL)
        let expectedSize = 44 + (sampleCount * 2)
        #expect(fileData.count == expectedSize)
        
        // Validate RIFF header
        let riffHeader = String(data: fileData[0..<4], encoding: .ascii)
        let waveHeader = String(data: fileData[8..<12], encoding: .ascii)
        let fmtHeader = String(data: fileData[12..<16], encoding: .ascii)
        
        #expect(riffHeader == "RIFF")
        #expect(waveHeader == "WAVE")
        #expect(fmtHeader == "fmt ")
        
        // Validate sample rate bytes (offset 24, 4 bytes little-endian)
        let sampleRateBytes = fileData[24..<28].withUnsafeBytes { $0.load(as: UInt32.self) }
        #expect(sampleRateBytes == 24000)
    }
    
    @Test("Writes 44.1 kHz WAV file with correct header sample rate")
    func testWav44kSampleRate() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let outURL = tempDir.appendingPathComponent("wav_writer_44k_\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: outURL) }
        
        let samples: [Float] = [0.1, -0.1, 0.2, -0.2]
        _ = try WavWriter.write(samples: samples, sampleRate: 44100, toPath: outURL.path)
        
        let fileData = try Data(contentsOf: outURL)
        let sampleRateBytes = fileData[24..<28].withUnsafeBytes { $0.load(as: UInt32.self) }
        #expect(sampleRateBytes == 44100)
    }
}
