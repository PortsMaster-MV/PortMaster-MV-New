## Notes

Thank you to [Chucklefish Games](https://chucklefish.org/) for making
such an amazing game.

This port is a heavily modified version of their code made to run on
low end retro handhelds. You **must** own a copy of Starbound to use
it. Base game assets are not provided and should be purchased to play
this game.

## Installation

Copy the game assets **`packed.pak`** from your normal Starbound
install to the **`starbound/assets`** directory before playing.

## Controls

| Button | Action | Description |
|--|--|--|
|A| action | Open doors, open chests, harvest items |
|B| equip matter manipulator |
|X| jump |
|Y| equip leftmost hotbar item | 
|R1| left-mouse | Use current equipped item's primary function |
|L1| right-mouse | Secondary use item, matter manipulator mine background tiles |
|R2| hotbar scroll right |
|L2| hotbar scroll left |
|select| esc | close current menu or open game options |
|start| i | open inventory menu |
|R3| alt | display info about nearby items |
|L3| *HOTKEY MODIFIER* |

| HOTKEY BUTTONS |||
|--|--|--|
|A| shift | fast-pickup / grouping or splitting (L1) / single block operations (R1) |
|B| f | enable Distortion Sphere tech or honk the mech horn |
|X| open crafting menu |
|Y| throw current item |
|start| toggle alternate hotbar |

## High-End Systems

If you are running on high-end aarch64 systems such as the Retroid
Pocket 5 or the Odin 2, you can delete the mods/speedup folder in
order to gain extra rendering quality at the expense of cpu.

## Building

```
git clone -b bmd-portmaster --single-branch https://github.com/bmdhacks/OpenStarbound.git
cd OpenStarbound/source
cmake --preset=portmaster-release
cmake --build --preset=portmaster-release
cd ../dist
strip starbound
```

## Mods

This version of Starbound is HIGHLY modified compared to OpenStarbound
and definitely vanilla Starbound.  Many mods will either not be
compatible or behave wildly differently.  Use them at your own peril.
Specifically mods that claim to affect performance in Starbound will
not work well with this version.

## Changes

Some significant changes in this version compared to OpenStarbound
- Backported rendering to OpenGL ES 2.0
- JSON Object string key interning (RAM savings)
- Lazy font loading (RAM savings)
- Audio streams from disk (RAM savings)
- ASTC compression of environment painter atlases (RAM savings)
- Half sized lighting texture with bilinear filtering (GPU
  performance)
- Perlin noise optimizations (RAM savings)
- Rendering changes to render at a lower resolution than the screen
  (GPU performance)
- Many other small improvements to RAM usage


