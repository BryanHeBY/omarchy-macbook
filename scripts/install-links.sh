#!/usr/bin/env bash
# Install the manifest's links with preflight checks and backups of replaced entries.
# A failed installation restores the entries touched by this invocation.
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
task_home=${HOME:?HOME must be set}
mode=dry-run
selection=all

usage() {
  echo 'Usage: scripts/install-links.sh [--dry-run | --apply] [--only hyprland | fonts | shell]'
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run) mode=dry-run; shift ;;
    --apply) mode=apply; shift ;;
    --only)
      selection=${2:-}
      [[ $selection == hyprland || $selection == fonts || $selection == shell ]] || { usage >&2; exit 2; }
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

# Serialize installers before examining existing destinations.
backup_parent="${XDG_STATE_HOME:-$task_home/.local/state}/omarchy-macbook/backups"
if [[ $mode == apply ]]; then
  mkdir -p -- "$backup_parent"
  exec {lock_fd}>"$backup_parent/install.lock"
  flock "$lock_fd"
fi

sources=()
destinations=()
while IFS=$'\t' read -r source destination; do
  [[ -z $source || $source == \#* ]] && continue
  case "$selection:$source" in
    all:*|hyprland:hyprland|fonts:fonts/*|shell:omarchy/plugins/*) ;;
    *) continue ;;
  esac
  # The manifest can only name repository content and relative user config paths.
  if [[ $source == /* || $source == *..* || $destination != .config/* || $destination == *..* ]] ||
     [[ ! -e $repo_root/$source ]]; then
    printf 'Invalid symlink entry  %s -> %s\n' "$source" "$destination" >&2
    exit 1
  fi
  target="$task_home/$destination"
  if [[ -L $target && $(readlink -f -- "$target") == "$repo_root/$source" ]]; then
    printf 'Already integrated  %s\n' "$destination"
    continue
  fi
  printf 'Pending link  %s -> %s\n' "$destination" "$source"
  sources+=("$source")
  destinations+=("$destination")
done < "$repo_root/install/symlinks.tsv"

if [[ $mode == dry-run || ${#sources[@]} == 0 ]]; then
  printf 'Preflight complete. Pending symlinks: %s.\n' "${#sources[@]}"
  exit 0
fi

backup_dir=$(mktemp -d "$backup_parent/install.XXXXXX")
printf 'Configuration backup  %s\n' "$backup_dir"
touched=()
rollback() {
  local status=$1
  local index destination target
  trap - ERR INT TERM
  for index in "${touched[@]}"; do
    destination=${destinations[index]}
    target="$task_home/$destination"
    # A new link is the only object this installer creates at the destination.
    if [[ -L $target && $(readlink -- "$target") == "$repo_root/${sources[index]}" ]]; then
      rm -- "$target"
    fi
    if [[ -e $backup_dir/$destination || -L $backup_dir/$destination ]]; then
      if [[ ! -e $target && ! -L $target ]]; then
        mv -T -- "$backup_dir/$destination" "$target" || true
      fi
    fi
  done
  printf 'Installation interrupted. Recovery attempted for touched entries. Backups: %s\n' "$backup_dir" >&2
  exit "$status"
}
trap 'rollback $?' ERR
trap 'rollback 130' INT
trap 'rollback 143' TERM

for index in "${!sources[@]}"; do
  destination=${destinations[index]}
  target="$task_home/$destination"
  mkdir -p -- "$(dirname -- "$target")"
  touched+=("$index")
  if [[ -e $target || -L $target ]]; then
    mkdir -p -- "$backup_dir/$(dirname -- "$destination")"
    mv -T -- "$target" "$backup_dir/$destination"
  fi
  ln -sT -- "$repo_root/${sources[index]}" "$target"
done
trap - ERR INT TERM
echo 'Symlinks installed. Follow the README to enable the desired modules and plugins.'
