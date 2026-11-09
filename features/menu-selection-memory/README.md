# Menu selection memory

[简体中文](README.zh-CN.md)

Promote the latest selected result for each menu and normalized search query.
Queries normalize case and whitespace; up to 256 menu/query selections are kept.

| File | Responsibility |
| --- | --- |
| `plugin/manifest.json` | Plugin ID, capabilities, entry points and `clonedFrom` metadata |
| `plugin/BarWidget.qml` | Menu bar button using the existing menu route |
| `plugin/Menu.qml` | Menu UI and selection recording |
| `plugin/MenuHistory.js` | Local history parsing, bounds and ranking |
| `plugin/MenuModel.js` | Upstream menu parsing, matching and rows |

The plugin ID is `menu-selection-memory`, replacing `omarchy.menu`. Activate it
through the [recommended installer](../../docs/installation.md), or enable this
ID after linking shell plugins and requesting discovery. Restart the shell after
symlinked plugin code changes.

Search with Super+Space, select a result, then repeat the query to check ranking.
History lives at
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/menu-history.json`. Enable
`omarchy.menu` to restore the built-in menu. Plugin sources derive from Omarchy
4.5 and retain the [upstream MIT notice](../../LICENSES/Omarchy-MIT.txt).
