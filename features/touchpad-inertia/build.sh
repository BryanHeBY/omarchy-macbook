#!/usr/bin/env bash
# Build the vertical terminal inertia plugin through the shared native builder.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
exec bash "$repo_root/installer/build-native.sh" touchpad-inertia touchpad-inertia libeis-1.0
