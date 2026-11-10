# Touchpad natural scrolling

[简体中文](README.zh-CN.md)

Enable `input.touchpad.natural_scroll` for macOS-style touchpad scrolling. This
feature is enabled in the recommended profile. Hyprland applies natural scrolling
to both axes. The setting is scoped to touchpads, with mouse configuration kept
under its own input settings.

`hyprland.lua` owns the setting. Install from the repository root:

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only touchpad-scrolling
hyprctl reload
hyprctl configerrors
hyprctl getoption input:touchpad:natural_scroll
lua features/touchpad-scrolling/tests/config.lua
```

The patch installer backs up `input.lua` and adds a loader for the module linked
at `~/.config/hypr/customizations/touchpad-scrolling.lua`. Check that the runtime
option reports `true`, then verify vertical and horizontal finger scrolling.
Workspace navigation and two-finger focus selection use their own modules.

Personal input settings loaded afterward and per-device overrides can select
another direction. An existing standalone natural-scroll block can be retained
as a personal override, or removed after backup when adopting this module as the
setting's source. Review the load order when maintaining both.

To recover, remove `require("hypr.customizations.touchpad-scrolling")` from
`input.lua`, restore the desired personal setting if needed, then reload
Hyprland and check configuration errors. The same setting can explicitly be set
to `false` in a later personal override.
