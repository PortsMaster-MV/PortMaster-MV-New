## Information
Starship was built from GitHub Actions at the [HM64 Autobuild Factory](https://github.com/JeodC/hm64-builder).

## Installation
The supported ROMs are:
- US 1.0
- US 1.1
- JP 1.0 (JP Voices only)
- EU 1.0 (Lylat Voices only)
- CN 1.1

 You can verify you have dumped a supported copy of the game by using the SHA-1 File Checksum Online at https://www.romhacking.net/hash/. The hash for a US 1.1 ROM is SHA-1: 09F0D105F476B00EFA5303A3EBC42E60A7753B7A.

Legally obtain your rom and place it in `ports/starship`, then start the port. Texture pack files can be added to the `ports/starship/mods` folder.

Logs are recorded automatically as `ports/starship/log.txt`. Please provide a log if you report an issue. PortMaster does not maintain the Starship repository and is not responsible for bugs or issues outside of our control. Likewise, HarbourMasters is not affiliated with PortMaster and this distribution is not officially supported by them. *Please come to PortMaster for help before approaching the HarbourMasters!*

## Menu Navigation
There is a `starship.gptk` file you can use to change which button emulates F1 (default is L3). Some devices have a special button called `guide` that makes for a good F1 mapping.

## Japan / EU Audio Language
The menu has an option in `Settings->Language` where you can choose to install JP/EU Audio. **This will crash the port** because our supported devices are incompatible with the file explorer ui Starship uses. There is a way around this.

#### Generate audio from PC
Load Starship on a PC and use it to generate the audio you wish to use. Gather your ROM and use https://hack64.net/tools/swapper.php to convert it to .z64 format if it is not already. Audio will be generated to the `mods` folder as either `sf64eu.o2r` or `sf64jp.o2r`. The following are the differences:

- EU: English or Lylatese gibberish voices
- JP: Japanese voices

## Adding Mods
Mods are available at the port's [Gamebanana Page](https://gamebanana.com/games/21612).

## Default Gameplay Controls
The port uses SDL controller mapping and controls can be remapped from the menu bar.

## Thanks
- Nintendo for the game  
- HarbourMasters for the native pc port  
- Testers and Devs from the PortMaster Discord  




