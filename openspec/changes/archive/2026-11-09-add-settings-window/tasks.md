## 1. Core

- [x] 1.1 Add the `settings` button action and append `⚙` to the default buttons
- [x] 1.2 Split `validate_config` into a loader and `validate_config_data`
- [x] 1.3 Add symlink-safe atomic `save_config` and dot-path get/set helpers
- [x] 1.4 Scope the bar CSS to the bar window

## 2. Settings window

- [x] 2.1 Field spec lists for General (incl. style overrides) and Dictation
- [x] 2.2 Generic field row builder (choice, bool, int, float, text, path, keys, argv)
- [x] 2.3 Buttons tab: label, kind, chord editor, modifier, action, repeat, move, delete, add
- [x] 2.4 Cancel / Apply / Save with validation errors and warnings shown

## 3. Wiring

- [x] 3.1 Open or raise the window from the bar and rebuild after save
- [x] 3.2 `--settings [TAB]` standalone mode, SIGHUP only for the default config
- [x] 3.3 Watch the symlink target's directory in the bar

## 4. Docs and checks

- [x] 4.1 Update docs/configuration.md, README.md, CHANGELOG.md, example config
- [x] 4.2 ruff check/format, py_compile, --validate on temp configs
- [x] 4.3 Round-trip and symlink save tests on temp configs
- [x] 4.4 Screenshot each tab from a standalone window
