# 触摸板自然滚动

[English](README.md)

启用 `input.touchpad.natural_scroll`，让触摸板采用 macOS 风格的自然滚动。推荐预设默认启用此功能。Hyprland 的自然滚动同时作用于两个方向，配置范围为触摸板，鼠标使用自身的输入设置。

`hyprland.lua` 维护这一设置。在仓库根目录运行以下安装命令。

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only touchpad-scrolling
hyprctl reload
hyprctl configerrors
hyprctl getoption input:touchpad:natural_scroll
lua features/touchpad-scrolling/tests/config.lua
```

补丁安装器备份 `input.lua`，并添加对模块的加载。模块链接位于 `~/.config/hypr/customizations/touchpad-scrolling.lua`。检查运行值为 `true`，再实际验证纵向和横向手指滚动。工作区导航和双指焦点切换使用各自模块。

后续加载的个人输入设置和单设备覆盖可以选择其他方向。已有的独立自然滚动配置块可以作为个人覆盖保留，也可以在备份后移除，由此模块统一维护。两者共存时应检查加载顺序。

恢复时，从 `input.lua` 移除 `require("hypr.customizations.touchpad-scrolling")`，按需恢复个人设置，再重新加载 Hyprland 并检查配置错误。也可以在后续个人覆盖中将同一设置显式设为 `false`。
