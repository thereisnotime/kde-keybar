## Why

Dictation needs a tap on 🎤, and the bar is usually hidden unless the on-screen keyboard is up.
A spoken phrase lets you start dictation hands-free, from any window, without opening the
keyboard first.

## What Changes

- New helper `kde-keybar-wake` that listens on the microphone and prints `wake` each time a
  configured phrase is heard. It also reads raw audio from stdin for testing.
- The bar runs the helper when `dictation.wake_word.enabled` is true and starts a dictation on
  each `wake` while dictation is idle. The existing silence auto-stop ends it.
- A wake-started recording that hears no speech within 5 s is dropped.
- New config block `dictation.wake_word` (`enabled`, `phrase`, `model`, `python`), validated by
  `--validate`. Off by default.
- `just setup-wakeword` creates a per-user venv with Vosk and downloads a small English model;
  `just doctor` checks both. `just install`, `just uninstall`, nfpm and the RPM spec handle the
  helper binary.
- No GUI or bar button: the setting is the only switch (a settings window is built separately).

## Capabilities

### New Capabilities

- `wake-word`: spotting a spoken phrase and starting dictation from it, including the helper's
  output contract, the bar's handling of helper failures, and configuration.

### Modified Capabilities

None. Dictation itself has no spec yet; its tap-driven behavior is unchanged.

## Impact

- `kde-keybar`: new `WakeWord` class, `Dictation` gains `listen()`/`wake_heard()` and the
  no-speech drop, `validate_config`, `DEFAULT_CONFIG`.
- New file `kde-keybar-wake`; `ruff.toml` and CI include it.
- New optional runtime dependency: Vosk (pip, in a user venv) plus a ~40 MB model. Not
  packaged, since Vosk isn't in Fedora.
- Privacy: the microphone stays open while the feature is enabled.
