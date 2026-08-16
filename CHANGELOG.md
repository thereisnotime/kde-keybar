# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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
