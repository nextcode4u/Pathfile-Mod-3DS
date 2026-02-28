#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_OUT="$ROOT_DIR/builds"
LOG_DIR="$BUILD_OUT/logs"
JOBS="${JOBS:-$(nproc)}"

export DEVKITPRO="${DEVKITPRO:-/opt/devkitpro}"
export DEVKITARM="${DEVKITARM:-$DEVKITPRO/devkitARM}"
export PATH="$DEVKITARM/bin:$DEVKITPRO/tools/bin:$ROOT_DIR/external/snes9x_3ds/makerom/linux_x86_64:$PATH"

mkdir -p "$BUILD_OUT" "$LOG_DIR"
STATUS_FILE="$BUILD_OUT/STATUS.txt"
: > "$STATUS_FILE"

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool"
    return 1
  fi
}

copy_artifacts() {
  local from_dir="$1"
  local to_dir="$2"
  mkdir -p "$to_dir"
  find "$from_dir" -maxdepth 2 -type f \( -name '*.3dsx' -o -name '*.cia' -o -name '*.elf' -o -name '*.3ds' -o -name '*.smdh' \) -exec cp -f {} "$to_dir" \;
}

build_daedalus() {
  local name="daedalusx64"
  local src="$ROOT_DIR/external/DaedalusX64-3DS"
  local build_dir="$src/daedbuild"
  local out_dir="$BUILD_OUT/$name"

  echo "[build] $name"
  rm -rf "$build_dir"
  cmake -S "$src/Source" -B "$build_dir" \
    -DCTR_RELEASE=1 \
    -DCMAKE_TOOLCHAIN_FILE="$src/Tools/3dstoolchain.cmake" \
    -G "Unix Makefiles" \
    >"$LOG_DIR/$name-cmake.log" 2>&1 || return 1
  cmake --build "$build_dir" -- -j"$JOBS" >"$LOG_DIR/$name-make.log" 2>&1 || return 1

  rm -rf "$out_dir"
  copy_artifacts "$build_dir" "$out_dir"
}

build_snes9x() {
  local name="snes9x_3ds"
  local src="$ROOT_DIR/external/snes9x_3ds"
  local out_dir="$BUILD_OUT/$name"

  echo "[build] $name"
  make -C "$src" clean >"$LOG_DIR/$name-clean.log" 2>&1 || true
  make -C "$src" -j"$JOBS" 3dsx cia elf >"$LOG_DIR/$name-make.log" 2>&1 || return 1

  rm -rf "$out_dir"
  copy_artifacts "$src/output" "$out_dir"
}

build_mgba() {
  local name="mgba"
  local src="$ROOT_DIR/external/mgba"
  local build_dir="$src/build-3ds"
  local out_dir="$BUILD_OUT/$name"

  echo "[build] $name"
  rm -rf "$build_dir"
  cmake -S "$src" -B "$build_dir" \
    -DCMAKE_TOOLCHAIN_FILE="$src/src/platform/3ds/CMakeToolchain.txt" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_QT=OFF \
    -DBUILD_SDL=OFF \
    -DBUILD_LIBRETRO=OFF \
    -G "Unix Makefiles" \
    >"$LOG_DIR/$name-cmake.log" 2>&1 || return 1
  # Build the 3DS frontend ELF even when bannertool isn't available for CIA/3DSX packaging.
  cmake --build "$build_dir" --target mgba.elf -- -j"$JOBS" >"$LOG_DIR/$name-make.log" 2>&1 || return 1

  # Generate .3dsx without bannertool by creating .smdh via smdhtool.
  local mgba_elf="$build_dir/3ds/mgba.elf"
  local mgba_smdh="$build_dir/3ds/mgba.smdh"
  local mgba_3dsx="$build_dir/3ds/mgba.3dsx"
  if [[ -f "$mgba_elf" ]]; then
    smdhtool --create "mGBA" "mGBA for 3DS" "mGBA Team" "$src/res/mgba-48.png" "$mgba_smdh" >>"$LOG_DIR/$name-make.log" 2>&1 || return 1
    3dsxtool "$mgba_elf" "$mgba_3dsx" --smdh="$mgba_smdh" >>"$LOG_DIR/$name-make.log" 2>&1 || return 1
  fi

  rm -rf "$out_dir"
  copy_artifacts "$build_dir" "$out_dir"
}

TOOLING_OK=1
for tool in cmake make arm-none-eabi-gcc 3dsxtool makerom smdhtool; do
  if ! require_tool "$tool"; then
    TOOLING_OK=0
    echo "[fail] missing tool: $tool" | tee -a "$STATUS_FILE"
  fi
done

if [[ "$TOOLING_OK" -eq 0 ]]; then
  echo "[done] Build stopped due to missing required tools. See $STATUS_FILE"
  exit 1
fi

run_build() {
  local label="$1"
  shift
  if "$@"; then
    echo "[ok]   $label" | tee -a "$STATUS_FILE"
  else
    echo "[fail] $label (see $LOG_DIR)" | tee -a "$STATUS_FILE"
  fi
}

run_build "DaedalusX64-3DS" build_daedalus
run_build "snes9x_3ds" build_snes9x
run_build "mGBA (ELF target)" build_mgba

echo "[done] Build outputs: $BUILD_OUT"
find "$BUILD_OUT" -maxdepth 3 -type f | sort
