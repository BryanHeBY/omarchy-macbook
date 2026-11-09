# VS Code 触控板惯性滚动

[English](README.md)

> **为 Omarchy M（MacBook）优化。** 本功能属于一套配置与插件集，致力于提供接近原生 macOS 的使用习惯和桌面体验。

VS Code 在编辑器内部实现滚动。Linux 输入栈发送手指移动和停止事件，由应用实现抬手后继续运动的效果。VS Code 通过 `editor.inertialScroll` 提供这一行为，默认值为 `false`。`editor.smoothScrolling` 单独控制滚动过渡动画。

## 启用与关闭

在仓库根目录使用 Node.js 18 或更新版本运行以下命令。

```bash
# 预览目标与设置值。
node features/vscode-scrolling/configure.cjs

# 备份设置并启用惯性滚动。
node features/vscode-scrolling/configure.cjs --apply

# 将选项设回 false。
node features/vscode-scrolling/configure.cjs --apply --disable
```

默认目标为 `${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json`。使用其他发行版、命名配置文件、便携安装或自定义用户数据目录时，可通过 **Preferences: Open User Settings (JSON)** 找到当前用户设置，并显式传入路径。

```bash
node features/vscode-scrolling/configure.cjs --settings /path/to/settings.json
node features/vscode-scrolling/configure.cjs --settings /path/to/settings.json --apply
```

脚本仅修改顶层 `editor.inertialScroll` 属性，保留 JSONC 注释、尾随逗号和其他偏好。已有软链接会被解析并保留。JSONC 无效或目标键重复时，会在写入前报错。设置文件不存在时，仅在指定 `--apply` 后创建。值已匹配时会跳过写入和备份。

原有设置在原子替换前备份到 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/vscode-scroll-backups/` 下的私有目录，脚本会输出备份文件路径。应用设置前先关闭设置编辑器，可减少并发修改。

若只需撤销这一选项，使用 `--disable` 或手动移除 `editor.inertialScroll`。若需还原整个文件，先检查并保留后来新增的偏好，再将输出的备份复制到解析后的设置文件路径。备份可能包含个人设置，应存放在仓库之外。

## 检查效果

VS Code 通常会自动重新加载用户设置。打开较长的文本文件，双指上下滚动，并在移动过程中抬起手指，滚动应短暂继续并逐渐减速。选项不可用时，检查当前 VS Code 版本是否支持 `editor.inertialScroll`。

若效果未出现，检查当前配置文件、工作区设置和语言专属覆盖。确认设置后，可执行 **Developer: Reload Window** 刷新编辑器。此偏好作用于编辑器滚动，Webview、集成终端、侧栏和其他应用区域可能各自实现滚动行为。工具保留 `editor.smoothScrolling` 的现有值。

此工具独立于软链接安装器和补丁脚本，也可由推荐安装器在显式指定 `--with-vscode-inertia` 时调用。完整安装方式见 [安装说明](../../docs/installation.zh-CN.md)。

## 参考资料

- [VS Code 编辑器选项](https://github.com/microsoft/vscode/blob/main/src/vs/editor/common/config/editorOptions.ts)
- [VS Code 滚动处理](https://github.com/microsoft/vscode/blob/main/src/vs/base/browser/ui/scrollbar/scrollableElement.ts)
- [libinput 滚动与惯性运动](https://wayland.freedesktop.org/libinput/doc/latest/scrolling)
