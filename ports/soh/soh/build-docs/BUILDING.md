# Building from source Ship of Harkinian
Use a chroot or Docker image with the included dockerfile and `docker-setup.txt`.

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

## Build Shipwright
```
git clone --recursive https://github.com/HarbourMasters/Shipwright.git && cd Shipwright
CC=clang-18 CXX=clang++-18 cmake .. -GNinja -DUSE_OPENGLES=1 -DBUILD_CROWD_CONTROL=0 -DCMAKE_BUILD_TYPE=Release
cmake --build build-cmake --config Release --target GenerateSohOtr
cmake --build build-cmake --config Release -j$(nproc)
```

## Retrieve the binaries
```
cd build-cmake/soh
strip soh.elf
```

- Copy `soh.elf` and `soh.otr` to `roms/ports/soh`.
- Copy the `build-cmake/assets` folder to `ports/soh` and copy `build-cmake/ZAPD/ZAPD.out` to `ports/soh/assets/`.
- If the build is a new version open `ports/soh/assets/otrgen` with a text editor and edit `--portVer` around Line 50 to match the release version you pulled.
