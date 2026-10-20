import Foundation
import Testing
@testable import SayXCore

@Suite("CLIArguments Unit Tests")
struct CLIArgumentsTests {
    
    @Test("Parses help and version flags")
    func testHelpAndVersion() {
        if case .help = CLIParser.parse(arguments: ["--help"]) {} else {
            Issue.record("Expected .help for --help")
        }
        if case .help = CLIParser.parse(arguments: ["-h"]) {} else {
            Issue.record("Expected .help for -h")
        }
        if case .version = CLIParser.parse(arguments: ["--version"]) {} else {
            Issue.record("Expected .version for --version")
        }
        if case .version = CLIParser.parse(arguments: ["-V"]) {} else {
            Issue.record("Expected .version for -V")
        }
    }
    
    @Test("Parses TTS command with full options")
    func testTTSCommandParsing() {
        let args = [
            "-v", "bella",
            "-s", "1.25",
            "--pitch", "150",
            "-e", "supertonic",
            "-l", "es",
            "--steps", "8",
            "-o", "/tmp/out.wav",
            "Hello", "world"
        ]
        
        let cmd = CLIParser.parse(arguments: args)
        if case .tts(let opts) = cmd {
            #expect(opts.text == "Hello world")
            #expect(opts.rawVoice == "bella")
            #expect(opts.speed == 1.25)
            #expect(opts.pitch == 150.0)
            #expect(opts.engine == "supertonic")
            #expect(opts.language == "es")
            #expect(opts.steps == 8)
            #expect(opts.outputPath == "/tmp/out.wav")
            #expect(!opts.phonemesOnly)
        } else {
            Issue.record("Expected .tts command")
        }
    }
    
    @Test("Parses phoneme flags")
    func testPhonemeFlags() {
        let cmd1 = CLIParser.parse(arguments: ["-p", "Test text"])
        if case .tts(let opts) = cmd1 {
            #expect(opts.phonemesOnly)
        } else {
            Issue.record("Expected .tts with phonemesOnly")
        }
        
        let cmd2 = CLIParser.parse(arguments: ["--from-phonemes", "həˈloʊ"])
        if case .tts(let opts) = cmd2 {
            #expect(opts.fromPhonemes)
        } else {
            Issue.record("Expected .tts with fromPhonemes")
        }
    }
    
    @Test("Parses voice list and delete subcommands")
    func testVoiceSubcommands() {
        if case .voiceList = CLIParser.parse(arguments: ["voice", "list"]) {} else {
            Issue.record("Expected .voiceList")
        }
        if case .voiceList = CLIParser.parse(arguments: ["voice", "ls"]) {} else {
            Issue.record("Expected .voiceList for ls alias")
        }
        if case .voiceDelete(let name) = CLIParser.parse(arguments: ["voice", "rm", "carlos"]) {
            #expect(name == "carlos")
        } else {
            Issue.record("Expected .voiceDelete for voice rm")
        }
    }
    
    @Test("Parses voice clone subcommand")
    func testVoiceCloneParsing() {
        let args = ["voice", "clone", "/path/to/audio.wav", "--name", "myvoice", "--lang", "es"]
        let cmd = CLIParser.parse(arguments: args)
        if case .voiceClone(let opts) = cmd {
            #expect(opts.audioPath == "/path/to/audio.wav")
            #expect(opts.name == "myvoice")
            #expect(opts.language == "es")
        } else {
            Issue.record("Expected .voiceClone command")
        }
    }
    
    @Test("Parses listen daemon subcommand")
    func testListenParsing() {
        let args = [
            "listen",
            "--socket", "/tmp/custom.sock",
            "-v", "alba",
            "-e", "pocket",
            "--speed", "1.1",
            "--steps", "6",
            "--tee", "/tmp/record.wav"
        ]
        let cmd = CLIParser.parse(arguments: args)
        if case .listen(let opts) = cmd {
            #expect(opts.socketPath == "/tmp/custom.sock")
            #expect(opts.defaultVoice == "alba")
            #expect(opts.engine == "pocket")
            #expect(opts.speed == 1.1)
            #expect(opts.steps == 6)
            #expect(opts.teePath == "/tmp/record.wav")
        } else {
            Issue.record("Expected .listen command")
        }
    }
}
