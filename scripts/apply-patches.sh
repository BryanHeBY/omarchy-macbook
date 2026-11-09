#!/usr/bin/env bash
# 检查或应用本仓库的局部配置补丁，保留用户配置中的其他设置。
# 默认只读检查。--apply 写入前备份，执行失败时恢复本次触及的文件。
# 软链接和 Shell 插件接入方式见 README。
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
task_home=${HOME:?HOME must be set}
mode=dry-run
selection=all

usage() {
  cat <<'HELP'
Usage: scripts/apply-patches.sh [--dry-run | --apply] [--only hyprland | fcitx5 | display]

  --dry-run   检查补丁状态，默认模式
  --apply     备份后应用尚未生效的补丁
  --only      只处理指定部分，默认处理 hyprland 和 fcitx5
              display 为精确分数缩放的独立可选补丁

Hyprland 实际应用前，需要按 install/symlinks.tsv 接入 customizations 目录。
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

command -v patch >/dev/null || { echo '缺少 patch 命令。' >&2; exit 1; }
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

# 所有补丁先通过检查，避免遇到冲突后留下部分写入的配置。
for relative in "${patches[@]}"; do
  module=$(loader_module "$relative")
  target=$(patch_targets "$relative")
  loader_pattern="^[[:space:]]*require[[:space:]]*\\([[:space:]]*['\"]hypr\\.customizations\\.${module}['\"][[:space:]]*\\)[[:space:]]*;?[[:space:]]*(--.*)?$"
  if [[ -n $module ]] && grep -Eq "$loader_pattern" "$task_home/$target"; then
    printf '已接入  %s\n' "$relative"
  elif output=$(run_patch "$relative" --forward --dry-run 2>&1); then
    printf '待应用  %s\n' "$relative"
    pending+=("$relative")
  elif run_patch "$relative" --reverse --dry-run >/dev/null 2>&1; then
    printf '已应用  %s\n' "$relative"
  else
    printf '补丁与目标配置存在冲突  %s\n%s\n' "$relative" "$output" >&2
    exit 1
  fi
done

if [[ $mode == dry-run ]]; then
  printf '检查完成，待应用补丁数为 %s。\n' "${#pending[@]}"
  exit 0
fi
if (( ${#pending[@]} == 0 )); then
  echo '所选补丁已经生效。'
  exit 0
fi

for relative in "${pending[@]}"; do
  module=$(loader_module "$relative")
  if [[ -n $module ]]; then
    expected="$repo_root/hyprland/$module.lua"
    actual="$task_home/.config/hypr/customizations/$module.lua"
    if [[ ! -f $actual ]] || [[ $(realpath -- "$actual") != "$expected" ]]; then
      echo '请先按 install/symlinks.tsv 接入 ~/.config/hypr/customizations。' >&2
      exit 1
    fi
  fi
  while IFS= read -r target; do
    if [[ ! -f $task_home/$target || -L $task_home/$target ]]; then
      printf '补丁目标需要是普通配置文件  %s\n' "$task_home/$target" >&2
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

printf '配置备份  %s\n' "$backup_dir"
touched=()
rollback() {
  local status=$1
  trap - ERR INT TERM
  for target in "${touched[@]}"; do
    cp -a -- "$backup_dir/$target" "$task_home/$target" || true
  done
  printf '应用中断，已尝试恢复本次触及的文件。备份位于 %s\n' "$backup_dir" >&2
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
  printf '已完成  %s\n' "$relative"
done
trap - ERR INT TERM
echo '补丁应用完成。按 README 的对应部分执行重载命令。'
