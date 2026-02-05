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

# Variables
GAMEDIR="/$directory/ports/nuclearthronemobile"
GMLOADER_JSON="$GAMEDIR/gmloader.json"

# CD and set permissions
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x $GAMEDIR/gmlnext.aarch64

# Exports
export LD_LIBRARY_PATH="/usr/lib:$GAMEDIR/lib:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Find any APK starting with ntm
ntm_apk=$(find "$GAMEDIR" -maxdepth 1 -type f -name "ntm*.apk" | head -n 1)

if [ -n "$ntm_apk" ]; then
    # Only rename if it's not already named nuclearthronemobile.apk
    if [ "$(basename "$ntm_apk")" != "nuclearthronemobile.apk" ]; then
        mv "$ntm_apk" "$GAMEDIR/nuclearthronemobile.apk"
    fi
elif [ ! -f "$GAMEDIR/nuclearthronemobile.apk" ]; then
    pm_message "Error: Nuclear Throne Mobile apk not found in $GAMEDIR" >&2
    exit 1
fi

# Assign configs and load the game
$GPTOKEYB2 "gmlnext.aarch64" -c "nuclearthronemobile.gptk" &
pm_platform_helper "$GAMEDIR/gmlnext.aarch64"
./gmlnext.aarch64 -c "$GMLOADER_JSON"

# Cleanup
pm_finish