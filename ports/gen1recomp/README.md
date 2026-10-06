## Notes

Gen1Recomp is a native LÖVE recreation using assets extracted locally from a
player-supplied, supported canonical US ROM. No ROM or generated cache is included.

Based on the Pokemon Gen 1 Recompilation Project by BOIS CLUB GAMES, LLC
(https://github.com/bryanthaboi/gen1recomp).
Thanks to BOIS CLUB GAMES, LLC for the engine and permission to distribute the
launcher through PortMaster, and to the PortMaster team for the LÖVE runtime.
PortMaster packaging: Nexhas28.

## Installation

Install the port and keep PortMaster up to date (LÖVE 11.5 is required).
Copy your supported US ROM into `ports/gen1recomp/lovegame/`, launch
**Gen1Recomp**, and use **Choose ROM**. Start testing with Red or Blue.
No ROM download is supplied. The importer verifies the ROM before extraction.

## Controls

| Button | Action |
|--|--|
| D-pad | Move / navigate |
| A | Confirm |
| B | Cancel |
| Start | In-game menu |
| L1 / R1 | Launcher tabs |
| PortMaster exit combination | Quit |

In-game controls can be rebound in OPTIONS → CONTROLS.

## Saves and updates

Portable saves and extracted caches live in `gen1recomp/lovegame/`; LÖVE
configuration lives in `gen1recomp/conf/`. Back these up before updating.
Update this catalogue edition through PortMaster. Its launcher disables the
standalone application updater to avoid installing a differently named SBC pack.

To migrate from the standalone `gen1recomp-sbc` package: back it up, install this
edition, then copy its `lovegame/` and `conf/` contents into the corresponding
new directories **before reinstalling this catalogue package over them**. This
retains user data while restoring the catalogue edition's code. Do not launch
between copying and reinstalling. Do not migrate `updates/` directories.
Keep the original backup until saves have been loaded successfully.

## Build

From the source revision recorded in `gen1recomp/SOURCE.txt`:

```sh
python3 scripts/portmaster/package.py --version X.Y.Z --screenshot /path/to/gameplay.png
```

The output under `dist/portmaster/ports/gen1recomp/` is the unpacked submission.
The builder uses the existing shared payload packer; LÖVE is provided by
PortMaster, not bundled again. No native shader-conversion bridge is bundled;
converting new SHADER FX presets on-device is unavailable in this package.

## Testing status

Nexhas confirmed the catalogue candidate from source revision `fce5f086` works
on TrimUI Brick on 6 October 2026. Firmware/version and individual import/save,
exit and suspend checks have not been specified. Other devices and firmware
remain unverified. See `docs/portmaster-submission.md` for the candidate checksum
and testing checklist.
