# Installation

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
# optional, for the dictation button
sudo dnf install pulseaudio-utils wl-clipboard
```

On Debian/Ubuntu:

```sh
sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-gtk4-layer-shell-1.0 ydotool
# optional, for the dictation button
sudo apt install pulseaudio-utils wl-clipboard
```

Run `just doctor` at any time to check which of these are present.

## From packages

Prebuilt `.rpm` and `.deb` packages are attached to each [GitHub Release](https://github.com/thereisnotime/kde-keybar/releases) (built by CI).

```sh
# Fedora
sudo dnf install ./kde-keybar-*.rpm

# Debian/Ubuntu
sudo apt install ./kde-keybar_*.deb
```

A Fedora COPR spec also lives in [`packaging/rpm/`](../packaging/rpm/) if you want to build it yourself.

## From source

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

## ydotool setup

kde-keybar injects keys through `ydotoold`, which needs access to `/dev/uinput`. The easy path:

```sh
just setup-ydotool
```

That installs the bundled root system service ([`data/ydotoold.service`](../data/ydotoold.service)) which runs `ydotoold` as root and creates `/run/ydotoold.socket` owned by your user. Running it this way means `ydotool` works without adding your user to any group.

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

## Dictation (optional)

The 🎤 button needs a recorder, a speech model, and the CLI that runs it. Nothing leaves the
machine. The defaults use `parecord` (from `pulseaudio-utils`, works with PipeWire too) and
[whisper.cpp](https://github.com/ggml-org/whisper.cpp):

```sh
sudo dnf install git cmake make gcc-c++    # or: sudo apt install git cmake build-essential
just setup-dictation                       # builds whisper-cli, downloads the model
just doctor                                # the "Dictation" section should be all green
```

`setup-dictation` clones whisper.cpp (pinned tag, override with `WHISPER_VERSION=...`) into
`~/.cache/kde-keybar/whisper.cpp`, builds a static CPU-only `whisper-cli`, installs it to
`~/.local/bin`, and downloads `ggml-base.en.bin` to `~/.local/share/kde-keybar/models/`. It is
built from source because distro packages either lack the CLI (Fedora's `whisper-cpp` is
library-only) or are missing entirely.

If `glslc` and the Vulkan headers are installed, `whisper-cli` is built with GPU (Vulkan)
support, which is much faster on laptops: `sudo dnf install glslc vulkan-headers
vulkan-loader-devel`, then `REBUILD=1 just setup-dictation`.

Pick another model with `just setup-dictation small.en` (more accurate, slower) or `tiny.en`
(faster), then set `dictation.model` in the config. See
[configuration](configuration.md#dictation) for using a different engine.

### Wake word (optional)

To start dictation by voice instead of tapping 🎤, the bar runs a small helper,
`kde-keybar-wake`, that spots a wake phrase with [Vosk](https://alphacephei.com/vosk/). Vosk is
not packaged in Fedora, so it goes into a per-user venv rather than the system Python:

```sh
just setup-wakeword    # venv at ~/.local/share/kde-keybar/wake-venv + vosk-model-small-en-us-0.15 (~40 MB)
just doctor            # the "Wake word" section should be all green
```

It uses `uv venv` when `uv` is installed, `python3 -m venv` otherwise, and never touches the
system site-packages. Running it again is a no-op. The helper itself is installed by
`just install` and ships in the packages as `/usr/bin/kde-keybar-wake`. Then turn it on in the
config, see [wake word](configuration.md#wake-word).
