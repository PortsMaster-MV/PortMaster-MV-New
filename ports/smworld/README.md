## Notes

Thanks to the [snesrev project](https://github.com/snesrev/smw), to [Tekkenfede](https://github.com/Tekkenfede) for the original PortMaster port, and to [Desoxyn](https://github.com/Trademarked69) for pointing out that there was an easier way to handle the required game assets.

## Installation

Place your copy of *Super Mario World (USA)* into the root of the `ports/smworld/` directory, and name it `smw.sfc`. The correct ROM should have an MD5 checksum of `cdd3c8c37322978ca8669b34bc89c804`.

Additionally—if you want to be able to play *SMB1* or *The Lost Levels*—place your copy of *Super Mario All-Stars (USA)* into the root of the `ports/smworld/` directory, and name it `smas.sfc`. The correct ROM should have an MD5 checksum of `53c038150ba00d5f8d8574b4d36283f2`.

The required asset file(s) will be created the first time you run the game(s).

## Controls

| Button | Action |
|--|--| 
|Left Analog Stick|Move|
|D-Pad|Move|
|A Button|Spin Jump|
|B Button|Jump|
|X/Y Buttons|Dash/Grab/Shoot Fireballs|
|Start Button|pause/Menu Confirm|
|Select Button|Use Reserve Item/Menu Advance|
|L1 Button|Scroll Screen Left|
|R1 Button|Scroll Screen Right|
|L2 Button|Save State|
|R2 Button|Load State|
|Menu Button|Fast Forward|
|Start + Select buttons|Exit Game|

This game uses **SDL** for controls. In the event that **ABXY** do not correspond to the expected buttons on your device/firmware, you may wish to make use of your firmware's options (ex.: [Knulli](https://knulli.org/play/basic-inputs/#switch-ab-and-xy-for-ports), [muOS](https://muos.dev/tour/modules/muxcontrol)), or to modify the options in the `[GamepadMap]` section of `ports/smworld/smw.ini` (see also the `[KeyMap]` section of `smw.ini`).

## Configuration
There are several game options which may be configured by editing `ports/smworld/smw.ini`. The `SavePlaythrough`, `LinearFiltering`, and `IgnoreAspectRatio` options are just some of those that may be of interest.

Some devices—such as those with low or otherwise-unusual screen resolutions—*may* require modifying the `WindowSize`, `IgnoreAspectRatio`, or `Fullscreen` settings within the `[Graphics]` section.

## Performance
*SMB1* and *The Lost Levels* are more demanding than *Super Mario World*, and the performance of the former two games may be marginal on some devices. Usage of higher-than-default system governors can be beneficial in some cases. For example: selecting the `Performance` governor rather than the default `Ondemand` governor was observed to result in substantially smoother gameplay in *SMB1* and *The Lost Levels*, on both a TrimUI Brick Hammer as well as an Anbernic RG-35XX H, each of which were running the muOS firmware.

## Compile
This aarch64 build was built using Cebion's [WSL2 chroot environment](https://github.com/Cebion/Portmaster_builds).
```shell
git clone https://github.com/snesrev/smw.git
cd smw
make
```
