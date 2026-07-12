# Configuration

Config lives at `~/.config/kde-keybar.json` (respects `XDG_CONFIG_HOME`). It is written with the
defaults on first run, and any keys you omit fall back to those defaults. Changes apply live (see
[live reload](#live-reload)). Ready-made configs are in [`examples/`](../examples/).

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `position` | string | `"bottom"` | `"bottom"` places the bar above the OSK; `"top"` anchors it to the top edge. |
| `visibility` | string | `"keyboard"` | `"keyboard"` auto-shows/hides with the OSK via D-Bus; `"always"` keeps the bar on screen (and hugs the edge, no OSK margin). |
| `layer` | string | `"overlay"` | Stacking layer: `overlay` (above everything), `top`, `bottom`, or `background`. |
| `dock` | string/bool | `false` | Reserve space so windows avoid the bar. `false` (overlay, default), `"bar"` (reserve the strip), or `"keyboard"` (reserve the whole band up to the top of the bar, keyboard height included, so windows are pushed above the on-screen keyboard too). `true` is an alias for `"bar"`. |
| `monitor` | int or null | `null` | Output index to place the bar on. `null` uses the compositor default. |
| `font_px` | int | `20` | Button label font size in pixels. |
| `button_height_px` | int | `54` | Thickness of the strip (button height). |
| `button_min_width_px` | int | `64` | Minimum key width. When keys would be narrower than this, the row scrolls or wraps instead of shrinking further. |
| `overflow` | string | `"scroll"` | What happens when the keys do not fit one row: `"scroll"` (scroll sideways) or `"wrap"` (flow onto more rows). Keys always fill the width. |
| `gap_px` | int | `0` | Extra pixels between the bar and the keyboard. Positive nudges up, negative nudges down. |
| `margin_px` | int or null | `null` | Hard override of the bottom margin in pixels. `null` means auto-compute from the OSK height. Added on top of `gap_px`. |
| `keyboard_height_fraction` | object | `{ "landscape": 0.30, "portrait": 0.24 }` | Fraction of the screen height the OSK is assumed to cover, used to auto-place the bar above it. Selected by orientation. |
| `ydotool_socket` | string | `"/run/ydotoold.socket"` | Path to the `ydotoold` socket. Overridden by the `YDOTOOL_SOCKET` env var. |
| `theme` | string | `"dark"` | Built-in palette (run `kde-keybar --list-themes`). |
| `style` | object | `{}` | Overrides individual theme keys (see [theming](#theming)). |
| `buttons` | array | see below | List of buttons. Each entry is `{ "label": "<text>", "keys": ["<NAME>", …] }`. |

## Buttons and key chords

Each button has a `label` (any text, including Unicode like `←` or `⏎`) and a `keys` list. The
`keys` are **evdev key names** that form a chord: they are pressed in order and released in reverse
order. So `["LCTRL", "C"]` presses Ctrl, then C, then releases C, then Ctrl, which the focused app
sees as `Ctrl+C`.

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

Example, a zellij prefix (`Ctrl+B`) and a bare `F5`:

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

## Theming

Pick a built-in `theme`, tweak a theme with a few `style` overrides, or bring your own by setting
all the `style` keys:

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

## Always-on dock

To keep the bar on screen at all times as a panel that windows do not cover (instead of tracking
the keyboard), for example a permanent shortcut strip at the top:

```json
{ "visibility": "always", "position": "top", "dock": true }
```

`dock: "bar"` (or `true`) reserves the bar's height so maximized windows sit next to it, not under
it. See [`examples/dock-top.json`](../examples/dock-top.json).

### Push windows above the keyboard

The built-in on-screen keyboards only hover over windows; KWin does not reserve space for them.
You can get that effect anyway: with `dock: "keyboard"` and `visibility: "keyboard"`, the bar
reserves the whole band from the screen edge up to the top of the strip, keyboard height included.
KWin then pushes windows above that band, so the on-screen keyboard (which draws in the reserved
space) no longer covers your windows. The reservation appears and disappears with the keyboard.

```json
{ "dock": "keyboard", "position": "bottom", "visibility": "keyboard" }
```

The reserved height uses the same `keyboard_height_fraction` estimate as the bar placement, so tune
that (or `margin_px`) if the reserved band does not match your keyboard exactly.

## Commands

| Command | What it does |
| --- | --- |
| `kde-keybar` | Run the bar (this is what autostart launches). |
| `kde-keybar --list-themes` | Print the built-in theme names. |
| `kde-keybar --validate` | Check the config for errors and exit non-zero if any. |
| `kde-keybar --reload` | Tell running instances to reload their config now. |
| `kde-keybar -c <path>` | Use a config file other than the default. |
| `kde-keybar --version` | Print the version. |

## Live reload

kde-keybar watches its config file and reloads on save, so editing `~/.config/kde-keybar.json`
(theme, buttons, style, ...) updates the running bar with no restart. You can also force it with
`kde-keybar --reload`. If a save is momentarily invalid, the bar keeps the last good config and
logs a warning rather than crashing (run `--validate` to see why).

## Autostart

The bundled desktop entry ([`data/kde-keybar.desktop`](../data/kde-keybar.desktop)) is installed to
`/etc/xdg/autostart/` and launches kde-keybar in KDE autostart phase 2 with `GDK_BACKEND=wayland`.
Once installed, it starts with your session and appears whenever your on-screen keyboard shows
(with `visibility: "keyboard"`).

To run it manually for a quick look:

```sh
GDK_BACKEND=wayland KEYBAR_ALWAYS=1 kde-keybar
```

## Environment overrides

| Variable | Effect |
| --- | --- |
| `GDK_BACKEND=wayland` | Required. Layer-shell only works on the Wayland GDK backend. |
| `YDOTOOL_SOCKET` | Overrides `ydotool_socket` from the config. |
| `KEYBAR_MARGIN` | Overrides the bottom margin in pixels (integer). |
| `KEYBAR_ALWAYS` | If set, forces the bar to stay visible (same as `visibility: "always"`). |
