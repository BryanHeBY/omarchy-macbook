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

ROOT = Path(__file__).resolve().parent
PROFILE = ROOT / 'profiles/recommended.json'
FEATURES = {
    'workspace-navigation', 'tab-shortcuts', 'desktop-shortcuts', 'screenshot-shortcuts',
    'chinese-fonts', 'keyboard-input',
    'menu-selection-memory', 'system-tray', 'window-focus-gestures',
    'display-controls', 'passwordless-lock', 'vscode-scrolling',
}


def load_profile():
    """Read and validate the single source of recommended activation defaults."""
    profile = json.loads(PROFILE.read_text())
    if profile.get('input_method') not in ('caps-fn', 'shift'):
        raise RuntimeError('The profile input_method must be caps-fn or shift.')
    features = profile.get('features')
    if not isinstance(features, dict) or set(features) != FEATURES:
        raise RuntimeError('The recommended profile must declare every supported feature.')
    if any(type(enabled) is not bool for enabled in features.values()):
        raise RuntimeError('Feature selections must be JSON booleans.')
    return profile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--apply', action='store_true', help='install dependencies, configure and activate')
    mode.add_argument('--dry-run', action='store_true', help='print the complete plan (default)')
    parser.add_argument('--input-method', choices=('caps-fn', 'shift'))
    parser.add_argument('--with-two-finger-focus', action='store_true', default=None)
    parser.add_argument('--with-display-controls', action='store_true', default=None)
    parser.add_argument('--with-passwordless-lock', action='store_true', default=None)
    parser.add_argument('--with-vscode-inertia', action='store_true', default=None)
    parser.add_argument('--with-macos-screenshots', action='store_true', default=None)
    args = parser.parse_args()
    profile = load_profile()
    features = profile['features'].copy()
    input_method = args.input_method or profile['input_method']
    overrides = {
        'window-focus-gestures': args.with_two_finger_focus,
        'display-controls': args.with_display_controls,
        'passwordless-lock': args.with_passwordless_lock,
        'vscode-scrolling': args.with_vscode_inertia,
        'screenshot-shortcuts': args.with_macos_screenshots,
    }
    for name, enabled in overrides.items():
        if enabled is not None:
            features[name] = enabled
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

        packages = []
        if features['chinese-fonts']:
            packages.extend(['ttf-sarasa-gothic', 'noto-fonts-cjk'])
        if features['keyboard-input'] and input_method == 'caps-fn':
            packages.append('keyd')
        if features['window-focus-gestures']:
            packages.extend(['gcc', 'pkgconf'])
        if features['passwordless-lock']:
            packages.append('ffmpegthumbnailer')
        plugins = [name for name in ('menu-selection-memory', 'system-tray',
                   'display-controls', 'passwordless-lock') if features[name]]

        for plugin in plugins:
            run('omarchy', 'plugin', 'validate', ROOT / 'features' / plugin / 'plugin')
        if packages:
            run('omarchy', 'pkg', 'add', *packages)
        run('bash', ROOT / 'installer/links.sh', '--apply', '--only', 'hyprland')
        if features['chinese-fonts']:
            run('bash', ROOT / 'installer/links.sh', '--apply', '--only', 'fonts')
        if plugins:
            run('bash', ROOT / 'installer/links.sh', '--apply', '--only', 'shell')
        if features['workspace-navigation']:
            run('bash', ROOT / 'installer/patches.sh', '--apply', '--only', 'workspace')
        if features['tab-shortcuts']:
            run('bash', ROOT / 'installer/patches.sh', '--apply', '--only', 'tab-shortcuts')
        if features['desktop-shortcuts']:
            run('bash', ROOT / 'installer/patches.sh', '--apply', '--only', 'desktop-shortcuts')
        if features['screenshot-shortcuts']:
            run('bash', ROOT / 'installer/patches.sh', '--apply', '--only', 'screenshot-shortcuts')
        # The independent loader is inert until the feature's opt-in marker exists.
        run('bash', ROOT / 'installer/patches.sh', '--apply', '--only', 'window-focus')
        if features['keyboard-input']:
            run(sys.executable, ROOT / 'features/keyboard-input/configure.py', '--apply', '--profile', input_method)
        selection = '--enable' if features['window-focus-gestures'] else '--disable'
        run(sys.executable, ROOT / 'features/window-focus-gestures/configure.py', '--apply', selection)
        if features['display-controls']:
            run('bash', ROOT / 'installer/patches.sh', '--apply', '--only', 'display')
        if features['vscode-scrolling']:
            run('node', ROOT / 'features/vscode-scrolling/configure.cjs', '--apply')
        if features['chinese-fonts']:
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
