# shell-integration.json

> **Optimized for Omarchy M (MacBook).** Part of a configuration and plugin
> collection that brings familiar macOS workflows and a desktop experience
> closer to native macOS.

Declarative reference for shell integration, including widget replacements,
services, disabled plugins and pinned tray items.

- `widgetReplacements` maps the built-in menu, tray and display panel to custom plugins.
- `enabledServices` lists selected service plugins.
- `disabledPlugins` and `cloneSourceRestores` correspond to Omarchy clone management fields.
- `trayPinned` lists suggested pinned tray entries.

Use the `omarchy plugin enable` commands in the [README](../../README.md) to activate
plugins. This file documents integration intent by field; the shell reads the
user's `~/.config/omarchy/shell.json`. Documentation lives in this companion file
to keep the reference valid strict JSON.
