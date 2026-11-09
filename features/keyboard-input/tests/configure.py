# Check Shift-toggle migration and the exact keyboard selector without touching live settings.
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('keyboard_installer', ROOT / 'features/keyboard-input/configure.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class KeyboardConfigurationTests(unittest.TestCase):
    def test_shift_migration_preserves_other_settings(self):
        source = ('# Personal settings\n[Hotkey/TriggerKeys]\n0=Shift_L\n1=Zenkaku_Hankaku\n'
                  '2=Control+space\n\n[Hotkey/AltTriggerKeys]\n0=Shift_L\n1=Shift_R\n'
                  '\n[Behavior]\nActiveByDefault=False\n# Retain this comment\n')
        result = installer.remove_shift_toggle(source)
        self.assertEqual(result, source.replace('0=Shift_L\n', '')
                         .replace('1=Zenkaku_Hankaku', '0=Zenkaku_Hankaku')
                         .replace('2=Control+space', '1=Control+space')
                         .replace('1=Shift_R', '0=Shift_R'))
        self.assertEqual(installer.remove_shift_toggle(result), result)

    def test_unrelated_shift_setting_is_retained(self):
        source = '[Other]\n0=Shift_L\n[Hotkey/TriggerKeys]\n0=Control+space\n'
        self.assertEqual(installer.remove_shift_toggle(source), source)

    def test_shift_profile_can_be_restored_repeatedly(self):
        source = '[Hotkey/TriggerKeys]\n0=Zenkaku_Hankaku\n1=Control+space\n\n[Hotkey/AltTriggerKeys]\n\n[Behavior]\nActiveByDefault=False\n'
        shifted = installer.shift_profile(source)
        self.assertIn('0=Shift_L\n1=Zenkaku_Hankaku\n2=Control+space', shifted)
        self.assertEqual(installer.shift_profile(shifted), shifted)
        self.assertEqual(installer.remove_shift_toggle(shifted), source)

    def test_shift_profile_creates_missing_trigger_group(self):
        source = '[Behavior]\nActiveByDefault=False\n'
        result = installer.shift_profile(source)
        self.assertIn(source, result)
        self.assertIn('[Hotkey/TriggerKeys]\n0=Shift_L\n', result)
        self.assertEqual(installer.shift_profile(result), result)

    def test_default_and_previous_repository_formats(self):
        for comment, trigger in [
            ('# A lone Shift leaves an engine like Pinyin for Latin input and returns to it.', '0=Zenkaku_Hankaku\n1=Hangul\n'),
            ('# Left Shift toggles input methods even in a new, initially inactive window.', '0=Shift_L\n1=Zenkaku_Hankaku\n2=Hangul\n'),
        ]:
            source = '[Hotkey/TriggerKeys]\n' + trigger + '\n' + comment + '\n[Hotkey/AltTriggerKeys]\n0=Shift_L\n'
            result = installer.remove_shift_toggle(source)
            self.assertIn('0=Zenkaku_Hankaku\n1=Hangul', result)
            self.assertNotIn('=Shift_L', result)
            self.assertIn('# Caps Lock and Fn switching', result)

    def test_keyboard_selector_cannot_match_shared_trackpad_id(self):
        source = (ROOT / 'features/keyboard-input/keyd.conf').read_text()
        identifiers = source.split('[ids]\n')[1].split('[global]')[0].strip().splitlines()
        self.assertEqual(identifiers, ['05ac:0281:2bd1f3de'])
        subprocess.run(['keyd', 'check', str(ROOT / 'features/keyboard-input/keyd.conf')], check=True)

    def test_conflicting_keyd_mapping_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            other = Path(directory) / 'other.conf'
            for selector in ('*', '05ac:0281', 'k:05ac:0281:2bd1f3de'):
                other.write_text('[ids]\n' + selector + '\n[main]\n')
                with self.assertRaises(RuntimeError):
                    installer.check_keyd_conflicts(Path(directory))
            other.write_text('[ids]\n*\n-05ac:0281\n[main]\n')
            installer.check_keyd_conflicts(Path(directory))
            other.write_text('[ids]\n05ac:0281:0dd00711\n[main]\n')
            installer.check_keyd_conflicts(Path(directory))

    def test_partial_failure_restores_user_and_system_files(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            config = home / 'config'
            bindings = config / 'hypr/bindings.lua'
            fcitx = config / 'fcitx5/config'
            bindings.parent.mkdir(parents=True)
            fcitx.parent.mkdir(parents=True)
            bindings.write_text('-- personal binding\n-- ' + installer.LOADER + '\n')
            fcitx.write_text('[Hotkey/TriggerKeys]\n0=Shift_L\n1=Hangul\n')
            (config / 'hypr/customizations').mkdir()
            (config / 'hypr/customizations/macbook-keyboard.lua').symlink_to(ROOT / 'features/keyboard-input/hyprland.lua')
            system = home / 'etc/keyd/omarchy-macbook.conf'
            system.parent.mkdir(parents=True)
            system.write_text('# previous system configuration\n')
            originals = {file: file.read_bytes() for file in (bindings, fcitx, system)}

            def run(command, **kwargs):
                if command[:2] == ['systemctl', 'is-active'] or command[:2] == ['systemctl', 'is-enabled']:
                    return subprocess.CompletedProcess(command, 1)
                if command[:2] == ['sudo', 'install']:
                    Path(command[-1]).write_bytes(Path(command[-2]).read_bytes())
                if command[:3] == ['sudo', 'systemctl', 'enable']:
                    self.assertIn(installer.LOADER, bindings.read_text().splitlines()[-1])
                    self.assertNotIn('=Shift_L', fcitx.read_text())
                    self.assertNotEqual(system.read_bytes(), originals[system])
                    raise subprocess.CalledProcessError(1, command)
                return subprocess.CompletedProcess(command, 0)

            def output(command, **kwargs):
                if command == ['hyprctl', '-j', 'devices']:
                    return '{"keyboards":[{"capsLock":false}]}'
                return ''

            with patch.object(installer, 'KEYD_TARGET', system), \
                 patch.object(installer, 'supported_keyboard_present', return_value=True), \
                 patch.object(installer.os, 'geteuid', return_value=1000), \
                 patch.object(installer.shutil, 'which', return_value='/usr/bin/keyd'), \
                 patch.object(Path, 'home', return_value=home), \
                 patch.dict(os.environ, {'XDG_CONFIG_HOME': str(config), 'XDG_STATE_HOME': str(home / 'state')}), \
                 patch.object(installer.subprocess, 'run', side_effect=run), \
                 patch.object(installer.subprocess, 'check_output', side_effect=output), \
                 patch('sys.argv', ['install-macbook-keyboard.py', '--apply']):
                with self.assertRaises(subprocess.CalledProcessError):
                    installer.main()
            for file, content in originals.items():
                self.assertEqual(file.read_bytes(), content)


if __name__ == '__main__':
    unittest.main()
