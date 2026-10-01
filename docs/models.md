# Model Storage, Downloads & Offline Operation

`sayx` prioritizes user privacy, transparency, and predictable disk usage. This document outlines how neural model weights are downloaded, where they reside on your filesystem, and how to inspect or reclaim disk space.

---

## 1. On-Demand Lazy Downloads

`sayx` does **not** bundle large model weights inside the binary, nor does it download models at build time. Models are downloaded over HTTPS on-demand **only when a voice or feature requiring that specific model is first invoked**.

| Engine / Component | Download Trigger | Download Size | Primary Source (Hugging Face) | Local Cache Directory |
| :--- | :--- | :--- | :--- | :--- |
| **Kokoro-82M CoreML** | First run of any Kokoro voice (e.g. `heart`, `adam`, `bella`) | ~90 MB | [`FluidInference/kokoro-82m-coreml`](https://huggingface.co/FluidInference/kokoro-82m-coreml) | `~/.cache/fluidaudio/Models/kokoro-82m-coreml` |
| **Kokoro G2P Tokenizer** | First run of any Kokoro voice or phonemizer (`-p`) | ~40 MB | [`FluidInference/kokoro-82m-coreml`](https://huggingface.co/FluidInference/kokoro-82m-coreml) | `~/.cache/fluidaudio/Models/kokoro` |
| **PocketTTS FlowLM + Mimi** | First run of a PocketTTS voice (`alba`), `-e pocket`, or `voice clone` | ~569 MB | [`FluidInference/pocket-tts-coreml`](https://huggingface.co/FluidInference/pocket-tts-coreml) | `~/.cache/fluidaudio/Models/pocket-tts` |
| **Custom Cloned Voices** | Generated locally via `sayx voice clone` | ~300 KB / voice | Pure on-device computation (zero network) | `~/.cache/sayx/voices/<name>/` |

### Upstream Model Provenance

- **Kokoro-82M Base Weights:** Originally created by `@hexgrad` on Hugging Face at [`hexgrad/Kokoro-82M`](https://huggingface.co/hexgrad/Kokoro-82M). Optimized and compiled for Apple Neural Engine fp16 execution by [`FluidInference/kokoro-82m-coreml`](https://huggingface.co/FluidInference/kokoro-82m-coreml).
- **PocketTTS & Mimi Codec:** Developed by Kyutai Labs ([`kyutai-labs/pocket-tts`](https://github.com/kyutai-labs/pocket-tts)). Optimized for Apple Silicon GPU acceleration by [`FluidInference/pocket-tts-coreml`](https://huggingface.co/FluidInference/pocket-tts-coreml).

### Key Isolation Guarantees

- **Minimal Default Footprint:** If you only use default Kokoro voices on the Apple Neural Engine, only **~130 MB** is ever downloaded. The ~570 MB PocketTTS model is **never** downloaded unless you explicitly request PocketTTS voices or run voice cloning.
- **Zero Build-Time Bloat:** Compiling `sayx` from source or downloading the release binary transfers only the executable (~10 MB), keeping installation fast and lightweight.

---

## 2. 100% Offline Operation

Once model files are cached in your local directory:

- **Zero Network Traffic:** `sayx` operates entirely offline.
- **No Telemetry or Analytics:** `sayx` contains no tracking beacons, analytics pings, or telemetry reporting back to any server.
- **Air-Gapped Environments:** You can pre-populate `~/.cache/fluidaudio/Models/` on a networked Mac and transfer the directory to an air-gapped machine.

---

## 3. Directory Layout on Disk

All models and voice profiles are stored in standard user cache directories under your home folder:

```text
~/.cache/
├── fluidaudio/
│   └── Models/
│       ├── kokoro-82m-coreml/   # CoreML ANE model graph and fp16 tensor weights (~90 MB)
│       ├── kokoro/              # G2P phonemizer vocabulary and language assets (~40 MB)
│       └── pocket-tts/          # FlowLM transformer weights and Mimi neural audio codec (~569 MB)
│
└── sayx/
    └── voices/                  # User-generated voice clones (~300 KB each)
        ├── brooke/
        │   ├── pocket_voice.bin # Voice conditioning embedding
        │   └── voice.json       # Metadata record
        └── carlos/
            ├── pocket_voice.bin
            └── voice.json
```

---

## 4. Cache Management & Cleanup

You have full control over the local model cache.

### Check Current Disk Usage

```bash
# Check disk usage of downloaded models
du -sh ~/.cache/fluidaudio/Models/*

# Check disk usage of custom cloned voices
du -sh ~/.cache/sayx/voices/*
```

### Free Disk Space

To remove all downloaded models:

```bash
# Delete all downloaded model weights (~700 MB)
rm -rf ~/.cache/fluidaudio/Models

# Delete only PocketTTS models (~570 MB), keeping Kokoro
rm -rf ~/.cache/fluidaudio/Models/pocket-tts
```

If you delete cached models, `sayx` will automatically re-download them the next time they are needed.

### Remove Custom Voice Presets

```bash
# Remove a single voice via CLI
sayx voice rm brooke

# Or remove all custom voices manually
rm -rf ~/.cache/sayx/voices
```
