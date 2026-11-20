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
GAMEDIR="/$directory/ports/lighthouse"

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}":$LD_LIBRARY_PATH
export SDL_GAMECONTROLLERCONFIG=$sdl_controllerconfig

# CD and set log
cd $GAMEDIR
: > "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x "$GAMEDIR/Lighthouse.${DEVICE_ARCH}"

# -------------------- BEGIN FUNCTIONS --------------------

# Lighthouse extracts roms itself (torch) using config.yml and assets/yaml/ from its folder
unzip_assets() {
    if [ -f "$GAMEDIR/assets/extractor.zip" ]; then
        $LOVE_RUN "$GAMEDIR/extract" --text "Unpacking extractor assets..." assets/extractor.zip || exit 1
        rm -f "$GAMEDIR/assets/extractor.zip"
    fi
}

# Pass baseroms to Lighthouse when no o2r exists yet; it prompts on screen and then starts the game
otr_check() {
    ROMS=()
    if [ ! -f "bk.o2r" ]; then
        for rom in "$GAMEDIR/baseroms/"*.z64; do
            [ -f "$rom" ] && ROMS+=("$rom")
        done
        if [ ${#ROMS[@]} -eq 0 ]; then
            pm_message "Missing ROM! Place a Banjo-Kazooie .z64 in baseroms/"
            sleep 5
            pm_finish
            exit 0
        fi
    fi
}

# --------------------- END FUNCTIONS ---------------------

# Launcher (Love2D): Anchor player name / room ID, frame rate and N64 low-res mode;
# also closes the game menu and enables controller navigation in lighthouse.cfg.json
rm -f "$GAMEDIR/launch.cfg"
source $controlfolder/runtimes/"love_11.5"/love.txt
$LOVE_RUN "$GAMEDIR/launcher" "$GAMEDIR/lighthouse.cfg.json" "$GAMEDIR/launch.cfg"

# Continue only if the user chose Play (launcher writes LAUNCHER_PLAY=1 to launch.cfg)
if ! grep -qx "LAUNCHER_PLAY=1" "$GAMEDIR/launch.cfg" 2>/dev/null; then
  pm_finish
  exit 0
fi

# Perform functions
unzip_assets
otr_check

$GPTOKEYB "Lighthouse.${DEVICE_ARCH}" -c "lighthouse.gptk" &
pm_platform_helper "Lighthouse.${DEVICE_ARCH}" >/dev/null
./Lighthouse.${DEVICE_ARCH} "${ROMS[@]}"

# Cleanup
rm -rf "$GAMEDIR/tmp"
rm -rf "$GAMEDIR/logs/"
pm_finish
