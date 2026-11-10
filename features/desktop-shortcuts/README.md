# Desktop editing shortcuts

[简体中文](README.zh-CN.md)

Use Super as Command for common document actions, browser navigation and
contextual deletion. This feature is enabled in the recommended profile.

## Bindings

| Shortcut | Forwarded action |
| --- | --- |
| Super+Z | Ctrl+Z, undo |
| Super+Shift+Z | Ctrl+Shift+Z, redo |
| Super+S | Ctrl+S, save |
| Super+Shift+S | Ctrl+Shift+S, save as |
| Super+F | Ctrl+F, find |
| Super+O | Ctrl+O, open |
| Super+P | Ctrl+P, print |
| Super+L | Ctrl+L, address/location in browsers and file managers |
| Super+R | Ctrl+R, reload in browsers and file managers |
| Super+Backspace | Delete in file managers; Ctrl+U in terminals; Shift+Home then Backspace elsewhere |

Common document actions apply to non-terminal windows. Omarchy's `terminal` tag
identifies terminal windows, and its browser tags scope address/reload actions.
File manager classes cover Nautilus, Dolphin, Thunar and Nemo. Existing clipboard
and tab shortcuts use their own Omarchy and repository modules.

Deletion is interpreted by the focused application. In file lists, native Delete
uses the application's trash handling and prompts. In text fields, Shift+Home
selects toward the application's Home position before Backspace removes it.
Indent-aware Home behavior, wrapped lines and existing selections follow the
widget's selection rules. In terminals, Ctrl+U follows the shell or TUI binding.
Embedded terminals retain the containing application's native shortcut behavior.

Forwarding uses Omarchy's explicit key-down/key-up pattern to the focused surface,
so a shell menu receives the keys when open. Multi-step deletion stops if the
active window changes. Application-specific shortcut customizations can alter
the result. The reference behaviors come from Apple and GNOME documentation.
[Apple keyboard shortcuts](https://support.apple.com/en-us/102650),
[GNOME file deletion](https://help.gnome.org/gnome-help/files-delete.html).

## Default binding changes

| Shortcut | Replaced Omarchy action |
| --- | --- |
| Super+Backspace | Toggle window transparency |
| Super+F | Full screen |
| Super+S | Toggle scratchpad |
| Super+Shift+S | Google Maps |
| Super+O | Float and pin the window |
| Super+P | Pseudo window |
| Super+L | Cycle workspace layout |

Full-screen actions remain accessible through the existing Super+Ctrl+F tiled
full-screen binding. Other replaced actions can be assigned personal bindings
in `~/.config/hypr/bindings.lua`. Later personal bindings take precedence when
defined with `o.rebind`.

## Install, verify and recover

`hyprland.lua` owns the bindings and forwarding. From the repository root:

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only desktop-shortcuts
hyprctl reload
hyprctl configerrors
lua features/desktop-shortcuts/tests/shortcuts.lua
```

The patch installer backs up `bindings.lua`. The installed module alias is
`~/.config/hypr/customizations/desktop-shortcuts.lua`. Verify with disposable text
and a disposable file selected in a local trash-capable folder. Check undo/redo,
line-start deletion, native trash behavior, browser search and address focus.

Remove `require("hypr.customizations.desktop-shortcuts")` from `bindings.lua` and
reload Hyprland to restore the defaults. The independent
[screenshot shortcuts](../screenshot-shortcuts/README.md) are opt-in.
