# 按应用适配的标签页快捷键

[English](README.md)

| 应用 | `Super+W` 转发为 | `Super+T` 转发为 | 行为 |
| --- | --- | --- | --- |
| Chromium 系及 Firefox 浏览器 | `Ctrl+W` | `Ctrl+T` | 关闭或新建浏览器标签页 |
| Nautilus、Dolphin、Thunar、Nemo、Obsidian | `Ctrl+W` | `Ctrl+T` | 关闭或新建标签页 |
| VS Code／Insiders、Code OSS、VSCodium、Cursor、Windsurf | `Ctrl+W` | `Ctrl+N` | 关闭当前编辑器或新建空白文档 |
| Kate、KWrite、Gedit、Sublime Text | `Ctrl+W` | `Ctrl+N` | 关闭或新建文档 |
| Konsole、GNOME Terminal、Xfce Terminal、WezTerm、Ghostty | `Ctrl+Shift+W` | `Ctrl+Shift+T` | 关闭当前终端标签或会话，新建标签页 |
| Kitty | `Ctrl+Shift+Q` | `Ctrl+Shift+T` | 关闭或新建标签页 |

在编辑器中，`Super+T` 遵循新建空白文档的习惯。保存提示、最后一个标签页和焦点位于内嵌终端时的效果，均由应用自身的快捷键行为决定。映射依据各应用文档设置。[VS Code](https://code.visualstudio.com/docs/reference/default-keybindings)、[Konsole](https://docs.kde.org/stable_kf6/en/konsole/konsole/commandreference.html)、[Kitty](https://sw.kovidgoyal.net/kitty/invocation/)、[WezTerm](https://wezterm.org/config/default-keys.html)。

应用通过精确窗口类名或 Omarchy 浏览器标签识别。可在 `features/tab-shortcuts/hyprland.lua` 中扩展分组。其他应用使用回退行为，`Super+W` 关闭窗口，`Super+T` 不执行操作。Foot 和 Alacritty 使用该回退行为。

`hyprland.lua` 定义应用分组和按键按下／释放的转发。在仓库根目录运行以下命令。

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only tab-shortcuts
hyprctl reload
hyprctl configerrors
lua features/tab-shortcuts/tests/shortcuts.lua
```

安装后的别名路径为 `~/.config/hypr/customizations/tab-shortcuts.lua`。在受支持的浏览器、编辑器和终端中检查 Super+W 与 Super+T。移除 `bindings.lua` 中对应模块的加载语句并重新加载 Hyprland，可恢复桌面默认行为。
