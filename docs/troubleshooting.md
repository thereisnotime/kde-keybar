# Troubleshooting

Run `just doctor` first, it checks every runtime dependency and the ydotool daemon.

**The bar doesn't appear.** It must run under the Wayland GDK backend. Start it with
`GDK_BACKEND=wayland` (the installed desktop entry already does this). Also confirm
`gtk4-layer-shell` is installed. The script sets `LD_PRELOAD` for `libgtk4-layer-shell.so.0` by
re-executing itself; if you package it differently, make sure that preload happens.

**It opens as a normal window with a taskbar icon.** That is the fallback when the layer surface
fails to initialize, almost always the `LD_PRELOAD` issue above. Confirm `libgtk4-layer-shell.so.0`
is on the loader path (`ldconfig -p | grep gtk4-layer-shell`).

**Buttons do nothing.** `ydotoold` is probably not running, or the socket path is wrong. Check
`systemctl status ydotoold`, confirm `/run/ydotoold.socket` exists and is owned by your user, and
make sure `ydotool_socket` / `YDOTOOL_SOCKET` points at it. Verify `ydotool` is on `PATH`.

**Buttons are cut off on the right in portrait.** The bar keeps a single row and the overflow
scrolls sideways, so nothing is clipped. If you want everything visible without scrolling, remove
some buttons in the config or lower `font_px`. You can also set `overflow: "wrap"`.

**Bar sits at the wrong height over the keyboard.** Tune `keyboard_height_fraction` for your OSK,
nudge with `gap_px`, or set a hard `margin_px` (or `KEYBAR_MARGIN`) override.

**Config change did not take effect.** kde-keybar reloads on save, but a syntax error stops it (it
keeps the last good config). Run `kde-keybar --validate` to see the problem, or `--reload` to force
a reload.
