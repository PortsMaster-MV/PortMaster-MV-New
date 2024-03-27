#!/bin/bash
# PORTMASTER: gtavc.zip, Grand Theft Auto Vice City.sh
# Built from https://github.com/nosro1/re3 (branch miami-sdl2)

PORTNAME="Grand Theft Auto Vice City"

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
get_controls

CUR_TTY=/dev/tty0
$ESUDO chmod 666 $CUR_TTY

GAMEDIR="/$directory/ports/gtavc"

if [[ ! -d "$GAMEDIR/data" ]]; then
  echo "Missing game files. Copy original game files to roms/ports/gtavc." > $CUR_TTY
  sleep 5
  $ESUDO systemctl restart oga_events &
  printf "\033c" >> $CUR_TTY
  exit 1
fi

# Check if reVC project files are already installed
# (needs to be done after the game files are copied, since it overwrites certain files)
if [[ -d "$GAMEDIR/reVC-data" ]]; then
  echo "Installing reVC files..." > $CUR_TTY
  cp -rf "$GAMEDIR/reVC-data"/* "$GAMEDIR" && rm -rf "$GAMEDIR/reVC-data"
fi

OPENGL=$(glxinfo | grep "OpenGL version string")
if [ ! -z "${OPENGL}" ]; then
  LIBS=""
  REVC="reVC_gl"
  GAMEPAD=$(cat /sys/class/input/js0/device/name)
  sed -i "/JoystickName/c\JoystickName = ${GAMEPAD}" ${GAMEDIR}/reVC.ini
else
  LIBS="libs"
  REVC="reVC"
fi

cd "$GAMEDIR"
$ESUDO chmod 666 /dev/uinput
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export LD_LIBRARY_PATH="$GAMEDIR/${LIBS}":$LD_LIBRARY_PATH
$GPTOKEYB "${REVC}" &
./${REVC} 2>&1 | tee log.txt

$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
printf "\033c" >> $CUR_TTY