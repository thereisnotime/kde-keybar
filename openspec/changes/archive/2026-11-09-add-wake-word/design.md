## Context

Dictation records with `parecord` and transcribes with whisper.cpp, all driven from the GLib
main loop through `Gio.Subprocess`. Whisper is far too heavy to run continuously, so wake-word
spotting needs a separate, cheap recognizer. The bar runs on the system Python (PyGObject from
the distro), and Vosk is not packaged in Fedora.

## Goals / Non-Goals

**Goals:**

- Any word or phrase in the model's vocabulary, chosen in the config.
- Low steady CPU while listening, no UI blocking, no effect when disabled.
- Robust to the helper crashing or not being set up.

**Non-Goals:**

- A bar button or GUI for toggling (the settings window will expose the keys).
- Custom-trained wake word models, speaker verification, non-English defaults.
- Audible or visual feedback beyond the existing 🎤 button states.

## Decisions

**Vosk with a restricted grammar.** The helper builds a `KaldiRecognizer` with the grammar
`[phrase, "[unk]"]`. Decoding against a two-entry grammar is much cheaper than open
vocabulary decoding (measured ~5-7% of one core vs several times that) and the result can only
ever be the phrase or `[unk]`, so matching is a word-sequence check. Alternatives: openWakeWord
or Porcupine need per-phrase models (Porcupine also a licence key); full-vocabulary Vosk costs
more CPU and, on test clips, missed the bare phrase more often.

The flip side is that the grammar forces speech towards the phrase. On ~3 min of synthetic
sentences, a single word (`computer`) fired 10 times, two-word phrases 0-2 times. So the default
is a two-word phrase, `start dictation` (0 false hits, self-explanatory, both words in the
small model's vocabulary), and `--validate` warns about one-word phrases. Adding a few hundred
common words to the grammar as decoys cut false hits further at ~2x CPU; left out for now to keep
the grammar the documented `[phrase, "[unk]"]`.

**Hits from partial results, with a stability check and debounce.** Final results only arrive
after Vosk's endpointing, which is too late to catch the speech that follows. Partials arrive
every 100 ms chunk but flicker early in a word, so a partial hit counts only once the phrase has
stayed in it for 4 chunks in a row (a final result counts immediately). After a hit the
recognizer is reset, and any further hit within 1.5 s of audio is ignored so one utterance never
fires twice. The debounce is measured in audio time, not wall time, so stdin tests are exact.

**Separate helper process run from a venv.** Importing Vosk into the bar would tie the bar to
a pip install in the system Python (not allowed on Fedora without `--break-system-packages`)
and put a native library with its own threads into the GTK process. A helper keeps the bar's
dependencies unchanged, can be restarted on its own, and is easy to test with `--stdin`. The
bar finds it next to its own real path, so a checkout and `/usr/bin` both work. Its contract is
one line `wake` per hit on stdout, messages on stderr, and exit status 3 for setup problems.

**Bar integration.** `WakeWord` spawns the helper with `Gio.Subprocess`, reads stdout with
`Gio.DataInputStream.read_line_async`, and watches the exit with `wait_async`. Exit status 3 or
a missing interpreter/helper flashes `no wake` on 🎤 and logs once, with no retry until the next
rebuild. Any other exit restarts it after 1, 2, 4 ... 60 s (reset after a minute of uptime).
The listener belongs to the `Dictation` instance: `cancel()` (rebuild, exit) sends it SIGTERM,
and `rebuild()` starts the new one only after the new window was built. The helper also exits
when its parent changes, so a killed bar doesn't leave the mic open.

**State machine.** `wake` only acts in IDLE and calls `start(woken=True)`; RECORDING and
TRANSCRIBING ignore it. Silence auto-stop ends the recording as for a tap. A woken recording
also runs the level watcher even when auto-stop is off, and is dropped (no transcription) if no
speech is heard within 5 s, so a false trigger in a quiet room doesn't record for `max_seconds`.

## Risks / Trade-offs

- [False triggers type stray speech into the focused window] → two-word default, stability
  check, `--validate` warning, docs explain how to pick a phrase.
- [Mic always open while enabled] → off by default, documented; audio is never written to disk.
- [Words said right after the phrase can be clipped while `parecord` starts] → docs ask for a
  short pause; the recorder already uses 50 ms latency.
- [Two processes open the mic during a recording] → fine on PipeWire/PulseAudio.
- [Rebuilds (config change, rotation) restart the helper and reload the model, ~1.5 s CPU] →
  acceptable for how rarely they happen.
- [Phrase words not in the model vocabulary would be silently dropped by Vosk] → the helper
  checks each word and exits with status 3 and a message.

## Migration Plan

Opt-in only. Users run `just setup-wakeword` and set `dictation.wake_word.enabled`. Removing the
key or setting it false stops the helper on the next reload.
