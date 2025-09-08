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
GAMEDIR="/$directory/ports/sm64coopdx"
CONFDIR="$GAMEDIR/conf"
ARGS="--fullscreen"

# CD and set permissions
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x $GAMEDIR/sm64coopdx.${DEVICE_ARCH}

$ESUDO mkdir -p "$CONFDIR"
bind_directories ~/.local/share/sm64coopdx "$CONFDIR"

# Exports
# export TEXTINPUTPRESET="Name"
# export TEXTINPUTINTERACTIVE="Y"
# export TEXTINPUTNOAUTOCAPITALS="Y"
# export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

## Check for rom
if [ ! -f "$GAMEDIR/baserom.us.z64" ]; then
  # Look for a .z64 or .n64 file
  romfile="$(find "$GAMEDIR" -maxdepth 1 -type f \( -iname "*.z64" -o -iname "*.n64" \) | head -n 1)"
  
  if [ -n "$romfile" ]; then
    mv "$romfile" "$GAMEDIR/baserom.us.z64"
  else
    pm_message "Missing ROM, see README for more info."
    sleep 5
    exit 1
  fi
fi

## Extract the files
if [ -f "$GAMEDIR/files.zip" ]; then
  if unzip "$GAMEDIR/files.zip" -d "$GAMEDIR"; then
    rm "$GAMEDIR/files.zip"
  else
    pm_message "Failed to extract files.zip"
    sleep 5
    exit 1
  fi
fi

# Run the game
$GPTOKEYB "sm64coopdx.${DEVICE_ARCH}" &
pm_platform_helper "$GAMEDIR/sm64coopdx.${DEVICE_ARCH}"
./sm64coopdx.${DEVICE_ARCH} $ARGS

# Cleanup
pm_finish
