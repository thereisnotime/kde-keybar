# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Settings window: tap the new `⚙` button (`{"action": "settings"}`, appended to the
  default set) or run `kde-keybar --settings [general|dictation|buttons]` to edit the config
  in a plain GTK4 window with General, Dictation and Buttons tabs. Saving validates like
  `--validate` (errors block, warnings don't), keeps unknown keys and key order, and writes
  atomically to the symlink target so a config linked from a dotfiles repo stays a link.
  The bar reloads right after a save; standalone `--settings` only signals running bars
  when it saved the default config.

- Wake word for dictation: say a phrase ("hey scribe" by default) and dictation starts as
  if you had tapped 🎤, then stops on silence as usual. A new helper, `kde-keybar-wake`, spots
  the phrase with Vosk restricted to a one-phrase grammar and prints `wake`; the bar runs it as
  a subprocess and reads it without blocking, restarts it with backoff if it dies, and stops it
  on reload and exit. Off by default (`dictation.wake_word.enabled`), since it keeps the mic
  open. Vosk isn't packaged on Fedora, so `just setup-wakeword` puts it in a per-user venv and
  downloads `vosk-model-small-en-us-0.15`. The helper is installed by `just install` and ships
  in both packages; `just doctor` checks the venv and model. A wake-started recording that hears
  nothing for 5 s is dropped.

- Wake word `listen` setting (also in the settings window): `"always"` (default) or
  `"keyboard"`, which runs the listener only while the on-screen keyboard is open, so the
  mic is closed and nothing runs otherwise. Hiding stops it after 3 s, so the keyboard
  flickering between fields doesn't restart it.

- KWin script `kde-keybar-fit`: keeps the active window above the bar while it sits on top
  of the on-screen keyboard, so the bar no longer covers the bottom of the window (KWin only
  makes room for the keyboard itself). Installed and enabled by `just install`, shipped in
  the packages under `/usr/share/kwin/scripts/`. It also reports the keyboard's real height
  to the bar over D-Bus, so the bar sits flush on the keyboard instead of relying on the
  `keyboard_height_fraction` estimate, and re-maximizes windows KWin left at the shrunk
  size after the keyboard closed.

- Dictation stops by itself after you stop talking: `dictation.silence_stop_seconds`
  (default 1.5, `0` turns it off) of quiet, counted only once speech has been heard.
  `dictation.silence_level` sets what counts as quiet. Tapping again still stops it.

- One-shot modifier buttons: `{"label": "Ctrl", "modifier": "LCTRL"}` (now in the default
  set). Tap it and the bar turns into a key grid; the next key you tap is sent as
  Ctrl+key and the bar switches back. Works for any modifier (`LALT`, `LSUPER`, …).
  This exists because the on-screen keyboards commit text, so a held Ctrl never
  combines with letters typed on them.

- Hold to repeat: holding an arrow (or Backspace, Delete, PgUp/PgDn, Space) keeps sending
  it like a hardware keyboard, instead of firing once on release. Tunable with
  `repeat_delay_ms` / `repeat_interval_ms`, and any button can opt in or out with
  `"repeat": true|false`. It follows the button's own pressed state, so a tap still
  sends once and a swipe that starts on an arrow still scrolls the bar.

- Offline dictation button (`{"action": "dictate"}`, `🎤` in the default set). Tap to
  record, tap again to transcribe with a local open model and type the result into the
  focused window. Defaults to `parecord` + whisper.cpp (`whisper-cli`), and both commands
  are configurable argv templates under the new `dictation` key, so any speech CLI works.
  The default command sizes whisper's encoder window to the clip (`-ac {audio_ctx}`)
  and decodes greedily, which roughly halves transcription time; `setup-dictation` builds
  with Vulkan (GPU) when `glslc` is available. `output: "paste"` goes through `wl-copy` for non-ASCII text. New `just setup-dictation`
  builds `whisper-cli` from source into `~/.local/bin` and downloads a model, `just doctor` checks the optional deps, and the packages now
  recommend `pulseaudio-utils` and suggest `wl-clipboard`.

- `data/kde-keybar.service`, a user unit that owns startup and **restarts the bar
  when it dies**. kde-keybar exits non-zero if its Wayland connection drops (a
  compositor crash or restart); previously the XDG autostart entry had no way to
  express a restart policy, so the bar stayed dead until the next login, which can
  be weeks on a machine that only suspends. `PartOf=graphical-session.target` still
  stops it cleanly on logout, and `StartLimitBurst=5` avoids hammering a compositor
  that is genuinely gone. Installed by `just install` and by both packages.
- `X-systemd-skip=true` in the autostart entry, so `systemd-xdg-autostart-generator`
  no longer creates a second, restart-less unit that would race the real one.
  Non-systemd sessions still autostart from the `.desktop` as before.

- `Copy` and `Paste` buttons in the default button set, sending `Ctrl+C` / `Ctrl+V`.
  These are the GUI chords: in a terminal `Copy` sends SIGINT, exactly like the
  existing `^C` button. Swap them for `Ctrl+Shift+C` / `Ctrl+Shift+V` if you mostly
  use the bar over a terminal.

- Optional Maliit keyboard patches (`maliit/`, `just setup-maliit`): a working hide
  key, space long-press (cursor swipe) disabled, a more compact keyboard, and digit +
  symbol rows on the English and phonetic Bulgarian layouts. Idempotent, revertible, and
  re-applied after `maliit-keyboard` updates through a dnf actions hook.

### Fixed

- With a symlinked config, editing the target file (e.g. in a dotfiles repo) now reloads
  the bar too; only the link's directory was watched before.
- A partial `keyboard_height_fraction` (only `portrait` or only `landscape`) takes the
  missing one from the defaults instead of dropping to a fixed 320 px margin.
- The bar re-positions itself when the screen rotates (it kept the old orientation's
  margin until restarted).
- `--reload` only signals kde-keybar processes, not every process that has
  "kde-keybar" somewhere in its command line.
- Dictation: raised whisper's minimum audio context to 768. Smaller contexts misheard
  short clips ("above the" became "a month of").
- Wake word: saying only part of the phrase (just "start", or "hey there") no longer wakes
  it. Vosk was given only the phrase and a catch-all, so anything close got forced to the
  phrase; it now also gets the phrase's words alone and a few hundred common words to pick
  instead. Default phrase is now "hey scribe".
- Dictation no longer types `you` when the mic is muted. Whisper makes that up from
  silence, so clips that never rise above `silence_level` are dropped and the button
  shows `mic silent` instead.

### Changed

- The bar's theme stylesheet is scoped to the bar window, so it no longer styles other
  windows of the same process (the settings window).

- With `overflow: "scroll"` the bar no longer draws a horizontal scrollbar over the keys.
  It still scrolls by swiping or with the mouse wheel (the scrollbar is hidden in CSS;
  the scroll policy is unchanged so touch drag-scrolling keeps working).

## [0.1.0] - 2026-07-10

Initial release.

### Added

- On-screen key strip for KDE Plasma 6 Wayland that injects real key chords (Esc, Tab, Alt+Tab, Ctrl+C, arrows, Enter, and more) into the focused app.
- Key injection through `ydotool` / `ydotoold` (kernel `uinput`), which KWin cannot block, so chords reach terminals like vim, tmux, zellij, and Claude Code.
- Auto show/hide that follows any KDE on-screen keyboard by watching KWin's `org.kde.kwin.VirtualKeyboard.visible` D-Bus signal (`visibility: "keyboard"`), plus an `"always"` mode.
- GTK 3 layer-shell window anchored to the bottom (or top), lifted above the OSK by its height, with `keyboard-interactivity=none` so tapping it never steals focus.
- Responsive `FlowBox` layout that wraps buttons onto more rows on narrow or portrait screens.
- JSON config at `~/.config/kde-keybar.json`, auto-created on first run: `position`, `visibility`, `font_px`, `button_height_px`, `gap_px`, `margin_px`, `keyboard_height_fraction`, `ydotool_socket`, and fully customizable `buttons`.
- Configurable buttons defined as chords of evdev key names (modifiers, arrows, navigation, F1–F12, letters, digits, and punctuation).
- Environment overrides: `GDK_BACKEND`, `YDOTOOL_SOCKET`, `KEYBAR_MARGIN`, `KEYBAR_ALWAYS`.
- Autostart desktop entry (`data/kde-keybar.desktop`) and a root `ydotoold` systemd service (`data/ydotoold.service`) that exposes a user-owned socket.
- Packaging for `.rpm` and `.deb`, plus a Fedora COPR spec under `packaging/rpm/`.

[Unreleased]: https://github.com/thereisnotime/kde-keybar/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/thereisnotime/kde-keybar/releases/tag/v0.1.0
