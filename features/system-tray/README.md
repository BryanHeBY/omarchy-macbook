# System tray

[简体中文](README.zh-CN.md)

Manage tray icon visibility, pinning and activation. Left-clicking Clash launches
`/usr/bin/clash-verge`; right-clicking opens its tray menu. Pin an icon in the tray
management panel to keep it visible.

| File | Responsibility |
| --- | --- |
| `plugin/manifest.json` | Plugin identity, bar entry point and `clonedFrom` replacement |
| `plugin/Tray.qml` | Tray UI and application click actions |
| `plugin/TrayModel.js` | Item identification, visibility and pinning |

The plugin ID is `system-tray`, replacing `omarchy.tray`. The Clash shortcut
requires the application providing `/usr/bin/clash-verge`. Other entries use
their normal tray activation behavior.

Activate through the [recommended installer](../../docs/installation.md), or enable
`system-tray` after linking shell plugins and requesting discovery. Restart the
shell after symlinked plugin code changes. Check pinning, visibility and left- and
right-click actions. Enable `omarchy.tray` to restore the built-in tray.

Sources derive from Omarchy 4.5 and retain the
[upstream MIT notice](../../LICENSES/Omarchy-MIT.txt).
