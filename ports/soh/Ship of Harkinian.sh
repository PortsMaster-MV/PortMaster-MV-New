#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Set variables
GAMEDIR="/$directory/ports/soh"

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}":$LD_LIBRARY_PATH
export SDL_GAMECONTROLLERCONFIG=$sdl_controllerconfig

# CD and set log
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x "$GAMEDIR/soh.elf.${DEVICE_ARCH}"

# Close the menu if open
sed -i 's/"Menu": *1/"Menu": 0/' shipofharkinian.json

# -------------------- BEGIN FUNCTIONS --------------------

# SoH 9.3+ extracts roms itself (torch) using the ymls in assets/, so no patcher is needed
unzip_assets() {
    if [ -f "$GAMEDIR/assets/extractor.zip" ]; then
        pm_message "Unpacking extractor assets..."
        if "$controlfolder/7zzs.${DEVICE_ARCH}" x -y "$GAMEDIR/assets/extractor.zip" -o"$GAMEDIR/assets" >/dev/null; then
            rm -f "$GAMEDIR/assets/extractor.zip"
        else
            pm_message "Failed to unpack extractor.zip!"
            sleep 5
            exit 1
        fi
    fi
}

# Pass baseroms to soh.elf when no o2r exists yet; it prompts on screen and then starts the game
otr_check() {
    ROMS=()
    if [ ! -f "oot.o2r" ] && [ ! -f "oot-mq.o2r" ]; then
        for rom in "$GAMEDIR/baseroms/"*.z64 "$GAMEDIR/baseroms/"*.n64 "$GAMEDIR/baseroms/"*.v64; do
            [ -f "$rom" ] && ROMS+=("$rom")
        done
        if [ ${#ROMS[@]} -eq 0 ]; then
            pm_message "Missing ROM files! Place a .z64, .n64 or .v64 in baseroms/"
            sleep 5
            exit 1
        fi
    fi
}

# Temporary swap for rom extraction on <=1GB devices (swap_on/swap_off)
source "$GAMEDIR/swap.txt"

# --------------------- END FUNCTIONS ---------------------

# Launcher (Love2D): Anchor player name / room ID, frame rate and N64 low-res mode;
# also closes the game menu and enables controller navigation in shipofharkinian.json
rm -f "$GAMEDIR/launch.cfg"
source $controlfolder/runtimes/"love_11.5"/love.txt
$LOVE_RUN "$GAMEDIR/launcher" "$GAMEDIR/shipofharkinian.json" "$GAMEDIR/launch.cfg"

LAUNCHER_PLAY=0
[ -f "$GAMEDIR/launch.cfg" ] && source "$GAMEDIR/launch.cfg"
if [ "$LAUNCHER_PLAY" != "1" ]; then
  echo "Launcher exited without starting the game"
  pm_finish
  exit 0
fi

# Perform functions
unzip_assets
otr_check
swap_on
trap swap_off EXIT

# torch writes the finished o2r to $TMPDIR before copying it here; /tmp is RAM (tmpfs) on most CFWs
if [ ${#ROMS[@]} -gt 0 ]; then
    rm -rf "$GAMEDIR/tmp"
    mkdir -p "$GAMEDIR/tmp"
    export TMPDIR="$GAMEDIR/tmp"
fi

# Run the game
$GPTOKEYB "soh.elf.${DEVICE_ARCH}" -c "soh.gptk" &
pm_platform_helper "soh.elf.${DEVICE_ARCH}" >/dev/null
./soh.elf.${DEVICE_ARCH} "${ROMS[@]}"

# Cleanup
swap_off
rm -rf "$GAMEDIR/tmp"
rm -rf "$GAMEDIR/logs/"
pm_finish
