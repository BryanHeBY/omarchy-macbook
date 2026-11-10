#!/usr/bin/env python3
"""Explicitly enable or disable touchpad inertia, previewing by default."""

from pathlib import Path
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'installer'))
from native_plugin import configure

if __name__ == '__main__':
    try:
        configure('touchpad-inertia', 'touchpad-inertia', 'touchpad-inertia', 'Touchpad inertia')
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        raise SystemExit(f'Error: {error}')
