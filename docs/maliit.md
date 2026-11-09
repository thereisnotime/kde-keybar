# Maliit patches

kde-keybar works with the stock Maliit keyboard, but a few changes make Maliit much nicer on a
tablet running a terminal. They live in [`maliit/patches/`](../maliit/patches) as plain unified
diffs against `maliit-keyboard` 2.3.1 and are entirely optional.

| Patch | What it does |
| --- | --- |
| `10-hide-key-action` | Teaches `CharKey` an `action: "hide"`, used by the ▼ key in the layouts below to close the keyboard. |
| `20-space-no-long-press` | Disables long-press on the space bar (Maliit's cursor-swipe mode). Holding space just types a space. |
| `30-compact-size` | Smaller key labels (font 1.8) and a shorter keyboard: 24% of the screen in portrait, 30% in landscape. |
| `40-terminal-rows-en` | English layout with a digit row and a `- _ / \ \| ~ : ; + =` row on top, accent popups removed. |
| `41-terminal-rows-bg-phonetic` | Bulgarian phonetic layout (я в е р т ъ у и о п ш щ) with the same digit and symbol rows. |

`40` and `41` use the ▼ key from `10`, so apply `10` with them.

## Install

```sh
just setup-maliit            # all patches
just setup-maliit 10 20 30   # only some, by prefix
just maliit-status           # applied / clean / conflict for each patch
just revert-maliit           # back to stock
```

`setup-maliit` copies the patches and [`maliit/apply.sh`](../maliit/apply.sh) to
`/usr/share/kde-keybar/maliit/` and applies them. Applying is idempotent: patches that are
already in place are skipped, and a patch that does not match the installed file (another
Maliit version, or a hand edit) is reported as a conflict and left alone.

Maliit only reads its files at start-up. Close the on-screen keyboard, then restart it with
`pkill -x maliit-keyboard` (KWin starts it again). The script deliberately does not do this
itself: killing Maliit while a key is held, or several times in quick succession, can leave a
key stuck in auto-repeat.

## Surviving updates

A `maliit-keyboard` update replaces the patched files. On Fedora, install the dnf actions
plugin and `setup-maliit` adds a hook that re-applies the same patches after every update:

```sh
sudo dnf install libdnf5-plugin-actions
just setup-maliit
```

The hook is `/etc/dnf/libdnf5-plugins/actions.d/kde-keybar-maliit.actions`. Elsewhere, run
`just setup-maliit` again after an update.

## Other Maliit versions

`apply.sh` finds Maliit under `/usr/lib64`, `/usr/lib` or `/usr/lib/<triplet>`
(set `MALIIT_LIBDIR` and `MALIIT_SHAREDIR` to point it somewhere else). The patches are small,
so they often still apply to nearby versions; `just maliit-status` tells you before anything
is changed.
