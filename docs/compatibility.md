# Compatibility

kde-keybar is built for KDE Plasma 6 on Wayland (KWin) and works alongside Plasma Keyboard, Qt
Virtual Keyboard, and Maliit.

| Environment | Works? | Notes |
|---|---|---|
| KDE Plasma 6 / Wayland (KWin) | Full | Layer-shell, auto-show with the keyboard, and injection. The primary target. |
| wlroots compositors (sway, Hyprland, river, ...) | Partial | Layer-shell and ydotool work. The auto-show hook is KDE-specific, so set `visibility: "always"`. |
| GNOME (Mutter) | No | Mutter does not implement `wlr-layer-shell`, so there is nowhere to anchor the bar. See the roadmap. |
| X11 | No | `gtk4-layer-shell` is Wayland-only. |

## Companion on-screen keyboard

kde-keybar is not a full keyboard: it provides the control keys the built-in ones can't send. Pair
it with any KWin on-screen keyboard for text entry:

- **Plasma Keyboard** (`plasma-keyboard`) is the stock default and the most stable choice.
- **Maliit** (`maliit-keyboard`) is what we run, because its QML layout is easy to customize (font
  size, extra rows, symbols). Note that on current Fedora it can crash on the Wayland "surrounding
  text" event; kde-keybar is unaffected by that since it doesn't depend on the keyboard.

Select one under System Settings, Keyboard, Virtual Keyboard. kde-keybar shows above whichever you
pick.

## Non-KDE compositors

On wlroots compositors (sway, Hyprland) the two core pieces still work: ydotool injection and the
layer-shell window. The auto-show hook is KDE-specific, though, because it listens on KWin's
`org.kde.kwin.VirtualKeyboard` D-Bus interface. On those compositors set `visibility` to `"always"`
(or run with `KEYBAR_ALWAYS=1`) and place the bar yourself.
