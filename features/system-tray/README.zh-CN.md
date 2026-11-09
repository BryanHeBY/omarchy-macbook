# 系统托盘

[English](README.md)

管理托盘图标的显隐、置顶与激活动作。左键点击 Clash 会启动 `/usr/bin/clash-verge`，右键点击打开其托盘菜单。在托盘管理面板中置顶图标，可使其保持可见。

| 文件 | 职责 |
| --- | --- |
| `plugin/manifest.json` | 插件身份、状态栏入口与 `clonedFrom` 替换关系 |
| `plugin/Tray.qml` | 托盘界面与应用点击动作 |
| `plugin/TrayModel.js` | 图标识别、显隐与置顶 |

插件 ID 为 `system-tray`，替换 `omarchy.tray`。Clash 快捷动作需要安装提供 `/usr/bin/clash-verge` 的应用，其他条目沿用各自的托盘激活行为。

可以通过 [推荐安装器](../../docs/installation.zh-CN.md) 启用，也可以先部署 Shell 插件链接并请求插件发现，再启用 `system-tray`。通过软链接引用的插件代码修改后，需要重启 Shell。检查置顶、显隐以及左右键点击动作。启用 `omarchy.tray` 可恢复内置托盘。

源码派生自 Omarchy 4.5，并保留 [上游 MIT 声明](../../LICENSES/Omarchy-MIT.txt)。
