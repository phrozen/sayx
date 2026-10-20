import Foundation
import Testing
@testable import SayXCore

@Suite("AudioEffects Unit Tests")
struct AudioEffectsTests {
    
    @Test("Fast path preserves samples bit-identically at 1.0x speed and 0 pitch")
    func testFastPath() throws {
        let original: [Float] = [0.1, 0.2, 0.3, 0.4, 0.5]
        let result = try AudioEffects.applyTimePitch(samples: original, speed: 1.0, pitch: 0.0)
        #expect(result == original)
    }
    
    @Test("2.0x playback rate approximately halves sample count")
    func testDoubleSpeed() throws {
        let sampleCount = 24000
        var sineWave = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            sineWave[i] = sin(Float(i) * 2.0 * .pi * 440.0 / 24000.0) * 0.5
        }
        
        let faster = try AudioEffects.applyTimePitch(samples: sineWave, sampleRate: 24000, speed: 2.0, pitch: 0.0)
        let ratio = Double(faster.count) / Double(sineWave.count)
        #expect(ratio > 0.45 && ratio <= 0.65)
    }
    
    @Test("0.5x playback rate approximately doubles sample count")
    func testHalfSpeed() throws {
        let sampleCount = 24000
        var sineWave = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            sineWave[i] = sin(Float(i) * 2.0 * .pi * 440.0 / 24000.0) * 0.5
        }
        
        let slower = try AudioEffects.applyTimePitch(samples: sineWave, sampleRate: 24000, speed: 0.5, pitch: 0.0)
        let ratio = Double(slower.count) / Double(sineWave.count)
        #expect(ratio > 1.80 && ratio < 2.25)
    }
    
    @Test("+400 cents pitch shift renders valid audio without NaNs")
    func testPitchShift() throws {
        let sampleCount = 24000
        var sineWave = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            sineWave[i] = sin(Float(i) * 2.0 * .pi * 440.0 / 24000.0) * 0.5
        }
        
        let pitchShifted = try AudioEffects.applyTimePitch(samples: sineWave, sampleRate: 24000, speed: 1.0, pitch: 400.0)
        #expect(!pitchShifted.isEmpty)
        #expect(pitchShifted.allSatisfy { !$0.isNaN && !$0.isInfinite })
    }
    
    @Test("AudioStreamer initializes with custom sample rate, speed, and pitch")
    func testAudioStreamerInit() throws {
        let streamer = try AudioStreamer(sampleRate: 24000, speed: 1.5, pitch: 200.0)
        #expect(streamer.sampleRate == 24000)
        #expect(streamer.speed == 1.5)
        #expect(streamer.pitch == 200.0)
        streamer.stop()
    }
}
