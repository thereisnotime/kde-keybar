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
    row doctor         "Check that all runtime dependencies are present"
    row install        "Install to system paths (sudo)"
    row uninstall      "Remove installed files (sudo)"
    row setup-ydotool  "Install ydotool + enable ydotoold.service"
    row setup-dictation "Build whisper-cli + download a model for the 🎤 button"
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

# Check that all runtime dependencies are present (Fedora / Debian-Ubuntu).
doctor:
    #!/usr/bin/env sh
    g=$(printf '\033[32m'); rd=$(printf '\033[31m'); y=$(printf '\033[33m')
    d=$(printf '\033[2m'); z=$(printf '\033[0m')
    ok()   { printf '  %s✓%s %s\n' "$g" "$z" "$1"; }
    bad()  { printf '  %s✗%s %s\n' "$rd" "$z" "$1"; miss=1; }
    warn() { printf '  %s!%s %s\n' "$y" "$z" "$1"; }
    miss=0

    printf '%sSession%s\n' "$d" "$z"
    if [ "${XDG_SESSION_TYPE:-}" = wayland ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        ok "Wayland session"
    else
        warn "not a Wayland session (kde-keybar needs Wayland)"
    fi

    printf '%sPython + GTK4%s\n' "$d" "$z"
    command -v python3 >/dev/null 2>&1 && ok "python3" || bad "python3"
    python3 -c "import gi" 2>/dev/null && ok "PyGObject (python3-gobject / python3-gi)" || bad "PyGObject"
    python3 -c "import gi; gi.require_version('Gtk','4.0')" 2>/dev/null \
        && ok "GTK 4 typelib" || bad "GTK 4 (gtk4 / gir1.2-gtk-4.0)"
    python3 -c "import gi; gi.require_version('Gtk4LayerShell','1.0')" 2>/dev/null \
        && ok "Gtk4LayerShell typelib" || bad "gtk4-layer-shell (gtk4-layer-shell / gir1.2-gtk4-layer-shell-1.0)"
    ldconfig -p 2>/dev/null | grep -q libgtk4-layer-shell && ok "libgtk4-layer-shell.so" || bad "libgtk4-layer-shell.so"

    printf '%sydotool%s\n' "$d" "$z"
    command -v ydotool >/dev/null 2>&1 && ok "ydotool" || bad "ydotool"
    if systemctl is-active --quiet ydotoold.service 2>/dev/null; then
        ok "ydotoold.service running"
    else
        warn "ydotoold.service not running (run: just setup-ydotool)"
    fi
    [ -S /run/ydotoold.socket ] && ok "/run/ydotoold.socket" || warn "/run/ydotoold.socket missing"

    printf '%sDictation (optional)%s\n' "$d" "$z"
    command -v parecord >/dev/null 2>&1 && ok "parecord" || warn "parecord missing (pulseaudio-utils)"
    command -v whisper-cli >/dev/null 2>&1 && ok "whisper-cli" || warn "whisper-cli missing (run: just setup-dictation)"
    model="${XDG_DATA_HOME:-$HOME/.local/share}/kde-keybar/models/ggml-base.en.bin"
    [ -f "$model" ] && ok "default model" || warn "no default model (run: just setup-dictation)"
    command -v wl-copy >/dev/null 2>&1 && ok "wl-copy" || warn "wl-copy missing (only needed for output \"paste\")"

    printf '\n'
    if [ "$miss" = 1 ]; then
        if command -v dnf >/dev/null 2>&1; then
            printf 'Install missing (Fedora):\n  sudo dnf install python3-gobject gtk4 gtk4-layer-shell ydotool\n'
        elif command -v apt >/dev/null 2>&1; then
            printf 'Install missing (Debian/Ubuntu):\n  sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-gtk4-layer-shell-1.0 ydotool\n'
        else
            printf 'Install the packages noted above with your package manager.\n'
        fi
        exit 1
    fi
    printf '%sAll good.%s\n' "$g" "$z"

# Install kde-keybar to the system (needs sudo).
install:
    #!/usr/bin/env sh
    set -eu
    sudo install -Dm0755 kde-keybar /usr/bin/kde-keybar
    sudo install -Dm0644 data/kde-keybar.desktop /etc/xdg/autostart/kde-keybar.desktop
    sudo install -Dm0644 data/ydotoold.service /usr/lib/systemd/system/ydotoold.service
    sudo install -Dm0644 data/kde-keybar.service /usr/lib/systemd/user/kde-keybar.service
    # The user unit owns startup now; it restarts the bar when the compositor
    # drops it. Any leftover autostart-generated unit is stopped first so the
    # two do not race.
    systemctl --user stop 'app-kde\x2dkeybar@autostart.service' 2>/dev/null || true
    systemctl --user daemon-reload
    systemctl --user enable --now kde-keybar.service
    cfg="${XDG_CONFIG_HOME:-$HOME/.config}/kde-keybar.json"
    if [ -e "$cfg" ]; then
        echo "Config already exists, leaving it alone: $cfg"
    else
        install -Dm0644 config/kde-keybar.example.json "$cfg"
        echo "Wrote default config: $cfg"
    fi
    if systemctl is-active --quiet ydotoold.service && command -v ydotool >/dev/null 2>&1; then
        echo "Installed. ydotoold is running, you are all set."
    else
        echo "Installed. ydotoold is not running yet, run 'just setup-ydotool' to enable it."
    fi

# Remove installed files (needs sudo). Leaves your user config in place.
uninstall:
    #!/usr/bin/env sh
    set -eu
    systemctl --user disable --now kde-keybar.service 2>/dev/null || true
    sudo rm -f /usr/bin/kde-keybar
    sudo rm -f /etc/xdg/autostart/kde-keybar.desktop
    sudo rm -f /usr/lib/systemd/system/ydotoold.service
    sudo rm -f /usr/lib/systemd/user/kde-keybar.service
    systemctl --user daemon-reload
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

# Build whisper-cli from source into ~/.local/bin and download a model (base.en ~140 MB; also tiny.en, small.en, ...).
setup-dictation MODEL="base.en" WHISPER_VERSION="v1.7.6":
    #!/usr/bin/env sh
    set -eu
    bindir="$HOME/.local/bin"
    if command -v whisper-cli >/dev/null 2>&1 && [ -z "${REBUILD:-}" ]; then
        echo "whisper-cli already installed: $(command -v whisper-cli) (REBUILD=1 to rebuild)"
    else
        for t in git cmake make g++; do
            command -v "$t" >/dev/null 2>&1 || { echo "Missing $t (Fedora: sudo dnf install git cmake make gcc-c++)"; exit 1; }
        done
        src="${XDG_CACHE_HOME:-$HOME/.cache}/kde-keybar/whisper.cpp"
        if [ -d "$src/.git" ]; then
            git -C "$src" fetch --depth 1 origin tag {{WHISPER_VERSION}}
            git -C "$src" checkout -q {{WHISPER_VERSION}}
        else
            mkdir -p "$(dirname "$src")"
            git clone --depth 1 --branch {{WHISPER_VERSION}} https://github.com/ggml-org/whisper.cpp "$src"
        fi
        # Vulkan runs the encoder on the GPU (Intel/AMD/NVIDIA), several times faster
        # than CPU on laptops. Needs glslc + Vulkan headers; falls back to CPU otherwise.
        gpu=OFF
        if command -v glslc >/dev/null 2>&1 && [ -f /usr/include/vulkan/vulkan.h ]; then
            gpu=ON
        else
            echo "Note: building CPU-only. For a GPU build: sudo dnf install glslc vulkan-headers vulkan-loader-devel"
            echo "      (Debian/Ubuntu: glslc libvulkan-dev), then: REBUILD=1 just setup-dictation"
        fi
        echo "Building whisper.cpp {{WHISPER_VERSION}} (static, Vulkan=$gpu) ..."
        rm -rf "$src/build"
        cmake -S "$src" -B "$src/build" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
            -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_SERVER=OFF -DGGML_VULKAN=$gpu >/dev/null
        cmake --build "$src/build" --target whisper-cli -j "$(nproc)"
        install -Dm0755 "$src/build/bin/whisper-cli" "$bindir/whisper-cli"
        echo "Installed: $bindir/whisper-cli"
        case ":$PATH:" in *":$bindir:"*) ;; *) echo "Note: $bindir is not on PATH; set dictation.transcribe_command to the full path." ;; esac
    fi
    dir="${XDG_DATA_HOME:-$HOME/.local/share}/kde-keybar/models"
    file="$dir/ggml-{{MODEL}}.bin"
    mkdir -p "$dir"
    if [ -f "$file" ]; then
        echo "Model already present: $file"
    else
        echo "Downloading ggml-{{MODEL}}.bin ..."
        curl -fL --progress-bar -o "$file.part" \
            "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-{{MODEL}}.bin"
        mv "$file.part" "$file"
        echo "Saved: $file"
    fi
    if [ "{{MODEL}}" != "base.en" ]; then
        echo "Point the config at it: \"dictation\": { \"model\": \"$file\" }"
    fi
    command -v parecord >/dev/null 2>&1 || echo "Missing parecord: install pulseaudio-utils."
