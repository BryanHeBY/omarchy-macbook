#!/usr/bin/env bash
# Build the compositor plugin using matching installed Hyprland development headers.
# The shared library is installed in the user's data directory, outside the repository.
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
output_dir="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins"
compiler=${CXX:-g++}
command -v "$compiler" >/dev/null
pkg-config --exists hyprland
mkdir -p -- "$output_dir"
temporary=$(mktemp "$output_dir/.two-finger-focus.XXXXXX.so")
trap 'rm -f -- "$temporary"' EXIT
read -r -a include_flags <<< "$(pkg-config --cflags hyprland)"
"$compiler" -std=c++26 -shared -fPIC -fno-gnu-unique -O2 -Wall -Wextra \
  "${include_flags[@]}" "$repo_root/features/window-focus-gestures/native/plugin.cpp" -o "$temporary"
chmod 755 -- "$temporary"
mv -f -- "$temporary" "$output_dir/two-finger-focus.so"
printf 'Built %s\n' "$output_dir/two-finger-focus.so"
