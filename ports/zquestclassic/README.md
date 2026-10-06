## Notes

Thanks to the [ZQuest Classic team](https://github.com/ZQuestClassic/ZQuestClassic) for over two decades of keeping Zelda Classic alive and growing it into an engine that has produced hundreds of fan-made quests.

The bundled demo quest The Deep is ready to play. For more quests, including the original classic ones, download them from [PureZC](https://www.purezc.net/index.php?page=quests) and drop the downloaded `.zip` as-is into `zquestclassic/quests/`; it's unpacked there on the next launch. Many quests also offer a separate music or support pack: drop that `.zip` in too, or copy its music folder into `zquestclassic/quests/`. Without it, those quests fall back to placeholder MIDI music that can sound badly out of tune. Each new save file asks which quest to play through a file browser, and the slot remembers it from then on.

The script JIT is turned off by default (`jit = 0` under `[ZSCRIPT]` in `zquestclassic/zc.cfg`), because compiling some quests' larger scripts needs several GB of RAM. On devices with plenty of memory you can set it to `1` for faster script-heavy quests.

## Controls

| Button | Action |
|--|--|
| D-Pad | Move |
| Left Analog | Mouse pointer (menus) |
| A | A button (sword) |
| B | B button (selected item) |
| X | Ex1 |
| Y | Ex2 |
| L1 | L button (item cycling in most quests) |
| R1 | R button (item cycling in most quests) / mouse click in menus |
| L2 | Ex3 |
| R2 | Ex4 |
| Start | Subscreen / confirm |
| Select | Map |
| Select + A | Open / close the system menu |
| Start + Select | Quit |

Menus and the quest file browser can be used with the mouse pointer (Left Analog + R1), or the D-Pad and Start.

## Compile

Run from this port's folder, so `patches/` sits next to the clone.

ZQuest Classic's own SDL_mixer fork (MIDI/Timidity only) is built first. It adds the beat functions ZC uses for custom MIDI loop points:

```bash
git clone --branch zc-fork-1 --depth 1 https://github.com/connorjclark/SDL_mixer.git SDL_mixer-zc
cmake -S SDL_mixer-zc -B SDL_mixer-zc/build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DSDL2MIXER_VENDORED=OFF -DSDL2MIXER_SAMPLES=OFF -DSDL2MIXER_INSTALL=OFF -DSDL2MIXER_CMD=OFF \
  -DSDL2MIXER_FLAC=OFF -DSDL2MIXER_MOD=OFF -DSDL2MIXER_MP3=OFF -DSDL2MIXER_OPUS=OFF \
  -DSDL2MIXER_VORBIS=OFF -DSDL2MIXER_WAVE=OFF -DSDL2MIXER_WAVPACK=OFF \
  -DSDL2MIXER_MIDI=ON -DSDL2MIXER_MIDI_TIMIDITY=ON -DSDL2MIXER_MIDI_FLUIDSYNTH=OFF \
  "-DCMAKE_C_FLAGS=-include $PWD/patches/glibc-compat.h"
ninja -C SDL_mixer-zc/build
```

Then ZQuest Classic itself:

```bash
git clone --branch "3.0.0-prerelease.226+2026-10-01" --depth 1 https://github.com/ZQuestClassic/ZQuestClassic.git
cd ZQuestClassic
git apply ../patches/zquestclassic-portmaster.patch
CC=gcc-12 CXX=g++-12 cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DALLEGRO_SDL=ON -DGL_BUILD_TYPE=gles2+ \
  -DWANT_X11=OFF -DWANT_OPENAL=OFF -DWANT_NATIVE_DIALOG=OFF \
  -DWANT_NFD=OFF -DWANT_WEBSOCKETS=OFF -DCMAKE_DISABLE_FIND_PACKAGE_CURL=ON \
  -DWANT_SENTRY=OFF -DWANT_ZUPDATER=OFF -DWANT_GIT_HOOKS=OFF -DWANT_ZC_TESTS=OFF \
  -DWANT_ERROR_CHECKING=FALSE \
  "-DCMAKE_C_FLAGS=-fsigned-char -include $PWD/../patches/glibc-compat.h" \
  "-DCMAKE_CXX_FLAGS=-fsigned-char -include $PWD/../patches/glibc-compat.h" \
  -DSDL2_MIXER_INCLUDE_DIR=$PWD/../SDL_mixer-zc/include \
  -DSDL2_MIXER_LIBRARY=$PWD/../SDL_mixer-zc/build/libSDL2_mixer-2.0.so.0.700.0
ninja -C build zplayer
```

Requires SDL2, GLES2/EGL, libuuid, bison and flex development packages, plus CMake 3.27 or newer. The patch lets Allegro run on its SDL2 backend with GLES2 (skipping the vendored SDL2 and the X11-only window raise), plays MIDI music through ZQuest Classic's SDL_mixer fork (Timidity) with upstream's web-player patch set, exactly like ZQuest Classic's own web build, makes Allegro's SDL audio buffer size configurable, and adds an optional software-drawn mouse cursor for displays without a hardware cursor plane. `patches/glibc-compat.h` pins `hypot`/`hypotf` and `std::condition_variable::wait` to older symbol versions so the build runs on glibc 2.34 and GCC 11-era libstdc++.
