# Verify recommended defaults, explicit options and activation ordering without live changes.
from contextlib import redirect_stdout
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('recommended_installer', ROOT / 'scripts/install.py')
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
        self.assertIn('configure-two-finger-focus.py --apply --disable', plan)
        self.assertIn('omarchy plugin enable menu-selection-memory', plan)
        self.assertIn('omarchy plugin enable system-tray', plan)
        self.assertNotIn('omarchy plugin enable passwordless-lock', plan)
        self.assertNotIn('omarchy plugin enable display-controls', plan)
        self.assertNotIn('configure-vscode-scroll.cjs --apply', plan)
        self.assertIn('omarchy restart shell', plan)
        self.assertIn('hyprctl configerrors', plan)

    def test_legacy_and_optional_features_are_explicit(self):
        plan = self.preview('--input-method', 'shift', '--with-two-finger-focus',
                            '--with-display-controls', '--with-passwordless-lock', '--with-vscode-inertia')
        self.assertIn('--profile shift', plan)
        self.assertIn('configure-two-finger-focus.py --apply --enable', plan)
        self.assertIn('omarchy plugin enable display-controls', plan)
        self.assertIn('omarchy plugin enable passwordless-lock', plan)
        self.assertIn('configure-vscode-scroll.cjs --apply', plan)

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
            if 'apply-patches.sh' in str(command):
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
