# Touchpad scroll inertia

[简体中文](README.zh-CN.md)

An optional native Hyprland plugin adds decaying vertical movement after a
touchpad scroll ends. The default targets are Foot and Omarchy's keyboard-focused
menu layer. This covers Super+K's shortcut list, Super+Space and selection menus.
The recommended profile leaves the feature opt-in.

## Behavior and scope

- Physical finger events pass through to the application. A recent sequence of
  at least two vertical samples can start momentum on its vertical stop event.
- A pause longer than 80 ms before release discards the old velocity. Reversing
  direction replaces the velocity's direction, and a missing stop event leaves
  scrolling under direct finger control.
- Momentum decays on 16 ms frames and stops on another finger gesture, a
  recognized touchpad hold, pointer motion, a click, a key, a focus change,
  configuration reload, locking or a target change.
- Only `FINGER` events qualify. Horizontal-dominant sequences have no synthetic
  tail, and synthetic events bypass the horizontal window-focus gesture filter.
- Foot classes are `foot` and `org.codeberg.dnkl.foot`. Omarchy TUI wrappers with
  `org.omarchy.*` or `TUI.*` classes qualify when their initial title is `foot`.
- The `omarchy-menu` layer qualifies while it has keyboard focus and the pointer
  is over its surface. Other panels use their existing application behavior.
- The configured natural direction and Hyprland's touchpad, device and window
  scroll factors apply to momentum. Browser and VS Code classes use their own
  scrolling implementations under the default allowlist.

Foot's scrollback and foreground terminal programs interpret incoming scroll
events themselves. This can produce different line increments in a shell,
pager or TUI. Qt menus also retain their own widget rendering and bounds.
The implementation follows libinput's finger/stop model and the installed
Hyprland seat API. The separate natural direction feature has its own guide.
[libinput scrolling](https://wayland.freedesktop.org/libinput/doc/latest/scrolling),
[natural scrolling](../touchpad-scrolling/README.md).

## Files and requirements

| File | Responsibility |
| --- | --- |
| `hyprland.lua` | Marker-gated loading, Foot classes, menu namespaces and decay |
| `native/plugin.cpp` | Input, target validation, timer and synthetic seat events |
| `native/ScrollState.hpp` | Direction, velocity, release and decay state |
| `native/WindowPolicy.hpp` | Exact class and menu namespace matching |
| `build.sh` | Feature entry point for the shared native builder |
| `configure.py` | Feature entry point for shared activation and rollback |
| `tests/` | Momentum state, target policy and opt-in loader tests |

The current native API targets Hyprland 0.56.2. Build against headers matching
the running compositor, using a C++26-capable G++, pkg-config and libei's
`libeis-1.0` development metadata. Python 3.10 or newer runs the helper.

## Install and activate

Run as the desktop user from the repository root. The complete installer accepts
`python3 install.py --apply --with-touchpad-inertia`. For targeted installation:

```bash
omarchy pkg add gcc pkgconf libei
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only touchpad-inertia
python3 features/touchpad-inertia/configure.py --enable
python3 features/touchpad-inertia/configure.py --apply --enable
```

The helper compiles the library, saves existing marker/library files under
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/native-plugin-backups/`,
creates `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-macbook/touchpad-inertia.enabled`,
loads the plugin, reloads Hyprland and checks the result. Its library lives at
`${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/touchpad-inertia.so`.
Native installers share a lock, and failed activation restores prior files and
attempts to restore the loaded state. Building a library alone leaves activation
controlled by the marker. Re-enable after a Hyprland upgrade to rebuild it.

Later full installations that omit this optional feature retain its current
selection. Disable explicitly with the dedicated helper when desired.

```bash
python3 features/touchpad-inertia/configure.py --apply --disable
```

Adjust `classes`, `layers` or `decay_ms` in the feature's Lua module. Decay is
bounded to 40–600 ms, with 180 ms as the default exponential time constant.
Reload Hyprland after changes. Review a target's own kinetic behavior before
adding it to the allowlist.

## Verify and recover

```bash
lua features/touchpad-inertia/tests/loader.lua
g++ -std=c++20 -Wall -Wextra features/touchpad-inertia/tests/scroll-state.cpp -o /tmp/test-touchpad-inertia
/tmp/test-touchpad-inertia
python3 tests/installation/native_plugin.py
hyprctl plugin list
hyprctl configerrors
```

In Foot with long scrollback and in Super+K, flick vertically and lift. Check
deceleration, a pause before release, a new touch, focus changes and the edges of
the scrollable content. With two tiled windows, verify the existing horizontal
focus gesture still switches once. Check the browser and VS Code separately.

The disable helper unloads the plugin and removes the marker. Restore an earlier
runtime library/marker from the printed backup if needed, then reload and verify
Hyprland. Reconcile current settings before restoring complete user files.
