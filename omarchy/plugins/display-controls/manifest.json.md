# manifest.json

> **Optimized for Omarchy M (MacBook).** Part of a configuration and plugin
> collection that brings familiar macOS workflows and a desktop experience
> closer to native macOS.

`display-controls` provides brightness, text size, monitor toggles and scale
presets, derived from the Omarchy display panel.

`clonedFrom` points to `omarchy.monitor`, routing the built-in display entry and
shortcuts to this plugin. It retains the corresponding IPC name and uses a
portable semantic identifier. The upstream license is preserved in
[`LICENSES/Omarchy-MIT.txt`](../../../LICENSES/Omarchy-MIT.txt).

Scale presets are 1, 1.25, 1.6, 1.8, 1.9, 2 and 3. `Panel.qml` invokes the adjacent
`set-scale.sh` to apply exact values using upstream persistence logic. `Model.js`
manages presets and current-scale matching. Enable
`hypr.customizations.fractional-scaling` first to allow fractional logical pixels
and their rounding errors.
