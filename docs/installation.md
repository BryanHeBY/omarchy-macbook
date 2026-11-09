# Recommended installation and activation

The recommended profile brings familiar macOS workflows to Omarchy M on MacBook.
Run the installer as your desktop user from the repository root. The default
invocation prints its complete plan. `--apply` runs the plan with backups at the
individual configuration stages.

```bash
python3 scripts/install.py
python3 scripts/install.py --apply
```

## Recommended defaults

| Component | Fresh installation |
| --- | --- |
| Three- and four-finger workspace switching | Enabled |
| Workspace animations and application-aware tab shortcuts | Enabled |
| Chinese font fallback rules | Enabled |
| Caps Lock/Fn input switching and Fn+E Emoji shortcut | Enabled |
| Menu selection memory and system tray plugins | Enabled |
| Two-finger focus switching | Explicit opt-in |
| Exact fractional display controls | Explicit opt-in |
| Passwordless lock dismissal | Explicit opt-in |
| VS Code editor inertia | Explicit opt-in |

Two-finger horizontal movements reach applications under the default profile.
Enabling two-finger focus switching assigns horizontal gestures to focus cycling
when multiple tiled windows are eligible. Three- and four-finger workspace
gestures are independent of this selection.

## Input switching profiles

The default `caps-fn` profile provides Caps Lock tap/hold, Fn tapping and Fn+E.
The original primary Left Shift trigger remains available as the `shift` profile.
Choose one when installing, or use the keyboard installer to switch an existing
installation.

```bash
# Recommended profile, including activation.
python3 scripts/install.py --apply --input-method caps-fn

# Original Left Shift input switching.
python3 scripts/install.py --apply --input-method shift

# Switch only the keyboard/input profile.
python3 scripts/install-macbook-keyboard.py --apply --profile shift
python3 scripts/install-macbook-keyboard.py --apply --profile caps-fn
```

The Shift profile restores Left Shift as a primary Fcitx5 trigger, removes the
MacBook keyboard module loader and removes this project's keyd mapping. The
installer reloads other keyd mappings if present, or stops and disables the
service when this was its only configuration. Other hotkeys are retained.
Switch profiles with Caps Lock off.

The original stock-template patch is preserved in
`input-method/fcitx5-shift-hotkeys.patch` and can be applied with
`scripts/apply-patches.sh --apply --only fcitx5-shift`. For switching an installed
profile, the keyboard installer handles the existing configuration directly.
See the [keyboard guide](macbook-keyboard.md) for device support and recovery.

## Optional features

Pass the desired options together with `--apply`.

```bash
python3 scripts/install.py --apply --with-two-finger-focus
python3 scripts/install.py --apply --with-display-controls
python3 scripts/install.py --apply --with-passwordless-lock
python3 scripts/install.py --apply --with-vscode-inertia
```

The default installation selects Caps Lock/Fn and disables two-finger focus
switching. Pass the two-finger option on subsequent full installations when you
want that feature enabled. Independently select its state with the dedicated
helper.

```bash
python3 scripts/configure-two-finger-focus.py --enable
python3 scripts/configure-two-finger-focus.py --apply --enable
python3 scripts/configure-two-finger-focus.py --apply --disable
```

Enabling compiles the native plugin with matching Hyprland development headers,
creates `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-macbook/two-finger-focus.enabled`,
loads the library and validates Hyprland. Disabling removes the marker, unloads
the library and reloads configuration. A compiled library alone is insufficient
to activate the feature. The helper backs up an existing marker, serializes its
updates and attempts to restore the previous selection on failure.

Display controls enable `debug.disable_scale_checks`, allowing fractional logical
pixels with possible alignment errors. Passwordless locking permits a click or
any key to enter the session. Select these options according to your intended
desktop behavior. The VS Code option invokes its independent settings helper.
Existing optional shell plugin selections are preserved during subsequent
installations that select other components.

## Activation stages

The installer validates selected shell plugins, installs required packages,
creates the manifest's symlinks and applies the Hyprland module-loader patches.
It then configures the selected input profile and two-finger state, applies
selected optional settings, and rebuilds the font cache.

Shell plugin discovery is asynchronous. The installer requests a rescan and
waits for the selected plugin IDs before enabling them. It reloads Hyprland,
checks configuration errors, restarts the shell once and verifies its IPC
response. The input installer reloads Fcitx5 and activates the appropriate
system service.

Each stage has its own backup and recovery behavior. A failure stops later
stages. Completed stages remain installed, and rerunning the selected command
continues through idempotent configuration steps. The installer serializes full
installations with a state-directory lock. Component helpers can also be used
independently for targeted changes.

The font packages, keyd for Caps Lock/Fn, and optional compiler tools are installed
with `omarchy pkg add`. The base Omarchy desktop, Fcitx5 input methods and a
running Hyprland/Shell session should already be configured. Native compilation
requires headers matching the running Hyprland build.
