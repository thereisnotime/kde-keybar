## 1. Tab

- [ ] 1.1 "Voice commands" tab and `--settings voice`, with the wake phrase hint and a note when the wake word is off
- [ ] 1.2 Command cards: phrase, kind dropdown, sequence editor reusing the chord chips/picker, add/remove step
- [ ] 1.3 Reorder, delete, add command, reset to defaults; writes only `dictation.wake_word.commands`

## 2. Checks

- [ ] 2.1 Inline errors (empty phrase, no keys) that block saving; duplicate and similar-phrase warnings
- [ ] 2.2 Async, debounced, cached `--check-words` call; graceful fallback when the helper or model is missing

## 3. Tests and docs

- [ ] 3.1 Widget tests on temp and symlinked configs: edit sequences, switch kind, reorder, reset, round-trip, blocked save, fake helper for the vocabulary check
- [ ] 3.2 Screenshot of the tab; docs Settings window section and CHANGELOG
