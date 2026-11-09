# Two-finger window focus gestures

This optional feature cycles focus among at least two visible, focusable tiled
windows on the same workspace when the pointer is over tiled window content.
Windows are ordered left to right, then top to bottom. Each swipe switches once.
The recommended profile disables the feature.

| File | Responsibility |
| --- | --- |
| `hyprland.lua` | Load the native plugin when its explicit opt-in marker exists |
| `native/plugin.cpp` | Hyprland input integration and focus selection |
| `native/GestureState.hpp` | Scroll classification and gesture state |
| `build.sh` | Compile against the installed matching Hyprland headers |
| `configure.py` | Persist selection, load/unload and validate configuration |
| `tests/` | Gesture state and opt-in loader regression coverage |

Vertical scrolling and mouse-wheel events reach applications. Single-window,
floating, fullscreen, locked-session and modified-key contexts also pass
scrolling through. The horizontal threshold is 18 accumulated input units with
1.5x directional dominance. Finger release ends a sequence; 400 ms of inactivity
also resets it when a stop event is missing.

Run from the repository root.

```bash
bash installer/links.sh --apply --only hyprland
bash installer/patches.sh --apply --only window-focus
python3 features/window-focus-gestures/configure.py --enable
python3 features/window-focus-gestures/configure.py --apply --enable
python3 features/window-focus-gestures/configure.py --apply --disable
```

Enabling builds the library with C++26, creates
`${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-macbook/two-finger-focus.enabled`,
loads the library and validates Hyprland. Disabling removes the marker and unloads
the library. The compiled library lives at
`${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/two-finger-focus.so`.
Re-enable after Hyprland upgrades using headers matching the running build.

```bash
lua features/window-focus-gestures/tests/loader.lua
g++ -std=c++20 -Wall -Wextra features/window-focus-gestures/tests/gesture-state.cpp -o /tmp/test-window-focus
/tmp/test-window-focus
hyprctl plugin list
hyprctl configerrors
```

Check focus cycling with two tiled windows, then single-window horizontal
scrolling and vertical scrolling. The helper backs up existing selection markers
and attempts to restore the previous selection on failure.
