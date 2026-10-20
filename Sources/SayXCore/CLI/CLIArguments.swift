import Foundation

/// Parsed command representation for sayx CLI execution.
public enum ParsedCommand {
    case tts(TTSOptions)
    case listen(ListenOptions)
    case voiceClone(VoiceCloneOptions)
    case voiceList
    case voiceDelete(name: String)
    case help
    case version
}

public struct TTSOptions {
    public var text: String
    public var rawVoice: String? = nil
    public var outputPath: String? = nil
    public var engine: String? = nil
    public var language: String? = nil
    public var speed: Float = 1.0
    public var pitch: Float = 0.0
    public var steps: Int = 5
    public var phonemesOnly: Bool = false
    public var showPhonemes: Bool = false
    public var fromPhonemes: Bool = false
}

public struct ListenOptions {
    public var socketPath: String = "/tmp/sayx.sock"
    public var defaultVoice: String? = nil
    public var engine: String? = nil
    public var teePath: String? = nil
    public var speed: Float = 1.0
    public var pitch: Float = 0.0
    public var steps: Int = 5
}

public struct VoiceCloneOptions {
    public var audioPath: String
    public var name: String
    public var language: String = "english"
}

public enum CLIParser {
    
    public static func parse(arguments: [String]) -> ParsedCommand {
        guard let first = arguments.first else {
            // No arguments passed -> read from stdin in TTS mode
            return .tts(TTSOptions(text: readStdin()))
        }
        
        switch first {
        case "-h", "--help":
            return .help
            
        case "-V", "--version":
            return .version
            
        case "listen":
            return parseListenCommand(Array(arguments.dropFirst()))
            
        case "voice":
            return parseVoiceCommand(Array(arguments.dropFirst()))
            
        default:
            return parseTTSCommand(arguments)
        }
    }
    
    private static func parseListenCommand(_ args: [String]) -> ParsedCommand {
        var options = ListenOptions()
        var i = 0
        while i < args.count {
            let arg = args[i]
            switch arg {
            case "--socket", "-s":
                if i + 1 < args.count {
                    options.socketPath = args[i + 1]
                    i += 1
                }
            case "-v", "--voice":
                if i + 1 < args.count {
                    options.defaultVoice = args[i + 1]
                    i += 1
                }
            case "-e", "--engine":
                if i + 1 < args.count {
                    options.engine = args[i + 1]
                    i += 1
                }
            case "--tee", "--tee-output":
                if i + 1 < args.count {
                    options.teePath = args[i + 1]
                    i += 1
                }
            case "--speed", "--rate":
                if i + 1 < args.count, let val = Float(args[i + 1]) {
                    options.speed = val
                    i += 1
                }
            case "--pitch":
                if i + 1 < args.count, let val = Float(args[i + 1]) {
                    options.pitch = val
                    i += 1
                }
            case "--steps":
                if i + 1 < args.count, let val = Int(args[i + 1]), val > 0 {
                    options.steps = val
                    i += 1
                }
            case "-h", "--help":
                return .help
            default:
                if !arg.hasPrefix("-") && options.socketPath == "/tmp/sayx.sock" {
                    options.socketPath = arg
                }
            }
            i += 1
        }
        return .listen(options)
    }
    
    private static func parseVoiceCommand(_ args: [String]) -> ParsedCommand {
        guard let sub = args.first else {
            return .voiceList
        }
        
        switch sub {
        case "list", "ls":
            return .voiceList
            
        case "delete", "rm":
            if args.count > 1 {
                return .voiceDelete(name: args[1])
            } else {
                fputs("Error: Missing voice name to delete\n", stderr)
                exit(1)
            }
            
        case "clone", "create":
            return parseVoiceCloneCommand(Array(args.dropFirst()))
            
        case "-h", "--help":
            return .help
            
        default:
            fputs("Error: Unknown voice subcommand '\(sub)'. Use 'list' or 'clone'.\n", stderr)
            exit(1)
        }
    }
    
    private static func parseVoiceCloneCommand(_ args: [String]) -> ParsedCommand {
        var audioPath = ""
        var name = ""
        var language = "english"
        
        var i = 0
        while i < args.count {
            let arg = args[i]
            switch arg {
            case "--name", "-n":
                if i + 1 < args.count {
                    name = args[i + 1]
                    i += 1
                }
            case "--lang", "-l", "--language":
                if i + 1 < args.count {
                    language = args[i + 1]
                    i += 1
                }
            case "-h", "--help":
                return .help
            default:
                if !arg.hasPrefix("-") {
                    if audioPath.isEmpty {
                        audioPath = arg
                    } else if name.isEmpty {
                        name = arg
                    }
                }
            }
            i += 1
        }
        
        if audioPath.isEmpty || name.isEmpty {
            fputs("Error: Missing required arguments.\nUsage: sayx voice clone <audio_file.wav> --name <voice_name> [--lang en|es]\n", stderr)
            exit(1)
        }
        
        return .voiceClone(VoiceCloneOptions(audioPath: audioPath, name: name, language: language))
    }
    
    private static func parseTTSCommand(_ args: [String]) -> ParsedCommand {
        var options = TTSOptions(text: "")
        var positional: [String] = []
        
        var i = 0
        while i < args.count {
            let arg = args[i]
            switch arg {
            case "-h", "--help":
                return .help
                
            case "-V", "--version":
                return .version
                
            case "-p", "--phonemes":
                options.phonemesOnly = true
                
            case "--show-phonemes":
                options.showPhonemes = true
                
            case "--from-phonemes", "--ipa":
                options.fromPhonemes = true
                
            case "-v", "--voice":
                if i + 1 < args.count {
                    options.rawVoice = args[i + 1]
                    i += 1
                }
                
            case "-o", "--output":
                if i + 1 < args.count {
                    options.outputPath = args[i + 1]
                    i += 1
                }
                
            case "-e", "--engine":
                if i + 1 < args.count {
                    options.engine = args[i + 1]
                    i += 1
                }
                
            case "-l", "--lang", "--language":
                if i + 1 < args.count {
                    options.language = args[i + 1]
                    i += 1
                }
                
            case "-s", "--speed", "-r", "--rate":
                if i + 1 < args.count, let val = Float(args[i + 1]) {
                    options.speed = val
                    i += 1
                }
                
            case "--pitch":
                if i + 1 < args.count, let val = Float(args[i + 1]) {
                    options.pitch = val
                    i += 1
                }
                
            case "--steps":
                if i + 1 < args.count, let val = Int(args[i + 1]), val > 0 {
                    options.steps = val
                    i += 1
                }
                
            case "--listen":
                // Flag style listen: sayx --listen [/tmp/sayx.sock]
                var listenOpts = ListenOptions()
                listenOpts.defaultVoice = options.rawVoice
                listenOpts.engine = options.engine
                listenOpts.steps = options.steps
                if i + 1 < args.count && !args[i + 1].hasPrefix("-") {
                    listenOpts.socketPath = args[i + 1]
                    i += 1
                }
                return .listen(listenOpts)
                
            default:
                if arg.hasPrefix("-") && arg != "-" {
                    fputs("Error: Unknown option '\(arg)'. Use --help for usage.\n", stderr)
                    exit(1)
                } else {
                    positional.append(arg)
                }
            }
            i += 1
        }
        
        let joined = positional.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if joined.isEmpty || joined == "-" {
            options.text = readStdin()
        } else {
            options.text = joined
        }
        
        return .tts(options)
    }
    
    private static func readStdin() -> String {
        let stdinData = FileHandle.standardInput.readDataToEndOfFile()
        guard let str = String(data: stdinData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !str.isEmpty else {
            fputs("Error: No text provided. Pass text as arguments or pipe via stdin.\n", stderr)
            exit(1)
        }
        return str
    }
}
