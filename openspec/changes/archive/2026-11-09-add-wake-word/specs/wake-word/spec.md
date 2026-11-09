## Purpose

Let the user start dictation by saying a configured phrase instead of tapping the dictation
button, fully offline, with the microphone only listened to while the feature is enabled.

## ADDED Requirements

### Requirement: Wake word helper output

The wake word helper SHALL listen to 16 kHz mono 16-bit audio, from the default microphone or
from stdin when run with `--stdin`, and SHALL print exactly one line `wake` on stdout each time
the configured phrase is spoken. It MUST NOT print `wake` more than once for a single utterance
of the phrase.

#### Scenario: Phrase spoken once

- **WHEN** the audio contains the phrase once, alone or inside a longer sentence
- **THEN** the helper prints `wake` exactly once

#### Scenario: Phrase spoken twice with a pause

- **WHEN** the audio contains the phrase twice, separated by a few seconds
- **THEN** the helper prints `wake` twice

#### Scenario: No phrase

- **WHEN** the audio is silence or speech that does not contain the phrase
- **THEN** the helper prints nothing

### Requirement: Wake word helper setup errors

The helper SHALL exit with status 3 and a message on stderr when it cannot work without user
action: Vosk is not importable, the model directory is missing or invalid, a phrase word is not
in the model vocabulary, the phrase is empty, or no recorder is available.

#### Scenario: Model missing

- **WHEN** the helper is started with a model path that does not exist
- **THEN** it exits with status 3 and names the path and `just setup-wakeword` on stderr

#### Scenario: Unknown word

- **WHEN** the phrase contains a word the model does not know
- **THEN** it exits with status 3 and names the word on stderr

### Requirement: Wake word configuration

The config SHALL accept `dictation.wake_word` with `enabled` (boolean, default false), `phrase`
(non-empty string, default `start dictation`), `model` and `python` (non-empty paths, `~`
expanded). `kde-keybar --validate` SHALL report wrong types and an empty phrase as errors, and
unknown keys and one-word phrases as warnings.

#### Scenario: Disabled by default

- **WHEN** the config has no `dictation.wake_word` or `enabled` is false
- **THEN** the bar does not start the helper and does not open the microphone for it

#### Scenario: Invalid values

- **WHEN** `enabled` is not a boolean or `phrase` is blank
- **THEN** `--validate` prints an error for each and exits non-zero

### Requirement: Starting dictation from the wake word

When enabled, the bar SHALL run the helper and read its output without blocking the UI. On
`wake`, if dictation is idle, the bar SHALL start a recording exactly as a tap on the dictation
button would, and the normal silence auto-stop, transcription and typing SHALL follow. A `wake`
while recording or transcribing MUST be ignored. Listening SHALL continue whether or not the bar
is visible.

#### Scenario: Wake while idle

- **WHEN** the helper prints `wake` and dictation is idle
- **THEN** a recording starts and the dictation button shows the recording state

#### Scenario: Wake while busy

- **WHEN** the helper prints `wake` while a recording or transcription is in progress
- **THEN** nothing changes

#### Scenario: Nothing said after the phrase

- **WHEN** a wake-started recording hears no speech for 5 seconds
- **THEN** the recording is dropped without transcription and `no speech` flashes on the button

### Requirement: Helper lifecycle and failures

The bar SHALL stop the helper when the config is reloaded, when the window is rebuilt, and on
exit. If the helper exits unexpectedly, the bar SHALL restart it with an increasing delay capped
at 60 seconds. If the interpreter or helper is missing or the helper exits with status 3, the bar
SHALL flash a short message on the dictation button, log the reason once, and not retry until
the next reload. The helper SHALL exit on its own if the bar dies without stopping it.

#### Scenario: Helper crashes

- **WHEN** the helper exits with a status other than 3
- **THEN** the bar starts it again after 1 s, then 2 s, 4 s and so on

#### Scenario: Not set up

- **WHEN** the configured interpreter does not exist or the helper exits with status 3
- **THEN** `no wake` flashes on the dictation button, the reason is logged once, and no restart
  is attempted

#### Scenario: Config reload

- **WHEN** the config file changes
- **THEN** the old helper is stopped before the new configuration starts its own
