# MacBook 键盘与输入法切换

[English](README.md)

> **为 Omarchy M（MacBook）优化。** Caps Lock 和 Globe/Fn 的操作遵循熟悉的 macOS 输入法切换、大写输入和表情快捷键习惯。

## 按键行为

| 按键 | 行为 |
| --- | --- |
| 短按 Caps Lock | 在已配置的输入法之间切换 |
| 单独长按 Caps Lock 达到 350 ms | 切换到直接英文输入并启用大写锁定 |
| 大写锁定时按下 Caps Lock | 关闭大写锁定，继续使用英文输入 |
| 在 350 ms 内单独短按 Fn | 切换输入法，若已开启大写锁定则先关闭 |
| 长按 Fn 超过 350 ms | 松开时保持当前输入法 |
| Fn+E | 打开 Omarchy 可搜索的表情面板 |
| Control+Super+Space | 打开同一表情面板 |
| Fn+上／下方向键 | Page Up／Page Down |
| Fn+左／右方向键 | Home／End，具体行为由当前应用解释 |
| Fn+Backspace | 向前删除 |

输入法轮换使用 Omarchy 现有的输入源读取机制，与 `Super+I` 一致。配置英文和拼音后，短按会在两者之间切换。长按 Caps Lock 会发送真实的大写锁定事件，因此松开按键后仍可持续输入大写，键盘指示灯也跟随系统状态。再次按下 Caps Lock 退出大写锁定。

Fn 组合键会消耗单独按 Fn 的动作。亮度、多媒体键以及经驱动转换的功能键继续通过现有键盘驱动处理。

默认 Caps Lock/Fn 方案会从 Fcitx5 的主触发键和备用触发键列表中移除原来的单独左 Shift 切换。内部 Caps Lock 映射也接管此前的 Shift+Caps Lock Compose 组合。其他 Fcitx5 热键予以保留，输入状态指示器和表情界面由 Shell 提供。

## 选择输入法方案

推荐默认使用 Caps Lock/Fn。原来的左 Shift 主触发键保留为可选方案。

```bash
python3 features/keyboard-input/configure.py --profile shift
python3 features/keyboard-input/configure.py --apply --profile shift
python3 features/keyboard-input/configure.py --apply --profile caps-fn
```

Shift 方案会在 Fcitx5 主触发键列表中恢复 `Shift_L`，移除 MacBook 模块加载语句，并删除本项目的 keyd 映射。若存在其他 keyd 配置，则重新加载它们。若这是唯一的 keyd 配置，则停止服务并取消开机启用。Caps Lock/Fn 方案会重新安装对应映射并启用服务。切换方案时应先关闭大写锁定。

两种方案均保留针对默认模板的独立补丁。也可以通过完整安装流程选择相同方案，见 [推荐安装说明](../../docs/installation.zh-CN.md)。

## 组件与设备匹配

- `features/keyboard-input/keyd.conf` 定义 keyd 的时间阈值、层与按键映射。
- `features/keyboard-input/hyprland.lua` 将内部键码连接到用户会话中的输入法切换、直接输入和表情面板。
- `features/keyboard-input/configure.py` 预览、备份并安装两部分配置。
- `features/keyboard-input/patches/caps-fn.patch` 移除默认的单独 Shift 切换。
- `features/keyboard-input/patches/shift.patch` 保留原来的左 Shift 主触发键设置。

提供的 keyd 配置匹配 `05ac:0281:2bd1f3de`，这是经过测试的 Apple SPI Keyboard 能力与名称指纹，用于描述设备型号。Apple SPI Trackpad 与键盘共享厂商和产品 ID，因此需要使用完整的 keyd 标识。安装器会检查键盘指纹，并拒绝存在冲突 keyd 配置的安装。

对于其他键盘型号，可通过 `sudo keyd monitor` 检查完整 ID 和 Fn 事件，再调整设备选择器及安装器中的指纹检查。当前方案面向经过测试的 Apple SPI Keyboard。

keyd 使用 F13、F14 和 F15 发送内部信号。常见键盘布局会给这些按键分配多媒体键符，因此 Hyprland 针对 `keyd-virtual-keyboard` 绑定其 XKB 键码 191、192 和 193。系统配置是由 root 持有的副本，位于 `/etc/keyd/omarchy-macbook.conf`。修改仓库中的源配置后需要重新执行安装器。

## 安装与生效

在仓库根目录以桌面用户运行以下命令。需要 Python 3.10 或更新版本、keyd 2.6、Hyprland、Omarchy Shell 和已运行的 Fcitx5 会话。请先配置英文和所需中文输入法。

```bash
omarchy pkg add keyd
./installer/links.sh --apply --only hyprland
python3 features/keyboard-input/configure.py
python3 features/keyboard-input/configure.py --apply
```

安装器通过 `sudo` 写入系统配置并管理服务。用户快捷键、Fcitx5 设置和已有 keyd 映射备份到 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/keyboard-backups/`，并输出备份目录。

安装过程添加模块加载语句、从两个切换列表中移除左 Shift、重新加载 Hyprland 和 Fcitx5、复制 keyd 映射，并设置 `keyd.service` 开机启用。失败时会尝试恢复文件和服务状态。当配置一致且服务已运行、已开机启用时，重复执行会跳过安装。文件锁用于串行化安装器调用。

修改或重新加载 keyd 映射前，先关闭大写锁定。keyd 的大写层跟踪自身生成的原生锁定事件。若通过外部方式改变了锁定状态，应关闭大写锁定并重新加载 keyd，使内部层与系统状态一致。

默认补丁脚本也可以移除默认的 Shift 切换。独立键盘安装器同时处理默认 Fcitx5 设置和本仓库此前的左 Shift 主触发键配置，并保留其他偏好。

## 验证与调整

```bash
keyd check features/keyboard-input/keyd.conf
systemctl is-active keyd.service
hyprctl configerrors
sudo journalctl -u keyd.service -n 15 --no-pager
python3 features/keyboard-input/tests/configure.py
```

确认日志匹配 Apple SPI Keyboard，并忽略 Apple SPI Trackpad。在新编辑器或终端中短按 Caps Lock 和 Fn，检查语言切换。长按 Caps Lock 超过阈值后松开，再输入字母，检查持续大写与指示灯。再次按下 Caps Lock，应恢复小写英文。使用 Fn+E 搜索并插入表情，再检查 Fn+方向键和功能键。

修改 `features/keyboard-input/keyd.conf` 中的 `350` 可调整长按阈值和单独 Fn 的超时。关闭大写锁定后重新执行安装器。两个时间值可以分别调整。

## 恢复

停止 keyd 可立即释放键盘映射。keyd 的紧急退出组合键是 Backspace+Escape+Enter。

```bash
sudo systemctl stop keyd.service
```

移除此集成时，删除 `/etc/keyd/omarchy-macbook.conf`，从 `~/.config/hypr/bindings.lua` 移除 `require("hypr.customizations.macbook-keyboard")`，并按需从安装器输出的备份恢复 Fcitx5 偏好。恢复完整文件前应合并后来新增的个人设置，再重新加载 Hyprland 和 Fcitx5。

```bash
hyprctl reload
hyprctl configerrors
fcitx5-remote --check -r
```

若安装了其他 keyd 映射，应为对应设备重新加载或启动服务。若这是唯一的映射，可使用 `sudo systemctl disable keyd.service` 取消开机启用。

## 参考资料

- [Apple 输入源设置](https://support.apple.com/en-bw/guide/mac-help/mchl84525d76/mac)
- [Apple 键盘快捷键](https://support.apple.com/en-us/102650)
- [keyd 2.6 手册](https://github.com/rvaiya/keyd/blob/v2.6.0/docs/keyd.scdoc)
