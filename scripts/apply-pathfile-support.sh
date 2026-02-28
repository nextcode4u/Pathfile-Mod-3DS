#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

apply_patch_if_needed() {
  local name="$1"
  local repo_path="$2"
  local patch_path="$3"

  if [[ ! -e "$repo_path/.git" ]]; then
    echo "[skip] $name: repo not found at $repo_path"
    return 0
  fi

  if git -C "$repo_path" apply --check "$patch_path" >/dev/null 2>&1; then
    git -C "$repo_path" apply "$patch_path"
    echo "[ok]   $name: patch applied"
    return 0
  fi

  if git -C "$repo_path" apply --reverse --check "$patch_path" >/dev/null 2>&1; then
    echo "[ok]   $name: patch already present"
    return 0
  fi

  echo "[err]  $name: patch could not be applied cleanly"
  return 1
}

apply_patch_if_needed \
  "DaedalusX64-3DS" \
  "$ROOT_DIR/external/DaedalusX64-3DS" \
  "$ROOT_DIR/patches/daedalusx64-pathfile.patch"

apply_patch_if_needed \
  "snes9x_3ds" \
  "$ROOT_DIR/external/snes9x_3ds" \
  "$ROOT_DIR/patches/snes9x-pathfile.patch"

apply_patch_if_needed \
  "mGBA" \
  "$ROOT_DIR/external/mgba" \
  "$ROOT_DIR/patches/mgba-pathfile.patch"
