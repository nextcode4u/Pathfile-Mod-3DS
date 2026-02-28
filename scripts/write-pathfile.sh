#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <gba|snes|n64> <rom_path>"
  exit 1
fi

core="$1"
rom_path="$2"

case "$core" in
  gba) file_name="gba_launch.txt" ;;
  snes) file_name="snes_launch.txt" ;;
  n64) file_name="n64_launch.txt" ;;
  *)
    echo "Invalid core '$core'. Use: gba, snes, n64"
    exit 1
    ;;
esac

pathfile_dir="${PATHFILE_DIR:-/pathfile}"
mkdir -p "$pathfile_dir"
printf '%s\n' "$rom_path" > "$pathfile_dir/$file_name"

echo "Wrote $pathfile_dir/$file_name"
