# Contributing to kde-keybar

Thanks for taking the time to help out. kde-keybar is a small single-file tool, so contributing is straightforward.

## Setup

You need the runtime dependencies plus `just` and `ruff`.

```sh
# Fedora
sudo dnf install python3-gobject gtk3 gtk-layer-shell ydotool just ruff

# Debian/Ubuntu
sudo apt install python3-gi gir1.2-gtk-3.0 gir1.2-gtklayershell-0.1 ydotool just
pipx install ruff
```

Clone the repo and list the available recipes:

```sh
git clone git@github.com:thereisnotime/kde-keybar.git
cd kde-keybar
just
```

## Code style

The code is linted with [ruff](https://docs.astral.sh/ruff/). Run it before you push:

```sh
just lint
```

Keep the tool a single readable Python file. Match the existing style: short helpers, comments only where the behavior is non-obvious (D-Bus quirks, keycodes, layer-shell placement).

## Testing locally

There is no automated test suite; kde-keybar is verified by running it. You need a KDE Plasma 6 Wayland session and a working `ydotoold` (see the ydotool setup in the README).

```sh
just run          # launches the bar always-on for a quick visual check
```

Focus a terminal, tap a few buttons, and confirm the chords land (e.g. `Ctrl+C` interrupts, arrows move the cursor). If you touched the auto show/hide logic, test it with your on-screen keyboard by toggling the OSK and watching the bar follow it.

If you added or changed config keys, update the table in the README and the example config.

## Pull requests

- Keep PRs focused on one change.
- Explain what you changed and why, and note how you tested it.
- Update the README and `config/kde-keybar.example.json` when you change behavior or config.
- Add a line under `## [Unreleased]` in `CHANGELOG.md`.

DCO / sign-off is not required. Just open the PR.
