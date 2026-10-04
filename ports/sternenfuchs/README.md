## Notes

Thanks to KandoWontU for [Star Fox Enhanced](https://github.com/kandowontu2/starfox-enhanced),
the open-source native runtime this port packages, and to Team SFEX
(Star Fox EX) and SunlitSpace542 (UltraStarFox) for the community projects it
builds on. Thanks to bmdhacks for the SDL3-to-SDL2 backend shim.

No Nintendo ROM or ROM-derived data is included. Copy your own legally
obtained Star Fox/Starwing `.sfc` or `.smc` ROM (USA, Japan or Europe retail
revision) into the `ports/sternenfuchs/` folder, where the `your rom here.txt`
file marks the spot (e.g. `/roms/ports/sternenfuchs/` on KNULLI). On first
launch the game builds `Starfox-Assets.BIN` from it.

Supported unmodified retail dumps (No-Intro names; a 512-byte copier header
is fine). The launcher and game check the CRC32:

| ROM | CRC32 |
| --- | ----- |
| Star Fox (USA) | `0bae0941` |
| Star Fox (USA) (Rev 1) | `b18676b2` |
| Star Fox (USA) (Rev 2) | `8fc4e6d0` |
| Star Fox (Japan) | `41a60b3f` |
| Star Fox (Japan) (Rev 1) | `ad668a41` |
| Starwing (Europe) | `865f1a71` |
| Starwing (Europe) (Rev 1) | `ba64da2b` |
| Starwing (Germany) | `b48ca238` |

Tested with Star Fox (USA): SHA-1 `1f5355534ccfaf26ae6c8f055f3e4768f9d72a7e`,
MD5 `9dce6a9dcbe4e304d67b9e8fd8999e7e`.

Expect roughly 30-45 FPS in flight on H700-class devices; game speed stays
correct regardless.

Third-party licenses are in `sternenfuchs/licenses/`; full credits are in
upstream's [CREDITS.md](https://github.com/kandowontu2/starfox-enhanced/blob/main/CREDITS.md).

## Controls

Buttons map to the SNES buttons with the same label. The in-game controls
menu can remap them.

| Button | Action |
| ------ | ------ |
| D-PAD / Left stick | SNES D-pad |
| A / B / X / Y | SNES A / B / X / Y |
| L1 / R1 | SNES L / R |
| SELECT | SNES Select |
| START | SNES Start |
| SELECT + START | Quit |

## Compiling

The binary is built from source by `scripts/build-arm64.sh` in
[mtoensing/sternenfuchs](https://github.com/mtoensing/sternenfuchs) (branch
`prototype/rg40xx`). It targets aarch64 and needs glibc 2.35 or older at
runtime, so build on Ubuntu 22.04 arm64 (CI uses `ubuntu:22.04` on
`ubuntu-24.04-arm`).

```bash
apt-get install -y ca-certificates git curl cmake ninja-build build-essential \
  python3 zip file binutils pkg-config
git clone -b prototype/rg40xx https://github.com/mtoensing/sternenfuchs.git
cd sternenfuchs
./scripts/build-arm64.sh
```

The script:

1. Clones Star Fox Enhanced from `kandowontu2/starfox-enhanced` and checks out
   the pinned commit `6612cb05e4bda0a5e25e8e805d64d0e3db50896a` (see
   `scripts/versions.sh`). To build from your own clone or mirror that
   contains the commit, set `STARFOX_REPO` to its URL or path.
2. Builds the pinned `bmdhacks/SDL` SDL3-to-SDL2 shim (`libSDL3.so.0`) and
   installs it into a private prefix. Vulkan is off.
3. Applies `patches/0001-system-sdl3.patch` and
   `patches/0002-software-renderer-fallback.patch` to the game source.
4. Builds `starfox_pc` with `-mcpu=cortex-a53`, LTO and the committed
   profile-guided optimization data in `pgo-data/`.
5. Packages `dist/sternenfuchs.zip` (sideload layout) and
   `dist/sternenfuchs-pr.zip` (PortMaster submission layout).

The port ships two binaries: `starfox.aarch64` and `libs.aarch64/libSDL3.so.0`.
