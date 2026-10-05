## Notes

Thanks to the [doldecomp/melee](https://github.com/doldecomp/melee) contributors, whose
decompilation turned Melee's game code back into C that compiles for any CPU, and to
[encounter/aurora](https://github.com/encounter/aurora) and
[encounter/dawn](https://github.com/encounter/dawn), which render the GameCube graphics calls on
OpenGL ES. Thanks also to the PortMaster team, to bmdhacks for the SDL3-over-SDL2 shim, to the
Dusklight porters whose launcher this one follows, and to everyone who tested.

This is a native AArch64 build of *Super Smash Bros. Melee* (US 1.02) that runs on the device's
own OpenGL ES 3.1 driver. It includes no game data: you need your own dump of a Super Smash Bros.
Melee disc (US, version 1.02, `GALE01`). Port source and newer builds:
[zalo/melee, branch `release`](https://github.com/zalo/melee/tree/release);
`melee/version.txt` names the build installed.

Mali-G52 devices (RK3566: Miyoo Flip, RGB30, RG353) need libmali g2p0 (stock Miyoo Flip firmware,
spruceOS) or g29p1 (ROCKNIX 20260901 and newer, dArkOS). g13p0 (Knulli on the Flip) and g24p0
(older ROCKNIX) drop draws; the port detects this in the first menus, shows a "GPU driver update
needed" notice and keeps the picture correct at about 9-12 FPS. On ROCKNIX, update or switch the
GPU driver setting to Panfrost (40-50 FPS). PowerVR (TrimUI Smart Pro) is unconfirmed: an earlier
build failed to start there and the fix has not been retested on that hardware.

When a device cannot draw 60 frames a second, single-player still runs at full speed: the game
simulates every frame and draws fewer of them, as the GameCube does under load. The first matches
after installing stutter while shaders compile; later runs use the cache in `melee/runtime/cache`.
When something goes wrong, `melee/log.txt` has the details.

## Installation

1. Dump your disc following the
   [Dolphin ripping guide](https://wiki.dolphin-emu.org/index.php?title=Ripping_Games).
   `.iso`, `.gcm`, `.ciso` and `.rvz` all work.
2. Copy the image into `melee/assets/`.
3. Answer **Yes** at the memory-card prompt on first boot. Saves live in `melee/runtime/config`.

## Controls

| Handheld | Game |
| --- | --- |
| Left stick | Control stick |
| D-pad | D-pad (taunt) |
| Right stick | C-stick |
| A / B | A / B |
| X, Y | Jump |
| R1 | Z (grab) |
| L2 / R2 | L / R (shield) |
| Start | Start |
| Start + Select | Exit |

## Online play (two devices on the same Wi-Fi)

Both devices must run the same build of this port. In VS Mode > Melee, on the character select
screen, press **Z** (R1): an overlay offers **Host a match**, a **Join** row for every other device
hosting on the network, and the input delay (**Auto** measures the connection). One player hosts,
the other joins; both games restart together (about ten seconds, with the host's save so unlocks
agree) and return to the character select screen, where the host is player 1 and the guest player 2.
The match runs at the pace of the slower device. A desync or a lost connection turns the status
line red, and the game continues offline from there.

## Port Settings

Main menu > **Options** > **Port Settings** (the fourth row). Left and right change a value, A
activates a row, B saves and returns.

| Row | Effect |
| --- | --- |
| Debug Menu, Y on title | On: Y on the title screen opens the game's developer menu. Off by default. |
| Debug Overlays | On: matches listen for the development chords below. Off by default. |
| Show Frame Rate | On: the frames drawn a second in the top right corner. |
| Unlock All Characters and Stages | Sets every unlock in the current save and writes the memory card. The game then hands out its trophy pop-ups once on the next visit to the main menu. |
| Online Play | Opens the host / join screen described above. |

With Debug Overlays on, the chords sit on the D-pad, so a taunt with X, Y or R2 held sets one off.
If a match suddenly freezes, loses its HUD or shows boxes and text, repeat the same chord until it
is gone, and leave the setting off for normal play.

| Chord | Tool |
| --- | --- |
| R2 + D-pad up | Cycle the collision-bubble view (hurtboxes and hitboxes) |
| R2 + D-pad left | Cycle extra ranges (ledge grab, throws, item pickup) |
| Y (hold) + D-pad down | Toggle the action-state / animation info panel |
| X (hold) + D-pad down | Cycle the HUD off and on |
| X (hold) + D-pad up | Debug pause, and again to resume |
| R1 (Z) while debug-paused | Advance one frame |
| Y (hold) + D-pad left/right | Camera info and free camera (C-stick moves it) |

## Building

The port is cross-compiled on an x86_64 Linux host with the Bootlin
`aarch64--glibc--stable-2023.08-1` toolchain for `-mcpu=cortex-a35` and linked against a glibc 2.30
sysroot (`min_glibc` in `port.json`). The C++ runtime is linked statically; the only bundled library
is `libs.aarch64/libSDL3.so.0`, the [SDL3-over-SDL2 shim](https://github.com/bmdhacks/SDL/tree/sdl2-backend)
that Dusklight also ships, so display, sound and pads go through the CFW's own SDL 2. No GPU driver
is bundled. The release workflow (`.github/workflows/portmaster.yml`) runs the same steps and lists
the host packages:

```sh
git clone -b release https://github.com/zalo/melee.git
cd melee
export FLIP_TOOLS=$PWD/build/flip-tools
export RUSTUP_HOME=$FLIP_TOOLS/rustup CARGO_HOME=$FLIP_TOOLS/cargo PATH=$FLIP_TOOLS/cargo/bin:$PATH
curl -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal --default-toolchain stable
rustup target add aarch64-unknown-linux-gnu
python3 native/tools/prepare_flip.py --no-device --cpu a35
export FLIP_TOOLCHAIN=$FLIP_TOOLS/aarch64--glibc--stable-2023.08-1 FLIP_DAWN_PREFIX=$FLIP_TOOLS/dawn-install-a35
sh native/platform/portmaster/build_portmaster.sh
```

`prepare_flip.py` downloads the toolchain and builds the patched Dawn (the slow part); the zip and
the unpacked port are written to `dist/portmaster/`.
