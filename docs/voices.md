# Voice Catalog & Speaker Routing

`sayx` provides a unified catalog of 88+ natural voices across 31 languages, combining models from:
- **Kokoro-82M** (Apple Neural Engine, 24.0 kHz)
- **PocketTTS** (Apple GPU, 24.0 kHz)
- **Supertonic-3** (Apple Neural Engine Flow-Matching Diffusion, 44.1 kHz studio quality)

---

## Voice Resolution Overview

When selecting a voice via the CLI (`-v, --voice`) or inline dialogue tags (`[v:name]` or `[v:name,l:lang]`), `sayx` resolves voices using the following priority order:

1. **Explicit Engine Override (`-e, --engine`):**
   - `-e supertonic`: Defaults to `m1` (Supertonic Male 1 Narrator) at 44.1 kHz.
   - `-e pocket`: Defaults to `alba` (PocketTTS Female Studio) at 24.0 kHz.
   - `-e kokoro`: Defaults to `af_heart` (Kokoro American Female) at 24.0 kHz.
2. **Direct JSON Style File:** Any path ending with `.json` (e.g. `sayx -v style.json "..."`) automatically loads the custom tensor as a Supertonic-3 voice style.
3. **Custom Supertonic Style Presets:** Checks `~/.cache/sayx/voices/<name>/style.json` or `~/.cache/sayx/voices/<name>.json`.
4. **Supertonic-3 Voice Styles & Semantic Aliases:** Matches built-in IDs `m1`–`m5`, `f1`–`f5` or friendly aliases like `m-narrator`, `f-studio`, `m-casual`.
5. **Custom Cloned Presets:** Checked in `~/.cache/sayx/voices/<name>/pocket_voice.bin`. Automatically routes to PocketTTS.
6. **PocketTTS Studio Character Voices:** Matches names like `alba`, `javert`, `cosette`, `fantine`. Automatically routes to PocketTTS on the GPU.
7. **Canonical Kokoro Identifiers & Aliases:** Matches informal aliases like `heart`, `adam`, `bella`, `george`, or exact IDs like `af_heart`, `am_adam`, `bm_george`, `zf_xiaobei`.

---

## 1. Built-in Supertonic-3 Voices (Apple Neural Engine Diffusion - 44.1 kHz)

Supertonic-3 is a flow-matching diffusion TTS model accelerated on the Apple Neural Engine. It operates at studio-grade 44.1 kHz Float32 with sub-second generation and native support for 31 languages across 10 built-in voice styles.

### Male Voice Cast

| Voice ID | Semantic Alias | Character Profile |
| :--- | :--- | :--- |
| **`m1`** *(default)* | **`m-narrator`**, `narrator` | Clear, balanced studio narrator. Excellent for audiobooks and podcasts. |
| **`m2`** | **`m-casual`** | Relaxed, warm, conversational cadence. |
| **`m3`** | **`m-dramatic`** | Deep, resonant, cinematic baritone. |
| **`m4`** | **`m-deep`** | Authoritative, low-frequency presenter. |
| **`m5`** | **`m-energetic`** | Dynamic, upbeat, fast-paced commercial voice. |

### Female Voice Cast

| Voice ID | Semantic Alias | Character Profile |
| :--- | :--- | :--- |
| **`f1`** *(default)* | **`f-studio`**, `studio` | Crisp, professional studio anchor. Default female voice. |
| **`f2`** | **`f-casual`** | Warm, friendly, conversational delivery. |
| **`f3`** | **`f-warm`** | Gentle, narrative, storytelling cadence. |
| **`f4`** | **`f-expressive`** | Bright, articulate, high-energy delivery. |
| **`f5`** | **`f-calm`** | Soothing, meditative, melodic tone. |

### 31 Supported Languages

Supertonic-3 natively supports 31 languages via Unicode NFKD normalization and phoneme tokenization. Pass any standard ISO-639 code or language name via `-l, --lang`:

```bash
sayx -e supertonic -v f-studio -l es "Bienvenidos a nuestro podcast semanal."
sayx -e supertonic -v m-narrator -l ja "こんにちは、皆さん。"
sayx -e supertonic -v m1 -l de "Guten Morgen und herzlich willkommen."
```

Supported codes:
`en` (English), `es` (Spanish), `fr` (French), `de` (German), `it` (Italian), `pt` (Portuguese), `ja` (Japanese), `ko` (Korean), `zh` (Chinese), `ru` (Russian), `nl` (Dutch), `pl` (Polish), `ar` (Arabic), `hi` (Hindi), `tr` (Turkish), `vi` (Vietnamese), `id` (Indonesian), `uk` (Ukrainian), `sv` (Swedish), `da` (Danish), `fi` (Finnish), `el` (Greek), `cs` (Czech), `hu` (Hungarian), `ro` (Romanian), `sk` (Slovak), `sl` (Slovenian), `hr` (Croatian), `bg` (Bulgarian), `lt` (Lithuanian), `lv` (Latvian), `et` (Estonian).

### Custom JSON Style Weights

Pass any offline JSON style vector directly:
```bash
sayx -v ~/styles/narrator_custom.json "Synthesized using custom flow style."
```

---

## 2. Built-in Kokoro-82M Voices (Apple Neural Engine - 24.0 kHz)

Kokoro-82M voices run directly on the 16-core Apple Neural Engine (ANE) via CoreML, delivering sub-200ms latency to first audio with near-zero CPU and GPU utilization.

### American English

| Voice Alias | Canonical ID | Gender | Description / Character Profile |
| :--- | :--- | :--- | :--- |
| **`heart`** *(default)* | `af_heart` | Female | Default voice. Warm, clear, studio quality (Grade A). |
| **`bella`** | `af_bella` | Female | Expressive, bright, conversational (Grade A-). |
| **`nicole`** | `af_nicole` | Female | Calm, focused, educational (Grade B-). |
| **`sarah`** | `af_sarah` | Female | Professional, measured narrator. |
| **`sky`** | `af_sky` | Female | Light, airy, youthful delivery. |
| **`aoede`** | `af_aoede` | Female | Melodic, rhythmic cadence. |
| **`kore`** | `af_kore` | Female | Grounded, storytelling tone. |
| **`alloy`** | `af_alloy` | Female | Direct, neutral assistant tone. |
| **`nova`** | `af_nova` | Female | Energetic, modern pacing. |
| **`jessica`** | `af_jessica` | Female | Casual, friendly conversational style. |
| **`river`** | `af_river` | Female | Soft, meditative delivery. |
| **`adam`** | `am_adam` | Male | Deep, analytical, tech explainer (Grade A-). |
| **`michael`** | `am_michael` | Male | Confident, authoritative narrator. |
| **`fenrir`** | `am_fenrir` | Male | Gritty, dramatic baritone. |
| **`puck`** | `am_puck` | Male | Energetic, playful cadence. |
| **`echo`** | `am_echo` | Male | Clear, resonant announcer. |
| **`eric`** | `am_eric` | Male | Casual, relaxed delivery. |
| **`liam`** | `am_liam` | Male | Brisk, contemporary style. |
| **`onyx`** | `am_onyx` | Male | Deep, cinematic voice. |
| **`santa`** | `am_santa` | Male | Jovial, resonant, warm tone. |

### British English

| Voice Alias | Canonical ID | Gender | Description |
| :--- | :--- | :--- | :--- |
| **`emma`** | `bf_emma` | Female | Crisp, received pronunciation (Grade B-). |
| **`isabella`** | `bf_isabella` | Female | Refined, literary narrator. |
| **`alice`** | `bf_alice` | Female | Gentle, narrative British tone. |
| **`lily`** | `bf_lily` | Female | Youthful, clear British delivery. |
| **`george`** | `bm_george` | Male | Sophisticated, documentary style. |
| **`fable`** | `bm_fable` | Male | Storybook British narrator. |
| **`daniel`** | `bm_daniel` | Male | Formal, articulate voice. |
| **`lewis`** | `bm_lewis` | Male | Conversational, approachable British tone. |

### Multilingual Kokoro Voices

| Language | Voice IDs |
| :--- | :--- |
| **Spanish** | `ef_dora` (Female), `em_alex` (Male), `em_santa` (Male) |
| **French** | `siwis` (Female) |
| **Japanese** | `jf_alpha`, `gongitsune`, `nezumi`, `tebukuro`, `kumo` |
| **Mandarin Chinese** | `xiaobei`, `xiaoni`, `xiaoxiao`, `xiaoyi`, `yunjian`, `yunxi`, `yunxia`, `yunyang` |
| **Hindi** | `hf_alpha`, `hf_beta`, `omega`, `psi` |
| **Italian** | `sara`, `nicola` |
| **Portuguese** | `pf_dora`, `pm_alex`, `pm_santa` |

---

## 3. Built-in PocketTTS Studio Voices (Kyutai FlowLM - 24.0 kHz)

PocketTTS uses Kyutai Labs' FlowLM flow-matching language model and the Mimi neural audio codec running on the Apple GPU.

When invoking `sayx -e pocket` without specifying a voice, `sayx` automatically defaults to **`alba`** (rather than Kokoro's `heart`).

### Female Studio Cast
- **`alba`** *(default PocketTTS voice)*: Balanced, natural French-trained English studio presenter.
- **`anna`**: Clear, articulate conversational female.
- **`azelma`**: Expressive, literary female.
- **`caro_davy`**: Animated character delivery.
- **`cosette`**: Soft, gentle melodic tone.
- **`eponine`**: Brisk, streetwise delivery.
- **`estelle`**: Measured, formal diction.
- **`eve`**: Intimate, modern tone.
- **`fantine`**: Emotional, dramatic cadence.
- **`jane`**: Classic, narrative delivery.
- **`lola`**: Energetic, bright voice.
- **`mary`**: Warm, maternal tone.
- **`vera`**: Precise, professional presenter.

### Male Studio Cast
- **`charles`**: Resonant, classical narrator.
- **`giovanni`**: Mediterranean-inflected English male.
- **`javert`**: Deep, commanding baritone.
- **`jean`**: Measured, philosophical voice.
- **`juergen`**: European-inflected technical tone.
- **`marius`**: Youthful, earnest cadence.
- **`paul`**: Direct, punchy conversational male.
- **`rafael`**: Warm, melodic delivery.
- **`bill_boerst`**: Mature, character-driven voice.
- **`peter_yearsley`**: Classic audio drama narrator.
- **`stuart_bell`**: Low, documentary-style delivery.

---

## 4. Inline Multi-Voice & Multi-Language Switching

You can switch voices and languages turn-by-turn within a single text stream using inline bracket tags:

```bash
sayx "[v:heart] System check initiated. [v:m-narrator,l:es] ¡Todos los módulos operativos! [v:adam] Proceed with launch."
```

### Supported Tag Formats
- `[v:voice]` or `[voice:name]`: Switches the active speaker voice.
- `[v:voice,l:lang]` or `[v:voice,lang:code]`: Switches voice and language simultaneously.
- `[v:voice:code]`: Shorthand for voice and language (e.g. `[v:m1:es]`).
- `[l:code]` or `[lang:code]`: Changes language while keeping the active voice.

### Sample-Rate Harmonization
When mixing Kokoro or PocketTTS (24.0 kHz) with Supertonic-3 (44.1 kHz):
- The first speaker in the session establishes the master stream rate.
- Any subsequent chunk from another engine is automatically resampled via `AVAudioConverter` in microseconds.
- There are no pops, clicks, or discontinuities during engine transitions.

---

## 5. Phonemization & Debugging

`sayx` includes Kokoro's native G2P (Grapheme-to-Phoneme) engine:

```bash
# Print phonemized IPA string and exit
sayx -p "Hello world"

# Print phonemes to terminal before speaking
sayx --show-phonemes "Hello world"

# Synthesize directly from pre-computed IPA phonemes (bypassing G2P)
sayx --from-phonemes "həˈloʊ wɜːld"
```
