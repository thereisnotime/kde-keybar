## Purpose

Let the user edit voice commands in the settings window and see mistakes before saving.

## ADDED Requirements

### Requirement: Voice commands tab

The settings window SHALL have a "Voice commands" tab, also opened by `--settings voice`, that
lists every command with its phrase and either its key sequence or its action, and SHALL let the
user add, delete, reorder and edit commands and reset the list to the defaults. When the config
has no command list the defaults SHALL be shown.

#### Scenario: Edit a key sequence

- **WHEN** the user adds a second step with Esc to the "stop" command and saves
- **THEN** the config contains `{"say": "stop", "keys": [["ESC"], ["ESC"]]}`

#### Scenario: Switch kind

- **WHEN** the user changes a command from "Send keys" to "Cancel recording" and saves
- **THEN** that entry has `"action": "cancel"` and no `keys`

#### Scenario: Other settings untouched

- **WHEN** the user saves after editing only voice commands
- **THEN** every other key in the config file keeps its value and order

### Requirement: Problems shown before saving

Each command card SHALL show its problems inline: empty phrase, no keys, duplicate phrase,
similar-sounding phrases, and words not in the speech model. Empty phrases, missing keys and
other schema errors MUST block saving; similarity and vocabulary problems SHALL warn without
blocking.

#### Scenario: Unknown word

- **WHEN** a phrase contains a word the speech model does not know
- **THEN** the card shows that word as not in the speech model

#### Scenario: Empty phrase blocks saving

- **WHEN** a command has an empty phrase and the user presses Save
- **THEN** nothing is written and the error is shown

### Requirement: Responsive vocabulary check

The vocabulary check SHALL run in the background and MUST NOT block the window. If the helper
or model is unavailable the tab SHALL say the words could not be checked instead of failing.

#### Scenario: Wake word not set up

- **WHEN** the venv or model is missing
- **THEN** the tab shows that words couldn't be checked and editing and saving still work
