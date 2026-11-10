## Why

Terminal coding agents (Claude Code, OpenCode, Codex) are driven by a handful of keys: Enter to
send, Esc to interrupt, Esc twice to rewind, arrows for history, digits for permission prompts.
With dictation and the wake word in place, the user still has to reach for the screen to send
what they dictated or to stop the agent. Spoken commands after the wake phrase ("hey scribe
send") close that gap, and work the same whether or not a dictation is in progress.

## What Changes

- New config list `dictation.wake_word.commands`. Each entry maps a phrase to either a key
  sequence (`{"say": "send", "keys": [["ENTER"]]}`, a list of chords sent in order) or a
  built-in action (`{"say": "delete that", "action": "delete_last"}`; actions `delete_last`,
  `cancel`, `finish`). Validated by `--validate`.
- Defaults chosen to work in Claude Code, OpenCode and Codex alike: send, stop, go back,
  previous, next, new line, next mode, option one/two/three, delete that, cancel, done. No
  Ctrl+C by default (pressing it twice exits all three tools).
- `kde-keybar-wake` learns the command phrases and prints `cmd N <seconds>` when the wake
  phrase is followed by command N, `wake` when the phrase stands alone. Unknown command words
  are skipped with a warning instead of failing the helper.
- `kde-keybar-wake --check-words WORD...` prints the words missing from the speech model, for
  the settings window.
- The bar runs commands in every dictation state: idle sends the keys; while recording it stops,
  trims the spoken command off the audio and the transcript, types the text, then sends the
  keys (`cancel` discards); while transcribing it queues the keys or drops the result.
- The bar remembers the last dictated text so `delete_last` can remove it with backspaces.

## Capabilities

### New Capabilities

- `voice-commands`: phrase-to-keys and phrase-to-action commands spoken after the wake phrase,
  their configuration, the helper protocol, and how they interact with an ongoing dictation.

### Modified Capabilities

- `wake-word`: a bare `wake` is emitted only once the helper knows no command follows, which
  delays dictation start slightly.

## Impact

- `kde-keybar-wake`: grammar, output protocol, `--check-words`.
- `kde-keybar`: DEFAULT_CONFIG, validation, `WakeWord` line handling, `Dictation` (stop with
  trim, transcript stripping, queued keys, last-text tracking).
- Docs, example config, changelog. The settings window editor is a separate change
  (`add-voice-commands-settings`).
