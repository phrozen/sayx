import Foundation
import FluidAudio

/// Entrypoint for the `sayx` command-line utility.
///
/// Follows the Principle of Least Astonishment (POLA) and Separation of Concerns (SoC).
/// Delegates argument parsing, voice resolution, engine synthesis, and daemon IPC
/// to their respective modular components.
@main
struct SayX {
    
    static func main() async {
        let rawArguments = Array(CommandLine.arguments.dropFirst())
        let command = CLIParser.parse(arguments: rawArguments)
        
        do {
            switch command {
            case .help:
                HelpFormatter.printHelp()
                
            case .version:
                print("sayx \(HelpFormatter.version)")
                
            case .voiceList:
                HelpFormatter.printVoiceList()
                
            case .voiceDelete(let name):
                try VoicePreset.delete(named: name)
                print("Voice preset '\(name)' deleted.")
                
            case .test:
                TestRunner.runAll()
                
            case .voiceClone(let opts):
                try await VoiceCloner.cloneVoice(
                    audioPath: opts.audioPath,
                    name: opts.name,
                    rawLanguage: opts.language
                )
                
            case .listen(let opts):
                try await runListenDaemon(opts)
                
            case .tts(let opts):
                try await runTTS(opts)
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
    
    // MARK: - Subcommand Runners
    
    private static func runListenDaemon(_ opts: ListenOptions) async throws {
        let effectiveVoice = opts.defaultVoice ?? (opts.engine?.lowercased() == "pocket" ? "alba" : "heart")
        let dispatcher = EngineDispatcher(
            defaultVoice: effectiveVoice,
            explicitEngine: opts.engine
        )
        
        let server = SocketServer(
            socketPath: opts.socketPath,
            dispatcher: dispatcher,
            defaultVoice: effectiveVoice,
            teePath: opts.teePath,
            speed: opts.speed,
            pitch: opts.pitch
        )
        
        // Handle SIGINT cleanly
        signal(SIGINT) { _ in
            print("\nShutting down sayx daemon...")
            exit(0)
        }
        
        try await server.start()
    }
    
    private static func runTTS(_ opts: TTSOptions) async throws {
        let effectiveVoice = opts.rawVoice ?? (opts.engine?.lowercased() == "pocket" ? "alba" : "heart")
        let dispatcher = EngineDispatcher(
            defaultVoice: effectiveVoice,
            explicitEngine: opts.engine,
            explicitLang: opts.language
        )
        
        // Mode 1: Phonemizer only
        if opts.phonemesOnly {
            let phonemes = try await dispatcher.phonemes(for: opts.text)
            print(phonemes)
            return
        }
        
        if opts.showPhonemes {
            if let phonemes = try? await dispatcher.phonemes(for: opts.text) {
                print("Phonemes: \(phonemes)")
            }
        }
        
        let langHint = SentenceSplitter.resolveLanguage(code: opts.language)
        let sentences = SentenceSplitter.split(opts.text, language: langHint)
        var currentVoice = effectiveVoice
        
        if let outPath = opts.outputPath {
            // File Export Mode (-o)
            var allSamples: [Float] = []
            for rawSentence in sentences {
                let (tagVoice, sentence) = SentenceSplitter.extractVoiceTag(from: rawSentence)
                if let tag = tagVoice {
                    currentVoice = tag
                }
                guard !sentence.isEmpty else { continue }
                
                let samples: [Float]
                if opts.fromPhonemes {
                    samples = try await dispatcher.synthesizeFromPhonemes(sentence, voice: currentVoice)
                } else {
                    samples = try await dispatcher.synthesize(text: sentence, voice: currentVoice)
                }
                allSamples.append(contentsOf: samples)
            }
            
            var finalSamples = allSamples
            if abs(opts.speed - 1.0) > 1e-4 || abs(opts.pitch) > 1e-4 {
                finalSamples = try AudioEffects.applyTimePitch(
                    samples: allSamples,
                    sampleRate: Double(dispatcher.sampleRate),
                    speed: opts.speed,
                    pitch: opts.pitch
                )
            }
            
            let outURL = try WavWriter.write(
                samples: finalSamples,
                sampleRate: Double(dispatcher.sampleRate),
                toPath: outPath
            )
            print("Audio written to: \(outURL.path)")
            
        } else {
            // Live Hardware Speaker Streaming
            let streamer = try AudioStreamer(
                sampleRate: Double(dispatcher.sampleRate),
                speed: opts.speed,
                pitch: opts.pitch
            )
            
            for rawSentence in sentences {
                let (tagVoice, sentence) = SentenceSplitter.extractVoiceTag(from: rawSentence)
                if let tag = tagVoice {
                    currentVoice = tag
                }
                guard !sentence.isEmpty else { continue }
                
                while streamer.inFlightBuffers >= 6 {
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
                
                let samples: [Float]
                if opts.fromPhonemes {
                    samples = try await dispatcher.synthesizeFromPhonemes(sentence, voice: currentVoice)
                } else {
                    samples = try await dispatcher.synthesize(text: sentence, voice: currentVoice)
                }
                streamer.playChunk(samples: samples)
            }
            
            streamer.finishAndAwaitCompletion()
        }
    }
}
