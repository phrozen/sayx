# On-Device Voice Cloning

`sayx` provides instant, fully offline voice cloning powered by Kyutai Labs' **PocketTTS** (FlowLM and Mimi neural audio codec) running on Apple Silicon.

Any clean audio reference (3 to 15 seconds) can be cloned into a persistent voice preset in under 2 seconds. The resulting preset can be used immediately across the CLI, inline dialogue tags, and the Unix Domain Socket streaming daemon.

---

## Quick Start

```bash
# Clone a voice from an audio file
sayx voice clone reference.wav --name brooke

# Test the newly cloned voice
sayx -v brooke "Hello! This voice was cloned directly on my Mac."

# List all installed custom voice presets
sayx voice list

# Remove a cloned voice
sayx voice rm brooke
```

---

## Reference Audio Guidelines

For the best cloning fidelity:

| Attribute | Recommended | Notes |
| :--- | :--- | :--- |
| **Duration** | 5 - 15 seconds | Clips shorter than 3 seconds lack acoustic variety; clips longer than 30 seconds provide diminishing returns. |
| **Sample Quality** | Clean, dry vocal | Minimal background noise, room reverberation, or music. |
| **Speaking Style** | Natural cadence | Avoid dramatic whispering, shouting, or extreme pitch inflections unless intended for character work. |
| **File Formats** | WAV, MP3, M4A, FLAC, AIFF | Handled automatically by CoreAudio format decoders. |

### Automatic Pre-Processing Pipeline

Before computing the acoustic conditioning embedding, `sayx` automatically processes reference audio through its internal audio pipeline:

1. **Format Resampling:** Converts arbitrary sample rates and channel counts to 24 kHz mono Float32 PCM via CoreAudio `AVAudioConverter`.
2. **SIMD Normalization:** Scales the audio to -1.0 dBFS using Apple Accelerate `vDSP` vector instructions to guarantee standard broadcast input levels without DAC clipping.
3. **Mimi Latent Encoding:** Passes the normalized waveform into the Mimi neural audio codec to extract the low-dimensional acoustic profile.

---

## CLI Reference

### 1. `sayx voice clone`

Clones a voice from an audio sample and registers it locally.

```bash
sayx voice clone <audio_file> --name <voice_name> [--lang <language>]
```

**Options:**
- `<audio_file>`: Path to the input audio file (expands `~`).
- `-n, --name <name>`: Unique identifier for the voice preset (alphanumeric and underscores, lowercased automatically).
- `-l, --lang, --language <lang>`: Target language model (default: `english`). Supported options:
  - `english` / `en`
  - `spanish` / `es`
  - `french` / `fr`
  - `german` / `de`
  - `italian` / `it`
  - `portuguese` / `pt`

**Example:**
```bash
sayx voice clone ~/recordings/carlos_sample.wav --name carlos --lang es
sayx -v carlos "Hola, esta es mi voz clonada en espanol."
```

---

### 2. `sayx voice list`

Displays all custom voice presets registered on the system.

```bash
sayx voice list
```

**Output Example:**
```text
Installed Custom Voices (PocketTTS):
  - brooke   [english] (Created: 2026-10-01T12:00:00Z)
  - carlos   [spanish] (Created: 2026-10-01T12:05:00Z)
```

---

### 3. `sayx voice delete` / `rm`

Removes a custom voice preset and deletes its cached embedding files from disk.

```bash
sayx voice rm brooke
```

---

## On-Disk Storage Structure

Custom voice presets are stored in user space under `~/.cache/sayx/voices/`:

```text
~/.cache/sayx/voices/
├── brooke/
│   ├── pocket_voice.bin    # Binary acoustic conditioning embedding
│   └── voice.json          # Metadata record (engine, language, timestamp)
└── carlos/
    ├── pocket_voice.bin
    └── voice.json
```

### Metadata Format (`voice.json`)

```json
{
  "name": "brooke",
  "engine": "pocket",
  "language": "english",
  "createdAt": "2026-10-01T12:00:00Z",
  "sourceFile": "/Users/user/recordings/brooke_ref.wav"
}
```

---

## Multi-Voice Dialogue with Cloned Voices

Cloned presets integrate into the `sayx` voice routing catalog. You can switch between built-in Kokoro voices and cloned voices inside a single prompt using inline `[v:name]` tags:

```bash
sayx "[v:adam] System diagnosis initialized. [v:brooke] All systems operational. [v:heart] Have a productive day."
```

When switching from `adam` (Kokoro on ANE) to `brooke` (cloned preset on GPU), the `EngineDispatcher` routes the text chunk to PocketTTS without interruption or playback gaps.
