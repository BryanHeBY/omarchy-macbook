# shell-integration.json

Shell 插件集成的声明式参考，描述内置入口与定制插件的对应关系，以及服务、禁用项和托盘置顶项。

- `widgetReplacements` 将内置菜单、托盘和显示面板入口映射到对应定制插件。
- `enabledServices` 列出选用的服务插件。
- `disabledPlugins` 和 `cloneSourceRestores` 对应 Omarchy 的克隆插件管理字段。
- `trayPinned` 列出推荐置顶的托盘项目。

使用 README 中的 `omarchy plugin enable` 命令接入插件。此参考文件按字段组织集成意图，Shell 实际读取用户的 `~/.config/omarchy/shell.json`。严格 JSON 的说明保存在此配套文档中。
