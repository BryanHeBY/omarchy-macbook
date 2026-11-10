#!/usr/bin/env bash
# Check or apply scoped configuration patches while preserving unrelated user settings.
# Default to a read-only preview. --apply backs up targets and restores touched files on failure.
# See the README for symlink installation and shell plugin integration.
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
task_home=${HOME:?HOME must be set}
mode=dry-run
selection=all

usage() {
  cat <<'HELP'
Usage: installer/patches.sh [--dry-run | --apply] [--only hyprland | workspace | tab-shortcuts | desktop-shortcuts | screenshot-shortcuts | touchpad-scrolling | touchpad-inertia | window-focus | fcitx5 | fcitx5-shift | display]

  --dry-run   Check patch status (default)
  --apply     Back up targets and apply pending patches
  --only      Process one section; defaults to hyprland and fcitx5
              display is a separate opt-in patch for exact fractional scaling
              screenshot-shortcuts is a separate opt-in for MacBook capture keys
              touchpad-inertia is an independent, marker-controlled native plugin
              fcitx5-shift retains the original primary Left Shift profile

Before applying Hyprland patches, link customizations as listed in installer/symlinks.tsv.
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run) mode=dry-run; shift ;;
    --apply) mode=apply; shift ;;
    --only)
      selection=${2:-}
      [[ $selection == hyprland || $selection == workspace || $selection == tab-shortcuts || $selection == desktop-shortcuts || $selection == screenshot-shortcuts || $selection == touchpad-scrolling || $selection == touchpad-inertia || $selection == window-focus || $selection == fcitx5 || $selection == fcitx5-shift || $selection == display ]] || { usage >&2; exit 2; }
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

command -v patch >/dev/null || { echo 'The patch command is required.' >&2; exit 1; }
patches=()
if [[ $selection == all || $selection == hyprland ]]; then
  patches+=(installer/patches/hyprland-input.patch installer/patches/hyprland-bindings.patch installer/patches/hyprland-looknfeel.patch installer/patches/hyprland-window-focus.patch installer/patches/hyprland-desktop-shortcuts.patch installer/patches/hyprland-touchpad-scrolling.patch)
fi
[[ $selection != workspace ]] || patches+=(installer/patches/hyprland-input.patch installer/patches/hyprland-looknfeel.patch)
[[ $selection != tab-shortcuts ]] || patches+=(installer/patches/hyprland-bindings.patch)
[[ $selection != desktop-shortcuts ]] || patches+=(installer/patches/hyprland-desktop-shortcuts.patch)
[[ $selection != screenshot-shortcuts ]] || patches+=(installer/patches/hyprland-screenshot-shortcuts.patch)
[[ $selection != touchpad-scrolling ]] || patches+=(installer/patches/hyprland-touchpad-scrolling.patch)
[[ $selection != touchpad-inertia ]] || patches+=(installer/patches/hyprland-touchpad-inertia.patch)
[[ $selection != window-focus ]] || patches+=(installer/patches/hyprland-window-focus.patch)
[[ $selection != all && $selection != fcitx5 ]] || patches+=(features/keyboard-input/patches/caps-fn.patch)
[[ $selection != fcitx5-shift ]] || patches+=(features/keyboard-input/patches/shift.patch)
# Fractional pixel alignment is an explicit opt-in, separate from general Hyprland patches.
[[ $selection != display ]] || patches+=(installer/patches/hyprland-monitors.patch)
pending=()

run_patch() {
  local relative=$1
  shift
  patch --batch --fuzz=0 --no-backup-if-mismatch --reject-file=- \
    --directory="$task_home" -p1 --input="$repo_root/$relative" "$@"
}

patch_targets() {
  case "$1" in
    installer/patches/hyprland-window-focus.patch) printf '%s\n' .config/hypr/input.lua ;;
    installer/patches/hyprland-touchpad-scrolling.patch|installer/patches/hyprland-touchpad-inertia.patch) printf '%s\n' .config/hypr/input.lua ;;
    installer/patches/hyprland-input.patch) printf '%s\n' .config/hypr/input.lua ;;
    installer/patches/hyprland-bindings.patch) printf '%s\n' .config/hypr/bindings.lua ;;
    installer/patches/hyprland-desktop-shortcuts.patch) printf '%s\n' .config/hypr/bindings.lua ;;
    installer/patches/hyprland-screenshot-shortcuts.patch) printf '%s\n' .config/hypr/bindings.lua ;;
    installer/patches/hyprland-looknfeel.patch) printf '%s\n' .config/hypr/looknfeel.lua ;;
    installer/patches/hyprland-monitors.patch) printf '%s\n' .config/hypr/monitors.lua ;;
    features/keyboard-input/patches/caps-fn.patch|features/keyboard-input/patches/shift.patch)
      printf '%s\n' .config/fcitx5/config
      ;;
  esac
}

loader_module() {
  case "$1" in
    installer/patches/hyprland-window-focus.patch) echo two-finger-focus ;;
    installer/patches/hyprland-touchpad-scrolling.patch) echo touchpad-scrolling ;;
    installer/patches/hyprland-touchpad-inertia.patch) echo touchpad-inertia ;;
    installer/patches/hyprland-input.patch) echo workspace-gestures ;;
    installer/patches/hyprland-bindings.patch) echo tab-shortcuts ;;
    installer/patches/hyprland-desktop-shortcuts.patch) echo desktop-shortcuts ;;
    installer/patches/hyprland-screenshot-shortcuts.patch) echo screenshot-shortcuts ;;
    installer/patches/hyprland-looknfeel.patch) echo workspace-animation ;;
    installer/patches/hyprland-monitors.patch) echo fractional-scaling ;;
  esac
}

# Preflight every patch before writing so a conflict cannot leave a partially patched setup.
for relative in "${patches[@]}"; do
  module=$(loader_module "$relative")
  target=$(patch_targets "$relative")
  loader_pattern="^[[:space:]]*require[[:space:]]*\\([[:space:]]*['\"]hypr\\.customizations\\.${module}['\"][[:space:]]*\\)[[:space:]]*;?[[:space:]]*(--.*)?$"
  if [[ -n $module ]] && grep -Eq "$loader_pattern" "$task_home/$target"; then
    printf 'Already integrated  %s\n' "$relative"
  elif output=$(run_patch "$relative" --forward --dry-run 2>&1); then
    printf 'Pending patch  %s\n' "$relative"
    pending+=("$relative")
  elif run_patch "$relative" --reverse --dry-run >/dev/null 2>&1; then
    printf 'Already applied  %s\n' "$relative"
  else
    printf 'Patch conflicts with target configuration  %s\n%s\n' "$relative" "$output" >&2
    exit 1
  fi
done

if [[ $mode == dry-run ]]; then
  printf 'Preflight complete. Pending patches: %s.\n' "${#pending[@]}"
  exit 0
fi
if (( ${#pending[@]} == 0 )); then
  echo 'All selected patches are already active.'
  exit 0
fi

for relative in "${pending[@]}"; do
  module=$(loader_module "$relative")
  if [[ -n $module ]]; then
    module_source=$(awk -F '\t' -v target=".config/hypr/customizations/$module.lua" '$3 == target { print $2 }' "$repo_root/installer/symlinks.tsv")
    expected="$repo_root/$module_source"
    actual="$task_home/.config/hypr/customizations/$module.lua"
    if [[ ! -f $actual ]] || [[ $(realpath -- "$actual") != "$expected" ]]; then
      echo 'First link ~/.config/hypr/customizations as listed in installer/symlinks.tsv.' >&2
      exit 1
    fi
  fi
  while IFS= read -r target; do
    if [[ ! -f $task_home/$target || -L $task_home/$target ]]; then
      printf 'Patch target must be a regular configuration file  %s\n' "$task_home/$target" >&2
      exit 1
    fi
  done < <(patch_targets "$relative")
done

backup_parent="${XDG_STATE_HOME:-$task_home/.local/state}/omarchy-macbook/patch-backups"
mkdir -p -- "$backup_parent"
backup_dir=$(mktemp -d "$backup_parent/$(date +%Y%m%d-%H%M%S).XXXXXX")
for relative in "${pending[@]}"; do
  while IFS= read -r target; do
    mkdir -p -- "$backup_dir/$(dirname -- "$target")"
    cp -a -- "$task_home/$target" "$backup_dir/$target"
  done < <(patch_targets "$relative")
done

printf 'Configuration backup  %s\n' "$backup_dir"
touched=()
rollback() {
  local status=$1
  trap - ERR INT TERM
  for target in "${touched[@]}"; do
    cp -a -- "$backup_dir/$target" "$task_home/$target" || true
  done
  printf 'Patch application interrupted. Recovery attempted for touched files. Backups: %s\n' "$backup_dir" >&2
  exit "$status"
}
trap 'rollback $?' ERR
trap 'rollback 130' INT
trap 'rollback 143' TERM

for relative in "${pending[@]}"; do
  while IFS= read -r target; do
    touched+=("$target")
  done < <(patch_targets "$relative")
  run_patch "$relative" --forward
  printf 'Applied  %s\n' "$relative"
done
trap - ERR INT TERM
echo 'Patches applied. Run the reload commands in the corresponding README section.'
