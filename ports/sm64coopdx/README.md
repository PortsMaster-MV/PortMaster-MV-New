## Notes

Ported by [DedicatedToSoftware](https://dedicatedtosoftware.com).

Thanks to the [Coop Deluxe Team](https://github.com/coop-deluxe/sm64coopdx) for making sm64coopdx, and to Nintendo for the original Super Mario 64.

Thanks to CODEHEX4EVER for the original PortMaster port, which this release replaces.

This build targets aarch64 handhelds. It uses native SDL2 gamepad input, so no gptokeyb mapping is needed.

## Controls

The gamepad uses the standard N64 layout and bindings can be remapped in-game. Gamepads work out of the box via SDL2.

Text fields (e.g. player name or chat) use the controller-operated on-screen keyboard:

| Button | Action |
|--|--|
| D-pad / Analog stick | Move between keys |
| A | Enter the selected key |
| B | Backspace (hold to repeat) |
| L / R | Shift / capitalized characters |
| OK | Close the keyboard and keep the entered value |
| Start | Close the keyboard |

The chat window can be opened with R3 and scrolled with the right analog stick.

## Install

Copy your legally obtained US Super Mario 64 ROM to `ports/sm64coopdx/` as a `.z64` file (e.g. `baserom.us.z64`). The launcher renames it automatically on first run.

Cheers! - **DTS**
