# kde-keybar — developer tasks
# Run `just` (no args) for a colored, categorized menu of recipes.

VERSION := "0.1.0"

# nfpm config; its `src:` paths are relative to the working dir (repo root, where just runs).
NFPM_CONFIG := "packaging/nfpm.yaml"
DIST := "dist"

# ---- default: pretty, grouped help -----------------------------------------

# Show the colored, categorized recipe menu.
default:
    #!/usr/bin/env sh
    b=$(printf '\033[1m'); d=$(printf '\033[2m'); r=$(printf '\033[0m')
    cyan=$(printf '\033[36m'); grn=$(printf '\033[32m'); ylw=$(printf '\033[33m')
    mag=$(printf '\033[35m'); blu=$(printf '\033[34m')
    printf '%s%skde-keybar%s %sv{{VERSION}}%s  developer tasks\n\n' "$b" "$cyan" "$r" "$d" "$r"
    printf '  %sUsage:%s just <recipe>\n\n' "$d" "$r"
    row() { printf '    %s%-16s%s %s%s%s\n' "$grn" "$1" "$r" "$d" "$2" "$r"; }

    printf '%s%s Dev %s\n' "$b" "$blu" "$r"
    row run       "Visual test, always-on strip (no keyboard needed)"
    row run-live  "Run normally, tracks the on-screen keyboard"
    printf '\n'

    printf '%s%s Quality %s\n' "$b" "$ylw" "$r"
    row lint       "ruff check ."
    row fmt        "ruff format ."
    row fmt-check  "ruff format --check ."
    row check      "lint + fmt-check + py_compile"
    printf '\n'

    printf '%s%s Build & Package %s\n' "$b" "$mag" "$r"
    row package      "Build .deb and .rpm into ./dist via nfpm"
    row package-deb  "Build only the .deb"
    row package-rpm  "Build only the .rpm"
    row clean        "Remove ./dist and caches"
    printf '\n'

    printf '%s%s Install/System %s\n' "$b" "$cyan" "$r"
    row install        "Install to system paths (sudo)"
    row uninstall      "Remove installed files (sudo)"
    row setup-ydotool  "Install ydotool + enable ydotoold.service"
    printf '\n'

# ---- Dev -------------------------------------------------------------------

# Quick visual test: always-on strip so it is visible without a keyboard.
run:
    GDK_BACKEND=wayland KEYBAR_ALWAYS=1 ./kde-keybar

# Run normally; the strip tracks the on-screen keyboard visibility.
run-live:
    GDK_BACKEND=wayland ./kde-keybar

# ---- Quality ---------------------------------------------------------------

# Lint with ruff.
lint:
    ruff check .

# Auto-format with ruff.
fmt:
    ruff format .

# Verify formatting without writing changes.
fmt-check:
    ruff format --check .

# Lint, format-check, and Python syntax check.
check: lint fmt-check
    python3 -m py_compile kde-keybar

# ---- Build & Package -------------------------------------------------------

# Build both packages into ./dist.
package: package-deb package-rpm

# Build the .deb.
package-deb:
    #!/usr/bin/env sh
    set -eu
    if ! command -v nfpm >/dev/null 2>&1; then
        echo "nfpm not found. Install it with:"
        echo "  go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest"
        echo "  # or: brew install nfpm  /  see https://nfpm.goreleaser.com/install/"
        exit 1
    fi
    mkdir -p {{DIST}}
    VERSION={{VERSION}} nfpm pkg -f {{NFPM_CONFIG}} -p deb -t {{DIST}}
    echo "Built .deb in ./{{DIST}}"

# Build the .rpm.
package-rpm:
    #!/usr/bin/env sh
    set -eu
    if ! command -v nfpm >/dev/null 2>&1; then
        echo "nfpm not found. Install it with:"
        echo "  go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest"
        echo "  # or: brew install nfpm  /  see https://nfpm.goreleaser.com/install/"
        exit 1
    fi
    mkdir -p {{DIST}}
    VERSION={{VERSION}} nfpm pkg -f {{NFPM_CONFIG}} -p rpm -t {{DIST}}
    echo "Built .rpm in ./{{DIST}}"

# Remove build artifacts and caches.
clean:
    rm -rf {{DIST}} .ruff_cache __pycache__

# ---- Install/System --------------------------------------------------------

# Install kde-keybar to the system (needs sudo).
install:
    #!/usr/bin/env sh
    set -eu
    sudo install -Dm0755 kde-keybar /usr/bin/kde-keybar
    sudo install -Dm0644 data/kde-keybar.desktop /etc/xdg/autostart/kde-keybar.desktop
    sudo install -Dm0644 data/ydotoold.service /usr/lib/systemd/system/ydotoold.service
    cfg="${XDG_CONFIG_HOME:-$HOME/.config}/kde-keybar.json"
    if [ -e "$cfg" ]; then
        echo "Config already exists, leaving it alone: $cfg"
    else
        install -Dm0644 config/kde-keybar.example.json "$cfg"
        echo "Wrote default config: $cfg"
    fi
    echo "Installed. Run 'just setup-ydotool' if you have not enabled ydotoold yet."

# Remove installed files (needs sudo). Leaves your user config in place.
uninstall:
    #!/usr/bin/env sh
    set -eu
    sudo rm -f /usr/bin/kde-keybar
    sudo rm -f /etc/xdg/autostart/kde-keybar.desktop
    sudo rm -f /usr/lib/systemd/system/ydotoold.service
    echo "Removed system files. Your user config was left untouched."

# Install ydotool and enable the ydotoold service.
setup-ydotool:
    #!/usr/bin/env sh
    set -eu
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y ydotool
    elif command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y ydotool
    else
        echo "No supported package manager (dnf/apt) found. Install ydotool manually."
        exit 1
    fi
    sudo install -Dm0644 data/ydotoold.service /usr/lib/systemd/system/ydotoold.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now ydotoold.service
    uid=$(id -u); gid=$(id -g)
    echo "ydotoold enabled. Your uid:gid is ${uid}:${gid}."
    if [ "$uid" != "1000" ]; then
        echo "REMINDER: the shipped service sets --socket-own=1000:1000."
        echo "  Edit /usr/lib/systemd/system/ydotoold.service so --socket-own=${uid}:${gid},"
        echo "  then run: sudo systemctl daemon-reload && sudo systemctl restart ydotoold.service"
    fi
