# Omarchy MacBook

[简体中文](README.zh-CN.md)

**Configurations and plugins optimized for Omarchy M (MacBook), bringing familiar
macOS workflows and a desktop experience closer to native macOS.**

Select desktop features independently, or apply the recommended profile. Features
include workspace gestures, application-aware shortcuts, input switching, Chinese
fonts and Omarchy Shell extensions.

## Quick start

Run as your desktop user inside an existing Omarchy session:

```bash
python3 install.py
python3 install.py --apply
```

The first command previews the complete plan. The second installs dependencies,
backs up configuration, installs links and patches, activates the selected input
profile and plugins, refreshes fonts, and validates Hyprland and Shell activation.

Defaults come from [profiles/recommended.json](profiles/recommended.json). They
enable workspace navigation, tab and desktop editing shortcuts, Chinese fonts,
Caps Lock/Fn input switching, menu memory and the system tray. MacBook screenshot
keys, two-finger focus switching, exact fractional display controls, passwordless
locking and VS Code inertia are opt-in.

```bash
# Choose the original primary Left Shift input switching profile.
python3 install.py --apply --input-method shift

# Select optional features, combining flags as needed.
python3 install.py --apply --with-two-finger-focus
python3 install.py --apply --with-display-controls
python3 install.py --apply --with-passwordless-lock
python3 install.py --apply --with-vscode-inertia
python3 install.py --apply --with-macos-screenshots
```

A full run applies the selected input and two-finger states. Other existing user
selections are preserved. Each stage keeps its own backups and stops subsequent
stages on failure. See the [installation guide](docs/installation.md) for recovery
and independent component commands.

## Features

| Feature | Behavior | Guide |
| --- | --- | --- |
| Workspace navigation | Discrete three-/four-finger switching, empty workspaces and eased slide animations | [Workspace navigation](features/workspace-navigation/README.md) |
| Tab shortcuts | Super+W closes tabs/documents; Super+T creates tabs/documents according to the app | [Tab shortcuts](features/tab-shortcuts/README.md) |
| Desktop shortcuts | Undo, redo, save, find, open, print, browser navigation and contextual Super+Backspace | [Desktop shortcuts](features/desktop-shortcuts/README.md) |
| Screenshot shortcuts | Optional Super+Shift+3/4/5 and clipboard variants alongside Omarchy capture keys | [Screenshot shortcuts](features/screenshot-shortcuts/README.md) |
| Keyboard input | Caps Lock tap/hold, Fn input switching and Fn+E emojis; optional Left Shift profile | [Keyboard input](features/keyboard-input/README.md) |
| Chinese fonts | Sarasa UI/Mono SC with Noto CJK fallbacks | [Chinese fonts](features/chinese-fonts/README.md) |
| Menu selection memory | Promote the latest selection for each menu/query | [Menu selection memory](features/menu-selection-memory/README.md) |
| System tray | Pinning, visibility and click actions, including Clash activation | [System tray](features/system-tray/README.md) |
| Window focus gestures | Optional two-finger horizontal focus cycling among tiled windows | [Window focus gestures](features/window-focus-gestures/README.md) |
| Display controls | Exact scale presets of 1×, 1.25×, 1.6×, 1.8×, 1.9×, 2× and 3× | [Display controls](features/display-controls/README.md) |
| Passwordless lock | Dismiss the lock screen with a click or any key | [Passwordless lock](features/passwordless-lock/README.md) |
| VS Code scrolling | Continued editor scrolling after finger release | [VS Code scrolling](features/vscode-scrolling/README.md) |

## Organization

```text
install.py                 Recommended installation and activation entry point
profiles/recommended.json  Recommended feature and input-profile selections
features/<capability>/     Configuration, helpers, implementation, tests and guide
installer/                 Shared link/patch deployment and integration patches
tests/installation/        Cross-feature installation and recovery tests
docs/                      Installation and architecture guides
docs/examples/             Reference configurations
LICENSES/                  Preserved upstream notices
```

Each feature owns its source, configuration and focused tests. Shell plugin
payloads live together under `plugin/`, and native plugin code uses `native/`.
The installer maps sources to individual Lua links and complete shell-plugin
links. Runtime data belongs in user XDG directories. Read the
[architecture guide](docs/architecture.md) for directory boundaries and file roles.

## Requirements

- Omarchy 4.5 Lua configuration and Shell plugin interfaces with a running
  Hyprland, Quickshell and Fcitx5 session.
- Python 3.10 or newer, Bash, GNU patch/coreutils/awk, jq, util-linux and Fontconfig.
- The default keyboard profile targets the tested Apple SPI Keyboard fingerprint
  and uses keyd 2.6. The Shift profile supports the Fcitx5 primary Shift trigger.
- Chinese fonts use `ttf-sarasa-gothic` and `noto-fonts-cjk`.
- Optional focus gestures target Hyprland 0.56.2 and require matching development
  headers, pkg-config and a C++26-capable G++.
- VS Code inertia requires Node.js 18 or newer and a version of VS Code supporting
  `editor.inertialScroll`.
- The Clash tray shortcut uses `/usr/bin/clash-verge`. Video lock backgrounds use
  `ffmpegthumbnailer` and `flock`.

The installer adds selected feature packages through `omarchy pkg add`. Follow
individual feature guides for version requirements and activation details.

## Verification

Run from the repository root.

```bash
node tests/installation/configuration.cjs
python3 tests/installation/recommended.py
python3 features/keyboard-input/tests/configure.py
node features/display-controls/tests/scaling.cjs
node features/vscode-scrolling/tests/configure.cjs
lua features/tab-shortcuts/tests/shortcuts.lua
lua features/desktop-shortcuts/tests/shortcuts.lua
lua features/screenshot-shortcuts/tests/shortcuts.lua
lua features/window-focus-gestures/tests/loader.lua
g++ -std=c++20 -Wall -Wextra features/window-focus-gestures/tests/gesture-state.cpp -o /tmp/test-window-focus
/tmp/test-window-focus
```

Installation tests use temporary home/state directories and installed Omarchy
configuration templates. Feature tests exercise isolated settings, mocked display
commands, keyboard profiles, shortcut forwarding and gesture state. Each feature
README includes desktop verification steps.

## Local data and recovery

The installer prints backup locations under
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/`. Link backups retain user
paths, including replaced files and links. The keyboard and gesture helpers keep
component backups and attempt recovery on failure.

User configuration, credentials, search history, logs, caches and native binaries
stay in user directories. Menu history uses
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy/menu-history.json`. Display logs may
contain monitor names, paths and process arguments. Inspect diagnostic material
before sharing it. Follow the [installation guide](docs/installation.md) and
feature guides when restoring configuration.

## License and upstream

The collection uses the [MIT license](LICENSE). Shell extensions derive from
Omarchy 4.5 and preserve upstream authors and replacement metadata. The
[upstream MIT notice](LICENSES/Omarchy-MIT.txt) is retained.
See [Omarchy](https://github.com/omacom/omarchy) and its
[license](https://github.com/omacom/omarchy/blob/quattro/LICENSE).
