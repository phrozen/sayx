import Foundation
import Accelerate
import NaturalLanguage

/// Built-in unit test runner executing diagnostic tests for sayx core modules.
///
/// Can be invoked directly via `sayx test`.
public enum TestRunner {
    
    private final class Results {
        var passed = 0
        var failed = 0
        
        func check(_ condition: Bool, _ name: String) {
            if condition {
                print("  [PASS] \(name)")
                passed += 1
            } else {
                print("  [FAIL] \(name)")
                failed += 1
            }
        }
    }
    
    public static func runAll() {
        print("Running sayx built-in test suite...\n")
        let results = Results()
        
        testAudioNormalizer(results: results)
        testAudioEffects(results: results)
        testSentenceSplitter(results: results)
        testVoiceRegistry(results: results)
        
        print("\n" + String(repeating: "=", count: 50))
        if results.failed == 0 {
            print("All \(results.passed) tests passed successfully.")
        } else {
            print("FAILED: \(results.failed) test(s) failed, \(results.passed) passed.")
            exit(1)
        }
    }
    
    // MARK: - Test Suites
    
    private static func testAudioNormalizer(results: Results) {
        print("Suite: AudioNormalizer (Accelerate vDSP SIMD)")
        
        // 1. Quiet audio
        var quietSamples: [Float] = [0.0, 0.05, 0.10, 0.05, 0.0, -0.05, -0.10, -0.05]
        let targetPeak: Float = 0.891
        AudioNormalizer.peakNormalize(&quietSamples, targetPeak: targetPeak)
        var maxMag: Float = 0
        vDSP_maxmgv(quietSamples, 1, &maxMag, vDSP_Length(quietSamples.count))
        results.check(abs(maxMag - targetPeak) < 1e-4, "Peak normalizes quiet audio to target ceiling")
        
        // 2. Hot audio
        var hotSamples: [Float] = [0.0, 0.75, 1.50, 0.75, 0.0, -0.75, -1.50, -0.75]
        AudioNormalizer.peakNormalize(&hotSamples, targetPeak: targetPeak)
        vDSP_maxmgv(hotSamples, 1, &maxMag, vDSP_Length(hotSamples.count))
        results.check(abs(maxMag - targetPeak) < 1e-4 && maxMag <= 0.892, "Peak normalizes hot audio down to target ceiling")
        
        // 3. Silence
        var silence: [Float] = [0.0, 0.0, 0.0, 0.0]
        AudioNormalizer.peakNormalize(&silence)
        let silenceValid = silence.allSatisfy { !$0.isNaN && !$0.isInfinite && $0 == 0.0 }
        results.check(silenceValid, "Gracefully handles silence without NaN or crash")
        
        // 4. RMS with peak ceiling
        var impulse: [Float] = [0.01, 0.01, 0.01, 0.90, 0.01, 0.01, -0.90, 0.01]
        let ceiling: Float = 0.94
        AudioNormalizer.rmsNormalize(&impulse, targetRMS: 0.20, peakCeiling: ceiling)
        vDSP_maxmgv(impulse, 1, &maxMag, vDSP_Length(impulse.count))
        results.check(maxMag <= ceiling + 1e-4, "RMS normalization respects peak limiter ceiling")
    }
    
    private static func testAudioEffects(results: Results) {
        print("\nSuite: AudioEffects (AVAudioUnitTimePitch DSP)")
        
        // 1. Fast path: speed = 1.0, pitch = 0.0 returns identical array without allocation
        let original: [Float] = [0.1, 0.2, 0.3, 0.4, 0.5]
        let unchanged = (try? AudioEffects.applyTimePitch(samples: original, speed: 1.0, pitch: 0.0)) ?? []
        results.check(unchanged == original, "Fast path preserves samples bit-identically at 1.0x speed and 0 pitch")
        
        // 2. Synthesize test sine wave (1 second at 24 kHz = 24,000 samples)
        let sampleCount = 24000
        var sineWave = [Float](repeating: 0, count: sampleCount)
        for i in 0..<sampleCount {
            sineWave[i] = sin(Float(i) * 2.0 * .pi * 440.0 / 24000.0) * 0.5
        }
        
        // 3. Time stretching: 2.0x speed should produce ~50% the number of samples
        if let faster = try? AudioEffects.applyTimePitch(samples: sineWave, sampleRate: 24000, speed: 2.0, pitch: 0.0) {
            let ratio = Double(faster.count) / Double(sineWave.count)
            results.check(ratio > 0.45 && ratio <= 0.65, "2.0x playback rate approximately halves sample count (ratio: \(String(format: "%.2f", ratio)))")
        } else {
            results.check(false, "2.0x playback rate renders successfully")
        }
        
        // 4. Time stretching: 0.5x speed should produce ~200% the number of samples
        if let slower = try? AudioEffects.applyTimePitch(samples: sineWave, sampleRate: 24000, speed: 0.5, pitch: 0.0) {
            let ratio = Double(slower.count) / Double(sineWave.count)
            results.check(ratio > 1.80 && ratio < 2.25, "0.5x playback rate approximately doubles sample count (ratio: \(String(format: "%.2f", ratio)))")
        } else {
            results.check(false, "0.5x playback rate renders successfully")
        }
        
        // 5. Pitch shifting: +400 cents (major third)
        if let pitchShifted = try? AudioEffects.applyTimePitch(samples: sineWave, sampleRate: 24000, speed: 1.0, pitch: 400.0) {
            let noNaNs = pitchShifted.allSatisfy { !$0.isNaN && !$0.isInfinite }
            results.check(!pitchShifted.isEmpty && noNaNs, "+400 cents pitch shift renders valid audio without NaNs")
        } else {
            results.check(false, "Pitch shift renders successfully")
        }
        
        // 6. AudioStreamer queuedSeconds speed scaling
        if let streamer = try? AudioStreamer(sampleRate: 24000, speed: 2.0, pitch: 0.0) {
            results.check(streamer.speed == 2.0 && streamer.pitch == 0.0, "AudioStreamer initializes with custom speed and pitch")
            streamer.stop()
        } else {
            results.check(false, "AudioStreamer initializes with custom speed and pitch")
        }
    }
    
    private static func testSentenceSplitter(results: Results) {
        print("\nSuite: SentenceSplitter (Apple NaturalLanguage NLTokenizer)")
        
        // 1. Abbreviations & currency
        let text1 = "Dr. Watson met Mr. Sherlock Holmes at 221B Baker St. in London. They arrived at 8:30 a.m. sharp for the $3.50 tea."
        let sentences1 = SentenceSplitter.split(text1)
        results.check(sentences1.count == 2 && sentences1[0].contains("Dr. Watson") && sentences1[1].contains("$3.50"),
                      "Does not split on common English abbreviations and currency")
        
        // 2. Voice tags
        let text2 = "[v:adam] Hello world. [v:bella] How are you? Are you well? [v:adam] Doing fine."
        let sentences2 = SentenceSplitter.split(text2)
        let (v0, t0) = SentenceSplitter.extractVoiceTag(from: sentences2.first ?? "")
        let (v1, t1) = SentenceSplitter.extractVoiceTag(from: sentences2.count > 1 ? sentences2[1] : "")
        let (v2, _) = SentenceSplitter.extractVoiceTag(from: sentences2.count > 2 ? sentences2[2] : "")
        let (v3, t3) = SentenceSplitter.extractVoiceTag(from: sentences2.count > 3 ? sentences2[3] : "")
        
        let tagsCorrect = sentences2.count == 4 && v0 == "adam" && t0 == "Hello world." &&
                          v1 == "bella" && t1 == "How are you?" && v2 == nil &&
                          v3 == "adam" && t3 == "Doing fine."
        results.check(tagsCorrect, "Correctly extracts voice tags and isolates speaker turns")
        
        // 3. Spanish abbreviations
        let text3 = "¿Cómo estás, amigo? El Sr. Pérez dijo que vendría hoy. ¡Qué buena noticia!"
        let sentences3 = SentenceSplitter.split(text3, language: .spanish)
        results.check(sentences3.count == 3 && sentences3[1].contains("El Sr. Pérez"),
                      "Protects Spanish abbreviations when Spanish language hint is provided")
        
        // 4. Japanese full-width punctuation
        let text4 = "吾輩は猫である。名前はまだ無い。どこで生れたかとんと見当がつかぬ。"
        let sentences4 = SentenceSplitter.split(text4, language: .japanese)
        results.check(sentences4.count == 3, "Splits Japanese full-width punctuation naturally")
    }
    
    private static func testVoiceRegistry(results: Results) {
        print("\nSuite: VoiceRegistry (Resolution & Defaulting)")
        
        // 1. Kokoro
        let resHeart = VoiceRegistry.resolve(query: "heart")
        if case .kokoro(let canonical, _) = resHeart {
            results.check(canonical == "af_heart", "Resolves Kokoro 'heart' alias to 'af_heart'")
        } else {
            results.check(false, "Resolves Kokoro 'heart' alias")
        }
        
        let resAdam = VoiceRegistry.resolve(query: "adam")
        if case .kokoro(let canonical, _) = resAdam {
            results.check(canonical == "am_adam", "Resolves Kokoro 'adam' alias to 'am_adam'")
        } else {
            results.check(false, "Resolves Kokoro 'adam' alias")
        }
        
        // 2. PocketTTS Studio Voices
        let resJavert = VoiceRegistry.resolve(query: "javert")
        if case .pocket(let voice, let isCloned, _) = resJavert {
            results.check(voice == "javert" && !isCloned, "Resolves PocketTTS studio voice 'javert'")
        } else {
            results.check(false, "Resolves PocketTTS studio voice 'javert'")
        }
        
        let resCosette = VoiceRegistry.resolve(query: "cosette")
        if case .pocket(let voice, _, _) = resCosette {
            results.check(voice == "cosette", "Resolves PocketTTS studio voice 'cosette'")
        } else {
            results.check(false, "Resolves PocketTTS studio voice 'cosette'")
        }
        
        // 3. Engine Defaulting
        let resEmpty = VoiceRegistry.resolve(query: "", explicitEngine: "pocket")
        if case .pocket(let voice, _, _) = resEmpty {
            results.check(voice == "alba", "Defaults to 'alba' when pocket engine is selected without explicit voice")
        } else {
            results.check(false, "Defaults to 'alba' for pocket engine")
        }
        
        let resPocketHeart = VoiceRegistry.resolve(query: "heart", explicitEngine: "pocket")
        if case .pocket(let voice, _, _) = resPocketHeart {
            results.check(voice == "alba", "Normalizes default 'heart' to 'alba' when explicit engine is pocket")
        } else {
            results.check(false, "Normalizes default voice for pocket engine")
        }
    }
}
