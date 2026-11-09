# Omarchy MacBook

[English](README.md)

**为 Omarchy M（MacBook）优化的配置与插件集，致力于提供接近原生 macOS 的使用习惯和桌面体验。**

各功能可以独立选用，也可以使用推荐预设。功能涵盖工作区手势、应用感知快捷键、输入法切换、中文字体和 Omarchy Shell 插件。

## 快速开始

在已经启动的 Omarchy 会话中，以桌面用户运行以下命令。

```bash
python3 install.py
python3 install.py --apply
```

第一条命令预览完整计划。第二条会安装依赖、备份配置、接入软链接与补丁、启用所选输入法方案及插件、刷新字体，并验证 Hyprland 和 Shell 的生效状态。

默认选择集中在 [profiles/recommended.json](profiles/recommended.json)。推荐启用工作区导航、标签页快捷键、中文字体、Caps Lock/Fn、菜单记忆和托盘。双指焦点切换、精确分数缩放、免密锁屏及 VS Code 惯性滚动需要显式选择。

```bash
# 使用原来的左 Shift 输入法切换方案。
python3 install.py --apply --input-method shift

# 按需组合可选功能参数。
python3 install.py --apply --with-two-finger-focus
python3 install.py --apply --with-display-controls
python3 install.py --apply --with-passwordless-lock
python3 install.py --apply --with-vscode-inertia
```

每次完整安装会应用所选输入法方案和双指状态，保留其他已有用户选择。各步骤分别备份，发生错误时停止后续步骤。独立配置和恢复方法见 [安装说明](docs/installation.md)。

## 功能

| 功能 | 行为 | 说明 |
| --- | --- | --- |
| 工作区导航 | 三／四指离散切换、空工作区与缓出滑动动画 | [工作区导航](features/workspace-navigation/README.md) |
| 标签页快捷键 | Super+W 关闭标签或文档，Super+T 按应用习惯新建标签或文档 | [标签页快捷键](features/tab-shortcuts/README.md) |
| 键盘与输入法 | Caps Lock 长短按、Fn 切源、Fn+E 表情，另有左 Shift 方案 | [键盘与输入法](features/keyboard-input/README.md) |
| 中文字体 | Sarasa UI/Mono SC 与 Noto CJK 回退 | [中文字体](features/chinese-fonts/README.md) |
| 菜单选择记忆 | 同一菜单和搜索词优先显示上次选择 | [菜单选择记忆](features/menu-selection-memory/README.md) |
| 系统托盘 | 图标置顶、显隐和点击动作，包含 Clash 启动 | [系统托盘](features/system-tray/README.md) |
| 窗口焦点手势 | 可选双指横滑切换平铺窗口焦点 | [窗口焦点手势](features/window-focus-gestures/README.md) |
| 显示面板 | 精确的 1×、1.25×、1.6×、1.8×、1.9×、2×、3× 档位 | [显示面板](features/display-controls/README.md) |
| 免密锁屏 | 点击或任意按键进入桌面 | [免密锁屏](features/passwordless-lock/README.md) |
| VS Code 滚动 | 编辑器抬手后的惯性滚动 | [VS Code 滚动](features/vscode-scrolling/README.md) |

## 目录原则

```text
install.py                 推荐安装与生效入口
profiles/recommended.json  默认功能和输入法方案
features/<capability>/     按功能归属配置、脚本、实现、测试和说明
installer/                 通用软链接、补丁及加载接入
tests/installation/       跨功能安装与恢复测试
docs/                      安装与架构说明
docs/examples/             参考配置
LICENSES/                  上游许可声明
```

每个功能维护自己的源码、配置和测试。Shell 插件的完整运行目录放在 `plugin/`，原生插件源码放在 `native/`。安装器通过清单部署逐文件 Lua 链接及完整插件目录链接，运行数据使用用户的 XDG 目录。职责划分见 [架构说明](docs/architecture.md)。

## 环境与依赖

- Omarchy 4.5 的 Lua 配置和 Shell 插件接口，以及已启动的 Hyprland、Quickshell 和 Fcitx5 会话。
- Python 3.10 或更新版本、Bash、GNU patch/coreutils/awk、jq、util-linux 和 Fontconfig。
- 默认键盘方案使用经过验证的 Apple SPI Keyboard 完整指纹和 keyd 2.6，Shift 方案使用 Fcitx5 的主触发键。
- 中文字体使用 `ttf-sarasa-gothic` 和 `noto-fonts-cjk`。
- 可选双指插件针对 Hyprland 0.56.2，需要与运行版本匹配的头文件、pkg-config 和支持 C++26 的 G++。
- VS Code 惯性滚动需要 Node.js 18 或更新版本，以及支持 `editor.inertialScroll` 的 VS Code。
- Clash 托盘动作使用 `/usr/bin/clash-verge`，锁屏视频背景缩略图使用 `ffmpegthumbnailer` 和 `flock`。

安装器通过 `omarchy pkg add` 补充所选功能的依赖。各功能说明包含对应版本要求和生效命令。

## 验证

在仓库根目录运行以下命令。

```bash
node tests/installation/configuration.cjs
python3 tests/installation/recommended.py
python3 features/keyboard-input/tests/configure.py
node features/display-controls/tests/scaling.cjs
node features/vscode-scrolling/tests/configure.cjs
lua features/tab-shortcuts/tests/shortcuts.lua
lua features/window-focus-gestures/tests/loader.lua
g++ -std=c++20 -Wall -Wextra features/window-focus-gestures/tests/gesture-state.cpp -o /tmp/test-window-focus
/tmp/test-window-focus
```

安装测试使用临时 HOME、状态目录和本机 Omarchy 默认模板。功能测试覆盖设置编辑、显示持久化、输入法方案、按键转发和手势状态。各功能 README 另有桌面交互验证步骤。

## 数据与恢复

安装器打印 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/` 下的备份位置。软链接备份保留相对用户目录的路径，包含被替换的文件和链接。键盘与手势工具保留各自备份，并在失败时尝试恢复。

用户配置、凭据、搜索记录、日志、缓存和编译产物存放在用户目录。菜单记忆位于 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/menu-history.json`。显示日志可能包含显示器名称、路径和进程参数，分享诊断资料前应检查。恢复步骤见 [安装说明](docs/installation.md) 及各功能文档。

## 许可与上游

本仓库采用 [MIT 许可](LICENSE)。Shell 插件派生自 Omarchy 4.5，保留上游作者和替换元数据，并附带 [上游 MIT 声明](LICENSES/Omarchy-MIT.txt)。[Omarchy](https://github.com/omacom/omarchy) 和 [上游许可](https://github.com/omacom/omarchy/blob/quattro/LICENSE)。
