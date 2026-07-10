# kde-keybar

<p align="center"><em>Terminal control keys on-screen for KDE Plasma Wayland.</em></p>

<p align="center">
  <a href="https://github.com/thereisnotime/kde-keybar/actions/workflows/ci.yml"><img src="https://github.com/thereisnotime/kde-keybar/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/thereisnotime/kde-keybar/releases"><img src="https://img.shields.io/github/v/release/thereisnotime/kde-keybar?sort=semver&color=blue" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT"></a>
  <img src="https://img.shields.io/badge/KDE%20Plasma%206-Wayland-1d99f3?logo=kde&logoColor=white" alt="KDE Plasma 6 Wayland">
  <img src="https://img.shields.io/badge/python-3.11%2B-3776ab?logo=python&logoColor=white" alt="Python 3.11+">
</p>

A small on-screen row of tappable keys for KDE Plasma Wayland. It rides along with your on-screen keyboard and sends the control chords the built-in ones can't: `Ctrl+C`, `Esc`, `Alt+Tab`, arrows, a tmux/zellij prefix, whatever you put in the config. The keys go to the focused window as real key events, so vim, tmux, zellij, and the like actually work from a touchscreen.

![kde-keybar](docs/demo.png)

> The image above is a placeholder. Drop a real screenshot or GIF at `docs/demo.png`.

## Why this exists

On KDE Plasma Wayland, KWin refuses the Wayland virtual-keyboard and input-method protocols to external clients as an anti-keylogger measure, so external on-screen keyboards like `wvkbd` and `onboard` cannot run at all. The keyboards that do work (Plasma Keyboard, Qt Virtual Keyboard, Maliit) only **commit text**, so they can't send `Ctrl+C`, `Esc`, or Alt-chords to a terminal.

kde-keybar works around this two ways:

- Keys are injected through **ydotool**, which talks to the kernel `uinput` device. KWin cannot block that path, so real chords reach the focused window.
- The bar shows and hides by watching KWin's `org.kde.kwin.VirtualKeyboard.visible` D-Bus signal, so it rides along with **any** of the built-in keyboards instead of replacing them.

You keep using your normal on-screen keyboard for typing, and kde-keybar gives you the control keys it can't send.

## Features

- Real key injection via ydotool (kernel `uinput`), not text commit, so chords work in terminals.
- Auto show/hide together with the on-screen keyboard.
- Layer-shell overlay that never steals focus from your text field.
- 15 built-in themes plus full color/transparency overrides.
- Optional always-on dock mode that reserves space like a panel.
- Live config reload: edit the JSON, save, the bar updates.
- Small single-file Python script.

## Quick start

```sh
# Fedora (deps)
sudo dnf install python3-gobject gtk4 gtk4-layer-shell ydotool

# install kde-keybar + enable the ydotool daemon
git clone git@github.com:thereisnotime/kde-keybar.git && cd kde-keybar
just install
just setup-ydotool
```

Then pick an on-screen keyboard in System Settings (Keyboard, Virtual Keyboard) and the bar shows above it. Prebuilt `.rpm`/`.deb` packages are on the [releases page](https://github.com/thereisnotime/kde-keybar/releases).

Full details: **[docs/installation.md](docs/installation.md)**.

## Documentation

- **[Installation](docs/installation.md)** — requirements, packages, source, ydotool setup.
- **[Configuration](docs/configuration.md)** — every config key, buttons and key chords, theming, commands, live reload, dock mode.
- **[Troubleshooting](docs/troubleshooting.md)** — the bar not appearing, buttons doing nothing, and other common cases.
- **[Compatibility](docs/compatibility.md)** — KDE, wlroots, GNOME/X11, and companion keyboards.
- **[Examples](examples/)** — ready-to-use configs (minimal, dock, transparent, zellij, vim).

## Compatibility

Built for KDE Plasma 6 on Wayland. Works partially on wlroots compositors (sway, Hyprland) with `visibility: "always"`. Not GNOME/Mutter or X11 yet. See [docs/compatibility.md](docs/compatibility.md).

## Roadmap

- GNOME (Mutter) and X11 support via a non-layer-shell fallback window. Tracked in the [issues](https://github.com/thereisnotime/kde-keybar/issues).
- A Plasma panel widget variant for keys docked in the taskbar.

## Development

```sh
just          # colored list of recipes
just doctor   # check runtime dependencies
just run      # always-on visual test
just check    # lint + format-check + syntax
just package  # build .rpm / .deb
```

The whole tool is a single Python file, `kde-keybar`. Linting is [ruff](https://docs.astral.sh/ruff/). See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
