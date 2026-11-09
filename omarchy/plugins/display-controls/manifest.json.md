# manifest.json

`display-controls` 提供亮度、文字大小、显示器开关和缩放预设，派生自 Omarchy 的显示面板。

`clonedFrom` 指向 `omarchy.monitor`，使内置显示面板入口及快捷键解析到此插件。插件保留对应 IPC 名称，清单使用可共享的语义标识。上游许可见仓库根目录的 `LICENSES/Omarchy-MIT.txt`。

缩放预设为 1、1.25、1.6、1.8、1.9、2、3。`Panel.qml` 使用相邻的 `set-scale.sh` 应用精确倍率并复用上游持久化逻辑，`Model.js` 负责预设和当前倍率匹配。需先启用 `hypr.customizations.fractional-scaling`，允许分数逻辑像素及其舍入误差。
