## Information
2Ship2Harkinian v1.0.1 binaries were built by fpasteau. You can build your own binaries by following the below build guide.

## Installation
You must generate your `mm.o2r` file on a PC with one of the following SHAs:

```
d6133ace5afaa0882cf214cf88daba39e266c078 - N64 US
9743aa026e9269b339eb0e3044cd5830a440c1fd - GC US
```

Legally obtain your rom and download [2Ship2Harkinian](https://github.com/HarbourMasters/2ship2harkinian/releases), then place the rom in the same folder and run the 2ship binary to generate your `mm.o2r` file. Copy it to the `ports/soh2` folder. Texture pack files can be added to the `ports/soh2/mods` folder. Logs are recorded automatically and kept in `/ports/soh2/logs`. Please provide a log if you report an issue. PortMaster does not mantain the 2Ship2Harkinian repository and is not responsible for bugs or issues outside of our control.

## Graphics Adjustments
You can open `2ship2harkinan.json` in a text editor and modify the values as you wish. If you mess up the syntax, the game will regenerate this file and your settings will be reverted to default. Please create a backup before modification. If you're running a widescreen device, you can copy `json/2ship2harkinian-ws.json` to the base folder as `2ship2harkinian.json` for a widescreen HUD.

## Menu Navigation
There is a `soh2.gptk` file you can use to change which button emulates F1 (default is L3). Controller menu navigation is not implemented yet, but you can use a mouse.

## Default Gameplay Controls
The port uses SDL controller mapping and controls can be remapped from the menu bar.

## Suggested Mods
You can find mods at https://gamebanana.com/games/20371.

## Thanks
- Nintendo for the game  
- HarbourMasters for the native pc port 
- fpasteau for the builds   
- AkerHasReawakened for the cover art  
- Testers and Devs from the PortMaster Discord  

# Building from source 2Ship2Harkinian

## Install WSL and chroot
1. 	Install wsl and ubuntu (use wsl2)
```
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common qemu-user-static debootstrap
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt install docker-ce -y
sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
sudo qemu-debootstrap --arch arm64 bookworm /mnt/data/arm64 http://deb.debian.org/debian/
```
Use bullseye instead of bookworm if building compatibility.

Note: The folder `/mnt/data/arm64` can be modified, for example to `/mnt/data/bookworm-arm64`. This is useful if you like to maintain multiple chroots.

## Enter chroot and install dependencies
```
sudo chroot /mnt/data/arm64/`
apt -y install wget gcc g++ git cmake ninja-build lsb-release libsdl2-dev libpng-dev libsdl2-net-dev libzip-dev zipcmp zipmerge ziptool nlohmann-json3-dev libtinyxml2-dev libspdlog-dev libboost-dev libopengl-dev libglew-dev
```

## Bullseye and older (newer cmake)
```
wget https://github.com/Kitware/CMake/releases/download/v3.24.4/cmake-3.24.4-linux-aarch64.sh
chmod +x cmake-3.24.4-linux-aarch64.sh
./cmake-3.24.4-linux-aarch64.sh --prefix=/usr
echo 'export PATH=/usr/cmake-3.24.4-linux-aarch64/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

\* You may need to build and install tinyxml2 from source

## Build 2Ship (Develop)
```
git clone https://github.com/HarbourMasters/2ship2harkinian
cd 2ship2harkinian
git submodule update --init
cmake -H. -B build-cmake -GNinja -DUSE_OPENGLES=1 -DCMAKE_BUILD_TYPE:STRING=Release
cmake --build build-cmake --config Release --target Generate2ShipOtr -j$(nproc)
cmake --build build-cmake --config Release -j$(nproc)
```

## Build 2Ship (Releases)
1.  `git clone https://github.com/HarbourMasters/2ship2harkinian.git`
2.  `cd 2ship2harkinian`
3.  `git checkout tags/1.0.0` -- Change this to whatever release tag you want to use
4.  `git submodule update --init`
5.  `cmake -H. -Bbuild-cmake -GNinja -DUSE_OPENGLES=1 -DCMAKE_BUILD_TYPE:STRING=Release`
6.  `cmake --build build-cmake --config Release --target Generate2ShipOtr -j$(nproc)`
7.  `cmake --build build-cmake --config Release -j$(nproc)`

## Retrieve the binaries
1.  `cd build-cmake/mm`
2.  `strip 2s2h.elf`
3.  `mv 2s2h.elf performance.elf` -- Or compatibility.elf if you built on bullseye.
4.  `mv 2s2h.o2r performance.o2r` -- Or compatibility.otr if you built on bullseye.
5.  Copy both files to `roms/ports/soh2/bin/`