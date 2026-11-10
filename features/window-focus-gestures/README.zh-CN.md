# 双指窗口焦点手势

[English](README.md)

当指针位于平铺窗口内容区域，且同一工作区至少有两个可见、可聚焦的平铺窗口时，此可选功能使用双指横滑轮换窗口焦点。窗口先按从左到右、再按从上到下排序，每次滑动切换一次。推荐预设默认关闭此功能。

| 文件 | 职责 |
| --- | --- |
| `hyprland.lua` | 在存在显式启用标记时加载原生插件 |
| `native/plugin.cpp` | Hyprland 输入集成与焦点选择 |
| `native/GestureState.hpp` | 滚动分类与手势状态 |
| `build.sh` | 使用与已安装 Hyprland 匹配的头文件编译 |
| `configure.py` | 持久化选择、加载／卸载与配置验证 |
| `tests/` | 手势状态及显式启用加载器的回归测试 |

纵向滚动和鼠标滚轮事件继续传递给应用。单窗口、悬浮窗口、全屏、锁屏和按住修饰键等场景也会将滚动传递给应用。横向触发阈值为累计 18 个输入单位，且横向运动需达到纵向的 1.5 倍。手指离开后结束当前序列，若缺少停止事件，400 ms 无输入也会重置状态。

在仓库根目录运行以下命令。

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only window-focus
python3 features/window-focus-gestures/configure.py --enable
python3 features/window-focus-gestures/configure.py --apply --enable
python3 features/window-focus-gestures/configure.py --apply --disable
```

启用时使用 C++26 编译动态库，创建 `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-macbook/two-finger-focus.enabled`，加载动态库并验证 Hyprland。关闭时移除标记并卸载动态库。

编译产物位于 `${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/two-finger-focus.so`。Hyprland 升级后，需要使用与当前运行版本匹配的头文件重新启用。

```bash
lua features/window-focus-gestures/tests/loader.lua
g++ -std=c++20 -Wall -Wextra features/window-focus-gestures/tests/gesture-state.cpp -o /tmp/test-window-focus
/tmp/test-window-focus
hyprctl plugin list
hyprctl configerrors
```

使用两个平铺窗口检查焦点轮换，再检查单窗口横向滚动和纵向滚动。工具会备份已有选择标记，失败时尝试恢复此前状态。

共享原生安装器也会备份已有动态库，生效失败时恢复其内容和权限。
