# Omarchy MacBook

[English](README.md)

**为 Omarchy M（MacBook）优化的配置与插件集，致力于提供接近原生 macOS 的使用习惯和桌面体验。**

面向 Omarchy 的模块化桌面定制，提供工作区手势、动画、标签页快捷键、中文字体、输入法热键和 Shell 插件。配置通过软链接和局部补丁接入，各部分可以分别选用。

## 功能

| 部分 | 效果 | 文件 |
| --- | --- | --- |
| 工作区手势 | 三指或四指横滑触发一次切换，支持空工作区 | `hyprland/workspace-gestures.lua` |
| 窗口焦点手势 | 默认关闭，显式启用后双指横滑循环切换平铺窗口焦点 | `hyprland/plugins/two-finger-focus/` |
| 工作区动画 | 缓出曲线和滑动过渡 | `hyprland/workspace-animation.lua` |
| 标签页快捷键 | `Super+W` 关闭标签或文档，`Super+T` 新建标签或文档 | `hyprland/tab-shortcuts.lua` |
| MacBook 键盘 | 默认 Caps Lock/Fn，保留原左 Shift 切换作为可选方案 | `input-method/` |
| 中文字体 | Sarasa UI SC、Sarasa Mono SC 和 Noto CJK 回退 | `fonts/chinese-fonts.conf` |
| 显示面板 | 1×、1.25×、1.6×、1.8×、1.9×、2×、3× 缩放档位 | `omarchy/plugins/display-controls/` |
| 系统托盘 | 图标置顶、显隐和应用点击动作，包含 Clash 快捷启动 | `omarchy/plugins/system-tray/` |
| 菜单选择记忆 | 按菜单和搜索词记忆最近选择并置顶 | `omarchy/plugins/menu-selection-memory/` |
| VS Code 惯性滚动 | 独立脚本启用编辑器抬手后的惯性滚动 | `scripts/configure-vscode-scroll.cjs` |
| 免密锁屏 | 点击或任意按键直接进入桌面 | `omarchy/plugins/passwordless-lock/` |

手势左滑进入下一个工作区，右滑进入上一个工作区。

### 双指窗口焦点切换

该功能默认关闭，需要单独启用；仅编译插件不会自动生效。

同一工作区有至少两个可见、可聚焦的平铺窗口，且指针位于平铺窗口内容上时，双指横滑按窗口从左到右、同列从上到下的顺序循环切换焦点。每次滑动最多切换一次，抬手后可以再次切换。

单窗口、浮动窗口、全屏、锁屏和按住修饰键时，滚动交给应用处理。纵向滚动和鼠标滚轮同样由应用处理。三指、四指继续切换工作区。

该功能通过可选的原生 Hyprland 插件接管触控板横向滚动。识别阈值为累计 18 个输入单位，横向位移需达到纵向位移的 1.5 倍。阈值位于 `hyprland/plugins/two-finger-focus/GestureState.hpp`。正常序列在抬手时结束，超过 400ms 没有滚动事件时也会重置，以恢复缺失结束事件的输入序列。

### 应用感知的标签页快捷键

| 应用 | `Super+W` 转发 | `Super+T` 转发 | 行为 |
| --- | --- | --- | --- |
| Chromium、Firefox 系浏览器 | `Ctrl+W` | `Ctrl+T` | 关闭、新建浏览器标签 |
| Nautilus、Dolphin、Thunar、Nemo、Obsidian | `Ctrl+W` | `Ctrl+T` | 关闭、新建标签 |
| VS Code / Insiders、Code OSS、VSCodium、Cursor、Windsurf | `Ctrl+W` | `Ctrl+N` | 关闭当前编辑器、新建空白文档 |
| Kate、KWrite、Gedit、Sublime Text | `Ctrl+W` | `Ctrl+N` | 关闭、新建文档 |
| Konsole、GNOME Terminal、Xfce Terminal、WezTerm、Ghostty | `Ctrl+Shift+W` | `Ctrl+Shift+T` | 关闭当前终端标签或会话、新建标签 |
| Kitty | `Ctrl+Shift+Q` | `Ctrl+Shift+T` | 关闭当前标签、新建标签 |

编辑器中的 `Super+T` 采用新建空白文档的约定。保存提示、最后一个标签及嵌入终端焦点的处理由应用原生快捷键决定。默认快捷键依据应用文档配置。[VS Code](https://code.visualstudio.com/docs/reference/default-keybindings)、[Konsole](https://docs.kde.org/stable_kf6/en/konsole/konsole/commandreference.html)、[Kitty](https://sw.kovidgoyal.net/kitty/invocation/)、[WezTerm](https://wezterm.org/config/default-keys.html)。

应用通过精确窗口类或 Omarchy 的浏览器标签识别，分组可在 `hyprland/tab-shortcuts.lua` 中扩展。其余应用的 `Super+W` 关闭窗口，`Super+T` 结束处理。Foot、Alacritty 使用这一组窗口行为。

## 环境与依赖

- Omarchy 4.5 的 Lua 配置和 Shell 插件接口。
- Hyprland、Quickshell 及 Omarchy 提供的 `qs.Commons`、`qs.Ui` 组件。
- 双指焦点插件针对 Hyprland 0.56.2，需要匹配运行版本的开发头文件、支持 C++26 的 G++ 和 pkg-config。
- Bash、GNU patch、GNU coreutils、GNU awk、jq、util-linux（`flock`）和 Fontconfig。
- VS Code 惯性滚动脚本需要 Node.js 18 或更新版本，以及支持 `editor.inertialScroll` 的 VS Code。
- 回归测试使用 Lua、Node.js 和 G++。
- 输入法切换需要 Fcitx5，可选的 MacBook 键盘定制还需要 keyd 2.6 和 Python 3.10 或更新版本。
- 中文字体需要 `ttf-sarasa-gothic` 和 `noto-fonts-cjk`。
- Clash 快捷启动需要提供 `/usr/bin/clash-verge` 的应用包。
- 锁屏视频背景缩略图需要 `ffmpegthumbnailer` 和 `flock`。

补丁基于 Omarchy 4.5 默认配置生成。遇到上下文冲突时，apply 脚本会停止并显示对应文件。

## 目录

```text
docs/installation.md    推荐默认值与完整生效流程
docs/macbook-keyboard.md Caps Lock/Fn 行为、安装与恢复说明
docs/vscode-scrolling.md VS Code 惯性滚动与恢复说明
fonts/                  中文字体规则
hyprland/               Lua 模块与原生输入插件源码
input-method/           Fcitx5 补丁与 keyd 键盘映射
install/symlinks.tsv     软链接清单
omarchy/plugins/        Shell 插件及其完整本地依赖
omarchy/shell-integration.json
                        插件接入的声明式参考
patches/                Hyprland 模块加载补丁
scripts/install.py      推荐的一键安装与生效入口
scripts/configure-two-finger-focus.py
                        双指焦点切换的独立启停入口
scripts/install-links.sh
                        软链接预检、备份和安装入口
scripts/apply-patches.sh
                        补丁检查、备份和应用入口
scripts/build-two-finger-focus.sh
                        编译可选的双指焦点插件
scripts/install-macbook-keyboard.py
                        可选 Caps Lock/Fn 配置安装与备份
scripts/configure-vscode-scroll.cjs
                        独立预览、备份并设置 VS Code 惯性滚动
tests/vscode-scrolling.cjs
                        JSONC 编辑、备份、幂等与恢复选项测试
tests/recommended-install.py
                        默认选项及生效顺序测试
tests/two-finger-loader.lua
                        双指功能显式启用的加载测试
tests/macbook-keyboard.py
                        输入法迁移与键盘设备匹配测试
tests/tab-shortcuts.lua  应用感知快捷键的 Lua 回归测试
tests/two-finger-focus.cpp
                        双指手势状态与滚动转发回归测试
tests/display-controls.cjs
                        显示预设和缩放持久化回归测试
tests/install-scripts.cjs
                        安装、备份、重复运行与失败恢复测试
```

插件内部文件名符合 Omarchy 加载器约定。严格 JSON 配有同名 `.md` 说明，其他源码使用对应格式的注释。

## 接入配置

以下命令在仓库根目录执行。仓库可以放在任意目录，脚本通过自身位置解析源码路径，目标配置路径使用 `$HOME`。

### 推荐的一键安装

```bash
# 默认预览完整安装与生效计划。
python3 scripts/install.py
python3 scripts/install.py --apply

# 选择原来的左 Shift 输入法切换方案。
python3 scripts/install.py --apply --input-method shift

# 显式开启双指切换窗口焦点。
python3 scripts/install.py --apply --with-two-finger-focus
```

默认启用三／四指工作区手势、动画、标签页快捷键、中文字体、菜单记忆、托盘和 Caps Lock/Fn 输入法方案。双指焦点切换默认关闭，显示面板、免密锁屏和 VS Code 惯性滚动分别通过可选参数启用。脚本负责安装依赖、启用所选服务和插件、刷新字体、重载 Hyprland 并检查 Shell 响应。完整选项与失败恢复方式见 [安装说明](docs/installation.md)。

以下分项命令适合只调整某一部分配置。

### 建立软链接

`install/symlinks.tsv` 的第一列相对仓库根目录，第二列相对 `$HOME`。可以选择清单中的部分条目接入。

```bash
# 默认只读检查。确认计划后写入软链接。
./scripts/install-links.sh
./scripts/install-links.sh --apply

# 也可只接入某类配置。
./scripts/install-links.sh --dry-run --only hyprland
./scripts/install-links.sh --apply --only fonts
./scripts/install-links.sh --apply --only shell
```

脚本先检查全部选中项，替换前将原文件、目录或软链接移入用户状态目录的独立备份目录。安装失败时尝试恢复本轮触及的条目。重复运行会跳过已经指向当前仓库的链接。安装器通过 `flock` 避免同时运行造成冲突。

建立链接后，按下面的步骤选择模块与插件。精确分数缩放和免密锁屏分别启用。

| 仓库内容 | 加载位置 |
| --- | --- |
| `hyprland/` | `~/.config/hypr/customizations` |
| `fonts/chinese-fonts.conf` | `~/.config/fontconfig/conf.d/50-omarchy-input-method.conf` |
| `omarchy/plugins/menu-selection-memory/` | `~/.config/omarchy/plugins/menu-selection-memory` |
| `omarchy/plugins/system-tray/` | `~/.config/omarchy/plugins/system-tray` |
| `omarchy/plugins/passwordless-lock/` | `~/.config/omarchy/plugins/passwordless-lock` |
| `omarchy/plugins/display-controls/` | `~/.config/omarchy/plugins/display-controls` |

### 应用模块加载与输入法补丁

```bash
# 默认只读检查。
./scripts/apply-patches.sh

# 备份后应用默认补丁集合。
./scripts/apply-patches.sh --apply

# 也可按部分检查和应用。
./scripts/apply-patches.sh --dry-run --only hyprland
./scripts/apply-patches.sh --apply --only hyprland
./scripts/apply-patches.sh --apply --only fcitx5
```

Hyprland 补丁分别在 `input.lua`、`bindings.lua`、`looknfeel.lua` 中接入对应模块。脚本识别已有的 `require(...)`，支持重复执行和部分接入。输入法补丁移除默认的单按左 Shift 切换，由桌面键盘模块管理输入源切换。

补丁应用前会检查全部选中项，并确认 Lua 模块链接指向当前仓库。待修改文件备份到 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/patch-backups/`，执行失败时尝试恢复本次触及的文件。

### 接入 Shell 插件

建立插件链接后，通过 Omarchy 的克隆插件机制启用所需部分。

```bash
omarchy shell shell rescanPlugins
# 发现插件是异步过程，确认所需插件已出现后再执行 enable。
omarchy plugin list --json

omarchy plugin enable menu-selection-memory
omarchy plugin enable system-tray
# 显示面板还需下文的 display 补丁。
omarchy restart shell
```

插件清单中的 `clonedFrom` 对应内置菜单、托盘、显示面板和锁屏入口，原有菜单快捷键通过该机制解析到选用的插件。`omarchy/shell-integration.json` 提供字段级参考，具体插件状态由 Omarchy CLI 写入用户的 Shell 配置。

`system-tray` 保留通用托盘管理。Clash 左键执行 `/usr/bin/clash-verge`，右键打开托盘菜单。需要常驻显示的图标可在托盘管理面板中置顶。

免密锁屏单独启用。启用后，点击或任意按键会直接解锁，具有本机操作权限的人可以直接进入会话。

```bash
omarchy plugin enable passwordless-lock
omarchy restart shell
```

## 生效与验证

### 手势、动画和标签页快捷键

双指焦点切换需要显式启用标记和编译产物同时存在。独立脚本负责编译、保存选择、加载插件并验证 Hyprland，默认配置关闭该功能。

```bash
python3 scripts/configure-two-finger-focus.py --apply --enable
hyprctl plugin list
hyprctl configerrors
# 恢复应用自身的横向滚动。
python3 scripts/configure-two-finger-focus.py --apply --disable
```

编译产物位于 `${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/two-finger-focus.so`。Hyprland 升级后，需要用匹配的头文件重新编译。插件加载时校验版本和 ABI。修改插件源码并重新编译后，可卸载当前插件再重新加载配置。

```bash
hyprctl plugin unload "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/two-finger-focus.so"
hyprctl plugin load "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/two-finger-focus.so"
hyprctl reload
```

```bash
hyprctl reload
hyprctl configerrors
```

验证三指和四指横滑、空工作区切换，以及匹配应用中的 `Super+W`、`Super+T`。快捷键分组可通过 Lua 回归测试检查。

```bash
lua tests/tab-shortcuts.lua
g++ -std=c++20 -Wall -Wextra tests/two-finger-focus.cpp -o /tmp/test-two-finger-focus
/tmp/test-two-finger-focus
```

双指功能可在同一工作区打开两个平铺窗口验证横滑切换，再关闭其中一个验证应用横向滚动。多窗口时上下滚动应继续传入应用。

### 显示面板与精确分数缩放

`display-controls` 替换内置显示面板，缩放按钮依次为 1×、1.25×、1.6×、1.8×、1.9×、2×、3×。亮度、文字大小和显示器管理沿用上游行为。1.8× 和 1.9× 保留请求值，显示面板和配套命令均使用精确分数缩放。

此功能需要单独启用 `hyprland/fractional-scaling.lua`。它设置 `debug.disable_scale_checks = true`，允许逻辑显示尺寸包含小数，可能出现像素对齐和舍入误差。该选项作用于整个 Hyprland 会话。`display` 补丁独立于默认补丁集合，按需接入。[Hyprland 缩放校验选项](https://wiki.hypr.land/configuring/core/config-options/)

```bash
# 先建立 install/symlinks.tsv 中的 customizations 和 display-controls 软链接。
./scripts/apply-patches.sh --dry-run --only display
./scripts/apply-patches.sh --apply --only display
hyprctl reload
hyprctl configerrors
omarchy shell shell rescanPlugins
# 发现插件是异步过程，确认所需插件已出现后再执行 enable。
omarchy plugin list --json
omarchy plugin enable display-controls
omarchy restart shell
```

打开右上角显示面板，选择需要的倍率。缩放命令保留上游按显示器写入 `~/.config/hypr/monitors.lua`、GTK 整数缩放和变更日志的机制。插件相邻的 `set-scale.sh` 可用于命令行设置，仓库中的源码为真实文件，用户插件目录通过软链接接入。

```bash
bash omarchy/plugins/display-controls/set-scale.sh 1.8
hyprctl monitors -j
omarchy shell omarchy.monitor state
node tests/display-controls.cjs
```

恢复整数像素校验时，先在显示面板中选择与分辨率匹配的倍率，然后移除 `monitors.lua` 中对 `hypr.customizations.fractional-scaling` 的加载，并重载 Hyprland。显示面板通过 `omarchy plugin enable omarchy.monitor` 恢复内置版本。

### MacBook 键盘与输入法切换

可选键盘定制提供 Caps Lock 长短按及 Globe/Fn 行为。短按 Caps Lock 或 Fn 切换输入源，单独长按 Caps Lock 达到 350ms 后进入英文大写锁定，再按一次退出大写。Fn+E 和 Control+Super+Space 打开 Emoji 面板，使用 Fn 组合键后不会再触发单击切源。

```bash
omarchy pkg add keyd
python3 scripts/install-macbook-keyboard.py
python3 scripts/install-macbook-keyboard.py --apply
# 恢复原来的左 Shift 切换方案。
python3 scripts/install-macbook-keyboard.py --apply --profile shift
```

先接入 Hyprland 软链接，再以桌面用户运行安装器。默认方案会备份现有绑定和输入法配置，加载键盘模块，并安装 root 所有的 keyd 配置及启用开机服务。可选的 `shift` 方案会恢复原来的左 Shift 主切换键并移除 Caps Lock/Fn 映射，两套方案都保留其他热键。设备使用经过验证的 Apple SPI Keyboard 完整指纹匹配，排除共用厂商和产品 ID 的触控板。支持范围、阈值调整、验证及恢复步骤见 [键盘说明](docs/macbook-keyboard.md)。

```bash
systemctl --user restart omarchy-fcitx5.service
systemctl --user is-active omarchy-fcitx5.service
```

在新应用窗口短按 Caps Lock 或 Fn，确认可以切换中英文，再验证长按大写和 Fn+E 表情面板。原有 Super+I 也可切换输入源。

### 中文字体

```bash
fc-cache -f
fc-match 'sans-serif:charset=4e2d'
fc-match 'monospace:charset=4e2d'
fc-match 'serif:charset=4e2d'
```

以汉字“中”的码位检查回退，预期分别匹配 Sarasa UI SC、Sarasa Mono SC、Noto Serif CJK SC。应用可能需要重新打开后选取字体。

### VS Code 惯性滚动

VS Code 的 `editor.inertialScroll` 控制手指抬起后的惯性滚动，`editor.smoothScrolling` 控制滚动过渡动画，两者独立。独立脚本只调整前者，默认预览，需要显式应用。

```bash
node scripts/configure-vscode-scroll.cjs
node scripts/configure-vscode-scroll.cjs --apply
# 恢复为关闭惯性滚动。
node scripts/configure-vscode-scroll.cjs --apply --disable
# 其他发行版或命名配置文件需要传入对应设置文件。
node scripts/configure-vscode-scroll.cjs --settings /path/to/settings.json --apply
```

默认目标为 `${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json`。脚本保留 JSONC 注释及其他设置，写入前将原文件备份到 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/vscode-scroll-backups/` 并打印路径，重复运行会跳过已生效的值。应用前先关闭设置编辑器。此脚本独立于安装及补丁流程。

在较长的文本文件中双指上下滑动并抬手验证效果。若未生效，检查当前配置文件、工作区及语言级覆盖项，必要时执行 VS Code 的 `Developer: Reload Window`。它只针对编辑区，终端、侧栏及 Webview 可能采用其他滚动实现。完整说明与备份恢复方式见 [VS Code 惯性滚动](docs/vscode-scrolling.md)。

### Shell 插件

```bash
omarchy plugin validate "$PWD/omarchy/plugins/display-controls"
omarchy plugin validate "$PWD/omarchy/plugins/system-tray"
omarchy plugin validate "$PWD/omarchy/plugins/menu-selection-memory"
omarchy plugin validate "$PWD/omarchy/plugins/passwordless-lock"
omarchy restart shell
```

- 托盘中验证图标置顶、显隐和点击动作。
- 按 `Super+Space` 搜索并选择结果，再次输入相同搜索词，确认上次选择置顶。
- 启用免密锁屏后，可用 `omarchy system lock` 验证点击或按键进入桌面。

同一轮插件编辑集中重启一次 Shell 即可。插件子目录通过软链接接入时，显式重启可确保代码完整重新加载。

## 安装恢复

软链接安装器会打印备份目录，目录内保留相对 `$HOME` 的路径。恢复某个原配置时，先确认对应备份存在，移除当前指向本仓库的软链接，再把备份条目移回原位置。新建的链接可以直接移除。保留仓库文件即可再次接入。

补丁备份同样保留相对 `$HOME` 的路径。可从脚本打印的备份目录取回对应的 `input.lua`、`bindings.lua`、`looknfeel.lua`、`monitors.lua` 或 Fcitx5 配置。恢复 Hyprland 配置后执行 `hyprctl reload` 和 `hyprctl configerrors`，恢复输入法配置后重启 Fcitx5 服务。

插件可通过内置标识恢复。恢复显示面板前，按显示面板章节先选择适合分辨率的倍率，并移除精确分数缩放模块。

```bash
omarchy plugin enable omarchy.menu
omarchy plugin enable omarchy.tray
omarchy plugin enable omarchy.monitor
omarchy plugin enable omarchy.lock
omarchy restart shell
```

## 回归测试

```bash
python3 tests/recommended-install.py
python3 tests/macbook-keyboard.py
lua tests/two-finger-loader.lua
node tests/vscode-scrolling.cjs
node tests/install-scripts.cjs
node tests/display-controls.cjs
lua tests/tab-shortcuts.lua
g++ -std=c++20 -Wall -Wextra tests/two-finger-focus.cpp -o /tmp/test-two-finger-focus
/tmp/test-two-finger-focus
```

安装脚本测试使用临时 HOME 和状态目录，补丁部分读取已安装 Omarchy 的默认配置模板。缩放测试使用模拟的 Hyprland 命令，覆盖倍率保留、持久化及失败处理。

## 数据与维护

菜单按搜索词的大小写和空白规范化后记录选择，每个菜单和搜索词保留最近一次选择，最多 256 条。数据位于 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/menu-history.json`。

显示缩放沿用 Omarchy 的本地变更日志，保存到 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/monitor-scaling.log`，其中包含显示器名称、进程参数和父进程信息。免密锁屏沿用上游背景与指纹状态处理，其缓存位于用户缓存目录。分享诊断资料时应检查日志中的路径和进程信息。

运行时配置、搜索记录、日志、密钥、缓存、备份和编译产物存放在用户配置、状态、缓存或数据目录中。仓库只管理模块源码、通用接入文件和测试。

字体规则、Lua 模块与插件源码通过仓库中的文件维护。插件升级时应比对所依赖的 Omarchy API 和上游实现。备份、缓存和运行数据使用用户的状态或缓存目录。

## 许可与上游

本仓库采用 MIT 许可，见 `LICENSE`。Omarchy 派生组件保留上游版权及 MIT 许可。

Shell 插件派生自 Omarchy 4.5，清单保留上游作者信息和 `clonedFrom` 元数据。上游 MIT 许可文本保存在 `LICENSES/Omarchy-MIT.txt`。[Omarchy](https://github.com/omacom/omarchy)，[上游许可](https://github.com/omacom/omarchy/blob/quattro/LICENSE)。
