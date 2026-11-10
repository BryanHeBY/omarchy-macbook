"""Shared explicit activation and failure recovery for repository native plugins."""

import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def command(*args):
    print('+', ' '.join(map(str, args)), flush=True)
    return subprocess.check_output(args, text=True).strip()


def loaded(name):
    plugins = json.loads(subprocess.check_output(['hyprctl', '-j', 'plugin', 'list'], text=True))
    return any(plugin['name'] == name for plugin in plugins)


def restore(path, content):
    """Restore a runtime file atomically, preserving library inode isolation."""
    if content is None:
        path.unlink(missing_ok=True)
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as file:
        temporary = Path(file.name)
        try:
            file.write(content)
            file.flush()
            os.fsync(file.fileno())
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)


def configure(feature, name, integration, title, backup_group='native-plugin-backups'):
    parser = argparse.ArgumentParser(description=f'Explicitly configure {title.lower()}, previewing by default.')
    state = parser.add_mutually_exclusive_group(required=True)
    state.add_argument('--enable', action='store_true')
    state.add_argument('--disable', action='store_true')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true')
    mode.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    home = Path.home()
    config = Path(os.environ.get('XDG_CONFIG_HOME') or home / '.config')
    marker = config / f'omarchy-macbook/{name}.enabled'
    library = Path(os.environ.get('XDG_DATA_HOME') or home / '.local/share') / f'omarchy-macbook/plugins/{name}.so'
    print(title + ':', 'enabled' if args.enable else 'disabled')
    if not args.apply:
        print('Preview only. Use --apply to persist the selection and reload Hyprland.')
        return

    state_home = Path(os.environ.get('XDG_STATE_HOME') or home / '.local/state') / 'omarchy-macbook'
    state_home.mkdir(parents=True, exist_ok=True)
    with (state_home / 'native-plugin-install.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        module = config / f'hypr/customizations/{name}.lua'
        if not module.is_file() or module.resolve() != ROOT / f'features/{feature}/hyprland.lua':
            raise RuntimeError('Install the Hyprland symlink before configuring this feature.')
        if args.enable:
            loader = r'''^\s*require\s*\(\s*["']hypr\.customizations\.''' + re.escape(name) + r'''["']\s*\)'''
            if not re.search(loader, (config / 'hypr/input.lua').read_text(), re.MULTILINE):
                raise RuntimeError(f'Apply installer/patches.sh --apply --only {integration} first.')
        if marker.is_symlink() or library.is_symlink():
            raise RuntimeError('Runtime selection markers and native libraries must be regular files.')
        previous_marker = marker.read_bytes() if marker.exists() else None
        previous_library = library.read_bytes() if library.exists() else None
        previous_mode = library.stat().st_mode & 0o777 if library.exists() else None
        was_loaded = loaded(name)
        if previous_marker is not None or previous_library is not None:
            parent = state_home / backup_group
            parent.mkdir(parents=True, exist_ok=True)
            backup = Path(tempfile.mkdtemp(prefix=name + '-', dir=parent))
            for file in (marker, library):
                if file.exists():
                    shutil.copy2(file, backup / file.name)
            print('Backup:', backup)
        try:
            if args.enable:
                command('bash', str(ROOT / f'features/{feature}/build.sh'))
                restore(marker, b'enabled\n')
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
            if loaded(name) != args.enable:
                raise RuntimeError('The plugin state does not match the requested selection.')
        except BaseException:
            restore(marker, previous_marker)
            restore(library, previous_library)
            if previous_mode is not None:
                library.chmod(previous_mode)
            try:
                if loaded(name):
                    command('hyprctl', 'plugin', 'unload', str(library))
                if was_loaded:
                    command('hyprctl', 'plugin', 'load', str(library))
                command('hyprctl', 'reload')
            except (OSError, RuntimeError, subprocess.CalledProcessError) as recovery_error:
                print('Files restored. Session recovery also reported:', recovery_error)
            raise
        print('Applied ' + title.lower() + ' selection.')
