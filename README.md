# Omarchy MacBook

[简体中文](README.zh-CN.md)

**A collection of configurations and plugins optimized for Omarchy M (MacBook),
bringing familiar macOS workflows and a desktop experience closer to native macOS.**

Modular desktop customizations for Omarchy: workspace gestures, animations,
application-aware tab shortcuts, Chinese fonts, input-method hotkeys and shell
plugins. Symlinks and scoped patches let you select each component independently.

## Features

| Component | Behavior | Source |
| --- | --- | --- |
| Workspace gestures | One switch per three- or four-finger horizontal swipe, including empty workspaces | `features/workspace-navigation/gestures.lua` |
| Window focus gestures | Opt-in two-finger horizontal focus cycling among tiled windows | `hyprland/plugins/two-finger-focus/` |
| Workspace animations | Ease-out curve with slide transitions | `features/workspace-navigation/animations.lua` |
| Tab shortcuts | `Super+W` closes a tab or document; `Super+T` creates one | `features/tab-shortcuts/hyprland.lua` |
| MacBook keyboard | Default Caps Lock/Fn profile with an alternative primary Left Shift profile | `input-method/` |
| Chinese fonts | Sarasa UI SC, Sarasa Mono SC and Noto CJK fallbacks | `features/chinese-fonts/fontconfig.conf` |
| Display controls | Scale presets of 1×, 1.25×, 1.6×, 1.8×, 1.9×, 2× and 3× | `omarchy/plugins/display-controls/` |
| System tray | Pinning, visibility and activation, including Clash launch support | `omarchy/plugins/system-tray/` |
| Menu selection memory | Promote the latest choice for each menu and search query | `omarchy/plugins/menu-selection-memory/` |
| VS Code inertia | Standalone helper for continued editor scrolling after finger release | `features/vscode-scrolling/configure.cjs` |
| Passwordless lock | Enter the desktop with a click or any key | `omarchy/plugins/passwordless-lock/` |

Swipe left to enter the next workspace and right to enter the previous workspace.

### Two-finger window focus

This feature is disabled by default and requires explicit opt-in. Compiling the
library alone does not enable it.

When a workspace has at least two visible, focusable tiled windows and the pointer
is over tiled window content, a two-finger horizontal swipe cycles focus. Windows
are ordered left to right, then top to bottom within a column. Each gesture
switches at most once; lifting your fingers permits another switch.

Scrolling is passed to applications with a single window, a floating window,
fullscreen mode, a locked session or held modifiers. Vertical scrolling and mouse
wheel events are also passed through. Three- and four-finger gestures continue to
switch workspaces.

This optional native Hyprland plugin handles touchpad horizontal scrolling. Its
threshold is 18 accumulated input units, with horizontal movement at least 1.5
times the vertical movement. Thresholds live in
`features/window-focus-gestures/native/GestureState.hpp`. A sequence normally ends on
finger release; 400 ms without a scroll event also resets it to recover from a
missing stop event.

### Application-aware tab shortcuts

| Application | `Super+W` forwards | `Super+T` forwards | Behavior |
| --- | --- | --- | --- |
| Chromium and Firefox browsers | `Ctrl+W` | `Ctrl+T` | Close or create a browser tab |
| Nautilus, Dolphin, Thunar, Nemo, Obsidian | `Ctrl+W` | `Ctrl+T` | Close or create a tab |
| VS Code / Insiders, Code OSS, VSCodium, Cursor, Windsurf | `Ctrl+W` | `Ctrl+N` | Close the current editor or create a blank document |
| Kate, KWrite, Gedit, Sublime Text | `Ctrl+W` | `Ctrl+N` | Close or create a document |
| Konsole, GNOME Terminal, Xfce Terminal, WezTerm, Ghostty | `Ctrl+Shift+W` | `Ctrl+Shift+T` | Close the current terminal tab or session; create a tab |
| Kitty | `Ctrl+Shift+Q` | `Ctrl+Shift+T` | Close or create a tab |

In editors, `Super+T` follows the blank-document convention. Save prompts, the
last tab and embedded-terminal focus follow each application's native shortcut
behavior. The mappings follow application documentation:
[VS Code](https://code.visualstudio.com/docs/reference/default-keybindings),
[Konsole](https://docs.kde.org/stable_kf6/en/konsole/konsole/commandreference.html),
[Kitty](https://sw.kovidgoyal.net/kitty/invocation/),
[WezTerm](https://wezterm.org/config/default-keys.html).

Applications are identified by exact window classes or Omarchy browser tags.
Extend the groups in `features/tab-shortcuts/hyprland.lua`. For other applications,
`Super+W` closes the window and `Super+T` performs no action. Foot and Alacritty
use this fallback.

## Requirements

- Omarchy 4.5 Lua configuration and shell plugin interfaces.
- Hyprland, Quickshell and Omarchy's `qs.Commons` and `qs.Ui` components.
- The two-finger focus plugin targets Hyprland 0.56.2 and requires development
  headers matching the running version, a C++26-capable G++ and pkg-config.
- Bash, GNU patch, GNU coreutils, GNU awk, jq, util-linux (`flock`) and Fontconfig.
- The VS Code scrolling helper requires Node.js 18 or newer and a VS Code version
  supporting `editor.inertialScroll`.
- Regression tests use Lua, Node.js and G++.
- Fcitx5 for input switching, plus keyd 2.6 and Python 3.10 or newer for the optional MacBook keyboard integration.
- `ttf-sarasa-gothic` and `noto-fonts-cjk` for Chinese fonts.
- An application package providing `/usr/bin/clash-verge` for the Clash shortcut.
- `ffmpegthumbnailer` and `flock` for lock-screen video background posters.

Patches were generated against Omarchy 4.5 defaults. On a context conflict, the
apply script stops and identifies the affected file.

## Layout

```text
install.py                 Recommended installation entry point
features/                  Configuration, code and tests grouped by capability
installer/                 Shared symlink and patch integration
installer/symlinks.tsv     Deployment groups, source paths and user targets
tests/installation/        Cross-feature installation regression tests
docs/                      Installation and architecture guides
docs/examples/             Integration examples
LICENSES/                  Upstream license notices
```

Plugin filenames follow Omarchy loader conventions. Strict JSON files have
companion `.md` documentation; other sources use comments in their native format.

## Installation

Run these commands from the repository root. The repository can live anywhere:
scripts resolve sources relative to themselves and user configuration under
`$HOME`. The standalone VS Code helper also respects `$XDG_CONFIG_HOME`.

### Recommended installation

```bash
# Preview the complete installation and activation plan.
python3 install.py
python3 install.py --apply

# Select the original primary Left Shift profile.
python3 install.py --apply --input-method shift

# Explicitly opt into two-finger focus switching.
python3 install.py --apply --with-two-finger-focus
```

The recommended defaults activate three-/four-finger workspace gestures,
animations, tab shortcuts, Chinese fonts, menu memory, the system tray and
Caps Lock/Fn input switching. Two-finger focus switching is disabled by default.
Display controls, passwordless locking and VS Code inertia have individual opt-in
flags. The installer installs dependencies, enables selected services/plugins,
refreshes fonts, reloads Hyprland and checks the shell response. See the
[installation guide](docs/installation.md) for the complete selection and recovery
behavior.

The component commands below are available for individual configuration steps.

### Install symlinks

The first column in `installer/symlinks.tsv` is relative to the repository root; the
second is relative to `$HOME`. You can install selected groups independently.

```bash
# Preview by default, then write the links.
./installer/links.sh
./installer/links.sh --apply

# Select one configuration group.
./installer/links.sh --dry-run --only hyprland
./installer/links.sh --apply --only fonts
./installer/links.sh --apply --only shell
```

The installer preflights selected entries and moves replaced files, directories
or symlinks into a separate backup directory under the user state directory. On
failure it attempts to restore entries touched by the current invocation.
Repeated runs skip links already pointing to this repository. `flock` serializes
installers to avoid concurrent replacements.

After linking, select modules and plugins using the steps below. Exact fractional
scaling and passwordless locking require separate activation.

| Repository content | Loaded from |
| --- | --- |
| `features/*/*.lua` | `~/.config/hypr/customizations/*.lua` |
| `features/chinese-fonts/fontconfig.conf` | `~/.config/fontconfig/conf.d/50-omarchy-input-method.conf` |
| `omarchy/plugins/menu-selection-memory/` | `~/.config/omarchy/plugins/menu-selection-memory` |
| `omarchy/plugins/system-tray/` | `~/.config/omarchy/plugins/system-tray` |
| `omarchy/plugins/passwordless-lock/` | `~/.config/omarchy/plugins/passwordless-lock` |
| `omarchy/plugins/display-controls/` | `~/.config/omarchy/plugins/display-controls` |

### Apply module-loader and input-method patches

```bash
# Read-only preview by default.
./installer/patches.sh

# Back up targets and apply the default patch set.
./installer/patches.sh --apply

# Check or apply an individual section.
./installer/patches.sh --dry-run --only hyprland
./installer/patches.sh --apply --only hyprland
./installer/patches.sh --apply --only fcitx5
```

Hyprland patches load modules from `input.lua`, `bindings.lua` and `looknfeel.lua`.
The script recognizes existing `require(...)` calls, supports repeated runs and
allows partial integration. The input-method patch removes the stock solitary
Left Shift toggle so input switching can be managed by the desktop keyboard module.

All selected patches are checked before writing, including verification that the
Lua module link points to this repository. Targets are backed up under
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/patch-backups/`. A failed
application attempts to restore files touched by that invocation.

### Enable shell plugins

After installing plugin links, activate the desired replacements through
Omarchy's cloned-plugin mechanism.

```bash
omarchy shell shell rescanPlugins
# Discovery is asynchronous. Confirm the plugins appear before enabling them.
omarchy plugin list --json

omarchy plugin enable menu-selection-memory
omarchy plugin enable system-tray
# Display controls also need the display patch described below.
omarchy restart shell
```

Manifest `clonedFrom` values identify built-in menu, tray, display and lock entry
points, allowing existing routes and shortcuts to resolve to the selected clone.
`docs/examples/shell-integration.json` provides a field-level reference. Omarchy's CLI
writes the actual plugin state into the user's shell configuration.

`system-tray` provides general tray management. Left-clicking Clash runs
`/usr/bin/clash-verge`; right-clicking opens its tray menu. Pin icons in the tray
management panel to keep them visible.

Passwordless locking is enabled separately. A click or any key unlocks the
session, allowing anyone with physical access to enter it.

```bash
omarchy plugin enable passwordless-lock
omarchy restart shell
```

## Activation and verification

### Gestures, animations and tab shortcuts

Two-finger focus switching requires an explicit enable marker in addition to the
compiled library. The dedicated helper builds the plugin, saves the selection,
loads it and validates Hyprland. The default profile leaves the gesture disabled.

```bash
python3 features/window-focus-gestures/configure.py --apply --enable
hyprctl plugin list
hyprctl configerrors
# Return to normal application horizontal scrolling.
python3 features/window-focus-gestures/configure.py --apply --disable
```

The library is installed at
`${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/two-finger-focus.so`.
Rebuild against matching headers after Hyprland upgrades. The plugin checks the
version and ABI on load. After rebuilding changed sources, unload and explicitly
load the library before reloading configuration.

```bash
hyprctl plugin unload "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/two-finger-focus.so"
hyprctl plugin load "${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins/two-finger-focus.so"
hyprctl reload
hyprctl configerrors
```

Check three- and four-finger horizontal swipes, empty workspaces, and `Super+W`
and `Super+T` in supported applications. Test shortcut groups and gesture state:

```bash
lua features/tab-shortcuts/tests/shortcuts.lua
g++ -std=c++20 -Wall -Wextra features/window-focus-gestures/tests/gesture-state.cpp -o /tmp/test-two-finger-focus
/tmp/test-two-finger-focus
```

Open two tiled windows on the same workspace to check two-finger focus switching,
then close one to check application horizontal scrolling. Vertical scrolling
should continue to reach applications with multiple windows.

### Display controls and exact fractional scaling

`display-controls` replaces the built-in panel with presets of 1×, 1.25×, 1.6×,
1.8×, 1.9×, 2× and 3×. Brightness, text size and monitor management follow upstream
behavior. Both the panel and its helper preserve requested fractional scales.

Enable `features/display-controls/hyprland.lua` separately. It sets
`debug.disable_scale_checks = true`, allowing fractional logical dimensions and
possible pixel alignment or rounding errors. This option affects the entire
Hyprland session. The `display` patch is separate from the default patch set.
See the [Hyprland configuration options](https://wiki.hypr.land/configuring/core/config-options/).

```bash
# Install the customizations and display-controls links from the manifest first.
./installer/patches.sh --dry-run --only display
./installer/patches.sh --apply --only display
hyprctl reload
hyprctl configerrors
omarchy shell shell rescanPlugins
# Discovery is asynchronous. Confirm the plugin appears before enabling it.
omarchy plugin list --json
omarchy plugin enable display-controls
omarchy restart shell
```

Open the display panel in the status bar and select a scale. The helper retains
upstream per-monitor persistence in `~/.config/hypr/monitors.lua`, GTK integer
scaling and change logging. The adjacent `set-scale.sh` also accepts command-line
requests. Sources are regular repository files linked through the user plugin
directory.

```bash
bash features/display-controls/plugin/set-scale.sh 1.8
hyprctl monitors -j
omarchy shell omarchy.monitor state
node features/display-controls/tests/scaling.cjs
```

To restore integer-pixel checks, first select a scale compatible with the monitor
resolution, remove the `hypr.customizations.fractional-scaling` loader from
`monitors.lua`, and reload Hyprland. Restore the built-in display panel with
`omarchy plugin enable omarchy.monitor`.

### MacBook keyboard and input switching

The optional keyboard integration adds Caps Lock tap/hold and Globe/Fn actions.
Tap Caps Lock or Fn to cycle input sources. Hold Caps Lock alone for 350 ms to
enter direct English input with uppercase locked, then press it again to return
to lowercase. Fn+E and Control+Super+Space open the Emoji panel. Fn combinations
consume the solitary tap action.

```bash
omarchy pkg add keyd
python3 features/keyboard-input/configure.py
python3 features/keyboard-input/configure.py --apply
# Restore the original Left Shift profile.
python3 features/keyboard-input/configure.py --apply --profile shift
```

Install the Hyprland symlink first and run the installer as the desktop user.
The default profile backs up existing bindings and input settings, adds the
keyboard module and installs a root-owned keyd configuration. The alternative
`shift` profile restores the primary Left Shift trigger and removes the Caps/Fn
mapping. Both profiles preserve unrelated hotkeys.
The profile matches the tested Apple SPI Keyboard fingerprint and excludes the
trackpad that shares its vendor/product ID. The installer enables keyd at boot.
See the [keyboard guide](features/keyboard-input/README.md) for supported hardware,
thresholds, verification and recovery.

```bash
systemctl --user restart omarchy-fcitx5.service
systemctl --user is-active omarchy-fcitx5.service
```

In a newly opened application, tap Caps Lock or Fn to verify input switching,
then check hold-to-uppercase and Fn+E. The existing Super+I shortcut also cycles
input sources.

### Chinese fonts

```bash
fc-cache -f
fc-match 'sans-serif:charset=4e2d'
fc-match 'monospace:charset=4e2d'
fc-match 'serif:charset=4e2d'
```

These queries check fallback for U+4E2D, a Chinese character. Expected matches are
Sarasa UI SC, Sarasa Mono SC and Noto Serif CJK SC respectively. Reopen applications
if they need to refresh font selection.

### VS Code editor inertia

`editor.inertialScroll` continues motion after finger release.
`editor.smoothScrolling` controls animated transitions independently. The
standalone helper changes only the inertia setting and previews by default.

```bash
node features/vscode-scrolling/configure.cjs
node features/vscode-scrolling/configure.cjs --apply
# Set inertia back to false.
node features/vscode-scrolling/configure.cjs --apply --disable
# Select another edition or named profile explicitly.
node features/vscode-scrolling/configure.cjs --settings /path/to/settings.json --apply
```

The default target is
`${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json`. The script preserves
JSONC comments and unrelated settings, backs up the original under
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/vscode-scroll-backups/`,
and prints its path. Repeated runs skip already matching values. Close the
settings editor before applying. This helper runs independently of installation
and patch application.

Test in a long text file by scrolling vertically and lifting your fingers. If the
effect is missing, check the active profile, workspace and language overrides;
use **Developer: Reload Window** if needed. Other surfaces, including terminals,
sidebars and webviews, may use different scroll implementations. See the
[complete guide](features/vscode-scrolling/README.md) for details and backup recovery.

### Shell plugins

```bash
omarchy plugin validate "$PWD/omarchy/plugins/display-controls"
omarchy plugin validate "$PWD/omarchy/plugins/system-tray"
omarchy plugin validate "$PWD/omarchy/plugins/menu-selection-memory"
omarchy plugin validate "$PWD/omarchy/plugins/passwordless-lock"
omarchy restart shell
```

- Check tray pinning, visibility and click actions.
- Search with `Super+Space`, select a result, then repeat the query and confirm
  that the previous selection appears first.
- With passwordless locking enabled, use `omarchy system lock` to check click or
  key dismissal.

Restart the shell once after a batch of plugin edits. An explicit restart ensures
complete reloading when plugin subdirectories are symlinked.

## Installation recovery

The symlink installer prints its backup directory, retaining paths relative to
`$HOME`. To restore an original entry, confirm its backup exists, remove the
current link to this repository, and move the backup to its original destination.
New links can simply be removed. Keep repository sources to reinstall later.

Patch backups also retain paths relative to `$HOME`. Restore the relevant
`input.lua`, `bindings.lua`, `looknfeel.lua`, `monitors.lua` or Fcitx5 configuration
from the printed backup directory. After restoring Hyprland files, run
`hyprctl reload` and `hyprctl configerrors`. Restart Fcitx5 after restoring its
configuration. The VS Code helper has its own recovery instructions in the
[scrolling guide](features/vscode-scrolling/README.md).

Restore shell plugins using their built-in identifiers. Before restoring the
display panel, select a compatible scale and remove the exact fractional-scaling
module as described in the display section.

```bash
omarchy plugin enable omarchy.menu
omarchy plugin enable omarchy.tray
omarchy plugin enable omarchy.monitor
omarchy plugin enable omarchy.lock
omarchy restart shell
```

## Regression tests

```bash
python3 tests/installation/recommended.py
python3 features/keyboard-input/tests/configure.py
lua features/window-focus-gestures/tests/loader.lua
node features/vscode-scrolling/tests/configure.cjs
node tests/installation/configuration.cjs
node features/display-controls/tests/scaling.cjs
lua features/tab-shortcuts/tests/shortcuts.lua
g++ -std=c++20 -Wall -Wextra features/window-focus-gestures/tests/gesture-state.cpp -o /tmp/test-two-finger-focus
/tmp/test-two-finger-focus
```

Installer tests use temporary home and state directories; patch tests read
installed Omarchy default templates. Display tests mock Hyprland commands to
check scale preservation, persistence and failure handling. VS Code tests use
isolated JSONC fixtures to check preview, preservation, backups and disable mode.

## Local data and maintenance

Menu history normalizes query case and whitespace and retains the latest choice
for each menu/query pair, up to 256 entries. It lives at
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/menu-history.json`.

Display scaling retains Omarchy's local change log at
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/monitor-scaling.log`, including
monitor names, process arguments and parent process information. The lock plugin
retains upstream background and fingerprint state handling, with caches in the
user cache directory. Inspect paths and process information before sharing logs.

Runtime settings, search history, logs, credentials, caches, backups and compiled
libraries belong in user configuration, state, cache or data directories. This
repository manages module sources, generic integration files and tests.

Maintain font rules, Lua modules and plugin sources here. Compare dependent
Omarchy APIs and upstream implementations when updating plugins. Documentation
and source comments are in English; keep the linked Chinese README in sync when
changing installation or activation steps. The lock plugin retains its Chinese
UI translation catalog.

## License and upstream

This repository uses the MIT license in [LICENSE](LICENSE). Omarchy-derived
components retain upstream copyright and MIT licensing.

Shell plugins derive from Omarchy 4.5. Manifests retain upstream authors and
`clonedFrom` metadata. The upstream MIT text is preserved in
[LICENSES/Omarchy-MIT.txt](LICENSES/Omarchy-MIT.txt).
See [Omarchy](https://github.com/omacom/omarchy) and its
[upstream license](https://github.com/omacom/omarchy/blob/quattro/LICENSE).
