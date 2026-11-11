## Purpose

Let the user press keys and control dictation by speaking a command after the wake phrase.

## ADDED Requirements

### Requirement: Command configuration

The bar SHALL read voice commands from `dictation.wake_word.commands`, a list whose entries each
have a non-empty `say` phrase and exactly one of `keys` (a non-empty list of non-empty chords of
known key names) or `action` (`delete_last`, `cancel` or `finish`). When the key is absent the
default list SHALL be used. `--validate` MUST report malformed entries as errors and duplicate or
similar-sounding phrases as warnings.

#### Scenario: Defaults used

- **WHEN** the config has no `commands` key
- **THEN** the default commands (send, stop, go back, previous, next, new line, next mode, option one, option two, option three, delete that, cancel, done) are active

#### Scenario: Malformed entry

- **WHEN** an entry has both `keys` and `action`, or an unknown key name
- **THEN** `--validate` reports an error naming the entry

### Requirement: Helper command output

The wake word helper SHALL print `cmd N S` when the wake phrase is immediately followed by
command N (its index in the configured list), where S is the number of seconds of audio since
the wake phrase started, and SHALL print `wake` only when the wake phrase is heard with no
command following it. It MUST NOT print anything for a command phrase spoken without the wake
phrase.

#### Scenario: Command after the phrase

- **WHEN** the audio contains "hey scribe send"
- **THEN** the helper prints `cmd` with the index of "send" and nothing else

#### Scenario: Phrase alone

- **WHEN** the audio contains "hey scribe" followed by silence
- **THEN** the helper prints `wake`

#### Scenario: Command word without the phrase

- **WHEN** the audio contains "send it now"
- **THEN** the helper prints nothing

#### Scenario: Unknown command word

- **WHEN** a configured command contains a word missing from the speech model
- **THEN** the helper warns on stderr, skips that command, and keeps serving the others

### Requirement: Vocabulary check

`kde-keybar-wake --check-words WORD...` SHALL print every given word that is not in the speech
model's vocabulary, one per line, and exit 0, without opening the microphone.

#### Scenario: Mixed words

- **WHEN** it is run with a known and an unknown word
- **THEN** only the unknown word is printed

### Requirement: Commands while idle

When no dictation is running, a key command SHALL send its chords in order and an action SHALL
run: `delete_last` removes the text the last dictation typed; `cancel` and `finish` do nothing.

#### Scenario: Send

- **WHEN** "hey scribe send" is heard while idle
- **THEN** Enter is pressed once

#### Scenario: Delete the last dictation

- **WHEN** the last dictation typed 12 characters and "hey scribe delete that" is heard
- **THEN** Backspace is pressed 12 times

### Requirement: Commands during dictation

While recording, a command SHALL stop the recording at once, remove the spoken command from
both the audio and the transcript, type the remaining text, and then send the command's keys;
`cancel` and `delete_last` SHALL discard the recording instead. While transcribing, a key
command SHALL be sent after the text is typed and `cancel` SHALL drop the result.

#### Scenario: Dictate and send

- **WHEN** the user dictates "fix the login bug" followed by "hey scribe send"
- **THEN** "fix the login bug" is typed without the command words, then Enter is pressed

#### Scenario: Cancel mid-recording

- **WHEN** "hey scribe cancel" is heard while recording
- **THEN** the recording is discarded and nothing is typed
