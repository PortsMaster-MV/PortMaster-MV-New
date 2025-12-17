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
GAMEDIR="/$directory/ports/zeldadoi"

# CD and set permissions
cd "$GAMEDIR"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x "$GAMEDIR/gmloadernext.aarch64"

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Display loading splash
if [ "$CFW_NAME" == "muOS" ]; then
  $ESUDO $GAMEDIR/tools/splash "$GAMEDIR/splash.png" 1 
fi
$ESUDO $GAMEDIR/tools/splash "$GAMEDIR/splash.png" 7000

# Unzip data directory if needed
if [ -f "$GAMEDIR/saves/data.zip" ]; then
    cd saves
    if unzip "$GAMEDIR/saves/data.zip"; then
        rm -rf data.zip
        cd ..
    else
        echo "Couldn't unzip saves/data.zip. Please unzip manually."
        exit 1
    fi
fi

# Assign configs and load the game
$GPTOKEYB "gmloadernext.aarch64" &
pm_platform_helper "gmloadernext.aarch64" > /dev/null
./gmloadernext.aarch64 -c gmloader.json

# Cleanup
pm_finish