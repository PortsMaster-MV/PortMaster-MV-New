## Information
Ship of Harkinian 8.0.6 was built from the develop branch (bleeding edge) on 08/14/2024.

#### Where is the compatibility version?
The compatibility.elf version of this port was retired due to being too slow. Previous versions were tested, including fpasteau's R36S v8.0.4 binary. There is simply no point in maintaining it.

## Installation
You need to provide your own roms. See the [Shipwright](https://github.com/HarbourMasters/Shipwright/blob/develop/docs/supportedHashes.json) repository for a list of supported rom hashes. Gather your roms and put them in the `ports/soh` folder. Start the port, and on first run, your .otr files will be generated from the roms you provide. Note that only one `oot.otr` and `oot-mq.otr` will be made--if you provide more than one rom per game, strange things may occur. You *can* use pregenerated `.otr` files from elsewhere, but you may experience crashes.

Texture pack files and mods can be added to the `ports/soh/mods` folder. 

Logs are recorded automatically as `ports/soh/log.txt`. Please provide a log if you report an issue. PortMaster does not maintain the Ship of Harkinian repository and is not responsible for bugs or issues outside of our control. Likewise, HarbourMasters is not affiliated with PortMaster and this distribution is not officially supported by them. *Please come to PortMaster for help before approaching the HarbourMasters!*

## Menu Navigation
There is a `soh.gptk` file you can use to change which button emulates F1 (default is L3). Some devices have a special button called `guide` that makes for a good F1 mapping. Once you do so, make the menu bar appear, hold the north button (X or Y), press R, then press the north button again to access the menu bar navigation.

![menubar](https://github.com/JeodC/PortMaster-ShipOfHarkinian/assets/47716344/82b1de1d-11a9-49da-8500-61bc26902cbe)

The GUI may be too large or small. Navigate to `Settings->Graphics->IMGUI Menu Scale` to change it.

## Default Gameplay Controls
The port uses SDL controller mapping and controls can be remapped from the menu bar.

## Suggested Mods
You can find a ton of mods at [GameBanana](https://gamebanana.com/mods/games/16121?_aFilters%5BGeneric_Name%5D=contains%2C3ds&_sSort=Generic_MostDownloaded).  

I prefer the OoT 3DS look along with a studio ghibli style skybox:
<p float="left">
<img src="https://github.com/user-attachments/assets/821bf5b1-2c0e-4326-8d9b-6cd02cdf83dd" width="320"/> 
<img src="https://github.com/user-attachments/assets/009f80c6-99e4-4a85-94f4-a3c41ec3843d" width="320"/>
</p>
<p float="left">
<img src="https://github.com/user-attachments/assets/ef71b2e4-32ce-46e6-8e5b-5c8af908b305" width="320"/> 
<img src="https://github.com/user-attachments/assets/a391a341-922f-4637-a2af-03e32f59f38c" width="320"/>
</p>

- [Djipi's 3DS Experience](https://gamebanana.com/mods/477979)
    - delete `Djipi's 3DE - 02.otr` if using the 3ds link models below
- [3DS Adult & Young Link (just the models)](https://gamebanana.com/mods/475743)
- [Studio Ghibli Skybox](https://github.com/JeodC/PortMaster-ShipOfHarkinian/tree/main/external-mods/)

## Thanks
Nintendo for the game  
HarbourMasters for the native pc port  
fpasteau for the 8.0.4 compatibility build  
AkerHasReawakened for the cover art  
IanSantos for the ghibli skybox mod  
Testers and Devs from the PortMaster Discord  




