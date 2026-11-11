## Context

kde-keybar is one Python script using GTK4 and gtk4-layer-shell, run from a GLib main loop without
`Gtk.Application`. The config is JSON, merged over `DEFAULT_CONFIG`, and validated by
`validate_config`. The author's config is a symlink into a dotfiles repo. Another branch is adding
`dictation.wake_word` settings at the same time.

## Goals / Non-Goals

**Goals:**
- Edit every config key the bar uses day to day, including buttons, from a touch screen.
- Never corrupt or replace the user's file: keep the symlink, unknown keys, and key order.
- Make adding new scalar settings (wake word) a few lines.

**Non-Goals:**
- libadwaita or any new dependency.
- Editing `modifier_keys`, `ydotool_socket`, or arbitrary unknown keys (they are preserved, not
  shown).
- Live preview while editing; changes apply on Apply/Save.

## Decisions

- **Plain GTK4 toplevel.** A normal `Gtk.Window` (not layer-shell) so it gets focus, a title bar,
  and the on-screen keyboard. libadwaita would look nicer but adds a dependency for one window.
  Controls get a CSS min-height so they are finger sized; each tab is a `Gtk.ScrolledWindow`.
- **Data-driven fields.** `GENERAL_FIELDS` and `DICTATION_FIELDS` are lists of dicts
  (`key` dot path, `type`, `label`, `help`, `choices`, `min`/`max`, `nullable`, `optional`).
  One builder turns each spec into a row. Defaults come from `DEFAULT_CONFIG` by the same path,
  so a new setting is one dict once its default exists.
- **Edit a copy of the raw file.** The window loads the file as JSON (not merged with defaults),
  shows defaults for missing keys, and only writes a key when its widget changes. Python dicts keep
  insertion order, so existing keys keep their position, new ones are appended, unknown keys pass
  through. A file that fails to parse is shown as an error and saving is disabled rather than
  overwriting it.
- **Validation.** `validate_config` is split into a file loader and `validate_config_data(cfg)`;
  the window validates the in-memory copy. Errors block saving, warnings are shown.
- **Symlink-safe atomic save.** Resolve with `os.path.realpath`, write a temp file in the target's
  directory, fsync, copy the old file mode, and `os.replace` onto the real file. The link itself is
  never touched.
- **Reload path.** Inside the bar process the window calls the bar's `rebuild()` directly. The
  standalone `--settings` process sends SIGHUP via `reload_running_instances()` only when the saved
  file is the default config, so test configs never poke a running bar; it ignores SIGHUP itself.
  The bar also monitors the realpath's directory, so external edits to a symlink target reload.
- **Scoped bar CSS.** The bar's provider is display-wide, so its selectors are prefixed with
  `window.kde-keybar` to keep the theme off the settings window.

## Risks / Trade-offs

- Saving from the bar process also triggers the file watcher, so the bar may rebuild twice. It is
  idempotent; the only cost is cancelling a dictation in progress, which a save would do anyway.
- argv fields are edited one item per line, so an empty-string argv item cannot be represented.
- The settings window inherits the system GTK theme; on Plasma that is Breeze-GTK if installed.
