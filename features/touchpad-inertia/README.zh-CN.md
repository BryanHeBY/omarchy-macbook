# 触摸板滚动惯性

[English](README.md)

可选的 Hyprland 原生插件，在触摸板滚动结束后追加逐渐减速的纵向运动。默认适配 Foot，以及获得键盘焦点的 Omarchy 菜单层，覆盖 Super+K 快捷键列表、Super+Space 和选择菜单。推荐预设将此功能设为显式选用。

## 行为与范围

- 实际手指事件继续传给应用。最近至少两个纵向移动样本，可以在纵向停止事件到来时启动惯性。
- 松手前暂停超过 80 ms 会丢弃旧速度，反向滑动会更新速度方向。缺少停止事件时，滚动继续跟随实际手指输入。
- 惯性以 16 ms 为间隔衰减。新的手指手势、识别到的触摸板按住、指针移动、点击、按键、焦点变化、配置重载、锁屏或目标变化会停止惯性。
- 仅 `FINGER` 来源符合条件。横向主导的手势结束后不追加滚动，合成事件直接送到 seat，绕过横向窗口焦点手势过滤器。
- Foot 类名为 `foot` 和 `org.codeberg.dnkl.foot`。类名以 `org.omarchy.*` 或 `TUI.*` 开头的 Omarchy TUI，在初始标题为 `foot` 时也适配。
- `omarchy-menu` 层在获得键盘焦点且指针位于其界面时适配。其他面板沿用现有应用行为。
- 惯性沿用已配置的自然滚动方向，以及 Hyprland 的触摸板、设备和窗口滚动倍率。默认允许列表让浏览器与 VS Code 使用各自的滚动实现。

Foot 历史滚动和前台终端程序自行解释滚动事件，因此 Shell、分页器和 TUI 的行数增量可能不同。Qt 菜单也保留自身的控件绘制和边界处理。实现依据 libinput 的手指／停止模型与本机 Hyprland seat 接口，自然滚动方向另有独立说明。[libinput 滚动模型](https://wayland.freedesktop.org/libinput/doc/latest/scrolling)、[自然滚动](../touchpad-scrolling/README.zh-CN.md)。

## 文件与依赖

| 文件 | 职责 |
| --- | --- |
| `hyprland.lua` | 按标记加载，配置 Foot 类名、菜单命名空间与衰减 |
| `native/plugin.cpp` | 输入、目标验证、定时器与 seat 合成事件 |
| `native/ScrollState.hpp` | 方向、速度、松手与衰减状态 |
| `native/WindowPolicy.hpp` | 精确类名与菜单命名空间匹配 |
| `build.sh` | 共享原生构建工具的功能入口 |
| `configure.py` | 共享启停与回滚工具的功能入口 |
| `tests/` | 惯性状态、目标规则与显式启用加载器测试 |

当前原生接口面向 Hyprland 0.56.2。需要与运行中的合成器匹配的头文件、支持 C++26 的 G++、pkg-config，以及 libei 提供的 `libeis-1.0` 开发元数据。配置工具需要 Python 3.10 或更新版本。

## 安装与生效

在仓库根目录以桌面用户运行。完整安装器支持 `python3 install.py --apply --with-touchpad-inertia`。单独安装使用以下命令。

```bash
omarchy pkg add gcc pkgconf libei
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only touchpad-inertia
python3 features/touchpad-inertia/configure.py --enable
python3 features/touchpad-inertia/configure.py --apply --enable
```

工具编译动态库，将已有标记和动态库备份到 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/native-plugin-backups/`，创建 `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-macbook/touchpad-inertia.enabled`，加载插件、重新加载 Hyprland 并检查结果。

动态库位于 `${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/touchpad-inertia.so`。原生安装器共享文件锁，生效失败时恢复此前文件并尝试恢复加载状态。仅编译动态库时，是否生效仍由标记控制。Hyprland 升级后重新启用，以重新编译。

后续完整安装省略此可选功能时，会保留其当前选择。需要关闭时使用独立工具。

```bash
python3 features/touchpad-inertia/configure.py --apply --disable
```

在功能 Lua 模块中调整 `classes`、`layers` 或 `decay_ms`，再重新加载 Hyprland。衰减时间范围为 40–600 ms，默认指数衰减时间常数为 180 ms。扩展允许列表前，应检查目标已有的惯性行为。

## 验证与恢复

```bash
lua features/touchpad-inertia/tests/loader.lua
g++ -std=c++20 -Wall -Wextra features/touchpad-inertia/tests/scroll-state.cpp -o /tmp/test-touchpad-inertia
/tmp/test-touchpad-inertia
python3 tests/installation/native_plugin.py
hyprctl plugin list
hyprctl configerrors
```

在具有较长历史输出的 Foot 和 Super+K 列表中纵向甩动后抬手。检查减速、松手前暂停、新的触摸、焦点切换和滚动内容边缘。有两个平铺窗口时，检查原有横向焦点手势仍然每次切换一次，再分别检查浏览器和 VS Code。

关闭工具会卸载插件并移除标记。需要时可从输出的备份恢复此前动态库或标记，再重新加载并验证 Hyprland。恢复完整用户配置前，应合并当前个人设置。
