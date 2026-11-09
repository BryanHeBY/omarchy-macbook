#!/usr/bin/env python3
"""Install and activate the recommended Omarchy MacBook profile, previewing by default."""

import argparse
from contextlib import ExitStack
import fcntl
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true', help='install dependencies, configure and activate')
    mode.add_argument('--dry-run', action='store_true', help='print the complete plan (default)')
    parser.add_argument('--input-method', choices=('caps-fn', 'shift'), default='caps-fn')
    parser.add_argument('--with-two-finger-focus', action='store_true')
    parser.add_argument('--with-display-controls', action='store_true')
    parser.add_argument('--with-passwordless-lock', action='store_true')
    parser.add_argument('--with-vscode-inertia', action='store_true')
    args = parser.parse_args()
    if os.geteuid() == 0:
        raise RuntimeError('Run this script as the desktop user. Individual stages request sudo as needed.')

    def run(*command):
        command = list(map(str, command))
        print('+ ' + shlex.join(command), flush=True)
        if args.apply:
            subprocess.run(command, cwd=ROOT, check=True)

    with ExitStack() as resources:
        if args.apply:
            parent = Path(os.environ.get('XDG_STATE_HOME') or Path.home() / '.local/state') / 'omarchy-macbook'
            parent.mkdir(parents=True, exist_ok=True)
            # The descriptor stays open through all installation and activation stages.
            lock = resources.enter_context((parent / 'recommended-install.lock').open('a'))
            fcntl.flock(lock, fcntl.LOCK_EX)

        packages = ['ttf-sarasa-gothic', 'noto-fonts-cjk']
        if args.input_method == 'caps-fn':
            packages.append('keyd')
        if args.with_two_finger_focus:
            packages.extend(['gcc', 'pkgconf'])
        if args.with_passwordless_lock:
            packages.append('ffmpegthumbnailer')
        plugins = ['menu-selection-memory', 'system-tray']
        if args.with_display_controls:
            plugins.append('display-controls')
        if args.with_passwordless_lock:
            plugins.append('passwordless-lock')

        for plugin in plugins:
            run('omarchy', 'plugin', 'validate', ROOT / 'omarchy/plugins' / plugin)
        run('omarchy', 'pkg', 'add', *packages)
        run('bash', ROOT / 'scripts/install-links.sh', '--apply')
        run('bash', ROOT / 'scripts/apply-patches.sh', '--apply', '--only', 'hyprland')
        run(sys.executable, ROOT / 'scripts/install-macbook-keyboard.py', '--apply', '--profile', args.input_method)
        selection = '--enable' if args.with_two_finger_focus else '--disable'
        run(sys.executable, ROOT / 'scripts/configure-two-finger-focus.py', '--apply', selection)
        if args.with_display_controls:
            run('bash', ROOT / 'scripts/apply-patches.sh', '--apply', '--only', 'display')
        if args.with_vscode_inertia:
            run('node', ROOT / 'scripts/configure-vscode-scroll.cjs', '--apply')
        run('fc-cache', '-f')
        run('omarchy', 'shell', 'shell', 'rescanPlugins')
        if args.apply:
            for _ in range(40):
                discovered = json.loads(subprocess.check_output(['omarchy', 'plugin', 'list', '--json'], text=True))
                if set(plugins).issubset({plugin['id'] for plugin in discovered}):
                    break
                time.sleep(0.25)
            else:
                raise RuntimeError('Timed out waiting for shell plugin discovery. Retry after the shell is available.')
        for plugin in plugins:
            run('omarchy', 'plugin', 'enable', plugin)
        run('hyprctl', 'reload')
        print('+ hyprctl configerrors', flush=True)
        if args.apply:
            errors = subprocess.check_output(['hyprctl', 'configerrors'], text=True).strip()
            if errors:
                raise RuntimeError(errors)
        run('omarchy', 'restart', 'shell')
        run('omarchy', 'shell', 'shell', 'ping')
        if args.apply:
            print('Recommended profile installed and activated.')
        else:
            print('Preview complete. Use --apply to run this plan.')


if __name__ == '__main__':
    try:
        main()
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        raise SystemExit(f'Error: {error}')
