## Notes

### Information

Lighthouse is the HarbourMasters PC port of Banjo-Kazooie, built from the decompilation, with Anchor online co-op, romhack and multi-language support, and a built-in randomizer.

### Installation

You need to provide your own rom. Copy your Banjo-Kazooie `.z64` rom (US v1.0, US v1.1, JP or PAL) to `ports/lighthouse/baseroms`. `.n64` roms must be converted to `.z64` first. On first launch the rom is converted to `bk.o2r`, which can take a few minutes; choose No at "Run Lighthouse?" when it finishes and the game restarts automatically.

Extra languages (PAL: UK, French, German; JP: Japanese) can be extracted from another rom in the in-game menu under General -> Languages. Mods and romhacks (`.o2r`/`.otr`) go in the `ports/lighthouse/mods` folder. Logs are written to `ports/lighthouse/log.txt`; please include it when reporting an issue.

### Launcher

A settings launcher opens before the game: Anchor player name and room ID, frame rate, N64 low-res mode, VSync and aspect ratio. Choose Play, or wait for it to start the game.

### Thanks

- HarbourMasters for Lighthouse, the native PC port
- The Banjo-Kazooie decompilation team
- Fredomato and scorched11 for the randomizer
- Rare and Nintendo for the game
- Port by monkeyx

## Controls

Default Retro (N64) layout:

| Button | Action |
|--|--|
| A | Jump |
| B | Attack |
| L1 | L |
| L2 | Crouch |
| R2 | Camera |
| Right stick | C-buttons |
| D-pad | D-pad |
| Start | Start |
| Select | Menu |
| L3 | Menu bar |
| R3 | Alt assets |

L2 is the N64 Z button and R2 is R (center camera). X, Y and R1 are unused in this layout. The Modern (Xbox Live Arcade) and Pocket (D-pad friendly) layouts can be chosen under Control Scheme in the controls settings, and all buttons can be remapped there.

## Compile

Built with [PortMaster-Build-Templates](https://github.com/monkeyx-net/PortMaster-Build-Templates) from [HarbourMasters/Lighthouse](https://github.com/HarbourMasters/Lighthouse). The recipe folder [recipes/ports/lighthouse](https://github.com/monkeyx-net/PortMaster-Build-Templates/tree/main/recipes/ports/lighthouse) holds `build.sh`, which reads `recipe.json` and applies the patches and files in that folder before running the build command:

```sh
cmake
```
