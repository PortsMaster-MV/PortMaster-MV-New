## Information
2Ship2Harkinian binaries were built from the develop branch (bleeding edge) on 08/14/2024. You can build your own binaries by following the [BUILDING.md guide](soh2/BUILDING.md).

## Installation
You must generate your `mm.o2r` file with a rom that has one of the following SHAs:

```
d6133ace5afaa0882cf214cf88daba39e266c078 - N64 US
9743aa026e9269b339eb0e3044cd5830a440c1fd - GC US
```

You can verify your rom at https://2ship.equipment.

Legally obtain your rom and place it in `ports/soh2`, then start the port. Texture pack files can be added to the `ports/soh2/mods` folder.

Logs are recorded automatically as `ports/soh/log.txt`. Please provide a log if you report an issue. PortMaster does not maintain the 2Ship2Harkinian repository and is not responsible for bugs or issues outside of our control. Likewise, HarbourMasters is not affiliated with PortMaster and this distribution is not officially supported by them. *Please come to PortMaster for help before approaching the HarbourMasters!*

## Graphics Adjustments
You can open `2ship2harkinan.json` in a text editor and modify the values as you wish. If you mess up the syntax, the game will regenerate this file and your settings will be reverted to default. Please create a backup before modification.

## Menu Navigation
There is a `soh2.gptk` file you can use to change which button emulates F1 (default is L3). Some devices have a special button called `guide` that makes for a good F1 mapping.

## Default Gameplay Controls
The port uses SDL controller mapping and controls can be remapped from the menu bar.

## Suggested Mods
You can find mods at https://gamebanana.com/games/20371.

The [MM Reloaded](https://github.com/GhostlyDark/MM-Reloaded-2S2H) texture pack is in a prerelease state at time of writing, but it works. I recommend using the HD version, as the 4k version won't make much difference on the retro handhelds. Add the pack to `soh2/mods`, and either have the line `"gAltAssets": 1,` in your json or assign `TAB` to a button in the `soh2.gptk` file (default R3).

## Thanks
- Nintendo for the game  
- HarbourMasters for the native pc port  
- AkerHasReawakened for the cover art  
- Testers and Devs from the PortMaster Discord  




