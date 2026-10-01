# Voice Catalog & Speaker Routing

`sayx` provides a unified catalog of 78+ natural voices across 9 languages, combining models from **Kokoro-82M** (accelerated on the Apple Neural Engine) and **PocketTTS** (accelerated on the Apple GPU).

---

## Voice Resolution Overview

When selecting a voice via the CLI (`-v, --voice`) or inline dialogue tags (`[v:name]`), `sayx` resolves voices using the following priority order:

1. **Custom Cloned Presets:** Checked first in `~/.cache/sayx/voices/<name>/`. Automatically routes to PocketTTS.
2. **Kokoro-82M Friendly Aliases:** Matches informal names like `heart`, `adam`, `bella`, `george`. Automatically routes to Kokoro on the Apple Neural Engine.
3. **PocketTTS Studio Character Voices:** Matches names like `alba`, `javert`, `cosette`, `fantine`. Automatically routes to PocketTTS on the GPU.
4. **Canonical Kokoro Identifiers:** Exact IDs like `af_heart`, `am_adam`, `bm_george`, `zf_xiaobei`.

---

## 1. Built-in Kokoro-82M Voices (Apple Neural Engine)

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

## 2. Built-in PocketTTS Studio Voices (Kyutai FlowLM)

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

## 3. Inline Multi-Voice Switching (`[v:name]`)

You can switch voices clause-by-clause within a single text stream using inline bracket tags:

```bash
sayx "[v:adam] Central access confirmed. [v:bella] Proceeding to mainframe now."
```

### Transition Mechanics
- **Kokoro to Kokoro:** 0 ms overhead. The CoreML model graph remains resident; only the conditioning style vector is swapped.
- **Kokoro to PocketTTS:** Seamless. `EngineDispatcher` keeps both engines resident in unified memory. Audio buffers are queued sequentially into CoreAudio hardware with zero click, pop, or pause artifacts.
- **Multi-sentence turns:** A voice tag stays active across multiple sentences until a new `[v:...]` tag appears.

---

## 4. Phonemization & Debugging

`sayx` includes Kokoro's native G2P (Grapheme-to-Phoneme) engine:

```bash
# Print phonemized IPA string and exit
sayx -p "Hello world"

# Print phonemes to terminal before speaking
sayx --show-phonemes "Hello world"

# Synthesize directly from pre-computed IPA phonemes (bypassing G2P)
sayx --from-phonemes "həˈloʊ wɜːld"
```
