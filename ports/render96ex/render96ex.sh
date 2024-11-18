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
VERSION="us"  # at the moment only US is supported and has been tested in Portmaster
SM64US_MD5="20b854b239203baf6c961b850a4a51a2"

mkdir -p "$CONFDIR"

cd $GAMEDIR

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

export LD_LIBRARY_PATH="${GAMEDIR}/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export PATH="${GAMEDIR}/bin.${DEVICE_ARCH}:${PATH}"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Patcher config
export PATCHER_FILE="$GAMEDIR/tools/install_mario64"
export PATCHER_GAME="$(basename "${0%.*}")" # This gets the current script filename without the extension
export PATCHER_TIME="about 10 minutes"

# -------------------- BEGIN FUNCTIONS --------------------

check_mario()
{
  [[ ! -f $1 ]] && echo "error" && return 1
  calc_md5=`md5sum "$1" | cut -d' ' -f1`
  echo "calc_md5"
  [[ "$calc_md5" == "$SM64US_MD5" ]]
}

find_mario()
{
  echo "Searching rom file (expecting md5sum = $SM64US_MD5)"
  find $1 -iname "*.z64" -print0 |
  while IFS= read -r -d '' line; do
    echo -n "Checking $line "
    calc_md5=`check_mario "$line"`
    if [[ $? -eq 0 ]];then
      echo "- OK"
      mv "${line}" "${GAMEDIR}/baserom.${VERSION}.z64"
      return 0
    fi
    echo "- WRONG md5sum ($calc_md5)"
  done

  [[ -f "${GAMEDIR}/baserom.${VERSION}.z64" ]] && return 0
  echo "No rom found"
  sleep 10
  return 1
}

# --------------------- END FUNCTIONS ---------------------

# Check if mandatory ressources are installed
if [ ! -f $GAMEDIR/$RES_DIR/$BASEZIP ] || [ ! -d $GAMEDIR/$RES_DIR/$DEMOS_DIR ] || [ ! -d $GAMEDIR/$RES_DIR/$TEXTS_DIR ]
then
  echo "Ressources are missing."

  echo "Looking for the rom"
  # Check if a rom file is present
  check_mario "${GAMEDIR}/baserom.${VERSION}.z64" || find_mario "${GAMEDIR}/"

  if [ ! $? -eq 0 ]
  then
    echo "No baserom.${VERSION}.z64 file is present, can not proceed to the installation of the ressources"
    text_viewer -e -f 25 -w -t "Error" -m "Oh, no! Ressources are missing. Install them first (put ${BASEROM} in ${GAMEDIR})."
    exit 1
  fi

  echo "Okey dokey! The rom has been found. The installation of ressources will start"

  if [ -f "$controlfolder/utils/patcher.txt" ]; then

    source "$controlfolder/utils/patcher.txt"

    rm -rf ${RESTOOL_DIR}

  else
      echo "This port requires the latest version of PortMaster."
      text_viewer -e -f 25 -w -t "PortMaster needs to be updated" -m "This port requires the latest version of PortMaster. Please update PortMaster first."
      exit 0
  fi

fi

# Install a default sm64config.txt when it's missing
if [ ! -f $CONFDIR/sm64config.txt ]
then
  cp sm64config.default.txt $CONFDIR/sm64config.txt
fi

$GPTOKEYB "sm64.us.f3dex2e.${DEVICE_ARCH}" &
pm_platform_helper "$GAMEDIR/sm64.us.f3dex2e.${DEVICE_ARCH}"

./sm64.us.f3dex2e.${DEVICE_ARCH} --savepath ./conf/

pm_finish