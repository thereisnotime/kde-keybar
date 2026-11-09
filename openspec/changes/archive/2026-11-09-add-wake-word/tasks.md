## 1. Helper

- [x] 1.1 Write `kde-keybar-wake`: Vosk with `[phrase, "[unk]"]` grammar, partial-result hits with stability check, debounce, reset after a hit
- [x] 1.2 Audio from `parecord` (fallback `pw-record`), `--stdin` for tests, exit when the parent dies
- [x] 1.3 Exit status 3 with clear messages for missing Vosk, model, recorder, empty phrase, unknown words
- [x] 1.4 Test with espeak-ng clips via `--stdin`: phrase alone, in a sentence, twice, near-miss words, plain sentences, silence
- [x] 1.5 Measure CPU at real-time pace on 30 s of silence and of speech

## 2. Setup and packaging

- [x] 2.1 `just setup-wakeword`: venv (uv or python3 -m venv), vosk, model download, idempotent
- [x] 2.2 `just doctor` checks, `just install` / `uninstall`, `just check`, ruff and CI include the helper
- [x] 2.3 Ship `/usr/bin/kde-keybar-wake` in nfpm (deb + rpm) and the RPM spec

## 3. Bar integration

- [x] 3.1 `dictation.wake_word` in DEFAULT_CONFIG, example config, and `validate_config`
- [x] 3.2 `WakeWord` class: Gio.Subprocess, async line reads, backoff restart, one-time setup error
- [x] 3.3 Dictation: `listen()` after a successful rebuild, `wake_heard()` only when idle, stop on `cancel()` and exit
- [x] 3.4 Drop a wake-started recording that hears no speech in 5 s
- [x] 3.5 Test the listener with fake helpers (wake twice, crash, exit 3, missing python) and end to end with the real helper on stdin

## 4. Docs

- [x] 4.1 docs/configuration.md wake word section (keys, behavior, phrase choice, privacy, CPU)
- [x] 4.2 docs/installation.md, README features, CHANGELOG
