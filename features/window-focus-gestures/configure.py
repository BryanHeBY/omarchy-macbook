#!/usr/bin/env python3
"""Explicitly enable or disable two-finger focus switching, previewing by default."""

import argparse
from contextlib import ExitStack
import fcntl
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def command(*args):
    print('+', ' '.join(map(str, args)), flush=True)
    return subprocess.check_output(args, text=True).strip()


def loaded():
    plugins = json.loads(subprocess.check_output(['hyprctl', '-j', 'plugin', 'list'], text=True))
    return any(plugin['name'] == 'two-finger-focus' for plugin in plugins)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    state = parser.add_mutually_exclusive_group(required=True)
    state.add_argument('--enable', action='store_true')
    state.add_argument('--disable', action='store_true')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true')
    mode.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    home = Path.home()
    config = Path(os.environ.get('XDG_CONFIG_HOME') or home / '.config')
    marker = config / 'omarchy-macbook/two-finger-focus.enabled'
    library = Path(os.environ.get('XDG_DATA_HOME') or home / '.local/share') / 'omarchy-macbook/plugins/two-finger-focus.so'
    print('Two-finger focus switching:', 'enabled' if args.enable else 'disabled')
    if not args.apply:
        print('Preview only. Use --apply to persist the selection and reload Hyprland.')
        return
    with ExitStack() as resources:
        state_home = Path(os.environ.get('XDG_STATE_HOME') or home / '.local/state') / 'omarchy-macbook'
        state_home.mkdir(parents=True, exist_ok=True)
        lock = resources.enter_context((state_home / 'gesture-install.lock').open('a'))
        fcntl.flock(lock, fcntl.LOCK_EX)
        module = config / 'hypr/customizations/two-finger-focus.lua'
        if not module.is_file() or module.resolve() != ROOT / 'features/window-focus-gestures/hyprland.lua':
            raise RuntimeError('Install the Hyprland symlink before configuring this feature.')
        previous = marker.read_bytes() if marker.exists() else None
        was_loaded = loaded()
        if args.enable:
            command('bash', str(ROOT / 'features/window-focus-gestures/build.sh'))
        backup = None
        if previous is not None:
            parent = Path(os.environ.get('XDG_STATE_HOME') or home / '.local/state') / 'omarchy-macbook/gesture-backups'
            parent.mkdir(parents=True, exist_ok=True)
            backup = Path(tempfile.mkdtemp(prefix='two-finger-', dir=parent)) / marker.name
            backup.write_bytes(previous)
            print('Backup:', backup)
        try:
            if args.enable:
                marker.parent.mkdir(parents=True, exist_ok=True)
                marker.write_text('enabled\n')
            else:
                marker.unlink(missing_ok=True)
            if was_loaded:
                command('hyprctl', 'plugin', 'unload', str(library))
            if args.enable:
                command('hyprctl', 'plugin', 'load', str(library))
            command('hyprctl', 'reload')
            errors = command('hyprctl', 'configerrors')
            if errors:
                raise RuntimeError(errors)
            if loaded() != args.enable:
                raise RuntimeError('The plugin state does not match the requested selection.')
        except BaseException:
            if previous is None:
                marker.unlink(missing_ok=True)
            else:
                marker.parent.mkdir(parents=True, exist_ok=True)
                marker.write_bytes(previous)
            if loaded():
                command('hyprctl', 'plugin', 'unload', str(library))
            if was_loaded:
                command('hyprctl', 'plugin', 'load', str(library))
            command('hyprctl', 'reload')
            raise
        print('Applied two-finger focus selection.')


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        raise SystemExit(f'Error: {error}')
