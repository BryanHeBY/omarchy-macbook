# 推荐安装与生效

[English](installation.md)

推荐预设为 MacBook 上的 Omarchy M 提供熟悉的 macOS 操作习惯。默认选择来自 [profiles/recommended.json](../profiles/recommended.json)，命令行参数覆盖相应选项。

在仓库根目录以桌面用户运行安装器。默认调用预览完整计划，指定 `--apply` 后执行，并在各配置步骤分别备份。

```bash
python3 install.py
python3 install.py --apply
```

## 推荐默认值

| 组件 | 全新安装 |
| --- | --- |
| 三指和四指切换工作区 | 启用 |
| 工作区动画与按应用适配的标签页快捷键 | 启用 |
| 中文字体回退规则 | 启用 |
| Caps Lock/Fn 输入法切换与 Fn+E 表情快捷键 | 启用 |
| 菜单选择记忆和系统托盘插件 | 启用 |
| 双指窗口焦点切换 | 显式选用 |
| 精确分数缩放控制 | 显式选用 |
| 免密解锁 | 显式选用 |
| VS Code 编辑器惯性滚动 | 显式选用 |

默认预设会将双指横向移动传递给应用。启用双指焦点切换后，当多个平铺窗口满足条件时，横向手势用于轮换焦点。三指和四指工作区手势独立于这一选择。

## 输入法切换方案

默认 `caps-fn` 方案提供 Caps Lock 长短按、Fn 短按和 Fn+E。原来的左 Shift 主触发键保留为 `shift` 方案。可在安装时选择，也可通过独立键盘安装器切换已有配置。

```bash
# 推荐方案，同时执行生效步骤。
python3 install.py --apply --input-method caps-fn

# 原来的左 Shift 输入法切换。
python3 install.py --apply --input-method shift

# 单独切换键盘与输入法方案。
python3 features/keyboard-input/configure.py --apply --profile shift
python3 features/keyboard-input/configure.py --apply --profile caps-fn
```

Shift 方案会恢复左 Shift 为 Fcitx5 主触发键，移除 MacBook 键盘模块加载语句，并删除本项目的 keyd 映射。若还有其他 keyd 映射，安装器会重新加载它们。若这是唯一配置，则停止服务并取消开机启用。其他热键予以保留。切换方案时先关闭大写锁定。

原来针对默认模板的补丁保留在 `features/keyboard-input/patches/shift.patch`，可通过 `installer/patches.sh --apply --only fcitx5-shift` 应用。切换已安装方案时，独立键盘安装器会直接处理现有配置。设备支持和恢复步骤见 [键盘说明](../features/keyboard-input/README.zh-CN.md)。

## 可选功能

在 `--apply` 后添加所需参数。

```bash
python3 install.py --apply --with-two-finger-focus
python3 install.py --apply --with-display-controls
python3 install.py --apply --with-passwordless-lock
python3 install.py --apply --with-vscode-inertia
```

默认安装选择 Caps Lock/Fn，并关闭双指焦点切换。后续完整安装时，如需保持双指功能启用，应继续传入对应参数。也可以通过独立工具选择其状态。

```bash
python3 features/window-focus-gestures/configure.py --enable
python3 features/window-focus-gestures/configure.py --apply --enable
python3 features/window-focus-gestures/configure.py --apply --disable
```

启用时使用与 Hyprland 匹配的开发头文件编译原生插件，创建 `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-macbook/two-finger-focus.enabled`，加载动态库并验证 Hyprland。关闭时移除标记、卸载动态库并重新加载配置。工具会备份已有标记、串行化更新，失败时尝试恢复此前选择。具体行为见 [窗口焦点手势](../features/window-focus-gestures/README.zh-CN.md)。

[显示控制面板](../features/display-controls/README.zh-CN.md) 会启用 `debug.disable_scale_checks`，允许非整数逻辑像素，可能产生对齐误差。[免密解锁](../features/passwordless-lock/README.zh-CN.md) 允许点击或任意按键进入会话。请按预期桌面行为选择这些选项。VS Code 选项会调用独立的 [滚动设置工具](../features/vscode-scrolling/README.zh-CN.md)。后续安装选用其他组件时，会保留已有的可选 Shell 插件选择。

## 生效步骤

安装器验证所选 Shell 插件、安装依赖包、创建清单中的软链接，并应用 Hyprland 模块加载补丁。随后配置所选输入法方案和双指状态、应用所选可选设置，并重建字体缓存。

Shell 插件发现是异步过程。安装器请求重新扫描，等待所选插件 ID 出现后再启用。随后重新加载 Hyprland、检查配置错误、重启一次 Shell，并验证 IPC 响应。输入法安装器会重新加载 Fcitx5，并启用对应系统服务。

各步骤有独立的备份与恢复行为。失败后停止后续步骤，已完成步骤保留安装结果。重新执行所选命令时，会通过幂等配置步骤继续安装。安装器通过状态目录中的锁串行化完整安装，各功能工具也支持单独执行。

字体包、Caps Lock/Fn 所需的 keyd 和可选编译工具通过 `omarchy pkg add` 安装。基础 Omarchy 桌面、Fcitx5 输入法以及运行中的 Hyprland/Shell 会话需要预先配置。原生编译需要与当前运行的 Hyprland 构建匹配的头文件。

## 恢复配置

各组件安装器会输出备份目录。链接备份保留相对 HOME 的路径。恢复被替换的条目前，先确认备份存在，再移除已安装链接，将备份项移回目标位置。目录链接迁移还会保存此前的父目录链接及剩余本地内容。还原早期目录布局的源码时，应使用对应仓库快照。

补丁备份在状态目录下保留用户路径。恢复所需配置文件，合并后来新增的手动修改，再重新加载相应组件。[键盘](../features/keyboard-input/README.zh-CN.md) 和 [滚动](../features/vscode-scrolling/README.zh-CN.md) 文档说明了各自的备份格式。

```bash
hyprctl reload
hyprctl configerrors
fcitx5-remote --check -r
```

需要时可通过内置插件 ID 恢复对应 Shell 功能。

```bash
omarchy plugin enable omarchy.menu
omarchy plugin enable omarchy.tray
omarchy plugin enable omarchy.monitor
omarchy plugin enable omarchy.lock
omarchy restart shell
```

移除分数缩放前，先选择兼容的缩放比例，再按照 [显示控制面板说明](../features/display-controls/README.zh-CN.md) 移除加载语句。各功能文档提供对应验证与恢复步骤。
