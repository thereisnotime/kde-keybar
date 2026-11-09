#!/usr/bin/env sh
# Apply (or revert) kde-keybar's Maliit keyboard patches to the installed maliit-keyboard.
#
#   apply.sh                  apply every patch (skips ones already applied)
#   apply.sh 20 40            apply only patches whose name starts with 20 or 40
#   apply.sh --revert [..]    undo applied patches
#   apply.sh --status         show which patches are applied
#
# Needs root to write to Maliit's install dirs. Package updates overwrite the files, so
# re-run after an update (or install the dnf hook, see docs/maliit.md).
set -eu

here=$(cd "$(dirname "$0")" && pwd)
mode=apply
case "${1:-}" in
    --revert) mode=revert; shift ;;
    --status) mode=status; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
esac

# Maliit's data lives under a libdir that differs per distro.
# MALIIT_LIBDIR / MALIIT_SHAREDIR override the detection (testing, unusual installs).
libdir=${MALIIT_LIBDIR:-}
[ -n "$libdir" ] || for d in /usr/lib64/maliit/keyboard2 /usr/lib/maliit/keyboard2 /usr/lib/*/maliit/keyboard2; do
    if [ -f "$d/qml/keys/CharKey.qml" ]; then libdir=$d; break; fi
done
sharedir=${MALIIT_SHAREDIR:-/usr/share/maliit/keyboard2}
if [ -z "$libdir" ] || [ ! -d "$sharedir/devices" ]; then
    echo "maliit-keyboard not found (looked for qml/keys/CharKey.qml and $sharedir/devices)" >&2
    exit 1
fi

wanted() { # wanted NAME [PREFIX...]: true if no prefixes were given or one matches
    name=$1; shift
    [ $# -eq 0 ] && return 0
    for p in "$@"; do
        case "$name" in "$p"*) return 0 ;; esac
    done
    return 1
}

changed=0
for kind in lib share; do
    if [ "$kind" = lib ]; then root=$libdir; else root=$sharedir; fi
    for patch in "$here"/patches/$kind/*.patch; do
        [ -f "$patch" ] || continue
        name=$(basename "$patch" .patch)
        wanted "$name" "$@" || continue
        if patch -s -R -p1 --dry-run -d "$root" < "$patch" >/dev/null 2>&1; then
            state=applied
        elif patch -s -N -p1 --dry-run -d "$root" < "$patch" >/dev/null 2>&1; then
            state=clean
        else
            state=conflict
        fi
        case "$mode:$state" in
            status:*) echo "$state  $name" ;;
            apply:applied | revert:clean) echo "ok       $name (nothing to do)" ;;
            apply:clean)
                patch -s -N -p1 -d "$root" --no-backup-if-mismatch < "$patch"
                echo "applied  $name"; changed=1 ;;
            revert:applied)
                patch -s -R -p1 -d "$root" --no-backup-if-mismatch < "$patch"
                echo "reverted $name"; changed=1 ;;
            *:conflict)
                echo "CONFLICT $name: the installed file differs from what the patch expects" >&2
                echo "         (different maliit-keyboard version, or edited by hand)" >&2 ;;
        esac
    done
done

# Maliit only reads its QML at start-up. It is deliberately NOT restarted from here:
# killing it while a key is held (or several times in a row) can leave a key stuck in
# auto-repeat, e.g. an endless stream of backspaces. Restart it yourself, with the
# keyboard closed.
if [ "$changed" = 1 ]; then
    echo "Close the on-screen keyboard, then run: pkill -x maliit-keyboard  (KWin restarts it)"
fi
