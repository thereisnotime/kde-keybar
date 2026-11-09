# Configuration

Config lives at `~/.config/kde-keybar.json` (respects `XDG_CONFIG_HOME`). It is written with the
defaults on first run, and any keys you omit fall back to those defaults. Changes apply live (see
[live reload](#live-reload)). Ready-made configs are in [`examples/`](../examples/). Most of it can
also be edited without touching JSON in the [settings window](#settings-window).

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
| `overflow` | string | `"scroll"` | What happens when the keys do not fit one row: `"scroll"` (swipe sideways, no scrollbar is drawn) or `"wrap"` (flow onto more rows). Keys always fill the width. |
| `gap_px` | int | `0` | Extra pixels between the bar and the keyboard. Positive nudges up, negative nudges down. |
| `margin_px` | int or null | `null` | Hard override of the bottom margin in pixels. `null` means auto-compute from the OSK height. Added on top of `gap_px`. |
| `keyboard_height_fraction` | object | `{ "landscape": 0.30, "portrait": 0.24 }` | Fraction of the screen height the OSK is assumed to cover, used to auto-place the bar above it. Selected by orientation. |
| `ydotool_socket` | string | `"/run/ydotoold.socket"` | Path to the `ydotoold` socket. Overridden by the `YDOTOOL_SOCKET` env var. |
| `repeat_delay_ms` | int | `400` | How long a key must be held before it starts repeating. |
| `repeat_interval_ms` | int | `50` | Time between repeats while held (50 ms = 20 keys/s). |
| `theme` | string | `"dark"` | Built-in palette (run `kde-keybar --list-themes`). |
| `style` | object | `{}` | Overrides individual theme keys (see [theming](#theming)). |
| `buttons` | array | see below | List of buttons. Each entry is `{ "label": "<text>", "keys": ["<NAME>", …] }`, `{ "label": "Ctrl", "modifier": "LCTRL" }` for a [one-shot modifier](#one-shot-ctrl--alt), `{ "label": "🎤", "action": "dictate" }` for the [dictation](#dictation) button, or `{ "label": "⚙", "action": "settings" }` to open the [settings window](#settings-window). |
| `modifier_keys` | array | A–Z, arrows, Tab, ⏎, digits, symbols | Keys offered after tapping a `modifier` button. |
| `dictation` | object | see [dictation](#dictation) | Recorder, speech model, and output settings for the dictation button, plus the optional [wake word](#wake-word). |

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

### One-shot Ctrl / Alt

The on-screen keyboards commit letters as text, so a Ctrl held down by kde-keybar would not
combine with a letter typed on them. A `modifier` button solves it inside the bar instead:
tap **Ctrl**, the bar turns into a grid of keys (A–Z, arrows, Tab, ⏎, digits, symbols), tap one,
and kde-keybar sends Ctrl+that key and switches straight back. Tap **Ctrl ✕** to cancel. The
grid also closes when the on-screen keyboard hides.

```json
{ "label": "Ctrl", "modifier": "LCTRL" },
{ "label": "Alt",  "modifier": "LALT" },
{ "label": "^⇧",   "modifier": "LCTRL", "keys": ["C", "V", "T", "W"] }
```

`keys` on a modifier button limits its grid; otherwise the top-level `modifier_keys` list (or the
built-in one) is used. For two modifiers at once, combine them in a plain chord button instead,
e.g. `{ "label": "^⇧V", "keys": ["LCTRL", "LSHIFT", "V"] }`.

### Hold to repeat

Holding a button sends the chord once, waits `repeat_delay_ms`, then repeats every
`repeat_interval_ms` until you let go, like a hardware keyboard. This is on by default for
single-key buttons on `UP`, `DOWN`, `LEFT`, `RIGHT`, `BACKSPACE`, `DELETE`, `PGUP`, `PGDN`, and
`SPACE`. Turn it on or off per button with `"repeat"`:

```json
{ "label": "^W", "keys": ["LCTRL", "W"], "repeat": true },
{ "label": "↓",  "keys": ["DOWN"], "repeat": false }
```

A swipe that starts on a repeating key still scrolls the bar and sends nothing.

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

## Dictation

A button with `"action": "dictate"` (in the default set as `🎤`) turns speech into typed text,
fully offline:

1. Tap it: recording starts and the button turns red (`● Rec`).
2. Stop talking: after `silence_stop_seconds` of quiet (1.5 s by default) recording stops by
   itself. You can also tap again, or it stops at `max_seconds`. Then and the button shows `…` while the model runs.
3. The transcript is typed into the focused window, then the button goes back to `🎤`.

```json
{
  "buttons": [{ "label": "🎤", "action": "dictate" }],
  "dictation": {
    "record_command": ["parecord", "--channels=1", "--rate=16000", "--format=s16le", "--file-format=wav", "--latency-msec=50", "{wav}"],
    "transcribe_command": ["whisper-cli", "-m", "{model}", "-f", "{wav}", "-l", "{language}", "-ac", "{audio_ctx}", "-bs", "1", "-bo", "1", "-nt", "-np"],
    "model": "~/.local/share/kde-keybar/models/ggml-base.en.bin",
    "language": "en",
    "output": "type",
    "paste_keys": ["LCTRL", "V"],
    "max_seconds": 120,
    "silence_stop_seconds": 1.5,
    "silence_level": 300
  }
}
```

| Key | Default | Description |
| --- | --- | --- |
| `record_command` | `parecord …` | argv that records 16 kHz mono WAV to `{wav}` until it gets SIGINT. `["pw-record", "--rate=16000", "--channels=1", "{wav}"]` also works. |
| `transcribe_command` | `whisper-cli … -ac {audio_ctx} -bs 1 -bo 1 …` | argv that prints the transcript on stdout. Lines wrapped in `[...]` or `(...)` (like `[BLANK_AUDIO]`) are dropped. |
| `model` | `~/.local/share/kde-keybar/models/ggml-base.en.bin` | Substituted for `{model}`. `~` is expanded. Get one with `just setup-dictation [name]`. |
| `language` | `"en"` | Substituted for `{language}`. Use `"auto"` with a multilingual model (no `.en` suffix). |
| `output` | `"type"` | `"type"` uses `ydotool type` (US layout, ASCII only). `"paste"` copies with `wl-copy` and sends `paste_keys`, which handles any Unicode. |
| `paste_keys` | `["LCTRL", "V"]` | Chord used by `output: "paste"`. Use `["LCTRL", "LSHIFT", "V"]` for terminals. |
| `max_seconds` | `120` | Auto-stop after this many seconds. `0` disables the limit. |
| `silence_stop_seconds` | `1.5` | Stop by itself after this much quiet, counted only once speech has been heard (so it waits while you think of what to say). `0` disables it: tap again to stop. Needs a recorder writing 16 kHz 16-bit mono WAV, like the default. |
| `silence_level` | `300` | Peak sample level (0 to 32767) below which audio counts as quiet. Used by auto-stop and to skip clips that are entirely silent, like a muted mic, which whisper would otherwise "transcribe" as `you`. Raise it in a noisy room if auto-stop never fires. |

Placeholders `{wav}`, `{model}`, `{language}`, and `{audio_ctx}` are replaced in every argv entry.
`{audio_ctx}` is the whisper encoder context sized to the recording (whisper otherwise always
encodes a full 30 s window, so a 5 s clip costs as much as a 30 s one).

### Making transcription faster

Rough numbers for an 11 s clip on an i7-1185G7 (CPU, power-saving clocks):

| Setup | Time |
| --- | --- |
| `base.en`, whisper defaults (30 s window, beam 5) | ~6.5 s |
| `base.en` + `-ac {audio_ctx}` + greedy (the default command) | ~3.5-4.5 s |
| `base.en-q5_1` (quantized) + same flags | ~3.5 s |
| `tiny.en` + same flags | ~1.5 s |

In order of impact:

1. **GPU build.** Install `glslc` and the Vulkan headers and run `REBUILD=1 just setup-dictation`;
   the encoder then runs on the iGPU/GPU.
2. **Smaller model.** `just setup-dictation tiny.en` (fastest, a bit less accurate) or
   `base.en-q5_1` (quantized, same accuracy as `base.en`), then set `dictation.model`.
3. Keep `-ac {audio_ctx}` and `-bs 1 -bo 1` in `transcribe_command` (already the default). Any open model
with a CLI works. For example, with [faster-whisper](https://github.com/SYSTRAN/faster-whisper)
through a small wrapper script:

```json
{ "dictation": { "transcribe_command": ["fw-transcribe", "{wav}"] } }
```

Run `just doctor` to check the dictation dependencies. Errors (missing model, recorder, or CLI)
flash briefly on the button and are logged on stderr (`journalctl --user -u kde-keybar`).

### Wake word

Say a phrase instead of tapping 🎤. Set it up once with `just setup-wakeword` (a Vosk venv and
a ~40 MB English model, see [installation](installation.md#wake-word-optional)), then enable it:

```json
{
  "dictation": {
    "wake_word": {
      "enabled": true,
      "phrase": "start dictation",
      "model": "~/.local/share/kde-keybar/models/vosk-model-small-en-us-0.15",
      "python": "~/.local/share/kde-keybar/wake-venv/bin/python"
    }
  }
}
```

| Key | Default | Description |
| --- | --- | --- |
| `enabled` | `false` | Start the listener. Off by default because it keeps the microphone open. |
| `phrase` | `"start dictation"` | Word or phrase to listen for. Every word must be in the model's vocabulary; the helper says so on stderr if one isn't. |
| `model` | `~/.local/share/kde-keybar/models/vosk-model-small-en-us-0.15` | Vosk model directory. Any [Vosk model](https://alphacephei.com/vosk/models) works; the small ones are plenty for a single phrase. |
| `python` | `~/.local/share/kde-keybar/wake-venv/bin/python` | Interpreter that has `vosk` installed. |

How it behaves:

- When the phrase is heard and dictation is idle, a recording starts exactly as if you had
  tapped 🎤, and the usual silence auto-stop ends it, transcribes, and types the text. Saying the
  phrase while recording or transcribing does nothing.
- If you say nothing within 5 s after the phrase, the recording is dropped (`no speech` flashes on
  the button). That keeps a false trigger from recording for `max_seconds`.
- It keeps listening whether or not the bar is visible: dictation types into the focused window
  either way, so you can use it with the on-screen keyboard closed.
- Leave a short pause after the phrase. It is usually spotted right as you finish saying it,
  but the recorder needs a moment to start, and words spoken before that are lost. If the bar is
  visible, the button turning red is your cue.

**Choosing a phrase.** The helper restricts Vosk to just the phrase plus a catch-all, which makes
it cheap but also pulls everything said towards the phrase. On ~3 minutes of ordinary synthetic
(espeak) sentences, the single word `computer` fired 10 times ("compile", "commutes", "computing"
all count), `hey computer` and `okay computer` twice each, and `start dictation` never. A false
trigger during conversation would record and type what you say next, so pick two fairly long
words you would not say in passing; `kde-keybar --validate` warns about one-word phrases.

**Privacy and cost.** While `enabled` is true the microphone is open all the time, as long as the
bar is running (PipeWire/Plasma show the mic as in use). Audio never leaves the machine and is not
written to disk; the helper only prints a line when it hears the phrase. On an i7-1185G7 the helper
used about 5-7% of one core while listening (measured on 30 s of silence and of speech at
real-time pace), plus ~1.5 s of CPU and ~165 MB of RAM to load the model. It restarts with a
growing delay if it crashes; if the venv or model is missing, `no wake` flashes on 🎤 once and the
reason is logged, and it tries again on the next config change.

## Settings window

Tap **⚙** on the bar (`{ "label": "⚙", "action": "settings" }`, last in the default set) or run
`kde-keybar --settings` to edit the config in a normal window instead of JSON. Tapping ⚙ again
while it is open brings the existing window to the front.

- **General**: placement, visibility, layer, dock, monitor, theme, sizes, overflow, margins,
  keyboard height fractions, hold-to-repeat timing, and the [`style`](#style-keys) overrides
  (leave a field empty to use the theme's value).
- **Dictation**: model file, language, output, paste chord, auto-stop, and the record and
  transcribe commands (one argument per line).
- **Buttons**: label, kind (key chord, one-shot modifier, or action), the chord itself (picked
  from the [known key names](#buttons-and-key-chords), so typos are impossible), the grid keys of
  a modifier button, per-button hold-to-repeat (default, on, off), reorder, add, and delete.

**Apply** saves and keeps the window open, **Save** saves and closes, **Cancel** closes without
writing. Saving runs the same checks as `--validate`: errors are listed in the window and nothing
is written, warnings are shown but do not block. If the file on disk is not valid JSON, the
window says so and refuses to save over it.

The file is rewritten as 2-space-indented JSON. Keys the window does not know about are kept,
existing keys keep their order, and only the keys you change are added. If the config is a
symlink (for example into a dotfiles repo), the link is kept: the target file is replaced
atomically through a temp file in its own directory.

After a save the bar reloads right away. From the ⚙ button the window lives inside the bar, so
it rebuilds directly. `kde-keybar --settings` on the default config tells running bars to reload
(like `--reload`); with `-c <other file>` nothing is signalled. `--settings general`,
`--settings dictation`, or `--settings buttons` opens on that tab.

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
| `button_active_bg` | `"#5a6cff"` | Key background while pressed (and while dictation is transcribing). |
| `button_recording_bg` | `"#c0392b"` | Dictation button background while recording. |
| `font_family` | `null` | Font family for labels; `null` uses the default. |

## Always-on dock

To keep the bar on screen at all times as a panel that windows do not cover (instead of tracking
the keyboard), for example a permanent shortcut strip at the top:

```json
{ "visibility": "always", "position": "top", "dock": true }
```

`dock: "bar"` (or `true`) reserves the bar's height so maximized windows sit next to it, not under
it. See [`examples/dock-top.json`](../examples/dock-top.json).

### Keep windows above the bar (KWin script)

KWin moves the active window out of the way of the on-screen keyboard, but it does not know
about a bar floating on top of the keyboard, so with the default `dock: false` the bar covers
the bottom of the window. Reserving space with `dock` does not help either: KWin always places
the keyboard above reserved space, which puts the bar *under* the keyboard.

The bundled KWin script `kde-keybar-fit` fills that gap. While the keyboard and bar are up, it
trims the active window so it ends at the bar's top edge; when the keyboard hides, KWin restores
the window. Maximized windows are switched to horizontal-only maximize for that time (KWin
would otherwise re-apply the full height on every resize and the two would fight) and fully
re-maximized afterwards. A window that keeps growing back right away (three trims within two seconds) is left alone until the keyboard hides.

`just install` installs and enables it for your user. Packages ship it in
`/usr/share/kwin/scripts/`; enable it in System Settings, Window Management, KWin Scripts, or:

```sh
kwriteconfig6 --file kwinrc --group Plugins --key kde-keybar-fitEnabled true
dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure
```

The script also reports the keyboard's real height to the bar over D-Bus
(`io.github.thereisnotime.KdeKeybar`, method `SetKeyboardHeight(d)`), so the bar sits flush on
the keyboard even though Maliit's height changes with its suggestion row and with rotation.
Without the script the bar falls back to `keyboard_height_fraction`; an explicit `margin_px`
always wins.

Use it with the default `dock: false`. Set `debug` to `true` in the `[Script-kde-keybar-fit]`
group of `kwinrc` to log each trim to the journal.

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
| `kde-keybar --settings [TAB]` | Open only the [settings window](#settings-window), optionally on `general`, `dictation`, or `buttons`. Combine with `-c` to edit another file. |
| `kde-keybar -c <path>` | Use a config file other than the default. |
| `kde-keybar --version` | Print the version. |

## Live reload

kde-keybar watches its config file and reloads on save, so editing `~/.config/kde-keybar.json`
(theme, buttons, style, ...) updates the running bar with no restart. If the config is a symlink,
the directory of its target is watched too, so editing the file in your dotfiles repo also
reloads. You can also force it with
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
