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
export PORT_32BIT="Y"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/nuclearthronemobile"

cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x "$GAMEDIR/gmloader"

export GMLOADER_DEPTH_DISABLE=1
export GMLOADER_SAVEDIR="$GAMEDIR/gamedata/"
export LD_LIBRARY_PATH="/usr/lib:/usr/lib32:/$directory/ports/nuclearthronemobile/libs:$LD_LIBRARY_PATH"

if [ -f "$GAMEDIR/nuclearthronemobile.apk" ] || [ -f "$GAMEDIR/ntm2527.apk" ]; then
    mv "$GAMEDIR/ntm2527.apk" "$GAMEDIR/nuclearthronemobile.apk"
else
    pm_message "Error: ntm2527.apk not found in $GAMEDIR" >&2
    exit 1
fi

$ESUDO chmod 666 /dev/uinput
$GPTOKEYB "gmloader" -c "./nuclearthronemobile.gptk" &
./gmloader nuclearthronemobile.apk

pm_finish

