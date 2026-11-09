## Purpose

A touch-friendly GUI for editing the kde-keybar config, reachable from a bar button or the
`--settings` flag, that saves safely and reloads the running bar.

## ADDED Requirements

### Requirement: Settings button action
The bar SHALL support a button with `"action": "settings"` that opens the settings window, and the
default button set SHALL end with `{"label": "⚙", "action": "settings"}`.

#### Scenario: Opening from the bar
- **WHEN** the user taps a `settings` button and no settings window is open
- **THEN** a settings window for the bar's config opens

#### Scenario: Already open
- **WHEN** the user taps a `settings` button while the settings window is open
- **THEN** the existing window is raised and no second window is created

### Requirement: Standalone settings flag
`kde-keybar --settings` SHALL open only the settings window for the config given by `-c` (or the
default path), without creating the bar or any layer-shell surface.

#### Scenario: Launch from a launcher
- **WHEN** the user runs `kde-keybar --settings -c /path/to/config.json`
- **THEN** a normal toplevel settings window for that file opens and the process exits when it is
  closed

### Requirement: Editable settings
The window SHALL provide General, Dictation and Buttons tabs. General and Dictation SHALL be built
from field spec lists. Buttons SHALL allow editing the label, kind (keys, modifier, action), key
chord using only known key names, modifier key, action, per-button repeat (default, on, off), and
reordering, adding and deleting buttons.

#### Scenario: Unknown key name
- **WHEN** the user builds a key chord for a button
- **THEN** only names from the key code table can be added

#### Scenario: Nullable number
- **WHEN** the user ticks "Auto" on `margin_px`
- **THEN** `margin_px` is saved as `null`

### Requirement: Validated save
Apply and Save SHALL validate the edited config with the same rules as `--validate`. Errors SHALL
block saving and be shown in the window; warnings SHALL be shown without blocking. Cancel SHALL
close without writing.

#### Scenario: Invalid edit
- **WHEN** the edited config has a validation error and the user presses Save
- **THEN** the file is not written and the error is listed in the window

#### Scenario: Unparseable file
- **WHEN** the config file on disk is not valid JSON
- **THEN** the window shows the parse error and does not allow saving over it

### Requirement: Preserving save
Saving SHALL keep unknown keys and existing key order, write 2-space indented JSON with non-ASCII
characters unescaped and a trailing newline, and write atomically to the symlink target so a
symlinked config stays a symlink.

#### Scenario: Symlinked config
- **WHEN** the config path is a symlink and the user saves
- **THEN** the target file is replaced atomically and the path is still the same symlink

#### Scenario: Unknown keys
- **WHEN** the file contains keys the window does not know
- **THEN** they are written back unchanged and in their original position

### Requirement: Reload after save
After a successful save the running bar SHALL pick up the new config.

#### Scenario: Window inside the bar
- **WHEN** the window was opened from the bar's settings button and the user saves
- **THEN** the bar rebuilds with the new config right away

#### Scenario: Standalone on the default config
- **WHEN** `--settings` saves the default config path
- **THEN** running bar instances are sent SIGHUP

#### Scenario: Standalone on another config
- **WHEN** `--settings -c <other file>` saves
- **THEN** no running instance is signalled

#### Scenario: External edit to a symlink target
- **WHEN** the config is a symlink and its target file is edited in another directory
- **THEN** the bar reloads
