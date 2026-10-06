# Window Layout

An [Omarchy](https://omarchy.org) shell plugin for arranging windows with the mouse.
Click the icon in the bar and every tiling move you would otherwise do with a
keybinding is one click away: fullscreen, split direction, split ratios, swapping
windows, sending them to other workspaces or displays, and more.

<img src="preview.png?v=1.1.0" alt="Window Layout panel" width="380">

## What's in the panel

The panel acts on the window that was focused when you opened it. Its title is
shown at the top, so you always know what a button will change.

| Section | Buttons |
|---|---|
| **Window** | Fullscreen · Maximize (keeps the bar visible) · Float · Pin (Omarchy's pop out) · Close |
| **Split** | Toggle split (side by side ⇄ stacked) · Swap sides · Ratios 30/70, 40/60, 50/50, 60/40, 70/30 |
| **Move window** | Swap with the neighbor (↑ ← → ↓) · Send to workspace 1–9 · Send to another display |
| **Workspace** | Toggle dwindle/scrolling layout · Toggle gaps · Move the workspace to another display |
| **Saved layout** | Save current · Restore · Restore at login |
| **Displays** (laptops) | Laptop display on/off · Mirror the laptop display · Automatic laptop display |

Buttons that don't apply right now are dimmed. For example, split ratios need a
tiled window on a dwindle workspace. Buttons for moving to another display only
appear when more than one display is connected.

## Saved layout

Hyprland doesn't remember your windows across a reboot. Arrange your workspaces
the way you like them and press **Save current**: the plugin records which apps
sit on each workspace, in which order, side by side or stacked, and the split
ratio. It also works out how to reopen each app (Omarchy web apps, desktop
entries, or the window's own executable).

**Restore** reopens whatever is missing and puts every window back in place.
Windows that are already open are moved, not reopened. With **Restore at login**
on, this happens once per session when you log in, so even an abrupt power-off
comes back to the same layout. Browser tabs come back only if the browser itself
is set to continue where you left off.

The exact order and ratio are restored for workspaces with one or two windows;
with more, the windows land on the right workspace in the saved order. The
layout is kept in `~/.config/gread.window-layout/layout.json`, which you can
edit, for example to change how an app is opened.

## Automatic laptop display

For laptops docked to an external display with the laptop display turned off
(Super+Ctrl+Delete). Unplug the external display and the laptop display comes
back on; plug it in again and the laptop display turns off, so your workspaces
return to the big screen. Opening the lid with no external display also turns
the laptop display back on. Omarchy's own recovery can leave every screen dark
here, because it counts Hyprland's virtual `FALLBACK` output as an active
external display.

Both options are off until you switch them on in the panel. Settings live in
`~/.config/gread.window-layout/config.json`; what each automation decided is
logged to `~/.local/state/gread.window-layout/session.log`.

## Install

```bash
omarchy plugin add https://github.com/Gread/omarchy-window-layout.git --enable
```

The icon goes to the center of the bar. To put it somewhere else:

```bash
omarchy bar move gread.window-layout --section right
```

Update with `omarchy plugin update gread.window-layout`, remove with
`omarchy plugin remove gread.window-layout`.

## Language

The panel is available in English, Portuguese, and Swedish and follows the system
language, falling back to English. To pick one yourself, set `language` on the
widget entry in `~/.config/omarchy/shell.json` (`auto`, `en`, `pt`, or `sv`):

```json
{ "id": "gread.window-layout", "language": "pt" }
```

## Open it from the keyboard

The panel also answers to Omarchy shell IPC, so you can bind it to a key. In
`~/.config/hypr/bindings.lua`, using any free combination:

```lua
o.bind("SUPER + ALT + W", "Window layout panel", "omarchy-shell gread.window-layout toggle")
```

## Requirements

- Omarchy 4 (`omarchy-shell`) with Hyprland's Lua configuration
- `jq`

## How it works

`BarWidget.qml` and `Panel.qml` draw the icon and the panel. Every button runs
`bin/window-layout` with a fixed argument list. The script validates each argument
before passing it to `hyprctl dispatch`, and calls Omarchy's own commands for
gaps, layout, pop out, and the laptop display.

`bin/session` saves and restores the layout and runs the laptop display
automation. The bar widget calls it once at startup (it restores only once per
Hyprland session, so restarting the shell doesn't rearrange anything), when
Hyprland reports a display added or removed, and when no real display is left.
It returns at once when the option involved is off. Neither script uses sudo or
the network.

## License

[MIT](LICENSE)
