# sayx

> Next-generation neural speech synthesis CLI for macOS on Apple Silicon.  
> Powered by **Kokoro-82M (Apple Neural Engine)**, **PocketTTS (FlowLM + Mimi)**, and **Supertonic-3 (ANE Flow-Matching Diffusion)**.

`sayx` is a drop-in modern evolution of macOS `/usr/bin/say`. It provides studio-quality neural text-to-speech with sub-200ms time-to-first-audio, 44.1 kHz studio diffusion output, on-device voice cloning in pure Swift, 88+ natural voices across 31 languages, CoreAudio DSP time-pitch modulation, Accelerate SIMD loudness normalization, and a Unix Domain Socket streaming daemon with real-time JSON telemetry.

---

## Key Features

- **Apple Neural Engine (ANE) Acceleration:** Kokoro-82M and Supertonic-3 run directly on the 16-core NPU via CoreML. Up to ~94% ANE execution with fixed-bucket INT4 quantization, zero host CPU/GPU load, and sub-200ms latency to first audio chunk. See [Architecture Documentation](docs/architecture.md).
- **88+ Natural Voices Across 31 Languages:** 54 Kokoro voices, 24 PocketTTS studio cast voices, 10 Supertonic-3 character styles (`m1`–`m5`, `f1`–`f5`) with friendly aliases (`m-narrator`, `f-studio`), and dynamic multi-speaker dialogue with inline tags (`[v:heart] ... [v:m-narrator,l:es]`). See [Voice Catalog](docs/voices.md).
- **Studio-Quality 44.1 kHz Audio:** Supertonic-3 delivers broadcast 44.1 kHz Float32 sound with full flow-matching diffusion inference directly on the Apple Neural Engine.
- **In-Memory Sample-Rate Harmonization:** Seamlessly mix 24.0 kHz (Kokoro, PocketTTS) and 44.1 kHz (Supertonic) voices in the exact same audio stream or dialogue script without clicks or drift via CoreAudio `AVAudioConverter`.
- **On-Device Voice Cloning:** Clone any voice locally in ~1.5s from a short reference audio clip (`.wav`, `.mp3`, `.m4a`) using PocketTTS and the Mimi neural audio codec. No cloud dependencies or API keys required. See [Voice Cloning Guide](docs/cloning.md).
- **CoreAudio DSP & Accelerate SIMD Normalization:** Pitch-invariant speed stretching (0.03x to 32.0x) and semitone pitch modulation (-2400 to +2400 cents) via `AVAudioUnitTimePitch`, paired with -1.0 dBFS peak normalization via Apple Accelerate `vDSP`. See [Audio DSP Guide](docs/audio-dsp.md).
- **Unix Domain Socket Daemon:** Headless streaming daemon (`sayx listen`) over `/tmp/sayx.sock` with bidirectional JSON telemetry and master recording capture (`--tee`). See [Daemon Guide](docs/daemon.md).
- **Offline File Export:** Render long-form audio directly to WAV files at >25x real-time speed.
- **Comprehensive Swift Testing Suite:** Full unit and integration test coverage (`swift test`) validating SIMD math, sample rate converters, audio filters, sentence tokenization, voice routing, and Apple Neural Engine pipelines.

---

## System Requirements

- **Operating System:** macOS 14.0 (Sonoma) or later
- **Hardware:** Apple Silicon (M1 or later)
- **Toolchain:** Swift 6.0+ / Xcode 16+

---

## Installation

### Pre-built Binary

Download the latest release archive (`sayx-macos-arm64.tar.gz`) from the [Releases](https://github.com/phrozen/sayx/releases) page:

```bash
# Extract and install into PATH
tar -xzf sayx-macos-arm64.tar.gz
sudo mv sayx /usr/local/bin/sayx
```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/phrozen/sayx.git
cd sayx

# Build release executable
swift build -c release

# (Optional) Symlink into your PATH
sudo ln -sf "$(pwd)/.build/out/Products/Release/sayx" /usr/local/bin/sayx
```

---

## Quick Start

### Basic Speech Synthesis

```bash
# Default high-speed speech on Apple Neural Engine (default: heart)
sayx "Hello from the Apple Neural Engine."

# Select voice by friendly alias
sayx -v bella "Good morning! Ready for the day?"
sayx -v adam "System update completed successfully."
sayx -v javert "Do not forget my name. Do not forget me, 24601."

# Stream from standard input (pipes)
echo "Build succeeded in 12 seconds." | sayx
cat story.txt | sayx -v adam
```

### Supertonic-3 (44.1 kHz Studio Diffusion)

```bash
# Synthesize with Supertonic-3 on Apple Neural Engine
sayx -e supertonic -v m1 "That was an incredible performance. Let's do it again."

# Multi-lingual speech across 31 languages
sayx -e supertonic -v f-studio -l es "Bienvenidos al episodio de hoy."
sayx -e supertonic -v m-narrator -l ja "こんにちは、世界。"

# Customize diffusion ODE evaluation steps (default: 5)
sayx -v m-narrator --steps 8 "High-fidelity flow-matching diffusion on ANE."

# Use custom JSON voice style tensors
sayx -v /path/to/custom_style.json "Speech synthesized from custom style weights."
```

### Speed & Pitch Control (CoreAudio DSP)

```bash
# Speed up playback by 25% without pitch alteration
sayx -v bella -s 1.25 "Speeding up by 25 percent without pitch change."

# Slow down playback
sayx -v adam -s 0.85 "Slow, measured cadence."

# Shift vocal pitch up by 2 semitones (+200 cents)
sayx -v adam --pitch 200 "Speaking two semitones higher."
```

### Export to Audio File

```bash
# Export speech to WAV at >25x real-time speed
sayx -v cosette -s 1.1 "There is a castle on a cloud." -o castle.wav
sayx -e supertonic -v f1 "Studio audio exported at 44.1 kHz." -o studio.wav
```

### Voice Cloning & Multi-Character Dialogue

```bash
# 1. Clone a custom voice on-device from a WAV or MP3 file
sayx voice clone ~/recordings/sample.wav --name brooke

# 2. List all installed custom voices
sayx voice list

# 3. Speak with your cloned voice
sayx -v brooke "Hello! This voice was cloned directly on my Mac."

# 4. Mix multiple voices and engines in a single stream (automatic sample rate adaptation)
sayx "[v:heart] Access granted. [v:m-narrator,l:es] ¡Hola amigos! All systems operational." -o dialogue.wav
```

### Unix Domain Socket Streaming Daemon

```bash
# Start background daemon listening on /tmp/sayx.sock
sayx listen --socket /tmp/sayx.sock --tee master_recording.wav

# Stream text from another terminal or script (e.g. netcat, Python, Node.js)
printf "[v:adam] Chapter 1: The Beginning.\n[v:bella] Everything was quiet.\n" | nc -U /tmp/sayx.sock
```

### Running Tests

```bash
# Run unit test suite (fast, offline, no model downloads)
swift test --filter SayXUnitTests

# Run full integration test suite (ANE inference & IPC)
swift test --filter SayXIntegrationTests

# Run entire test suite
swift test --filter .
```

---

## Command-Line Reference

```text
Usage:
  sayx [OPTIONS] [TEXT]...               Synthesize speech from arguments or stdin
  sayx listen [OPTIONS]                  Run background Unix Domain Socket daemon
  sayx voice clone <AUDIO> --name <ID>   Clone a new voice on-device from an audio sample
  sayx voice list                        List all installed custom voices
  sayx voice rm <ID>                     Delete an installed custom voice

Commands:
  listen                 Start background streaming daemon (/tmp/sayx.sock)
  voice clone            Clone a custom voice from an audio file (.wav, .mp3, .m4a)
  voice list             List all available custom voice presets
  voice rm, delete       Remove an installed custom voice preset

TTS Options:
  -v, --voice <VOICE>    Voice alias, canonical ID, or cloned preset [default: heart]
  -s, --speed <RATE>     Playback speed multiplier (0.03 to 32.0) [default: 1.0]
      --pitch <CENTS>    Pitch shift in cents (-2400 to +2400) [default: 0.0]
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
  -s, --socket <PATH>    Unix Domain Socket path [default: /tmp/sayx.sock]
  -v, --voice <VOICE>    Default voice for incoming streams [default: heart]
  -e, --engine <ENGINE>  Default engine for incoming streams
      --speed <RATE>     Playback speed multiplier [default: 1.0]
      --pitch <CENTS>    Pitch shift in cents [default: 0.0]
      --steps <STEPS>    Diffusion evaluation steps [default: 5]
      --tee <FILE.WAV>   Save all audio streamed through daemon to disk
```

---

## Model Storage & Offline Usage

`sayx` operates transparently regarding network downloads and local disk storage:

- **On-Demand Downloads:** Models are **not** bundled into the binary or downloaded at build time. Weights are fetched over HTTPS on first use only when a voice requiring that specific model is requested.
  - **[Kokoro-82M CoreML](https://huggingface.co/FluidInference/kokoro-82m-coreml):** ~130 MB total (~90 MB model + ~40 MB tokenizer). Downloaded on first Kokoro synthesis.
  - **[PocketTTS FlowLM + Mimi](https://huggingface.co/FluidInference/pocket-tts-coreml):** ~569 MB. Downloaded only when using PocketTTS voices (`alba`), `-e pocket`, or `voice clone`.
  - **[Supertonic-3 Flow-Matching CoreML](https://huggingface.co/FluidInference/supertonic-3-coreml):** ~72 MB total (~32 MB INT4 bucketed vector estimator + ~40 MB vocoder/text encoder). Downloaded on first Supertonic use.
- **Local Storage Path:** Models are cached in standard user space at `~/.cache/fluidaudio/Models/`. Custom voice presets are stored in `~/.cache/sayx/voices/`.
- **100% Offline:** Once downloaded, `sayx` runs completely offline with zero network requests or analytics telemetry.
- **Cache Management:** Free up disk space anytime via `rm -rf ~/.cache/fluidaudio/Models`. See [Model Storage Guide](docs/models.md) for full details.

---

## Documentation

Comprehensive guides are organized in the [`docs/`](docs/) directory:

- [Voice Catalog & Routing (`docs/voices.md`)](docs/voices.md): Complete list of 88+ Kokoro-82M, PocketTTS, and Supertonic-3 voices, character profiles, language mappings, and inline multi-speaker dialogue.
- [Voice Cloning Guide (`docs/cloning.md`)](docs/cloning.md): Reference audio requirements, automatic pre-processing, CLI commands, and on-disk preset storage.
- [Model Storage & Offline Operation (`docs/models.md`)](docs/models.md): Detailed download sources, exact file sizes, cache layout on disk, and offline usage guarantees.
- [Unix Domain Socket Daemon (`docs/daemon.md`)](docs/daemon.md): Socket architecture, line protocol, bidirectional JSON telemetry events, client examples (Python, Node.js), and backpressure control.
- [CoreAudio DSP & Accelerate Normalization (`docs/audio-dsp.md`)](docs/audio-dsp.md): Phase-vocoder speed and pitch stretching, sample rate adaptation, and Accelerate SIMD peak/RMS loudness normalization.
- [System Architecture (`docs/architecture.md`)](docs/architecture.md): Hardware acceleration topology (ANE vs GPU vs CPU), component design, memory management, and Swift 6 concurrency.

---

## Codebase Layout

```text
Sources/SayX/
├── CLI/
│   ├── CLIArguments.swift     # Command line parser (listen, voice clone, tts, test)
│   ├── HelpFormatter.swift    # Terminal help screens and voice directory
│   └── TestRunner.swift       # Built-in diagnostic test harness
├── Core/
│   ├── AudioEffects.swift     # CoreAudio AVAudioUnitTimePitch phase-vocoder DSP
│   ├── AudioNormalizer.swift  # Accelerate vDSP SIMD peak & RMS normalizer + resampler
│   ├── AudioStreamer.swift    # CoreAudio AVAudioEngine player with buffer telemetry
│   ├── SentenceSplitter.swift # NaturalLanguage sentence segmentation and tag parsing
│   └── WavWriter.swift        # Broadcast WAV file encoder
├── Engines/
│   ├── TTSEngine.swift        # Unified speech engine protocol
│   ├── KokoroEngine.swift     # Kokoro-82M on Apple Neural Engine (CoreML)
│   ├── PocketEngine.swift     # PocketTTS FlowLM + Mimi codec on GPU
│   ├── SupertonicEngine.swift # Supertonic-3 flow-matching diffusion on ANE (CoreML)
│   └── EngineDispatcher.swift # Dynamic actor routing voices and adapting sample rates
├── Voices/
│   ├── VoiceRegistry.swift    # Catalog of 88+ voices, aliases, and dynamic resolution
│   ├── VoiceCloner.swift      # Mimi reference audio normalizer & encoder
│   └── VoicePreset.swift      # ~/.cache/sayx/voices/ preset persistence
├── IPC/
│   ├── SocketServer.swift     # Non-blocking AF_UNIX stream server
│   └── TelemetryEvent.swift   # Bidirectional JSON telemetry protocol
└── SayX.swift                 # Application entrypoint (@main)
```

---

## License & Credits

- Released under the [Apache License 2.0](LICENSE). Copyright 2026 Guillermo Estrada.
- Speech synthesis runtime powered by [FluidAudio](https://github.com/FluidInference/FluidAudio).
- Model weights and architectures derived from [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) by `@hexgrad`, [PocketTTS](https://github.com/kyutai-labs/pocket-tts) by Kyutai Labs, and Supertonic-3 by Supertone/FluidInference.
- CoreML ANE and GPU optimizations by `@FluidInference` and `@laishere`.
