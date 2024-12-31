#!/bin/bash

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
export PORT_32BIT="Y"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
GAMEDIR="/$directory/ports/am2r"

# CD and set permissions
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x -R $GAMEDIR/*

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs:/usr/lib:/usr/lib32:$LD_LIBRARY_PATH"

# Config
bind_directories "~/.config" "$GAMEDIR/conf/am2r"

# Run game
$GPTOKEYB "gmloader" -c "$GAMEDIR/am2r.gptk" &
pm_platform_helper "$GAMEDIR/gmloader"
./gmloader gamedata/am2r.apk

# Cleanup
pm_finish

