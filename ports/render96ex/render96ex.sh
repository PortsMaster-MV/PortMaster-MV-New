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

GAMEDIR="/$directory/ports/render96ex"
CONFDIR="$GAMEDIR/conf/"
BASEROM="baserom.us.z64"
RESTOOL_DIR="restool"
RESTOOL_ZIP="restool.zip"
RES_DIR="res"
BASEZIP="base.zip"
DEMOS_DIR="demos"
TEXTS_DIR="texts"

mkdir -p "$CONFDIR"

cd $GAMEDIR

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

export LD_LIBRARY_PATH="${GAMEDIR}/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export PATH="${GAMEDIR}/bin.${DEVICE_ARCH}:${PATH}"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Patcher config
export PATCHER_FILE="$GAMEDIR/restool/install-res.sh"
export PATCHER_GAME="$(basename "${0%.*}")" # This gets the current script filename without the extension
export PATCHER_TIME="about 10 minutes"

# Check if patchlog.txt to skip patching
if [ ! -f patchlog.txt ]; then
    if [ -f "$controlfolder/utils/patcher.txt" ]; then
        unzip "${RESTOOL_ZIP}"    

        if [ $? -eq 0 ];then
          source "$controlfolder/utils/patcher.txt"
        else
          echo "Unpacking ${RESTOOL_ZIP} has failed"
        fi

        rm -rf ${RESTOOL_DIR}
    else
        echo "This port requires the latest version of PortMaster."
        text_viewer -e -f 25 -w -t "PortMaster needs to be updated" -m "This port requires the latest version of PortMaster. Please update PortMaster first."
        exit 0
    fi
else
    echo "Patching process already completed. Skipping."
fi

# Install a default sm64config.txt when it's missing
if [ ! -f $CONFDIR/sm64config.txt ]
then
  cp sm64config.default.txt $CONFDIR/sm64config.txt
fi

# Check if mandatory ressources are installed before launching the game
if [ ! -f $GAMEDIR/$RES_DIR/$BASEZIP ] || [ ! -d $GAMEDIR/$RES_DIR/$DEMOS_DIR ] || [ ! -d $GAMEDIR/$RES_DIR/$TEXTS_DIR ]
then
  echo "Ressources are missing."
  text_viewer -e -f 25 -w -t "Error" -m "Oh, no! Ressources are missing. Install them first (put ${BASEROM} in ${GAMEDIR})."
else
  $GPTOKEYB "sm64.us.f3dex2e.${DEVICE_ARCH}" &
  pm_platform_helper "$GAMEDIR/sm64.us.f3dex2e.${DEVICE_ARCH}"
  ./sm64.us.f3dex2e.${DEVICE_ARCH} --savepath ./conf/
fi

pm_finish