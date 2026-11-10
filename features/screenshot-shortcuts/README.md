# Optional MacBook screenshot shortcuts

[简体中文](README.zh-CN.md)

This feature is disabled in the recommended profile. Enable it explicitly to add
MacBook-style capture keys alongside Omarchy's original capture bindings.

| Shortcut | Action |
| --- | --- |
| Super+Shift+3 | Save the focused monitor |
| Super+Shift+4 | Save a dragged region or clicked window through smart capture |
| Super+Shift+5 | Open Omarchy's capture and recording menu |
| Ctrl+Super+Shift+3 | Copy the focused monitor |
| Ctrl+Super+Shift+4 | Copy a dragged region or clicked window |

Omasnap supplies capture behavior. The smart overlay supports dragging a region
or clicking a window, and Escape cancels selection. Saved captures use the
configured screenshot directory, normally `~/Pictures/Screenshots`. Control
variants use clipboard-only output. The full-screen action captures the focused
monitor. The menu is Omarchy's capture menu. These commands use the installed
Omarchy screenshot wrapper, with macOS combinations as the reference.
[Apple screenshot shortcuts](https://support.apple.com/en-us/102650).

The original Print, Super+Ctrl+Alt+C and OCR shortcuts retain their definitions.
When this optional module is enabled, the physical number-row bindings
Super+Shift+3/4/5 replace moving the active window to workspaces 3/4/5. The
existing Super+Alt+Shift+3/4/5 bindings still move windows silently.

## Enable and verify

Choose the feature through the recommended installer, or install it independently.

```bash
python3 install.py --apply --with-macos-screenshots

bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only screenshot-shortcuts
hyprctl reload
hyprctl configerrors
lua features/screenshot-shortcuts/tests/shortcuts.lua
```

`hyprland.lua` owns the five bindings. The installer creates a module link and
backs up `bindings.lua` before adding its loader. Merely installing the link
leaves activation controlled by the loader. An existing loader is preserved on
later installations that omit this optional feature.

Test the saved file and clipboard variants with disposable screen content.
Remove `require("hypr.customizations.screenshot-shortcuts")` from
`~/.config/hypr/bindings.lua`, then reload Hyprland to disable the feature and
restore the workspace-move bindings.
