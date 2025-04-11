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
RESTOOL_DIR="restool"
RESTOOL_ZIP="restool.zip"
RES_DIR="res"
BASEZIP="base.zip"
DEMOS_DIR="demos"
TEXTS_DIR="texts"
VERSION="us"  # at the moment only US is supported and has been tested in Portmaster
BASEROM="baserom.${VERSION}.z64"
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

# execution flag
$ESUDO chmod a+x "$GAMEDIR/sm64.us.f3dex2e.aarch64"
$ESUDO chmod a+x "$GAMEDIR/bin.aarch64/text_viewer"

# -------------------- BEGIN FUNCTIONS --------------------

find_mario()
{
  echo "Searching rom file (expecting md5sum = $SM64US_MD5)"
  find $1 -iname "*.z64" -print0 |
  while IFS= read -r -d '' line; do
    [[ ! -f "$line" ]] && continue

    echo -n "Checking $line "
    calc_md5=`md5sum "$line" | cut -d' ' -f1`

    if [[ "$calc_md5" == "$SM64US_MD5" ]];then
      echo "- OK"
      cp "${line}" "${GAMEDIR}/${RESTOOL_DIR}/baserom.${VERSION}.z64"
      break
    fi

    mv "${line}" "${line}.incompatible"
    echo "- WRONG md5sum ($calc_md5)"
  done

  [[ -f "${GAMEDIR}/${RESTOOL_DIR}/baserom.${VERSION}.z64" ]] && return 0
  sleep 10
  return 1
}

# --------------------- END FUNCTIONS ---------------------

# Check if mandatory ressources are installed
if [ ! -f $GAMEDIR/$RES_DIR/$BASEZIP ] || [ ! -d $GAMEDIR/$RES_DIR/$DEMOS_DIR ] || [ ! -d $GAMEDIR/$RES_DIR/$TEXTS_DIR ]
then
  echo "Ressources are missing."

  mkdir -p "${RESTOOL_DIR}"

  echo "Looking for the rom"
  # Check if a rom file is present
  find_mario "${GAMEDIR}/"

  if [ ! $? -eq 0 ]
  then
    echo "No compatible rom file has been found, can not proceed to the installation of the ressources"
    text_viewer -e -f 25 -w -t "Error" -m "Oh, no! Ressources are missing. Install them first: put ${BASEROM} (md5sum ${SM64US_MD5}) in ${GAMEDIR}.\n\nPress SELECT to close this window."
    exit 1
  fi

  echo "Okey dokey! The rom has been found. The installation of ressources will start"

  if [ -f "$controlfolder/utils/patcher.txt" ]; then

    source "$controlfolder/utils/patcher.txt"

    rm -rf "${RESTOOL_DIR}"

  else
      echo "This port requires the latest version of PortMaster."
      text_viewer -e -f 25 -w -t "PortMaster needs to be updated" -m "This port requires the latest version of PortMaster. Please update PortMaster first.\n\nPress SELECT to close this window."
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

# 1:1 display hack
if [[ ${DISPLAY_WIDTH} -eq ${DISPLAY_HEIGHT} ]]; then
  grep "# patch for 1:1 display" "${GAMEDIR}/hacksdl.${ANALOG_STICKS}.conf" 2>&1 >/dev/null
  [[ $? -eq 0 ]] || cat "${GAMEDIR}/hacksdl.${DISPLAY_WIDTH}x${DISPLAY_HEIGHT}.conf" >> "${GAMEDIR}/hacksdl.${ANALOG_STICKS}.conf"
fi

# 3:2 (RG34XXH) display config
if  [[ ${DISPLAY_WIDTH} == 720 && ${DISPLAY_HEIGHT} == 480 ]]; then
  sed -i 's/window_w 640/window_w 720/g' "$GAMEDIR/conf/sm64config.txt"
fi

# use hacksdl to create a virtual analog stick from the dpad
if [[ -f "${GAMEDIR}/hacksdl.${ANALOG_STICKS}.conf" ]]; then
  export LD_PRELOAD="hacksdl.so"
  export HACKSDL_VERBOSE=1
  export HACKSDL_CONFIG_FILE="${GAMEDIR}/hacksdl.${ANALOG_STICKS}.conf"
fi

# Trick to get alsa dmix enabled on R36S with ArkOS
# ~/.asoundrc is removed before and port is started
# and put back after the port exits.
# So we put it back
[[ "$CFW_NAME" =~ ^ArkOS.* ]] && cp "${GAMEDIR}/asoundrc" "${HOME}/.asoundrc"

./sm64.us.f3dex2e.${DEVICE_ARCH} --savepath ./conf/

pm_finish