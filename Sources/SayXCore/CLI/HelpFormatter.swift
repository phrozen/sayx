import Foundation

/// Formats help text, usage instructions, and voice catalogs for the terminal.
public enum HelpFormatter {
    
    public static let version = "1.1.0"
    
    public static func printHelp() {
        print("""
sayx - Next-generation speech synthesis CLI for macOS on Apple Silicon
Powered by Kokoro-82M (ANE), PocketTTS (FlowLM+Mimi), & Supertonic-3 (ANE Diffusion)

Usage:
  sayx [OPTIONS] [TEXT]...               Synthesize speech from arguments or stdin
  sayx listen [OPTIONS]                  Run background Unix Domain Socket daemon
  sayx voice clone <AUDIO> --name <ID>   Clone a new voice on-device from a WAV sample
  sayx voice list                        List all installed built-in & cloned voices

Commands:
  listen                 Start background streaming daemon (/tmp/sayx.sock)
  voice clone            Clone a custom voice from an audio file (.wav, .mp3, .m4a)
  voice list             List all available voices and presets

TTS Options:
  -v, --voice <VOICE>    Voice to use (Kokoro, PocketTTS, Supertonic, or preset) [default: heart]
  -s, --speed <RATE>     Playback rate multiplier: 0.5 to 2.0 (e.g. 1.25) [default: 1.0]
      --pitch <CENTS>    Pitch shift in cents: -2400 to +2400 (100 = 1 semitone) [default: 0]
      --steps <STEPS>    Diffusion ODE evaluation steps (1-50, Supertonic default: 5)
  -o, --output <FILE>    Export speech to a WAV file instead of playing through speakers
  -e, --engine <ENGINE>  Force engine: 'kokoro' (ANE), 'pocket' (FlowLM), or 'supertonic' (ANE Diffusion)
  -l, --lang <LANG>      Language code (e.g. en, es, fr, de, ja, ko, zh; 31 langs supported) [default: en]
  -p, --phonemes         Print phonemized IPA representation to stdout and exit
      --show-phonemes    Print phonemized IPA representation before speaking
      --from-phonemes    Treat input text directly as pre-computed IPA phonemes (bypass G2P)
  -h, --help             Print help information
  -V, --version          Print version information

Daemon Options (sayx listen):
  --socket, -s <PATH>    Unix Domain Socket path [default: /tmp/sayx.sock]
  --tee <FILE.WAV>       Save all audio streamed through daemon to disk
  -v, --voice <VOICE>    Default voice for incoming streams
  -e, --engine <ENGINE>  Default engine for daemon
  --speed <RATE>         Playback rate multiplier [default: 1.0]
  --pitch <CENTS>        Pitch shift in cents [default: 0]
  --steps <STEPS>        Diffusion evaluation steps [default: 5]

Examples:
  # 1. High-speed speech on Apple Neural Engine (default: Kokoro 24 kHz)
  sayx "Hello from the Apple Neural Engine!"
  sayx -v bella -s 1.2 "Good morning! Ready for the day?"

  # 2. Supertonic-3 studio audio (44.1 kHz, 31 languages, flow-matching diffusion)
  sayx -e supertonic -v m1 "Welcome to the studio broadcast."
  sayx -e supertonic -v f-studio -l es "Bienvenidos al episodio de hoy."
  sayx -v m-narrator --steps 8 "Flow-matching diffusion with custom step count."

  # 3. Inline multi-engine dialogue script
  sayx "[v:heart] Welcome back! [v:m-narrator,l:es] ¡Hola amigos! What a journey."

  # 4. Clone a voice from audio (PocketTTS FlowLM pure Swift)
  sayx voice clone ~/audio/brooke.wav --name brooke
  sayx -v brooke "Hello from my freshly cloned voice!"

  # 5. Start background daemon for ambient streaming
  sayx listen --socket /tmp/sayx.sock
""")
    }
    
    public static func printVoiceList() {
        print("Available Voices in sayx:\n")
        
        let presets = VoicePreset.listPresets()
        if !presets.isEmpty {
            print("Custom Voice Presets (~/.cache/sayx/voices/):")
            for preset in presets {
                print("  - \(preset.name.padding(toLength: 14, withPad: " ", startingAt: 0)) [engine: \(preset.engine), lang: \(preset.language)] (Created: \(preset.createdAt.prefix(12)))")
            }
            print("")
        }
        
        print("Built-in Supertonic-3 Voice Styles (Flow-Matching Diffusion on ANE - 44.1 kHz):")
        print("  Male Cast:   m1 (m-narrator, default), m2 (m-casual), m3 (m-dramatic), m4 (m-deep), m5 (m-energetic)")
        print("  Female Cast: f1 (f-studio, default), f2 (f-casual), f3 (f-warm), f4 (f-expressive), f5 (f-calm)")
        print("  Custom Styles: Pass any .json style tensor file: sayx -v style.json \"...\"")
        print("  Languages: 31 languages supported (en, es, fr, de, it, pt, ja, ko, zh, ru, nl, pl, etc.)")
        print("")
        
        print("Built-in Kokoro-82M Voices (Apple Neural Engine - 24.0 kHz):")
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
        
        print("Built-in PocketTTS Studio Voices (Kyutai FlowLM - 24.0 kHz):")
        print("  Female Cast: alba (default), anna, azelma, caro_davy, cosette, eponine, estelle, eve, fantine, jane, lola, mary, vera")
        print("  Male Cast:   charles, giovanni, javert, jean, juergen, marius, paul, rafael, bill_boerst, peter_yearsley, stuart_bell")
    }
}
