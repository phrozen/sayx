import Foundation

/// Formats help text, usage instructions, and voice catalogs for the terminal.
public enum HelpFormatter {
    
    public static let version = "1.0.0"
    
    public static func printHelp() {
        print("""
sayx - Next-generation speech synthesis CLI for macOS on Apple Silicon
Powered by Kokoro-82M (ANE) & PocketTTS (FlowLM + Mimi) via CoreML

Usage:
  sayx [OPTIONS] [TEXT]...               Synthesize speech from arguments or stdin
  sayx listen [OPTIONS]                  Run background Unix Domain Socket daemon
  sayx voice clone <AUDIO> --name <ID>   Clone a new voice on-device from a WAV sample
  sayx voice list                        List all installed built-in & cloned voices
  sayx test                              Run built-in test suite (SIMD, NLP, Voices)

Commands:
  listen                 Start background streaming daemon (/tmp/sayx.sock)
  voice clone            Clone a custom voice from an audio file (.wav, .mp3, .m4a)
  voice list             List all available voices and presets
  test                   Run built-in diagnostic test suite

TTS Options:
  -v, --voice <VOICE>    Voice to use (Kokoro alias, built-in, or cloned preset) [default: heart]
  -s, --speed <RATE>     Playback rate multiplier: 0.5 to 2.0 (e.g. 1.25) [default: 1.0]
      --pitch <CENTS>    Pitch shift in cents: -2400 to +2400 (100 = 1 semitone) [default: 0]
  -o, --output <FILE>    Export speech to a WAV file instead of playing through speakers
  -e, --engine <ENGINE>  Force engine: 'kokoro' (ANE) or 'pocket' (FlowLM+Mimi)
  -l, --lang <LANG>      Language code: 'en', 'es', 'fr', 'de', 'it', 'pt'
  -p, --phonemes         Print phonemized IPA representation to stdout and exit
      --show-phonemes    Print phonemized IPA representation before speaking
      --from-phonemes    Treat input text directly as pre-computed IPA phonemes (bypass G2P)
  -h, --help             Print help information
  -V, --version          Print version information

Daemon Options (sayx listen):
  --socket, -s <PATH>    Unix Domain Socket path [default: /tmp/sayx.sock]
  --tee <FILE.WAV>       Save all audio streamed through daemon to disk
  -v, --voice <VOICE>    Default voice for incoming streams
  --speed <RATE>         Playback rate multiplier [default: 1.0]
  --pitch <CENTS>        Pitch shift in cents [default: 0]

Examples:
  # 1. High-speed speech on Apple Neural Engine (default: Kokoro)
  sayx "Hello from the Apple Neural Engine!"
  sayx -v bella -s 1.2 "Good morning! Ready for the day?"

  # 2. Pipe long novels with constant ~500 MB RAM
  cat novel.txt | sayx -v adam

  # 3. Clone a voice from audio (100% on-device pure Swift)
  sayx voice clone ~/audio/brooke.wav --name brooke
  sayx -v brooke "Hello from my freshly cloned voice!"

  # 4. Clone in Spanish / Mexican accent
  sayx voice clone ~/audio/carlos.wav --name carlos --lang es
  sayx -v carlos --lang es "Hola amigos, bienvenidos al podcast."

  # 5. Start background daemon for ambient podcast streaming
  sayx listen --socket /tmp/sayx.sock
""")
    }
    
    public static func printVoiceList() {
        print("Available Voices in sayx:\n")
        
        let presets = VoicePreset.listPresets()
        if !presets.isEmpty {
            print("Custom Cloned Voices (PocketTTS - ~/.cache/sayx/voices/):")
            for preset in presets {
                print("  - \(preset.name.padding(toLength: 14, withPad: " ", startingAt: 0)) [lang: \(preset.language)] (Created: \(preset.createdAt.prefix(10)))")
            }
            print("")
        }
        
        print("Built-in Kokoro-82M Voices (Apple Neural Engine):")
        print("  American Female: heart (default), bella, nicole, sarah, sky, aoede, kore, alloy, nova, jessica, river")
        print("  American Male:   adam, michael, fenrir, puck, echo, eric, liam, onyx, santa")
        print("  British Female:  emma, isabella, alice, lily")
        print("  British Male:    george, fable, daniel, lewis")
        print("  Spanish:         ef_dora, em_alex, em_santa")
        print("  French:          siwis")
        print("  Japanese:        jf_alpha, gongitsune, nezumi, tebukuro, kumo")
        print("  Mandarin:        xiaobei, xiaoni, xiaoxiao, xiaoyi, yunjian, yunxi, yunxia, yunyang")
        print("  Hindi:           hf_alpha, hf_beta, omega, psi")
        print("  Italian:         sara, nicola")
        print("  Portuguese:      pf_dora, pm_alex, pm_santa")
        print("")
        print("Built-in PocketTTS Studio Voices (Kyutai FlowLM):")
        print("  Female Cast: alba (default), anna, azelma, caro_davy, cosette, eponine, estelle, eve, fantine, jane, lola, mary, vera")
        print("  Male Cast:   charles, giovanni, javert, jean, juergen, marius, paul, rafael, bill_boerst, peter_yearsley, stuart_bell")
    }
}
