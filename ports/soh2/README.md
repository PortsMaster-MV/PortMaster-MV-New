## Information
2Ship2Harkinian v1.0.2 binaries built on 07/18/2024. You can build your own binaries by following the [BUILDING.md guide](BUILDING.md).

## Installation
You must generate your `mm.o2r` file with a rom that has one of the following SHAs:

```
d6133ace5afaa0882cf214cf88daba39e266c078 - N64 US
9743aa026e9269b339eb0e3044cd5830a440c1fd - GC US
```

Legally obtain your rom and place it in the `ports/soh2`, then start the port. Texture pack files can be added to the `ports/soh2/mods` folder.

Logs are recorded automatically as `ports/soh/log.txt`. Please provide a log if you report an issue. PortMaster does not maintain the Ship of Harkinian repository and is not responsible for bugs or issues outside of our control. Likewise, HarbourMasters is not affiliated with PortMaster and this distribution is not officially supported by them. *Please come to PortMaster for help before approaching the HarbourMasters!*

## Graphics Adjustments
You can open `2ship2harkinan.json` in a text editor and modify the values as you wish. If you mess up the syntax, the game will regenerate this file and your settings will be reverted to default. Please create a backup before modification. If you're running a widescreen device, you can copy `json/2ship2harkinian-ws.json` to the base folder as `2ship2harkinian.json` for a widescreen HUD.

## Menu Navigation
There is a `soh2.gptk` file you can use to change which button emulates F1 (default is L3). Once you do so, make the menu bar appear, hold the north button (X or Y), press R, then press the north button again to access the menu bar navigation.

## Default Gameplay Controls
The port uses SDL controller mapping and controls can be remapped from the menu bar.

## Suggested Mods
You can find mods at https://gamebanana.com/games/20371.

## Thanks
- Nintendo for the game  
- HarbourMasters for the native pc port  
- AkerHasReawakened for the cover art  
- Testers and Devs from the PortMaster Discord  




