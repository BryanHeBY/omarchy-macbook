# Verify recommended defaults, explicit options and activation ordering without live changes.
from contextlib import redirect_stdout
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('recommended_installer', ROOT / 'install.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class RecommendedInstallationTests(unittest.TestCase):
    def preview(self, *args):
        output = io.StringIO()
        with tempfile.TemporaryDirectory() as directory, \
             patch.dict(os.environ, {'HOME': directory, 'XDG_STATE_HOME': directory + '/state'}), \
             patch.object(installer.os, 'geteuid', return_value=1000), \
             patch('sys.argv', ['install.py', *args]), redirect_stdout(output):
            installer.main()
            self.assertEqual(list(Path(directory).iterdir()), [])
        return output.getvalue()

    def test_default_is_caps_fn_with_two_finger_disabled(self):
        plan = self.preview()
        self.assertIn('--profile caps-fn', plan)
        self.assertIn('features/window-focus-gestures/configure.py --apply --disable', plan)
        self.assertIn('omarchy plugin enable menu-selection-memory', plan)
        self.assertIn('omarchy plugin enable system-tray', plan)
        self.assertNotIn('omarchy plugin enable passwordless-lock', plan)
        self.assertNotIn('omarchy plugin enable display-controls', plan)
        self.assertNotIn('features/vscode-scrolling/configure.cjs --apply', plan)
        self.assertIn('omarchy restart shell', plan)
        self.assertIn('hyprctl configerrors', plan)
        self.assertIn('--only desktop-shortcuts', plan)
        self.assertNotIn('--only screenshot-shortcuts', plan)

    def test_legacy_and_optional_features_are_explicit(self):
        plan = self.preview('--input-method', 'shift', '--with-two-finger-focus',
                            '--with-display-controls', '--with-passwordless-lock', '--with-vscode-inertia',
                            '--with-macos-screenshots')
        self.assertIn('--profile shift', plan)
        self.assertIn('features/window-focus-gestures/configure.py --apply --enable', plan)
        self.assertIn('omarchy plugin enable display-controls', plan)
        self.assertIn('omarchy plugin enable passwordless-lock', plan)
        self.assertIn('features/vscode-scrolling/configure.cjs --apply', plan)
        self.assertIn('--only screenshot-shortcuts', plan)

    def test_recommended_file_drives_selection(self):
        profile = installer.load_profile()
        profile['input_method'] = 'shift'
        for feature in ('workspace-navigation', 'tab-shortcuts', 'desktop-shortcuts', 'chinese-fonts', 'menu-selection-memory'):
            profile['features'][feature] = False
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / 'profile.json'
            file.write_text(json.dumps(profile))
            with patch.object(installer, 'PROFILE', file):
                plan = self.preview()
        self.assertIn('--profile shift', plan)
        self.assertNotIn('--only workspace', plan)
        self.assertNotIn('--only tab-shortcuts', plan)
        self.assertNotIn('--only desktop-shortcuts', plan)
        self.assertNotIn('--only fonts', plan)
        self.assertNotIn('fc-cache -f', plan)
        self.assertNotIn('omarchy plugin enable menu-selection-memory', plan)
        self.assertIn('omarchy plugin enable system-tray', plan)

    def test_profile_requires_real_booleans(self):
        profile = installer.load_profile()
        profile['features']['chinese-fonts'] = 'false'
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / 'profile.json'
            file.write_text(json.dumps(profile))
            with patch.object(installer, 'PROFILE', file):
                with self.assertRaises(RuntimeError):
                    installer.load_profile()

    def test_apply_waits_for_discovery_before_enabling_plugins(self):
        calls = []
        discoveries = iter(['[]', '[{"id":"menu-selection-memory"},{"id":"system-tray"}]'])

        def output(command, **kwargs):
            calls.append(command)
            if command == ['omarchy', 'plugin', 'list', '--json']:
                return next(discoveries)
            return ''

        with tempfile.TemporaryDirectory() as directory, \
             patch.dict(os.environ, {'XDG_STATE_HOME': directory}), \
             patch.object(installer.os, 'geteuid', return_value=1000), \
             patch('sys.argv', ['install.py', '--apply']), \
             patch.object(installer.subprocess, 'run', side_effect=lambda command, **kwargs: calls.append(command)), \
             patch.object(installer.subprocess, 'check_output', side_effect=output), \
             patch.object(installer.time, 'sleep'), redirect_stdout(io.StringIO()):
            installer.main()
        discover = [index for index, call in enumerate(calls) if call == ['omarchy', 'plugin', 'list', '--json']]
        enable = calls.index(['omarchy', 'plugin', 'enable', 'menu-selection-memory'])
        self.assertEqual(len(discover), 2)
        self.assertLess(discover[-1], enable)
        self.assertEqual(calls[-1], ['omarchy', 'shell', 'shell', 'ping'])

    def test_failed_stage_stops_activation(self):
        calls = []

        def run(command, **kwargs):
            calls.append(command)
            if 'patches.sh' in str(command):
                raise subprocess.CalledProcessError(1, command)

        with tempfile.TemporaryDirectory() as directory, \
             patch.dict(os.environ, {'XDG_STATE_HOME': directory}), \
             patch.object(installer.os, 'geteuid', return_value=1000), \
             patch('sys.argv', ['install.py', '--apply']), \
             patch.object(installer.subprocess, 'run', side_effect=run), redirect_stdout(io.StringIO()):
            with self.assertRaises(subprocess.CalledProcessError):
                installer.main()
        self.assertFalse(any(call[:3] == ['omarchy', 'plugin', 'enable'] for call in calls))


if __name__ == '__main__':
    unittest.main()
