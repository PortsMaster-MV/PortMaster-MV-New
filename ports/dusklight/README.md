Dusklight is a from-scratch reimplementation of *The Legend
of Zelda: Twilight Princess*, built on the [zeldaret/tp](https://github.com/zeldaret/tp)
decompilation and rendered through [Aurora](https://github.com/encounter/aurora)
(GameCube GX → OpenGL ES).

Huge thanks to the [TwilitRealm/dusklight](https://github.com/TwilitRealm/dusklight)
team, the [zeldaret/tp](https://github.com/zeldaret/tp) decompilation
contributors, and [encounter/aurora](https://github.com/encounter/aurora) for
making native ports like this possible.

> [!IMPORTANT]
> Dusklight does **not** include, and will never include, any copyrighted game
> assets. You must dump your own copy of a Twilight Princess disc you own.

## Install

1. Dump your GameCube to `.iso`, following the [Dolphin ripping
   guide](https://wiki.dolphin-emu.org/index.php?title=Ripping_Games).
   Optionally compress it to `.rvz` with Dolphin or
   [nodtool](https://github.com/encounter/nod/releases) to save space.
2. Copy the `.iso`/`.rvz` file into `dusklight/assets/`.
3. Launch. Dusklight's own first-run screen lets you pick the disc and
   configure gameplay/enhancement options.

Only the GameCube USA/EUR releases are currently known to
work with this build.

## Configuration

You can edit the config file (or just use the in-game settings menu) but if you really screw it up, you can restore the default by deleting it:

```
dusklight/runtime/TwilitRealm/Dusklight/config.json
```

## Controls

Standard controls for the game.  Hit Select+R2 to enter the dusklight settings menu.  Start+Select to exit.

## Licenses

Dusklight itself is released under CC0 1.0 Universal (public domain). Bundled
libraries (SDL3, libjpeg-turbo) retain their own upstream
licenses. Game assets are proprietary Nintendo property and are never
distributed with this port.
