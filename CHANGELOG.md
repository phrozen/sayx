# Changelog

All notable changes to `sayx` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-10-20

### Added
- Supertonic-3 diffusion engine running on Apple Neural Engine (ANE) with 44.1 kHz studio audio output.
- Multilingual synthesis supporting 31 languages via `--lang` / `-l` (e.g., en, es, fr, de, ja, ko, zh).
- Configurable flow-matching diffusion ODE steps via `--steps` (1 to 50, default 5).
- 10 Supertonic semantic character voice aliases (`m-narrator`, `f-studio`, `m-casual`, etc.).
- Standalone and composite language directives in inline speaker tags (`[l:es]`, `[v:m1,l:es]`).
- Native Swift Testing targets (`SayXUnitTests` with 36 tests, `SayXIntegrationTests` with 9 tests).
- Automated GitHub Actions continuous integration workflow on pull requests and pushes to `main`.
- `SO_NOSIGPIPE` socket protection and robust disconnection handling for Unix domain streaming socket.

### Changed
- Decoupled application architecture into a reusable `SayXCore` library target and a thin `@main` CLI runner in `sayx`.
- Replaced legacy embedded `sayx test` runner with standard `swift test`.
- Updated release workflow to execute unit tests prior to asset packaging.
- Refreshed all CLI documentation, guides, and model architecture references.

### Removed
- Removed internal diagnostic test harness and `sayx test` command from shipping binary.

## [1.0.0] - 2026-10-01

### Added
- Initial release of `sayx` next-generation speech synthesis CLI for macOS on Apple Silicon.
- Kokoro-82M inference on Apple Neural Engine (24 kHz).
- PocketTTS FlowLM + Mimi neural audio codec on-device voice cloning.
- CoreAudio DSP for time stretching (0.03x to 32.0x) and pitch shifting (-2400 to +2400 cents).
- Apple Accelerate vDSP peak and RMS audio normalization with -1.0 dBFS ceiling.
- Unix domain socket streaming daemon (`sayx listen`) with JSON telemetry.
- Audio file export to WAV format (`-o`).
- In-memory sample rate harmonization between 24.0 kHz and 44.1 kHz.
