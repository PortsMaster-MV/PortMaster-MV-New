# Building from source 2Ship2Harkinian
Use a chroot or Docker image with the included dockerfile and `docker-setup.txt`.

The included `soh2.patch` file allows compiling on Ubuntu focal without having to recompile git.

## Build Dependencies
```
rm -rf */build-soh

git clone https://github.com/libsdl-org/SDL.git
cd SDL
git checkout release-2.32.0 # was 2.26.2
mkdir -p build-soh && cd build-soh
cmake ..
make -j$(nproc)
make install
cd ../..

git clone https://github.com/nih-at/libzip.git
cd libzip
mkdir build-soh && cd build-soh
cmake ..
make -j$(nproc)
make install
cd ../..

git clone https://github.com/nlohmann/json.git
cd json
mkdir build-soh && cd build-soh
cmake ..
make -j$(nproc)
make install
cd ../..

git clone https://github.com/libarchive/bzip2.git
cd bzip2
mkdir build-soh && cd build-soh
cmake ..
make -j$(nproc)
make install
cd ../..

git clone https://github.com/leethomason/tinyxml2.git
cd tinyxml2
git checkout .
mkdir build-soh && cd build-soh
cmake -DBUILD_SHARED_LIBS=ON ..
make -j$(nproc)
make install

# prevent this file being found by cmake when SoH is compiled
cd ..
mv cmake/tinyxml2-config.cmake cmake/tinyxml2-config.cmake.disabled
cd ..
```

## Build 2Ship (Releases)
```
git clone https://github.com/HarbourMasters/2ship2harkinian.git && cd 2ship2harkinian
git checkout tags/x.x.x
git submodule update --init --recursive

# Patch for old git
cd libultraship
patch -p1 < ../../soh2.patch
cd ..

CC=clang-18 CXX=clang++-18 cmake .. -GNinja -DUSE_OPENGLES=1 -DBUILD_CROWD_CONTROL=0 -DCMAKE_BUILD_TYPE=Release
cmake --build build-cmake --config Release --target Generate2ShipOtr -j$(nproc)
cmake --build build-cmake --config Release -j$(nproc)

cd build-cmake/mm
strip 2s2h.elf
```

## Retrieve the binaries
1.  Copy `2ship.o2r` and `2s2h.elf` to `roms/ports/soh2`.
2.  Copy the `build-cmake/assets` folder to `ports/soh2` and copy `build-cmake/ZAPD/ZAPD.out` to `ports/soh2/assets/extractor`.
3.  If the build is a new version open `ports/soh2/assets/extractor/otrgen` with a text editor and edit `--portVer` around Line 33.