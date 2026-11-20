## Notes

### Information

Starship is the HarbourMasters PC port of Star Fox 64, built from the decompilation, with enhancements such as higher frame rates, widescreen support and mod support.

### Installation

You need to provide your own rom. Copy your Star Fox 64 US v1.0 or v1.1 `.z64` rom to `ports/starship/baseroms`. JP, EU and CN roms are optional and add voice packs. On first launch the rom is converted to `sf64.o2r`, which can take a few minutes.

Mods can be added to the `ports/starship/mods` folder. Logs are written to `ports/starship/log.txt`; please include it when reporting an issue.

### Launcher

A settings launcher opens before the game: frame rate, N64 low-res mode, voices and Y axis inversion. Choose Play, or wait for it to start the game.

### Thanks

- HarbourMasters for Starship, the native PC port
- The Star Fox 64 decompilation team
- Nintendo for the game
- Port by monkeyx

## Controls

| Button | Action |
|--|--|
| A | Fire / lock-on |
| B | Brake |
| X | Smart bomb |
| Y | Boost |
| L1 | Bank left |
| R1 | Bank right |
| L2 | Brake |
| R2 | Boost |
| Select | Menu |
| Start | Pause |

Double-tap L1 or R1 to barrel roll. Right stick up changes the camera view, right stick right answers your wingmen. All buttons can be remapped from the in-game menu.

## Compile

Built with [PortMaster-Build-Templates](https://github.com/monkeyx-net/PortMaster-Build-Templates) from [HarbourMasters/Starship](https://github.com/HarbourMasters/Starship). The recipe folder [recipes/ports/starship](https://github.com/monkeyx-net/PortMaster-Build-Templates/tree/main/recipes/ports/starship) holds `build.sh`, which reads `recipe.json` and applies the patches and files in that folder before running the build command:

```sh
cmake
```
