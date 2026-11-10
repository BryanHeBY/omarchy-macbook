#!/usr/bin/env bash
# Build a feature's native plugin against the installed compositor headers.
set -euo pipefail
feature=${1:?feature name required}
plugin=${2:?plugin name required}
shift 2
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
output_dir="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-macbook/plugins"
compiler=${CXX:-g++}
command -v "$compiler" >/dev/null
pkg-config --exists hyprland "$@"
mkdir -p -- "$output_dir"
temporary=$(mktemp "$output_dir/.$plugin.XXXXXX.so")
trap 'rm -f -- "$temporary"' EXIT
read -r -a include_flags <<< "$(pkg-config --cflags hyprland "$@")"
"$compiler" -std=c++26 -shared -fPIC -fno-gnu-unique -O2 -Wall -Wextra \
  "${include_flags[@]}" "$repo_root/features/$feature/native/plugin.cpp" -o "$temporary"
chmod 755 -- "$temporary"
mv -f -- "$temporary" "$output_dir/$plugin.so"
printf 'Built %s\n' "$output_dir/$plugin.so"
