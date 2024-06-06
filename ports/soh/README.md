## Installation
CAREFULLY follow the guide at the [Ship of Harkinian website](https://www.shipofharkinian.com/setup-guide) for your desired platform to create your oot.otr and/or oot-mq.otr files. Once created put in the `ports/soh` folder. Texture pack files can be added to the `ports/soh/mods` folder. 
Logs are recorded automatically and kept in `/ports/soh/logs`. Please provide a log if you report an issue. PortMaster does not mantain the Ship of Harkinian repository and is not responsible for bugs or issues outside of our control.

## Menu Navigation
There is a `soh.gptk` file you can use to change which button emulates F1 (default is L3). Once you do so, make the menu bar appear, hold the north button (X or Y), press R, then press the north button again to access the menu bar navigation.

![menubar](https://github.com/JeodC/PortMaster-ShipOfHarkinian/assets/47716344/82b1de1d-11a9-49da-8500-61bc26902cbe)

The GUI may be too large or small. Navigate to Settings->Graphics->IMGUI Menu Scale to change it.

## Default Gameplay Controls
The port uses SDL controller mapping and controls can be remapped from the menu bar.

## Suggested Mods
You can find a ton of mods at [GameBanana](https://gamebanana.com/mods/games/16121?_aFilters%5BGeneric_Name%5D=contains%2C3ds&_sSort=Generic_MostDownloaded).  

I prefer the OoT 3DS look along with a studio ghibli style skybox:
- [Djipi's 3DS Experience](https://gamebanana.com/mods/477979)
- [3DS Adult & Young Link (just the models)](https://gamebanana.com/mods/475743)
- [OOT3D Link Textures](https://gamebanana.com/mods/478711)
- [Studio Ghibli Skybox](https://www.iansantosart.com/zeldaoot)

## Thanks
Nintendo for the game  
HarbourMasters for the native pc port  
fpasteau for the builds  
AkerHasReawakened for the cover art  
Testers and Devs from the PortMaster Discord  

# Building from source Ship of Harkinian

## Install WSL and chroot
1. 	Install wsl and ubuntu (use wsl2)
2. 	`sudo apt update`
3.	`sudo apt install -y apt-transport-https ca-certificates curl software-properties-common qemu-user-static debootstrap`
4.	`curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -`
5.	`sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"`
6.	`sudo apt install docker-ce -y`
7.	`sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`
8.	`sudo qemu-debootstrap --arch arm64 bookworm /mnt/data/arm64 http://deb.debian.org/debian/` -- Use bullseye instead of bookworm if building compatibility.

Note: The folder `/mnt/data/arm64` can be modified, for example to `/mnt/data/bookworm-arm64`. This is useful if you like to maintain multiple chroots.

## Enter chroot and install dependencies
1. 	`sudo chroot /mnt/data/arm64/`
2.  `apt -y install gcc g++ git cmake ninja-build lsb-release libsdl2-dev libpng-dev libsdl2-net-dev libzip-dev zipcmp zipmerge ziptool nlohmann-json3-dev libtinyxml2-dev libspdlog-dev libboost-dev libopengl-dev libglew-dev`

## Build Shipwright (Develop)
1.  `git clone https://github.com/HarbourMasters/Shipwright.git`
2.  `cd Shipwright`
3.  `git submodule update --init`
4.  `cmake -H. -B build-cmake -GNinja -DUSE_OPENGLES=1 -DCMAKE_BUILD_TYPE:STRING=Release`
5.  `cmake --build build-cmake --config Release --target GenerateSohOtr`
6.  `cmake --build build-cmake --config Release -j$(nproc)`

## Build Shipwright (Releases)
1.  `git clone https://github.com/HarbourMasters/Shipwright.git`
2.  `cd Shipwright`
3.  `git checkout tags/8.0.5` -- Change this to whatever release tag you want to use
4.  `git submodule update --init`
5.  `cmake -H. -Bbuild-cmake -GNinja -DUSE_OPENGLES=1 -DCMAKE_BUILD_TYPE:STRING=Release`
6.  `cmake --build build-cmake --config Release --target GenerateSohOtr`
7.  `cmake --build build-cmake --config Release -j$(nproc)`

## Retrieve the binaries
1.  `cd build-cmake/soh`
2.  `strip soh.elf`
3.  `mv soh.elf performance.elf` -- Or compatibility.elf if you built on bullseye.
4.  `mv soh.otr performance.otr` -- Or compatibility.otr if you built on bullseye.
5.  Copy both files to `roms/ports/soh/bin/`



