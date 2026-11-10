## Context

The wake word helper runs Vosk with a small grammar (phrase, its words, ~500 decoy words,
`[unk]`) and prints `wake`. The bar starts a dictation on `wake` when idle and ignores it
otherwise. Keys are sent through ydotool with the same chord sender the buttons use. On Wayland
the bar cannot see which app (or which TUI inside a terminal) has focus.

## Goals / Non-Goals

**Goals:**
- One configurable list of spoken commands, each sending keys or running a built-in action.
- Defaults that are useful in Claude Code, OpenCode and Codex without per-app logic.
- Commands work mid-dictation without leaving the spoken command in the typed text.

**Non-Goals:**
- Detecting the focused app and switching command sets automatically.
- Commands without the wake phrase prefix (a bare "send" mid-sentence would cut dictation off).
- Free-form voice control beyond a fixed phrase list.

## Decisions

- **Prefix every command with the wake phrase.** Keeps false fires near zero (the helper only
  reacts to phrase + command) and lets the same commands work while recording. Alternative
  considered: trailing "... send" detected in the transcript; rejected as the default because the
  word could no longer end a dictated sentence.
- **Commands live in the helper's grammar.** Adding `phrase + " " + command` entries keeps
  recognition constrained and cheap, and the existing decoys keep near-misses out. Recognition
  of command N is a single line `cmd N <seconds since the phrase started>`.
- **`wake` waits briefly.** The helper cannot tell "hey scribe" from "hey scribe send" until the
  utterance ends, so it emits `wake` on the final result or after ~0.7 s of the phrase standing
  alone. Measure the added latency; tune the hold if it hurts.
- **Keys as a list of chords.** Reuses the button chord semantics (press in order, release in
  reverse) and covers sequences such as Esc Esc and OpenCode's Ctrl+X leader.
- **Mid-dictation trimming does both audio and text.** Truncate the WAV by the reported seconds
  plus a small margin, then strip a trailing "hey scribe <command>" from the transcript ignoring
  case and punctuation (whisper writes "Hey, Scribe. Send."). Either alone leaves stray words.
- **`delete_last` uses the bar's own record** of what it typed (character count of what was
  actually typed) and sends backspaces. Correct only if the cursor has not moved; documented.
- **`--check-words` in the helper**, because only the venv can load the model; the settings
  window calls it asynchronously.

## Risks / Trade-offs

- Slower dictation start from a bare wake phrase (the hold) → keep it short and measured.
- Similar-sounding commands confuse each other → validation warns on prefixes and close
  matches; test every default with synthetic speech in several voices.
- Unknown words silently never fire in Vosk → the helper warns and skips them; the settings
  window flags them per row.
- Accidental destructive keys → no Ctrl+C in defaults; docs say why.
