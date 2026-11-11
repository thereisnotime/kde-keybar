## Context

The settings window is plain GTK4 with data-driven General and Dictation tabs and a Buttons tab
that edits key chords with removable chips and a KEYCODES dropdown. Saves are validated with
`validate_config_data` and written symlink-safe. The speech model can only be loaded by the
wake helper's venv python.

## Goals / Non-Goals

**Goals:**
- Edit every field of a voice command by touch, including multi-step key sequences.
- Show problems where they are, before saving.
- Keep the UI responsive while words are checked against the model.

**Non-Goals:**
- Recording a phrase by voice to test it (possible follow-up).
- Editing the wake phrase here (it stays in the Dictation tab).

## Decisions

- **Reuse the Buttons chord editor per step.** A sequence is a vertical list of chord editors
  labelled "then"; same chips and picker, so unknown key names cannot be entered.
- **Kind dropdown instead of free-form JSON.** Switching kind swaps the keys editor for nothing
  and writes exactly one of `keys` / `action`.
- **Vocabulary check through the helper.** Run `<venv python> <helper> --check-words <words>
  --model <dir>` with Gio.Subprocess + communicate_utf8_async, debounced while typing, cached per
  word. A failed or missing helper shows "couldn't check words" instead of an error.
- **Similarity warnings are local.** Prefix match or difflib ratio above ~0.8, computed in the
  window without the model.
- **Show the wake phrase in the hint** ("say: hey scribe send") and a note pointing to the
  Dictation tab when the wake word is off.

## Risks / Trade-offs

- The model takes ~1.5 s to load per check → debounce and cache; never block the UI.
- Long command lists get tall on a portrait tablet → cards stay compact; the tab scrolls.
