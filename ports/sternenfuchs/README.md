## Notes

Thanks to KandoWontU for [Star Fox Enhanced](https://archive.softwareheritage.org/swh:1:rev:6612cb05e4bda0a5e25e8e805d64d0e3db50896a;origin=https://github.com/kandowontu/starfox-enhanced)
(original repository since deleted; link points to the Software Heritage archive),
the open-source native runtime this port packages, and to Team SFEX
(Star Fox EX) and SunlitSpace542 (UltraStarFox) for the community projects it
builds on. Thanks to bmdhacks for the SDL3-to-SDL2 backend shim.

No Nintendo ROM or ROM-derived data is included. Copy your own legally
obtained Star Fox/Starwing `.sfc` or `.smc` ROM (USA, Japan or Europe retail
revision) into `ports/sternenfuchs/`. On first launch the game builds
`Starfox-Assets.BIN` from it.

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
upstream's [CREDITS.md](https://archive.softwareheritage.org/swh:1:rev:6612cb05e4bda0a5e25e8e805d64d0e3db50896a;origin=https://github.com/kandowontu/starfox-enhanced;path=/CREDITS.md).

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
