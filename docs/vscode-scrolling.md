# VS Code touchpad inertia

VS Code implements scrolling inside its editor. On Linux, the input stack sends
finger movement and a stop event; the application implements continued motion
after release. VS Code exposes this behavior through `editor.inertialScroll`,
which defaults to `false`. `editor.smoothScrolling` controls animated scroll
transitions and is a separate setting.

## Enable or disable

Run from the repository root with Node.js 18 or newer:

```bash
# Preview the target and requested value without writing anything.
node scripts/configure-vscode-scroll.cjs

# Back up settings and enable inertia.
node scripts/configure-vscode-scroll.cjs --apply

# Set the option back to false.
node scripts/configure-vscode-scroll.cjs --apply --disable
```

The default target is
`${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json`.
For another edition, a named profile, a portable installation or a custom
user-data directory, locate the active user settings with **Preferences: Open
User Settings (JSON)** and pass its path explicitly:

```bash
node scripts/configure-vscode-scroll.cjs --settings /path/to/settings.json
node scripts/configure-vscode-scroll.cjs --settings /path/to/settings.json --apply
```

The script changes only the top-level `editor.inertialScroll` property. It
preserves JSONC comments, trailing commas and unrelated preferences. Existing
symlinks are resolved and retained. Invalid JSONC and duplicate target keys cause
an error before writing. An absent settings file is created only with `--apply`.
An already matching value produces no write or backup.

Existing settings are copied to a private directory under
`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-configs/vscode-scroll-backups/`
before atomic replacement. The script prints the backup file path. Close the
settings editor before applying to reduce concurrent edits. To undo only this
option, use `--disable` or remove `editor.inertialScroll` manually. To restore the
whole file, copy the printed backup over the resolved settings file after
checking whether newer preferences need to be retained. Backups may contain
personal settings and should stay outside the repository.

## Check the result

VS Code normally reloads user settings automatically. Open a long text file,
scroll vertically with two fingers, and lift them while moving. Motion should
continue briefly and decelerate. If the option is unavailable, check whether the
installed VS Code version supports `editor.inertialScroll`.

If the effect is missing, inspect the active profile, workspace settings and any
language-specific overrides. **Developer: Reload Window** can refresh the editor
after checking settings. The preference applies to editor scrolling; webviews,
the integrated terminal, sidebars and other application surfaces may implement
their own behavior. This helper leaves `editor.smoothScrolling` at its existing
value.

The helper is independent of the symlink installer and patch application script.
It is never applied automatically during installation.

## References

- [VS Code editor options](https://github.com/microsoft/vscode/blob/main/src/vs/editor/common/config/editorOptions.ts)
- [VS Code scroll handling](https://github.com/microsoft/vscode/blob/main/src/vs/base/browser/ui/scrollbar/scrollableElement.ts)
- [libinput scrolling and kinetic motion](https://wayland.freedesktop.org/libinput/doc/latest/scrolling)
