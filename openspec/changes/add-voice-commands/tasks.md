## 1. Helper

- [ ] 1.1 Accept the command list; grammar gets phrase, phrase + command, command words, decoys, `[unk]`
- [ ] 1.2 Emit `cmd N S` (S from word timings or own bookkeeping) and a delayed `wake` (final result or ~0.7 s hold)
- [ ] 1.3 Skip commands with unknown words, with a stderr warning
- [ ] 1.4 `--check-words WORD...` (no audio, exit 0; exit 3 on setup errors)
- [ ] 1.5 Synthetic tests (espeak, 3 voices): every default fires as the right index, bare phrase gives `wake` (measure latency), no fires on the sentence corpus or on command words without the phrase

## 2. Bar

- [ ] 2.1 DEFAULT_CONFIG commands list and `validate_config_data` errors and warnings
- [ ] 2.2 Pass commands to the helper; parse `cmd` lines in `WakeWord`
- [ ] 2.3 Idle: send chord sequences; `delete_last` via remembered typed length
- [ ] 2.4 Recording: stop, trim WAV by S + margin, strip trailing command from transcript, type, then send keys; `cancel` / `delete_last` discard
- [ ] 2.5 Transcribing: queue keys after typing; `cancel` drops the result
- [ ] 2.6 Logic tests with a fake helper for every state, WAV trim validity, transcript stripping on whisper-style variants

## 3. Docs and release

- [ ] 3.1 docs/configuration.md (commands key, defaults, actions, mid-dictation behaviour, `--check-words`, why no Ctrl+C), example config, CHANGELOG
- [ ] 3.2 Install on the live machine, try each default in Claude Code and Codex, commit and push
