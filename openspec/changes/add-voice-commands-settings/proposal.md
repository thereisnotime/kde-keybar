## Why

Voice commands (`add-voice-commands`) are a phrase-to-keys table. Editing nested JSON lists of
chords by hand is error-prone, and a phrase with a word the speech model doesn't know silently
never fires. The settings window should edit the table directly and catch those mistakes.

## What Changes

- New "Voice commands" tab in the settings window (`kde-keybar --settings voice`).
- One card per command: phrase, kind (send keys / delete last dictation / cancel recording /
  finish dictation), and for keys a sequence editor (chords in order, each with the existing
  chip + key picker; add or remove steps). Reorder, delete, add, reset to defaults.
- Inline problems per card: empty phrase, no keys, duplicate or similar-sounding phrases, and
  words missing from the speech model (checked with `kde-keybar-wake --check-words`, run
  asynchronously).
- Errors block saving like the other tabs; saving only touches `dictation.wake_word.commands`.

## Capabilities

### New Capabilities

- `voice-commands-settings`: editing voice commands in the settings window, including
  validation feedback and the vocabulary check.

### Modified Capabilities

None.

## Impact

- `kde-keybar` settings window code only. Depends on the config schema and `--check-words`
  from `add-voice-commands`; works with an empty default list until that lands.
- Docs (Settings window section) and changelog.
