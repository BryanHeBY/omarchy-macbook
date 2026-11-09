# 菜单选择记忆

[English](README.md)

按菜单和标准化后的搜索词，优先显示最近一次选择的结果。搜索词会统一大小写并整理空白字符，最多保留 256 条菜单与搜索词的选择记录。

| 文件 | 职责 |
| --- | --- |
| `plugin/manifest.json` | 插件 ID、能力、入口与 `clonedFrom` 元数据 |
| `plugin/BarWidget.qml` | 使用现有菜单路由的状态栏按钮 |
| `plugin/Menu.qml` | 菜单界面与选择记录 |
| `plugin/MenuHistory.js` | 本地历史解析、数量限制与排序 |
| `plugin/MenuModel.js` | 上游菜单解析、匹配与条目模型 |

插件 ID 为 `menu-selection-memory`，替换 `omarchy.menu`。可以通过 [推荐安装器](../../docs/installation.zh-CN.md) 启用，也可以先部署 Shell 插件链接并请求插件发现，再启用该 ID。通过软链接引用的插件代码修改后，需要重启 Shell。

使用 Super+Space 搜索并选择一个结果，再次输入相同搜索词，检查排序变化。历史保存在 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/menu-history.json`。启用 `omarchy.menu` 可恢复内置菜单。

插件源码派生自 Omarchy 4.5，并保留 [上游 MIT 声明](../../LICENSES/Omarchy-MIT.txt)。
