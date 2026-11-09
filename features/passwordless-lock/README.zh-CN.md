# 免密解锁

[English](README.md)

点击或按任意键即可退出锁屏。启用后，能够直接操作机器的人均可进入当前会话。此功能需要在安装时显式选择。

| 文件 | 职责 |
| --- | --- |
| `plugin/manifest.json` | 插件 ID、入口及对 `omarchy.lock` 的替换关系 |
| `plugin/LockView.qml` | 锁屏界面与进入桌面的提示 |
| `plugin/Service.qml` | 锁屏生命周期、背景和退出锁屏处理 |
| `plugin/FingerprintModel.js` | 保留上游指纹状态与恢复逻辑 |
| `plugin/poster.sh` | 视频背景缩略图缓存 |
| `plugin/i18n/en.json` | 英文 `dismissHint` 翻译 |
| `plugin/i18n/zh-CN.json` | 简体中文 `dismissHint` 翻译 |

插件 ID 为 `passwordless-lock`，`clonedFrom` 指向 `omarchy.lock`。`LockView.qml` 通过 Omarchy 翻译组件读取扁平 JSON 翻译文件。背景缩略图工具需要 ffmpegthumbnailer 和 flock。

```bash
python3 install.py --apply --with-passwordless-lock
omarchy system lock
```

检查点击和按键是否都能退出锁屏。启用 `omarchy.lock` 并重启 Shell，可恢复内置锁屏行为。缩略图缓存使用用户缓存目录。

完整插件派生自 Omarchy 4.5，并保留 [上游 MIT 声明](../../LICENSES/Omarchy-MIT.txt)。
