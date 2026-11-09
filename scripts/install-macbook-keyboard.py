#!/usr/bin/env python3
"""Select Caps Lock/Fn (default) or Left Shift input switching, with backups."""

import argparse
from contextlib import ExitStack
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parent.parent
LOADER = 'require("hypr.customizations.macbook-keyboard")'
KEYD_TARGET = Path('/etc/keyd/omarchy-macbook.conf')


def supported_keyboard_present():
    """Match the keyd capabilities/name fingerprint, avoiding the shared trackpad ID."""
    for device in Path('/sys/class/input').glob('event*/device'):
        name = (device / 'name').read_text().strip()
        if name != 'Apple SPI Keyboard':
            continue
        vendor = (device / 'id/vendor').read_text().strip()
        product = (device / 'id/product').read_text().strip()
        count = sum(int(word, 16).bit_count() for word in (device / 'capabilities/key').read_text().split())
        fingerprint = 5183
        values = [(count >> shift) & 255 for shift in (24, 16, 8, 0)]
        for capability in ('abs', 'rel'):
            values.append(int(''.join((device / f'capabilities/{capability}').read_text().split()), 16) & 255)
        values.extend(name.encode())
        for value in values:
            fingerprint = (fingerprint * 33 + value) & 0xffffffff
        if f'{vendor}:{product}:{fingerprint:08x}' == '05ac:0281:2bd1f3de':
            return True
    return False


def remove_shift_toggle(source):
    """Remove only the previous solitary Left Shift toggle, retaining other hotkeys."""
    sections = []
    for line in source.splitlines(keepends=True):
        stripped = line.strip()
        if stripped.startswith('[') and stripped.endswith(']'):
            sections.append((stripped[1:-1], []))
        if not sections:
            sections.append(('', []))
        sections[-1][1].append(line)
    result = []
    for name, lines in sections:
        if name in ('Hotkey/TriggerKeys', 'Hotkey/AltTriggerKeys'):
            kept = []
            removed = False
            for line in lines:
                key, separator, value = line.strip().partition('=')
                if separator and key.isdigit() and value == 'Shift_L':
                    removed = True
                else:
                    kept.append(line)
            if removed:
                index = 0
                for position, line in enumerate(kept):
                    key, separator, value = line.partition('=')
                    if separator and key.strip().isdigit():
                        kept[position] = str(index) + '=' + value
                        index += 1
            lines = kept
        result.extend(lines)
    updated = ''.join(result)
    for comment in (
        '# A lone Shift leaves an engine like Pinyin for Latin input and returns to it.',
        '# Left Shift toggles input methods even in a new, initially inactive window.',
    ):
        updated = updated.replace(comment, '# Caps Lock and Fn switching are handled by the desktop keyboard customization.')
    return updated


def shift_profile(source):
    """Restore the primary Left Shift trigger, retaining other hotkeys."""
    updated = remove_shift_toggle(source)
    header = '[Hotkey/TriggerKeys]'
    lines = updated.splitlines(keepends=True)
    if header not in [line.strip() for line in lines]:
        updated = updated.rstrip() + '\n\n' + header + '\n'
        lines = updated.splitlines(keepends=True)
    start = next(index for index, line in enumerate(lines) if line.strip() == header)
    end = start + 1
    while end < len(lines) and not lines[end].strip().startswith('['):
        key, separator, value = lines[end].partition('=')
        if separator and key.strip().isdigit():
            lines[end] = str(int(key.strip()) + 1) + '=' + value
        end += 1
    lines.insert(start + 1, '0=Shift_L\n')
    return ''.join(lines).replace(
        '# Caps Lock and Fn switching are handled by the desktop keyboard customization.',
        '# Left Shift toggles input methods even in a new, initially inactive window.')


def check_keyd_conflicts(directory):
    """Avoid competing keyd configurations for the same physical keyboard."""
    for file in directory.glob('*.conf'):
        if file == KEYD_TARGET:
            continue
        section = ''
        identifiers = []
        for line in file.read_text().splitlines():
            value = line.strip()
            if value.startswith('['):
                section = value
            elif section == '[ids]' and value and not value.startswith('#'):
                identifiers.append(value.removeprefix('k:'))
        matches = {'05ac:0281', '05ac:0281:2bd1f3de'}
        exclusions = {'-' + value for value in matches} | {'-k:' + value for value in matches}
        excluded = any(value in exclusions for value in identifiers)
        if not excluded and any(value == '*' or value in matches for value in identifiers):
            raise RuntimeError(f'Existing keyd configuration matches this keyboard: {file}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true', help='back up and install the configuration')
    mode.add_argument('--dry-run', action='store_true', help='preview only (default)')
    parser.add_argument('--profile', choices=('caps-fn', 'shift'), default='caps-fn',
                        help='input switching profile (default: caps-fn)')
    parser.add_argument('--elevate', choices=('sudo', 'pkexec'), default='sudo',
                        help='privilege helper for system configuration (default: sudo)')
    args = parser.parse_args()
    if os.geteuid() == 0:
        raise RuntimeError('Run this installer as the desktop user, using --elevate for system changes.')
    macbook = args.profile == 'caps-fn'
    if macbook and not shutil.which('keyd'):
        raise RuntimeError('Install keyd first with: omarchy pkg add keyd')
    if macbook and not supported_keyboard_present():
        raise RuntimeError('No supported Apple SPI Keyboard fingerprint found. Check the device with sudo keyd monitor.')

    home = Path.home()
    config = Path(os.environ.get('XDG_CONFIG_HOME') or home / '.config')
    bindings = config / 'hypr/bindings.lua'
    fcitx = config / 'fcitx5/config'
    module = config / 'hypr/customizations/macbook-keyboard.lua'
    if macbook and (not module.is_file() or module.resolve() != ROOT / 'hyprland/macbook-keyboard.lua'):
        raise RuntimeError('Install the hyprland symlink with scripts/install-links.sh first.')
    for target in (bindings, fcitx):
        if not target.is_file() or target.is_symlink():
            raise RuntimeError(f'Expected a regular user configuration file: {target}')
    source = ROOT / 'input-method/macbook-keyboard.conf'
    if macbook:
        check_keyd_conflicts(KEYD_TARGET.parent)
        subprocess.run(['keyd', 'check', str(source)], check=True)

    with ExitStack() as resources:
        state = Path(os.environ.get('XDG_STATE_HOME') or home / '.local/state')
        if args.apply:
            lock_parent = state / 'omarchy-macbook'
            lock_parent.mkdir(parents=True, exist_ok=True)
            lock_file = resources.enter_context((lock_parent / 'keyboard-install.lock').open('a'))
            fcntl.flock(lock_file, fcntl.LOCK_EX)

        originals = {bindings: bindings.read_text(), fcitx: fcitx.read_text()}
        updated_bindings = originals[bindings]
        loader_pattern = r'''^\s*require\s*\(\s*["']hypr\.customizations\.macbook-keyboard["']\s*\)\s*;?\s*(?:--.*)?$'''
        if macbook and not re.search(loader_pattern, updated_bindings, re.MULTILINE):
            updated_bindings = updated_bindings.rstrip() + '\n\n-- MacBook Caps Lock and Fn session actions.\n' + LOADER + '\n'
        if not macbook:
            updated_bindings = re.sub(loader_pattern, '', updated_bindings, flags=re.MULTILINE)
            updated_bindings = updated_bindings.replace('-- MacBook Caps Lock and Fn session actions.\n', '')
        input_config = remove_shift_toggle(originals[fcitx]) if macbook else shift_profile(originals[fcitx])
        updates = {bindings: updated_bindings, fcitx: input_config}
        changes = {file: text for file, text in updates.items() if text != originals[file]}
        system_changed = (not KEYD_TARGET.is_file() or KEYD_TARGET.read_bytes() != source.read_bytes()) if macbook else KEYD_TARGET.exists()
        print(f'Input switching profile: {args.profile}')
        if macbook:
            print(f'Keyboard mapping: {source} -> {KEYD_TARGET}')
        elif system_changed:
            print(f'Remove keyboard mapping: {KEYD_TARGET}')
        for file in changes:
            print(f'Update: {file}')
        if not args.apply:
            print('Preview only. Use --apply to back up and install.')
            return
        active = subprocess.run(['systemctl', 'is-active', '--quiet', 'keyd.service'],
                                stderr=subprocess.DEVNULL).returncode == 0
        enabled = subprocess.run(['systemctl', 'is-enabled', '--quiet', 'keyd.service'],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
        if not changes and not system_changed and (not macbook or (active and enabled)):
            print('Already installed. Configuration and service are up to date.')
            return
        devices = json.loads(subprocess.check_output(['hyprctl', '-j', 'devices'], text=True))
        if any(keyboard['capsLock'] for keyboard in devices['keyboards']):
            raise RuntimeError('Turn Caps Lock off before installing or reloading the key mappings.')

        backups = state / 'omarchy-macbook/keyboard-backups'
        backups.mkdir(parents=True, exist_ok=True)
        backup = Path(tempfile.mkdtemp(prefix='install-', dir=backups))
        for file in (bindings, fcitx):
            destination = backup / file.relative_to(config)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(file, destination)
        existed = KEYD_TARGET.exists()
        if existed:
            shutil.copy2(KEYD_TARGET, backup / 'keyd.conf')
        privilege = [args.elevate]
        system_touched = False
        service_touched = False
        print(f'Backup: {backup}', flush=True)
        try:
            # Install the user session actions before activating the system key mappings.
            for file, text in changes.items():
                if file.read_text() != originals[file]:
                    raise RuntimeError(f'Configuration changed during installation: {file}')
                file.write_text(text)
            subprocess.run(['hyprctl', 'reload'], check=True)
            errors = subprocess.check_output(['hyprctl', 'configerrors'], text=True).strip()
            if errors:
                raise RuntimeError(errors)
            subprocess.run(['fcitx5-remote', '--check', '-r'], check=True)
            if macbook:
                if system_changed:
                    subprocess.run(privilege + ['install', '-D', '-o', 'root', '-g', 'root', '-m', '644',
                                   str(source), str(KEYD_TARGET)], check=True)
                    system_touched = True
                service_touched = True
                subprocess.run(privilege + ['systemctl', 'enable', '--now', 'keyd.service'], check=True)
                if active:
                    subprocess.run(privilege + ['keyd', 'reload'], check=True)
            elif system_changed:
                subprocess.run(privilege + ['rm', '-f', str(KEYD_TARGET)], check=True)
                system_touched = True
                service_touched = True
                if any(KEYD_TARGET.parent.glob('*.conf')):
                    if active:
                        subprocess.run(privilege + ['keyd', 'reload'], check=True)
                else:
                    subprocess.run(privilege + ['systemctl', 'disable', '--now', 'keyd.service'], check=True)
        except BaseException:
            for file in changes:
                shutil.copy2(backup / file.relative_to(config), file)
            if system_touched:
                if existed:
                    subprocess.run(privilege + ['install', '-m', '644', str(backup / 'keyd.conf'), str(KEYD_TARGET)])
                else:
                    subprocess.run(privilege + ['rm', '-f', str(KEYD_TARGET)])
            if service_touched:
                subprocess.run(privilege + ['systemctl', 'enable' if enabled else 'disable', 'keyd.service'])
                subprocess.run(privilege + ['systemctl', 'restart' if active else 'stop', 'keyd.service'])
            subprocess.run(['hyprctl', 'reload'])
            subprocess.run(['fcitx5-remote', '--check', '-r'])
            raise
        print(f'Installed input switching profile: {args.profile}')


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        raise SystemExit(f'Error: {error}')
