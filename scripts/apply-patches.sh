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
Usage: scripts/apply-patches.sh [--dry-run | --apply] [--only hyprland | fcitx5 | display]

  --dry-run   Check patch status (default)
  --apply     Back up targets and apply pending patches
  --only      Process one section; defaults to hyprland and fcitx5
              display is a separate opt-in patch for exact fractional scaling

Before applying Hyprland patches, link customizations as listed in install/symlinks.tsv.
HELP
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run) mode=dry-run; shift ;;
    --apply) mode=apply; shift ;;
    --only)
      selection=${2:-}
      [[ $selection == hyprland || $selection == fcitx5 || $selection == display ]] || { usage >&2; exit 2; }
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

command -v patch >/dev/null || { echo 'The patch command is required.' >&2; exit 1; }
patches=()
if [[ $selection == all || $selection == hyprland ]]; then
  patches+=(patches/hyprland-input.patch patches/hyprland-bindings.patch patches/hyprland-looknfeel.patch)
fi
[[ $selection != all && $selection != fcitx5 ]] || patches+=(input-method/fcitx5-hotkeys.patch)
# Fractional pixel alignment is an explicit opt-in, separate from general Hyprland patches.
[[ $selection != display ]] || patches+=(patches/hyprland-monitors.patch)
pending=()

run_patch() {
  local relative=$1
  shift
  patch --batch --fuzz=0 --no-backup-if-mismatch --reject-file=- \
    --directory="$task_home" -p1 --input="$repo_root/$relative" "$@"
}

patch_targets() {
  case "$1" in
    patches/hyprland-input.patch) printf '%s\n' .config/hypr/input.lua ;;
    patches/hyprland-bindings.patch) printf '%s\n' .config/hypr/bindings.lua ;;
    patches/hyprland-looknfeel.patch) printf '%s\n' .config/hypr/looknfeel.lua ;;
    patches/hyprland-monitors.patch) printf '%s\n' .config/hypr/monitors.lua ;;
    input-method/fcitx5-hotkeys.patch)
      printf '%s\n' .config/fcitx5/config
      ;;
  esac
}

loader_module() {
  case "$1" in
    patches/hyprland-input.patch) echo workspace-gestures ;;
    patches/hyprland-bindings.patch) echo tab-shortcuts ;;
    patches/hyprland-looknfeel.patch) echo workspace-animation ;;
    patches/hyprland-monitors.patch) echo fractional-scaling ;;
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
    expected="$repo_root/hyprland/$module.lua"
    actual="$task_home/.config/hypr/customizations/$module.lua"
    if [[ ! -f $actual ]] || [[ $(realpath -- "$actual") != "$expected" ]]; then
      echo 'First link ~/.config/hypr/customizations as listed in install/symlinks.tsv.' >&2
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

backup_parent="${XDG_STATE_HOME:-$task_home/.local/state}/omarchy-configs/patch-backups"
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
