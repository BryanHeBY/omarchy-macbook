# 可选 MacBook 截图快捷键

[English](README.md)

推荐预设默认关闭此功能。显式启用后，在 Omarchy 原有截图绑定之外增加 MacBook 风格的截图组合键。

| 快捷键 | 行为 |
| --- | --- |
| Super+Shift+3 | 保存当前焦点显示器的截图 |
| Super+Shift+4 | 通过智能截图拖动选区或点击窗口并保存 |
| Super+Shift+5 | 打开 Omarchy 截图与录屏菜单 |
| Ctrl+Super+Shift+3 | 复制当前焦点显示器的截图 |
| Ctrl+Super+Shift+4 | 拖动选区或点击窗口并复制截图 |

截图行为由 Omasnap 提供。智能遮罩支持拖动选区或点击窗口，Escape 取消选择。文件保存到已配置的截图目录，通常为 `~/Pictures/Screenshots`。带 Control 的组合仅输出到剪贴板。全屏动作截取当前焦点显示器，菜单入口打开 Omarchy 的截图菜单。命令使用本机已安装的 Omarchy 截图封装，组合键参考 macOS。[Apple 截图快捷键](https://support.apple.com/en-us/102650)。

原有 Print、Super+Ctrl+Alt+C 和 OCR 快捷键保留各自定义。启用此可选模块后，物理数字行上的 Super+Shift+3/4/5 会替换原来的移动窗口到工作区 3/4/5。现有 Super+Alt+Shift+3/4/5 仍可静默移动窗口。

## 启用与验证

可以通过推荐安装器选择，也可以单独安装。

```bash
python3 install.py --apply --with-macos-screenshots

bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only screenshot-shortcuts
hyprctl reload
hyprctl configerrors
lua features/screenshot-shortcuts/tests/shortcuts.lua
```

`hyprland.lua` 定义五个绑定。安装器创建模块链接，并在添加加载语句前备份 `bindings.lua`。仅安装链接时，是否生效由加载语句决定。后续安装省略此可选功能时，会保留已有加载语句。

使用临时屏幕内容检查保存和复制两种输出。从 `~/.config/hypr/bindings.lua` 移除 `require("hypr.customizations.screenshot-shortcuts")`，再重新加载 Hyprland，可关闭此功能并恢复工作区移动绑定。
