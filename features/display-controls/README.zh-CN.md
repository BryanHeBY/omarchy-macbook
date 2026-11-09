# 显示控制面板

[English](README.md)

为 Omarchy 显示面板提供 1、1.25、1.6、1.8、1.9、2 和 3 倍缩放预设。亮度、文字大小和显示器管理沿用上游面板的行为。

| 文件 | 职责 |
| --- | --- |
| `hyprland.lua` | 通过 `debug.disable_scale_checks` 启用精确分数缩放 |
| `plugin/Panel.qml` | 显示面板界面与预设按钮 |
| `plugin/Model.js` | 预设匹配与缩放计算 |
| `plugin/set-scale.sh` | 按显示器持久化设置、GTK 缩放与本地操作日志 |
| `plugin/manifest.json` | 插件身份、能力、入口与上游替换关系 |
| `tests/scaling.cjs` | 精确缩放持久化与失败保护测试 |

清单中的插件 ID 为 `display-controls`，`clonedFrom` 为 `omarchy.monitor`。插件保留上游显示面板的 IPC 路由。精确分数缩放会产生非整数逻辑像素，可能在 Hyprland 会话中引入对齐或取整误差。使用以下命令选用此功能。

```bash
python3 install.py --apply --with-display-controls
```

如需单独安装，先部署 Hyprland 和 Shell 分组的链接，执行 `installer/patches.sh --apply --only display`，重新加载 Hyprland，再在插件发现完成后启用 `display-controls`。具体步骤见 [安装说明](../../docs/installation.zh-CN.md)。

```bash
bash features/display-controls/plugin/set-scale.sh 1.8
hyprctl monitors -j
omarchy shell omarchy.monitor state
node features/display-controls/tests/scaling.cjs
```

恢复缩放校验前，先选择与显示器分辨率兼容的缩放比例，再从 `monitors.lua` 移除分数缩放模块的加载语句，并重新加载 Hyprland。启用 `omarchy.monitor` 可恢复内置面板。

操作日志位于 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/monitor-scaling.log`，包含显示器和进程信息。分享本地日志前应先检查内容。

插件源码派生自 Omarchy 4.5，保留上游作者元数据与 [MIT 声明](../../LICENSES/Omarchy-MIT.txt)。
