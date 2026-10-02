## Notes

Thanks to the [ZQuest Classic team](https://github.com/ZQuestClassic/ZQuestClassic) for over two decades of keeping Zelda Classic alive and growing it into an engine that has produced hundreds of fan-made quests.

The bundled demo quest The Deep is ready to play. For more quests, including the original classic ones, download them from [PureZC](https://www.purezc.net/index.php?page=quests) and drop the downloaded `.zip` as-is into `zquestclassic/quests/`; it's unpacked into its own folder on the next launch. Many quests also offer a separate music or support pack: drop that `.zip` in too, or copy its music folder next to the quest's `.qst`. Without it, those quests fall back to placeholder MIDI music that can sound badly out of tune. Each new save file asks which quest to play through a file browser, and the slot remembers it from then on.

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

```bash
git clone --branch 2.55.17 --depth 1 https://github.com/ZQuestClassic/ZQuestClassic.git
cd ZQuestClassic
git apply ../zquestclassic-portmaster.patch
CC=gcc-12 CXX=g++-12 cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DALLEGRO_SDL=ON -DGL_BUILD_TYPE=gles2+ \
  -DWANT_X11=OFF -DWANT_OPENAL=OFF -DWANT_NATIVE_DIALOG=OFF \
  -DWANT_NFD=OFF -DCMAKE_DISABLE_FIND_PACKAGE_CURL=ON \
  -DWANT_SENTRY=OFF -DWANT_ZUPDATER=OFF -DWANT_GIT_HOOKS=OFF \
  -DWANT_ERROR_CHECKING=FALSE \
  "-DCMAKE_C_FLAGS=-fsigned-char -include $PWD/../glibc-compat.h" \
  -DCMAKE_CXX_FLAGS=-fsigned-char
ninja -C build zplayer
```

Requires SDL2, GLES2/EGL, libvorbis, libuuid, bison and flex development packages, plus CMake 3.27 or newer. The patch lets Allegro run on its SDL2 backend with GLES2, adds portable fallbacks for the x86-only SSE tile drawing and JIT, makes the software DIGMID synth the default MIDI driver, and makes Allegro's SDL audio buffer size configurable. `glibc-compat.h` pins `hypot`/`hypotf` to their pre-2.35 symbol versions.
