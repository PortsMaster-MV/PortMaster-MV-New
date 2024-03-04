## Notes

Thanks to phobos for the [wipEout Rewrite](https://github.com/phoboslab/wipeout-rewrite).

This is a re-implementation of the 1995 PSX game wipEout.

## Running

This repository does not contain the assets (textures, 3d models etc.) required to run the game. This code mostly assumes to have the PSX NTSC data, but some menu models from the PC version are required as well. Both of these can be easily found on archive.org and similar sites. The music (optional) needs to be provided in QOA format. The intro video as MPEG1.

The directory structure is assumed to be as follows

./wipegame # the executable
./wipeout/textures/
./wipeout/music/track01.qoa
./wipeout/music/track02.qoa
...

Note that [the blog post](https://phoboslab.org/log/2023/08/rewriting-wipeout) announcing this project may or may not provide a link to a ZIP containing all files needed. Who knows!
