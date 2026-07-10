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
```

On Debian/Ubuntu:

```sh
sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-gtk4-layer-shell-1.0 ydotool
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
