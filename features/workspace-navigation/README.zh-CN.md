# 工作区导航

[English](README.md)

识别到三指或四指横向滑动时切换一次工作区。向左滑动前往下一个工作区，向右滑动前往上一个工作区，包含空工作区。滑动过渡采用 `macWorkspaceEase` 曲线，速度为 3.2。

| 文件 | 职责 |
| --- | --- |
| `gestures.lua` | 三／四指离散切换工作区 |
| `animations.lua` | 工作区过渡曲线与动画配置 |

在仓库根目录运行以下命令。

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only workspace
hyprctl reload
hyprctl configerrors
```

部署别名为 `~/.config/hypr/customizations/` 下的 `workspace-gestures.lua` 和 `workspace-animation.lua`，安装器分别从 `input.lua` 和 `looknfeel.lua` 加载它们。

检查两个滑动方向，并确认可以进入空工作区。可选的 [双指窗口焦点手势](../window-focus-gestures/README.zh-CN.md) 使用独立加载器与启用标记。
