# Display controls

An Omarchy display panel with scale presets of 1, 1.25, 1.6, 1.8, 1.9, 2 and 3.
Brightness, text size and monitor management follow the upstream panel.

| File | Responsibility |
| --- | --- |
| `hyprland.lua` | Enable exact fractional scales with `debug.disable_scale_checks` |
| `plugin/Panel.qml` | Display panel UI and preset buttons |
| `plugin/Model.js` | Preset matching and scale calculations |
| `plugin/set-scale.sh` | Per-monitor persistence, GTK scale and local audit log |
| `plugin/manifest.json` | Plugin identity, capabilities, entry point and upstream replacement |
| `tests/scaling.cjs` | Exact scale persistence and failure guards |

The manifest ID is `display-controls` and `clonedFrom` is `omarchy.monitor`.
The plugin retains the upstream display IPC route. Exact fractional logical
pixels can introduce alignment or rounding errors throughout the Hyprland
session. Select this optional feature with the following command.

```bash
python3 install.py --apply --with-display-controls
```

For component-only installation, link the Hyprland and shell groups, apply
`installer/patches.sh --apply --only display`, reload Hyprland and enable
`display-controls` after plugin discovery. See the
[installation guide](../../docs/installation.md).

```bash
bash features/display-controls/plugin/set-scale.sh 1.8
hyprctl monitors -j
omarchy shell omarchy.monitor state
node features/display-controls/tests/scaling.cjs
```

To restore scale checks, select a scale compatible with the monitor resolution,
remove the fractional-scaling loader from `monitors.lua` and reload Hyprland.
Enable `omarchy.monitor` to restore the built-in panel. Changes are logged under
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/monitor-scaling.log`, including
monitor and process information. Review local logs before sharing them.

Plugin sources derive from Omarchy 4.5. The upstream author metadata and
[MIT notice](../../LICENSES/Omarchy-MIT.txt) are retained.
