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

On KDE Plasma Wayland, KWin refuses the Wayland virtual-keyboard and input-method protocols to external clients as an anti-keylogger measure. Because of that, external on-screen keyboards like `wvkbd` and `onboard` cannot run at all.

The keyboards that do work (Plasma Keyboard, Qt Virtual Keyboard, Maliit) only **commit text**. They can't send `Ctrl+C`, `Esc`, or Alt-chords to a terminal, so vim, tmux, zellij, and the like are unusable from a touchscreen.

kde-keybar works around this two ways:

- Keys are injected through **ydotool**, which talks to the kernel `uinput` device. KWin cannot block that path, so real chords reach the focused window.
- The bar shows and hides by watching KWin's generic `org.kde.kwin.VirtualKeyboard.visible` D-Bus signal, so it rides along with **any** of the built-in OSKs instead of replacing them.

You keep using your normal on-screen keyboard for typing, and kde-keybar gives you the control keys that keyboard can't send.

## Features

- Real key injection via ydotool (kernel `uinput`), not text commit, so chords work in terminals.
- Auto show/hide together with the OSK, driven by KWin's `VirtualKeyboard` D-Bus signal.
- Layer-shell window anchored to the bottom (or top), lifted above the OSK by its height.
- `keyboard-interactivity=none`: tapping the bar never steals focus from your text field.
- The bar is a single row; on narrow or portrait screens the overflow scrolls sideways instead of clipping.
- Fully configurable buttons: every button is a chord of evdev key names.
- Small single-file Python script, no background service of its own beyond the standard autostart entry.

## Requirements

- KDE Plasma 6 on Wayland
- `python3`
- PyGObject (`python3-gobject` / `python3-gi`)
- GTK 4
- `gtk4-layer-shell` (provides the `Gtk4LayerShell` typelib)
- `ydotool` and its `ydotoold` daemon

On Fedora:

```sh
sudo dnf install python3-gobject gtk4 gtk4-layer-shell ydotool
```

On Debian/Ubuntu:

```sh
sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-gtk4-layer-shell-1.0 ydotool
```

## Installation

### From packages

Prebuilt `.rpm` and `.deb` packages are attached to each [GitHub Release](https://github.com/thereisnotime/kde-keybar/releases) (built by CI).

```sh
# Fedora
sudo dnf install ./kde-keybar-*.rpm

# Debian/Ubuntu
sudo apt install ./kde-keybar_*.deb
```

A Fedora COPR spec also lives in [`packaging/rpm/`](packaging/rpm/) if you want to build it yourself.

### From source

```sh
git clone git@github.com:thereisnotime/kde-keybar.git
cd kde-keybar
just install
```

`just install` copies the script and the autostart entry into place. If you prefer to do it by hand:

```sh
sudo install -Dm755 kde-keybar /usr/bin/kde-keybar
sudo install -Dm644 data/kde-keybar.desktop /etc/xdg/autostart/kde-keybar.desktop
install -Dm644 config/kde-keybar.example.json ~/.config/kde-keybar.json
```

The config file is auto-created on first run if it does not exist, so copying the example is optional.

### ydotool setup

kde-keybar injects keys through `ydotoold`, which needs access to `/dev/uinput`. The easy path:

```sh
just setup-ydotool
```

That installs the bundled root system service ([`data/ydotoold.service`](data/ydotoold.service)) which runs `ydotoold` as root and creates `/run/ydotoold.socket` owned by your user. Running it this way means `ydotool` works without adding your user to any group.

To do it manually:

```sh
sudo install -Dm644 data/ydotoold.service /etc/systemd/system/ydotoold.service
# edit the --socket-own=UID:GID in the unit to match your user (id -u / id -g)
sudo systemctl daemon-reload
sudo systemctl enable --now ydotoold.service
```

The service loads the `uinput` module, then runs:

```
ydotoold --socket-path=/run/ydotoold.socket --socket-own=1000:1000
```

Point kde-keybar at that socket with the `ydotool_socket` config key (default `/run/ydotoold.socket`) or the `YDOTOOL_SOCKET` environment variable.

## Configuration

Config lives at `~/.config/kde-keybar.json` (respects `XDG_CONFIG_HOME`). It is written with the defaults on first run, and any keys you omit fall back to those defaults.

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `position` | string | `"bottom"` | `"bottom"` places the bar above the OSK; `"top"` anchors it to the top edge. |
| `visibility` | string | `"keyboard"` | `"keyboard"` auto-shows/hides with the OSK via D-Bus; `"always"` keeps the bar on screen. |
| `font_px` | int | `20` | Button label font size in pixels. |
| `button_height_px` | int | `54` | Thickness of the strip (button height). |
| `button_min_width_px` | int | `64` | Minimum key width. When keys would be narrower than this, the row scrolls or wraps instead of shrinking further. |
| `overflow` | string | `"scroll"` | What happens when the keys do not fit one row: `"scroll"` (scroll sideways) or `"wrap"` (flow onto more rows). Keys always fill the width. |
| `gap_px` | int | `0` | Extra pixels between the bar and the keyboard. Positive nudges up, negative nudges down. |
| `margin_px` | int or null | `null` | Hard override of the bottom margin in pixels. `null` means auto-compute from the OSK height. Added on top of `gap_px`. |
| `keyboard_height_fraction` | object | `{ "landscape": 0.30, "portrait": 0.24 }` | Fraction of the screen height the OSK is assumed to cover, used to auto-place the bar above it. Selected by orientation. |
| `ydotool_socket` | string | `"/run/ydotoold.socket"` | Path to the `ydotoold` socket. Overridden by the `YDOTOOL_SOCKET` env var. |
| `theme` | string | `"dark"` | Built-in palette (run `kde-keybar --list-themes`). |
| `style` | object | `{}` | Overrides individual theme keys (see below). Set a few keys to tweak a theme, or all of them to bring your own. |
| `buttons` | array | see below | List of buttons. Each entry is `{ "label": "<text>", "keys": ["<NAME>", …] }`. |

### Theming

Pick a built-in `theme`, tweak a theme with a few `style` overrides, or bring your own by
setting all the `style` keys:

```json
{ "theme": "nord" }
```
```json
{ "theme": "dark", "style": { "button_radius_px": 14, "button_active_bg": "#00b894" } }
```
```json
{ "style": { "background": "rgba(0,0,0,0.4)", "button_bg": "#222", "button_fg": "#fff" } }
```

Built-in themes: `dark` (default), `light`, `nord`, `nord-light`, `solarized`, `transparent`,
`matrix`, `dracula`, `gruvbox`, `gruvbox-light`, `catppuccin`, `tokyonight`, `rose-pine`,
`monokai`, `onedark`. Run `kde-keybar --list-themes` to see the current set.

### `style` keys

All optional; each overrides the chosen theme. Values are CSS color/length strings unless noted.

| Key | Default | Notes |
|---|---|---|
| `background` | `"rgba(20,20,24,0.92)"` | Bar background. Use an `rgba(...)` with alpha < 1 for transparency. |
| `button_bg` | `"#33343a"` | Key background. |
| `button_fg` | `"#eeeeee"` | Key label color. |
| `button_border` | `"#4a4b52"` | Key border color. |
| `button_border_px` | `1` | Key border width (int). |
| `button_radius_px` | `8` | Key corner radius (int). |
| `button_padding_px` | `6` | Key inner padding (int). |
| `button_hover_bg` | `"#44454c"` | Key background on hover. |
| `button_active_bg` | `"#5a6cff"` | Key background while pressed. |
| `font_family` | `null` | Font family for labels; `null` uses the default. |

### Buttons and key chords

Each button has a `label` (any text, including Unicode like `←` or `⏎`) and a `keys` list. The `keys` are **evdev key names** that form a chord: they are pressed in order and released in reverse order. So `["LCTRL", "C"]` presses Ctrl, then C, then releases C, then Ctrl, which the focused app sees as `Ctrl+C`.

Supported key names (from the script's `KEYCODES` map):

- Editing/control: `ESC`, `TAB`, `ENTER`, `SPACE`, `BACKSPACE`, `DELETE`, `INSERT`, `CAPSLOCK`
- Modifiers: `LCTRL`, `RCTRL`, `LALT`, `RALT`, `LSHIFT`, `RSHIFT`, `LSUPER`, `RSUPER`
- Arrows: `UP`, `DOWN`, `LEFT`, `RIGHT`
- Navigation: `HOME`, `END`, `PGUP`, `PGDN`
- Function keys: `F1`–`F12`
- Letters: `A`–`Z`
- Digits: `0`–`9`
- Punctuation: `MINUS`, `EQUAL`, `SLASH`, `BACKSLASH`, `GRAVE`, `SEMICOLON`, `APOSTROPHE`, `LEFTBRACE`, `RIGHTBRACE`, `COMMA`, `DOT`

Key names are matched case-insensitively. Unknown names are skipped with a warning on stderr.

### Example button entries

A zellij prefix (`Ctrl+B`) and a bare `F5`:

```json
{
  "buttons": [
    { "label": "^B", "keys": ["LCTRL", "B"] },
    { "label": "F5", "keys": ["F5"] },
    { "label": "Super", "keys": ["LSUPER"] },
    { "label": "^⇧V", "keys": ["LCTRL", "LSHIFT", "V"] }
  ]
}
```

## Usage and autostart

The bundled desktop entry ([`data/kde-keybar.desktop`](data/kde-keybar.desktop)) is installed to `/etc/xdg/autostart/` and launches kde-keybar in KDE autostart phase 2 with `GDK_BACKEND=wayland`. Once installed, it starts with your session and appears whenever your on-screen keyboard shows (with `visibility: "keyboard"`).

To run it manually for a quick look:

```sh
GDK_BACKEND=wayland KEYBAR_ALWAYS=1 kde-keybar
```

### Commands

| Command | What it does |
| --- | --- |
| `kde-keybar` | Run the bar (this is what autostart launches). |
| `kde-keybar --list-themes` | Print the built-in theme names. |
| `kde-keybar --validate` | Check the config for errors and exit non-zero if any. |
| `kde-keybar --reload` | Tell running instances to reload their config now. |
| `kde-keybar -c <path>` | Use a config file other than the default. |
| `kde-keybar --version` | Print the version. |

**Config changes apply live.** kde-keybar watches its config file and reloads on save, so
editing `~/.config/kde-keybar.json` (theme, buttons, style, ...) updates the running bar with no
restart. You can also force it with `kde-keybar --reload`. If a save is momentarily invalid, the
bar keeps the last good config and logs a warning rather than crashing (run `--validate` to see why).

### Environment overrides

| Variable | Effect |
| --- | --- |
| `GDK_BACKEND=wayland` | Required. Layer-shell only works on the Wayland GDK backend. |
| `YDOTOOL_SOCKET` | Overrides `ydotool_socket` from the config. |
| `KEYBAR_MARGIN` | Overrides the bottom margin in pixels (integer). |
| `KEYBAR_ALWAYS` | If set, forces the bar to stay visible (same as `visibility: "always"`). |

## Troubleshooting

**The bar doesn't appear.** It must run under the Wayland GDK backend. Start it with `GDK_BACKEND=wayland` (the installed desktop entry already does this). Also confirm `gtk4-layer-shell` is installed. The script sets `LD_PRELOAD` for `libgtk4-layer-shell.so.0` by re-executing itself; if you package it differently, make sure that preload happens.

**Buttons do nothing.** `ydotoold` is probably not running, or the socket path is wrong. Check `systemctl status ydotoold`, confirm `/run/ydotoold.socket` exists and is owned by your user, and make sure `ydotool_socket` / `YDOTOOL_SOCKET` points at it. Verify `ydotool` is on `PATH`.

**Buttons are cut off on the right in portrait.** The bar keeps a single row and the overflow scrolls sideways, so nothing is clipped. If you want everything visible without scrolling, remove some buttons in the config or lower `font_px`.

**Bar sits at the wrong height over the keyboard.** Tune `keyboard_height_fraction` for your OSK, nudge with `gap_px`, or set a hard `margin_px` (or `KEYBAR_MARGIN`) override.

## Compatibility

kde-keybar is built for KDE Plasma 6 on Wayland (KWin) and works alongside Plasma Keyboard, Qt Virtual Keyboard, and Maliit.

### Companion on-screen keyboard

kde-keybar is not a full keyboard: it provides the control keys the built-in ones can't send. Pair it with any KWin on-screen keyboard for text entry:

- **Plasma Keyboard** (`plasma-keyboard`) is the stock default and the most stable choice.
- **Maliit** (`maliit-keyboard`) is what we run, because its QML layout is easy to customize (font size, extra rows, symbols). Note that on current Fedora it can crash on the Wayland "surrounding text" event; kde-keybar is unaffected by that since it doesn't depend on the keyboard.

Select one under System Settings, Keyboard, Virtual Keyboard. kde-keybar shows above whichever you pick.

On wlroots compositors (sway, Hyprland) the two core pieces still work: ydotool injection and the layer-shell window. The auto-show hook is KDE-specific, though, because it listens on KWin's `org.kde.kwin.VirtualKeyboard` D-Bus interface. On those compositors set `visibility` to `"always"` (or run with `KEYBAR_ALWAYS=1`) and place the bar yourself.

## Roadmap

- GNOME (Mutter) and X11 support via a non-layer-shell fallback window (regular always-on-top window instead of `wlr-layer-shell`). Tracked in the [issues](https://github.com/thereisnotime/kde-keybar/issues).
- A Plasma panel widget variant for people who want a few keys docked in the taskbar rather than floating.

## Development

Recipes are managed with [`just`](https://github.com/casey/just):

```sh
just              # list available recipes
just run          # quick always-on visual test (GDK_BACKEND=wayland, KEYBAR_ALWAYS)
just lint         # run ruff
just install      # install script + autostart entry locally
just package      # build the .rpm / .deb packages
```

The whole tool is a single Python file, `kde-keybar`. Linting is done with [ruff](https://docs.astral.sh/ruff/).

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, style, and how to test locally.

## License

MIT. See [LICENSE](LICENSE).
