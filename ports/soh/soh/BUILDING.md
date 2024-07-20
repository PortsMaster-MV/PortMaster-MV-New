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
```
git clone https://github.com/HarbourMasters/Shipwright.git
cd Shipwright
git submodule update --init
cmake -H. -B build-cmake -GNinja -DUSE_OPENGLES=1 -DCMAKE_BUILD_TYPE:STRING=Release
cmake --build build-cmake --config Release --target GenerateSohOtr
cmake --build build-cmake --config Release -j$(nproc)
```

## Build Shipwright (Releases)
```
git clone https://github.com/HarbourMasters/Shipwright.git
cd Shipwright
git checkout tags/x.x.x
git submodule update --init
cmake -H. -Bbuild-cmake -GNinja -DUSE_OPENGLES=1 -DCMAKE_BUILD_TYPE:STRING=Release
cmake --build build-cmake --config Release --target GenerateSohOtr
cmake --build build-cmake --config Release -j$(nproc)
```

## Retrieve the binaries
1.  `cd build-cmake/soh`
2.  `strip soh.elf`
3.  `mv soh.elf performance.elf` -- Or compatibility.elf if you built on bullseye.
4.  Copy the `.elf` to `roms/ports/soh/bin/` and copy `soh.otr` to `roms/ports/soh`.
5.  Copy the `build-cmake/assets` folder to `ports/soh` and copy `build-cmake/ZAPD/ZAPD.out` to `ports/soh/assets/extractor`.
6.  If the build is a new version open `ports/soh/assets/extractor/otrgen.txt` and edit `--portVer` around Line 50.