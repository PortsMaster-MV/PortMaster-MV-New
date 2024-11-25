# Building from source 2Ship2Harkinian

## Install WSL and chroot
1. 	Install wsl and ubuntu (use wsl2):
```
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common qemu-user-static debootstrap
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt install docker-ce -y
sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
sudo qemu-debootstrap --arch arm64 bookworm /mnt/data/arm64 http://deb.debian.org/debian/
```

Note: The folder `/mnt/data/arm64` can be modified, for example to `/mnt/data/bookworm-arm64`. This is useful if you like to maintain multiple chroots.

## Enter chroot and install dependencies
```
sudo chroot /mnt/data/arm64/
apt -y install wget gcc g++ git cmake ninja-build lsb-release libsdl2-dev libpng-dev libsdl2-net-dev libzip-dev zipcmp zipmerge ziptool nlohmann-json3-dev libtinyxml2-dev libspdlog-dev libboost-dev libopengl-dev libglew-dev
```

## Build 2Ship (Releases)
```
git clone https://github.com/HarbourMasters/2ship2harkinian.git && cd 2ship2harkinian
git checkout tags/x.x.x
git submodule update --init --recursive
cmake -H. -Bbuild-cmake -GNinja -DUSE_OPENGLES=1 -DBUILD_CROWD_CONTROL=0 -DCMAKE_BUILD_TYPE=Release
cmake --build build-cmake --config Release --target Generate2ShipOtr -j$(nproc)
cmake --build build-cmake --config Release -j$(nproc)
```

## Retrieve the binaries
1.  `cd build-cmake/mm`
2.  `strip 2s2h.elf`
3.  Copy `2ship.o2r` and `2s2h.elf` to `roms/ports/soh2`.
5.  Copy the `build-cmake/assets` folder to `ports/soh2` and copy `build-cmake/ZAPD/ZAPD.out` to `ports/soh2/assets/extractor`.
6.  If the build is a new version open `ports/soh2/assets/extractor/otrgen` with a text editor and edit `--portVer` around Line 33.