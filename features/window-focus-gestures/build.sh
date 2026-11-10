#!/usr/bin/env bash
# Build the focus plugin through the shared native build entry point.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
exec bash "$repo_root/installer/build-native.sh" window-focus-gestures two-finger-focus
