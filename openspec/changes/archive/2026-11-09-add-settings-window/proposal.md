## Why

Changing anything in kde-keybar means editing JSON by hand, which is awkward on the device the bar
is built for: a tablet with no hardware keyboard. A settings window that edits the config with
touch-sized controls removes that step, and a button on the bar itself makes it reachable without
a terminal.

## What Changes

- New button action `"settings"` (`{"label": "⚙", "action": "settings"}`), appended to the default
  button set. Tapping it opens the settings window, or raises it if it is already open.
- New CLI flag `kde-keybar --settings [TAB]` that opens only the settings window for the config
  given by `-c` (no bar, no layer-shell surface).
- Settings window: a plain GTK4 toplevel with General, Dictation and Buttons tabs. General and
  Dictation are built from data-driven field specs; Buttons edits the button list (label, kind,
  key chord, modifier, action, repeat, reorder, add, delete).
- Saving validates with the existing `validate_config` rules (errors block, warnings are shown),
  keeps unknown keys and key order, and writes atomically next to the real file so a symlinked
  config stays a symlink.
- After a save the running bar reloads: directly when the window lives in the bar process, via
  SIGHUP when run standalone on the default config. The bar's config watcher also watches the
  directory of the symlink target.
- The bar's stylesheet is scoped to the bar window so it no longer leaks into other windows of the
  same process.

## Capabilities

### New Capabilities
- `settings-window`: GUI editor for the kde-keybar config, the `settings` button action, the
  `--settings` flag, and symlink-safe saving with reload.

### Modified Capabilities

## Impact

- `kde-keybar` (single script): new field specs, settings window, save helpers, CLI flag, button
  action, scoped CSS, extra file monitor.
- Docs: `docs/configuration.md`, `README.md`, `CHANGELOG.md`, `config/kde-keybar.example.json`.
- No new dependencies (GTK4 only, no libadwaita).
