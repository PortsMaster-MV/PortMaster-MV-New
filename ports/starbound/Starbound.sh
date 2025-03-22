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

GAMEDIR=/$directory/ports/starbound
CONFDIR="$GAMEDIR/conf/"

mkdir -p "$GAMEDIR/conf"

cd $GAMEDIR

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

export XDG_DATA_HOME="$CONFDIR"
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

$GPTOKEYB2 starbound -c ./starbound.gptk.ini &>/dev/null &
cd ${GAMEDIR}/bin

pm_platform_helper ${GAMEDIR}/bin/starbound

export DEVICE_RAM=`free -m | grep Mem | awk '{print $2}'`
# for debug purposes
env

if [[ $DEVICE_RAM -lt 1500 ]]; then
  # tell the user they need to purchase a new handheld
  ${controlfolder}/sdl2imgshow -i ${GAMEDIR}/lowRam.png &
  sleep 5 # sdl2imgshow doesn't seem to respect -k option
  killall sdl2imgshow
  pm_message "TWO GIGABYTES of RAM required"
  # fall through and run the game but at least they know now
fi

# actually run the game
export TCMALLOC_RELEASE_RATE=0
LD_PRELOAD=${GAMEDIR}/libtcmalloc_minimal.so.4.5.16 ./starbound

pm_finish
