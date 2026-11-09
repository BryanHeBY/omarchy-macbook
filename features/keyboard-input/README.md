# MacBook keyboard and input switching

[简体中文](README.zh-CN.md)

> **Optimized for Omarchy M (MacBook).** Caps Lock and Globe/Fn actions follow
> familiar macOS input switching, uppercase typing and emoji shortcuts.

## Behavior

| Key | Action |
| --- | --- |
| Tap Caps Lock | Switch between the configured input methods |
| Hold Caps Lock alone for 350 ms | Select direct English input and enable Caps Lock |
| Press Caps Lock while uppercase is active | Disable Caps Lock and continue in English |
| Tap Fn alone within 350 ms | Switch input methods, clearing uppercase first if active |
| Hold Fn beyond 350 ms | Release without switching input |
| Fn+E | Open Omarchy's searchable Emoji panel |
| Control+Super+Space | Open the same Emoji panel |
| Fn+Up / Down | Page Up / Page Down |
| Fn+Left / Right | Home / End, interpreted by the focused application |
| Fn+Backspace | Forward Delete |

The input source cycle uses Omarchy's existing input reader, as does `Super+I`.
With English and Pinyin configured, taps switch between those two. Holding Caps
Lock sends a real lock-key event, so uppercase survives release and the keyboard
indicator follows the system state. The next Caps Lock press exits uppercase.
Fn combinations consume the solitary Fn action. Brightness, media keys and
driver-translated function keys pass through the existing keyboard driver.

The default Caps Lock/Fn profile removes the previous solitary Left Shift toggle from Fcitx5's
primary and alternate trigger lists. The internal Caps Lock mapping also takes
over the former Shift+Caps Lock Compose gesture. Other Fcitx5 hotkeys are
preserved. The shell supplies the input indicator and Emoji interface.

## Select a profile

Caps Lock/Fn is the recommended default. The original primary Left Shift trigger
is retained as an alternative profile.

```bash
python3 features/keyboard-input/configure.py --profile shift
python3 features/keyboard-input/configure.py --apply --profile shift
python3 features/keyboard-input/configure.py --apply --profile caps-fn
```

The Shift profile restores `Shift_L` in Fcitx5's primary trigger list, removes the
MacBook module loader and removes this project's keyd mapping. When other keyd
configurations exist, they are reloaded. Otherwise, the service is stopped and
disabled. The Caps Lock/Fn profile reinstalls its mapping and service. Switch with
Caps Lock off. Standalone stock-template patches for both styles are retained.
See the [recommended installer](../../docs/installation.md) to select the same profiles as
part of the complete activation workflow.

## Components and device matching

- `features/keyboard-input/keyd.conf` contains keyd timing, layers and mappings.
- `features/keyboard-input/hyprland.lua` connects internal keycodes to user-session
  input switching, direct input and the Emoji panel.
- `features/keyboard-input/configure.py` previews, backs up and installs both sides.
- `features/keyboard-input/patches/caps-fn.patch` removes the stock solitary Shift toggle.
- `features/keyboard-input/patches/shift.patch` preserves the original primary Shift setup.

The supplied keyd configuration matches `05ac:0281:2bd1f3de`, the tested Apple
SPI Keyboard capabilities/name fingerprint. This fingerprint describes a device
model rather than an individual machine. Apple SPI Trackpad shares the vendor
and product ID, so the complete keyd identifier is required. The installer
checks the keyboard fingerprint and rejects competing keyd configurations.

For another keyboard model, inspect its complete ID and Fn events with
`sudo keyd monitor`, then adapt the selector and installer fingerprint check.
The current profile targets the tested Apple SPI Keyboard.

keyd emits F13, F14 and F15 as internal signals. Hyprland binds their XKB keycodes
191, 192 and 193 specifically on `keyd-virtual-keyboard`, since common layouts
give those keys media keysyms. The system configuration is a root-owned copy at
`/etc/keyd/omarchy-macbook.conf`. Reapply the installer after changing its source.

## Install and activate

Run these commands as the desktop user from the repository root. Python 3.10 or
newer, keyd 2.6, Hyprland, Omarchy Shell and a running Fcitx5 session are required.
Configure English and the desired Chinese input method first.

```bash
omarchy pkg add keyd
./installer/links.sh --apply --only hyprland
python3 features/keyboard-input/configure.py
python3 features/keyboard-input/configure.py --apply
```

The installer invokes `sudo` for the system configuration and service. It saves
user bindings, Fcitx5 settings and any existing keyd mapping under
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-macbook/keyboard-backups/`, then
prints the backup directory. It adds the module loader, removes Left Shift from
the two switching lists, reloads Hyprland and Fcitx5, copies the keyd mapping and
enables `keyd.service` at boot. A failed installation attempts to restore the
files and service state. Matching configurations with an active, enabled service
are skipped on repeat runs. A file lock serializes installer invocations.

Turn Caps Lock off before changing or reloading keyd mappings. keyd's uppercase
layer tracks the native lock events it generates. After an external lock-state
change, disable Caps Lock and reload keyd to align the layer and system state.

The default patch script can also remove the stock Shift toggle. The standalone
keyboard installer handles both stock Fcitx5 settings and the repository's
previous primary Shift binding while retaining other preferences.

## Verify and tune

```bash
keyd check features/keyboard-input/keyd.conf
systemctl is-active keyd.service
hyprctl configerrors
sudo journalctl -u keyd.service -n 15 --no-pager
python3 features/keyboard-input/tests/configure.py
```

Confirm that the log matches Apple SPI Keyboard and ignores Apple SPI Trackpad.
In a new editor or terminal, tap Caps Lock and Fn to switch languages. Hold Caps
Lock beyond the threshold, release it, and type a letter to check continuous
uppercase and the indicator. Press it again to return to lowercase English.
Use Fn+E to search and insert an emoji, then check Fn+arrow and function keys.

Adjust `350` in `features/keyboard-input/keyd.conf` to tune the hold threshold
and solitary Fn timeout, then reapply the installer with Caps Lock off. The two
values can be adjusted independently.

## Recovery

To release the keyboard mapping immediately, stop keyd. Its emergency key
sequence is Backspace+Escape+Enter.

```bash
sudo systemctl stop keyd.service
```

To remove this integration, delete `/etc/keyd/omarchy-macbook.conf`, remove the
`require("hypr.customizations.macbook-keyboard")` line from
`~/.config/hypr/bindings.lua`, and restore Fcitx5 preferences from the printed
backup as needed. Reconcile newer user preferences before restoring complete
files. Reload Hyprland and Fcitx5 afterward.

```bash
hyprctl reload
hyprctl configerrors
fcitx5-remote --check -r
```

If other keyd mappings are installed, reload or start the service for those
devices. If this was the only mapping, use `sudo systemctl disable keyd.service`
to remove its boot activation.

## References

- [Apple input source settings](https://support.apple.com/en-bw/guide/mac-help/mchl84525d76/mac)
- [Apple keyboard shortcuts](https://support.apple.com/en-us/102650)
- [keyd 2.6 manual](https://github.com/rvaiya/keyd/blob/v2.6.0/docs/keyd.scdoc)
