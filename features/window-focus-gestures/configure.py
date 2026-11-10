#!/usr/bin/env python3
"""Explicitly enable or disable two-finger focus switching, previewing by default."""

from pathlib import Path
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'installer'))
from native_plugin import configure

if __name__ == '__main__':
    try:
        configure('window-focus-gestures', 'two-finger-focus', 'window-focus',
                  'Two-finger focus switching', 'gesture-backups')
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        raise SystemExit(f'Error: {error}')
