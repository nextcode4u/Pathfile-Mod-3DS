# Pathfile Mod 3DS

Pathfile Mod 3DS adds **pathfile-based auto-launch** support to 3DS emulator builds so a frontend can launch a selected ROM without showing the emulator file picker.

## What This Project Does

This repository tracks upstream emulator sources (as submodules) and applies pathfile launch support for:

- **DaedalusX64-3DS** (N64)
- **snes9x_3ds** (SNES)
- **mGBA** (GBA)

A frontend writes a ROM path into a known text file, launches the emulator, and the emulator auto-loads that ROM.

## Linked Repositories

Forks used by this project:

- DaedalusX64-3DS: https://github.com/nextcode4u/DaedalusX64-3DS
- snes9x_3ds: https://github.com/nextcode4u/snes9x_3ds
- mGBA: https://github.com/nextcode4u/mgba

Original upstream projects:

- DaedalusX64-3DS: https://github.com/masterfeizz/DaedalusX64-3DS
- snes9x_3ds: https://github.com/matbo87/snes9x_3ds
- mGBA: https://github.com/mgba-emu/mgba

## Pathfile Format

Pathfiles live on SD at:

- `sdmc:/pathfile/gba_launch.txt`
- `sdmc:/pathfile/snes_launch.txt`
- `sdmc:/pathfile/n64_launch.txt`

Each file should contain a single absolute ROM path, for example:

```txt
sdmc:/roms/gba/Metroid Fusion.gba
```

If a pathfile is missing, empty, or invalid, behavior falls back to each emulator's normal flow.

## Repository Layout

- `external/` upstream emulator submodules
- `patches/` reusable patch files for pathfile support
- `scripts/apply-pathfile-support.sh` reapplies pathfile patches after submodule updates
- `scripts/build-all.sh` builds all emulators and collects artifacts
- `scripts/write-pathfile.sh` helper to write launch files

## Clone

```bash
git clone --recurse-submodules <repo-url>
cd Pathfile-Mod-3DS
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

## Reapply Patches (After Upstream Sync)

```bash
./scripts/apply-pathfile-support.sh
```

## Build

Build all supported targets and collect outputs in `builds/`:

```bash
./scripts/build-all.sh
```

Build logs are written to `builds/logs/`.

## Build Outputs

Artifacts are copied to:

- `builds/daedalusx64/`
- `builds/snes9x_3ds/`
- `builds/mgba/`

Status summary is written to:

- `builds/STATUS.txt`

## Write Pathfiles Quickly

```bash
./scripts/write-pathfile.sh gba "sdmc:/roms/gba/Metroid Fusion.gba"
./scripts/write-pathfile.sh snes "sdmc:/roms/snes/Super Metroid.sfc"
./scripts/write-pathfile.sh n64 "sdmc:/roms/n64/Star Fox 64.z64"
```

Optional override for output directory (for testing on host):

```bash
PATHFILE_DIR=/tmp/pathfile ./scripts/write-pathfile.sh gba "sdmc:/roms/gba/Metroid Fusion.gba"
```

## Notes

- This repo is intended for frontend-driven launching via pathfiles.
- Some upstream toolchain combinations may produce different artifact sets (for example `.elf` only for some targets if packaging tools are unavailable).
- Upstream emulator code is maintained in their own repositories; this project layers launch integration on top.

## License And Attribution

This project modifies and redistributes code from multiple emulator projects. Each emulator keeps its own license terms:

- DaedalusX64-3DS: GNU GPL (see `external/DaedalusX64-3DS/copying.txt`)
- mGBA: Mozilla Public License 2.0 (see `external/mgba/LICENSE`)
- snes9x_3ds: Snes9x license text in source (see `external/snes9x_3ds/source/Snes9x/copyright.h`)

When distributing builds from this repository:

- Keep all original copyright and license notices.
- Provide corresponding source code for your modified binaries, including your patches.
- Include the license texts above with your release package.
- Follow Snes9x non-commercial terms unless you have separate permission from rights holders.
