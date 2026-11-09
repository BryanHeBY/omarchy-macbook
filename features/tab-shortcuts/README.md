# Application-aware tab shortcuts

[简体中文](README.zh-CN.md)

| Application | `Super+W` forwards | `Super+T` forwards | Behavior |
| --- | --- | --- | --- |
| Chromium and Firefox browsers | `Ctrl+W` | `Ctrl+T` | Close or create a browser tab |
| Nautilus, Dolphin, Thunar, Nemo, Obsidian | `Ctrl+W` | `Ctrl+T` | Close or create a tab |
| VS Code / Insiders, Code OSS, VSCodium, Cursor, Windsurf | `Ctrl+W` | `Ctrl+N` | Close the current editor or create a blank document |
| Kate, KWrite, Gedit, Sublime Text | `Ctrl+W` | `Ctrl+N` | Close or create a document |
| Konsole, GNOME Terminal, Xfce Terminal, WezTerm, Ghostty | `Ctrl+Shift+W` | `Ctrl+Shift+T` | Close the current terminal tab or session; create a tab |
| Kitty | `Ctrl+Shift+Q` | `Ctrl+Shift+T` | Close or create a tab |

In editors, `Super+T` follows the blank-document convention. Save prompts, the
last tab and embedded-terminal focus follow each application's native shortcut
behavior. The mappings follow application documentation.
[VS Code](https://code.visualstudio.com/docs/reference/default-keybindings),
[Konsole](https://docs.kde.org/stable_kf6/en/konsole/konsole/commandreference.html),
[Kitty](https://sw.kovidgoyal.net/kitty/invocation/),
[WezTerm](https://wezterm.org/config/default-keys.html).

Applications are identified by exact window classes or Omarchy browser tags.
Extend the groups in `features/tab-shortcuts/hyprland.lua`. For other applications,
`Super+W` closes the window and `Super+T` performs no action. Foot and Alacritty
use this fallback.

`hyprland.lua` owns application groups and press/release forwarding. Run from
the repository root:

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only tab-shortcuts
hyprctl reload
hyprctl configerrors
lua features/tab-shortcuts/tests/shortcuts.lua
```

The installed alias is `~/.config/hypr/customizations/tab-shortcuts.lua`.
Check Super+W and Super+T in a supported browser, editor and terminal. Remove its
loader from `bindings.lua` and reload Hyprland to restore the desktop defaults.
