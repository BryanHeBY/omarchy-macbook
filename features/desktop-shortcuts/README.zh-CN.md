# 桌面编辑快捷键

[English](README.md)

以 Super 对应 Command，适配常用文档操作、浏览器导航和按场景处理的删除。推荐预设默认启用此功能。

## 按键映射

| 快捷键 | 转发动作 |
| --- | --- |
| Super+Z | Ctrl+Z，撤销 |
| Super+Shift+Z | Ctrl+Shift+Z，重做 |
| Super+S | Ctrl+S，保存 |
| Super+Shift+S | Ctrl+Shift+S，另存为 |
| Super+F | Ctrl+F，查找 |
| Super+O | Ctrl+O，打开 |
| Super+P | Ctrl+P，打印 |
| Super+L | Ctrl+L，在浏览器和文件管理器中定位地址栏 |
| Super+R | Ctrl+R，在浏览器和文件管理器中刷新 |
| Super+Backspace | 文件管理器中发送 Delete，终端中发送 Ctrl+U，其他场景先发送 Shift+Home 再发送 Backspace |

常用文档操作作用于非终端窗口。通过 Omarchy 的 `terminal` 标签识别终端，通过浏览器标签限定地址栏和刷新操作。文件管理器支持 Nautilus、Dolphin、Thunar 和 Nemo 的窗口类名。复制粘贴和标签页快捷键由各自的 Omarchy 或仓库模块提供。

删除由当前获得焦点的应用解释。在文件列表中，原生 Delete 使用应用自身的回收站处理和提示。在文本框中，Shift+Home 先向应用定义的 Home 位置选择，再由 Backspace 删除。智能缩进 Home、折行和已有选区的效果遵循控件自身的选择规则。终端中的 Ctrl+U 遵循 Shell 或 TUI 的绑定，内嵌终端则沿用所在应用的原生快捷键行为。

转发沿用 Omarchy 显式发送按下／释放事件的方式，目标为当前获得焦点的界面，因此菜单打开时也会接收按键。多步骤删除在活动窗口变化时停止。应用自身的快捷键定制可能影响最终效果。参考行为见 Apple 和 GNOME 文档。[Apple 键盘快捷键](https://support.apple.com/en-us/102650)、[GNOME 文件删除](https://help.gnome.org/gnome-help/files-delete.html)。

## 默认绑定变化

| 快捷键 | 被替换的 Omarchy 动作 |
| --- | --- |
| Super+Backspace | 切换窗口透明度 |
| Super+F | 全屏 |
| Super+S | 切换暂存区 |
| Super+Shift+S | Google Maps |
| Super+O | 窗口悬浮并置顶 |
| Super+P | 伪平铺窗口 |
| Super+L | 切换工作区布局 |

现有 Super+Ctrl+F 可继续使用平铺全屏。其他被替换的动作可以在 `~/.config/hypr/bindings.lua` 中安排个人快捷键。使用 `o.rebind` 定义的后续个人绑定优先。

## 安装、验证与恢复

`hyprland.lua` 定义按键与转发逻辑。在仓库根目录运行以下命令。

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only desktop-shortcuts
hyprctl reload
hyprctl configerrors
lua features/desktop-shortcuts/tests/shortcuts.lua
```

补丁安装器备份 `bindings.lua`，安装后的模块别名为 `~/.config/hypr/customizations/desktop-shortcuts.lua`。使用临时文本，以及本地支持回收站的目录中的临时文件验证。检查撤销／重做、删除到行首、原生回收站行为、浏览器查找和地址栏定位。

从 `bindings.lua` 移除 `require("hypr.customizations.desktop-shortcuts")` 并重新加载 Hyprland，可恢复默认行为。独立的 [截图快捷键](../screenshot-shortcuts/README.zh-CN.md) 需要显式选用。
