# Building from source Ship of Harkinian

## Install WSL and chroot
1. 	Install wsl and ubuntu (use wsl2), and once installed and started:
```
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common qemu-user-static debootstrap
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt install docker-ce -y
sudo docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
sudo qemu-debootstrap --arch arm64 bookworm /mnt/data/arm64 http://deb.debian.org/debian/
```

## Enter chroot and install dependencies
```
sudo chroot /mnt/data/arm64/
apt -y install gcc g++ git cmake ninja-build lsb-release libsdl2-dev libpng-dev libsdl2-net-dev libzip-dev zipcmp zipmerge ziptool nlohmann-json3-dev libtinyxml2-dev libspdlog-dev libboost-dev libopengl-dev libglew-dev
```

## Build Shipwright
```
git clone --recursive https://github.com/HarbourMasters/Shipwright.git && cd Shipwright
git checkout tags/x.x.x
cmake -H. -Bbuild-cmake -GNinja -DUSE_OPENGLES=1 -DBUILD_CROWD_CONTROL=0 -DCMAKE_BUILD_TYPE=Release
cmake --build build-cmake --config Release --target GenerateSohOtr
cmake --build build-cmake --config Release -j$(nproc)
```

## Retrieve the binaries
```
cd build-cmake/soh
strip soh.elf
```

- Copy `soh.elf` and `soh.otr` to `roms/ports/soh/x.x.x/` where `x.x.x` matches the version you built.
- Copy the `build-cmake/assets` folder to `ports/soh/x.x.x/` and copy `build-cmake/ZAPD/ZAPD.out` to `ports/soh/x.x.x/assets/extractor`.
- If the build is a new version open `ports/soh/x.x.x/assets/extractor/otrgen` with a text editor and edit `--portVer` around Line 50 to match the release version you pulled.
