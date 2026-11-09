# Workspace navigation

[简体中文](README.zh-CN.md)

Switch workspaces once per recognized three- or four-finger horizontal swipe.
Left moves to the next workspace and right to the previous workspace, including
empty workspaces. Slide transitions use the macWorkspaceEase curve at speed 3.2.

| File | Responsibility |
| --- | --- |
| `gestures.lua` | Discrete three-/four-finger workspace switching |
| `animations.lua` | Workspace transition curve and animation configuration |

Run from the repository root.

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only workspace
hyprctl reload
hyprctl configerrors
```

The deployment aliases are `workspace-gestures.lua` and `workspace-animation.lua`
under `~/.config/hypr/customizations/`. The installer loads them from `input.lua`
and `looknfeel.lua`. Check both swipe directions and an empty workspace. The
optional [window-focus gesture](../window-focus-gestures/README.md) has its own
loader and activation marker.
