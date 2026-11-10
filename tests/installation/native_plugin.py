"""Verify shared native activation and rollback without a live compositor."""
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('native_plugin', ROOT / 'installer/native_plugin.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class NativePluginTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.home = Path(self.temporary.name)
        self.marker = self.home / 'config/omarchy-macbook/touchpad-inertia.enabled'
        self.library = self.home / 'data/omarchy-macbook/plugins/touchpad-inertia.so'
        module = self.home / 'config/hypr/customizations/touchpad-inertia.lua'
        module.parent.mkdir(parents=True)
        module.symlink_to(ROOT / 'features/touchpad-inertia/hyprland.lua')
        self.input = self.home / 'config/hypr/input.lua'
        self.input.write_text('require("hypr.customizations.touchpad-inertia")\n')
        self.loaded = False
        self.calls = []

    def command(self, *args):
        self.calls.append(args)
        if args[0] == 'bash':
            self.library.parent.mkdir(parents=True, exist_ok=True)
            self.library.write_bytes(b'new library')
        elif args[:3] == ('hyprctl', 'plugin', 'unload'):
            self.loaded = False
        elif args[:3] == ('hyprctl', 'plugin', 'load'):
            self.loaded = True
        return ''

    def invoke(self, *args, command=None):
        env = {'XDG_CONFIG_HOME': str(self.home / 'config'), 'XDG_DATA_HOME': str(self.home / 'data'),
               'XDG_STATE_HOME': str(self.home / 'state')}
        with patch.dict(os.environ, env), patch('sys.argv', ['configure.py', *args]), \
             patch.object(installer, 'loaded', side_effect=lambda _: self.loaded), \
             patch.object(installer, 'command', side_effect=command or self.command), redirect_stdout(io.StringIO()):
            installer.configure('touchpad-inertia', 'touchpad-inertia', 'touchpad-inertia', 'Touchpad inertia')

    def test_preview_writes_no_runtime_state(self):
        self.invoke('--enable')
        self.assertFalse((self.home / 'state').exists())
        self.assertFalse(self.marker.exists())

    def test_enable_disable(self):
        self.invoke('--apply', '--enable')
        self.assertTrue(self.loaded)
        self.assertEqual(self.marker.read_bytes(), b'enabled\n')
        self.invoke('--apply', '--disable')
        self.assertFalse(self.loaded)
        self.assertFalse(self.marker.exists())
        self.assertEqual(self.library.read_bytes(), b'new library')

    def test_failed_rebuild_restores_library_marker_and_loaded_state(self):
        self.marker.parent.mkdir(parents=True)
        self.marker.write_bytes(b'previous selection\n')
        self.library.parent.mkdir(parents=True)
        self.library.write_bytes(b'old library')
        self.library.chmod(0o755)
        self.loaded = True
        failures = 0

        def command(*args):
            nonlocal failures
            if args[:3] == ('hyprctl', 'plugin', 'load'):
                failures += 1
                if failures == 1:
                    raise subprocess.CalledProcessError(1, args)
                self.assertEqual(self.library.read_bytes(), b'old library')
            return self.command(*args)

        with self.assertRaises(subprocess.CalledProcessError):
            self.invoke('--apply', '--enable', command=command)
        self.assertTrue(self.loaded)
        self.assertEqual(self.marker.read_bytes(), b'previous selection\n')
        self.assertEqual(self.library.read_bytes(), b'old library')
        self.assertEqual(self.library.stat().st_mode & 0o777, 0o755)

    def test_unintegrated_loader_rejected_before_build(self):
        self.input.write_text('-- personal settings\n')
        with self.assertRaises(RuntimeError):
            self.invoke('--apply', '--enable')
        self.assertEqual(self.calls, [])

    def test_failed_first_load_removes_new_runtime_files(self):
        def command(*args):
            if args[:3] == ('hyprctl', 'plugin', 'load'):
                raise subprocess.CalledProcessError(1, args)
            return self.command(*args)

        with self.assertRaises(subprocess.CalledProcessError):
            self.invoke('--apply', '--enable', command=command)
        self.assertFalse(self.loaded)
        self.assertFalse(self.marker.exists())
        self.assertFalse(self.library.exists())


if __name__ == '__main__':
    unittest.main()
