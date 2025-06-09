# Building Starship
These build instructions are based on the upstream repository via their [GitHub Actions Workflow](https://github.com/HarbourMasters/Starship/blob/main/.github/workflows/linux.yml) and [build instructions](https://github.com/HarbourMasters/Starship/blob/main/docs/BUILDING.md).

## Build Tinyxml2
```
wget https://github.com/leethomason/tinyxml2/archive/refs/tags/10.0.0.tar.gz
tar -xzf 10.0.0.tar.gz
cd tinyxml2-10.0.0
mkdir build && cd build
cmake ..
make
make install
```

## Build Starship
```
git clone --recursive https://github.com/HarbourMasters/starship.git && cd starship
git checkout tags/vx.x.x
cmake -H. -Bbuild-cmake -GNinja -DUSE_OPENGLES=1 -DBUILD_CROWD_CONTROL=0 -DCMAKE_BUILD_TYPE=Release
cmake --build build-cmake --config Release --target GeneratePortO2R
cmake --build build-cmake
```