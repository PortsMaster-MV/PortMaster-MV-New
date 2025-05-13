#!/bin/bash
# Built from https://github.com/nosro1/re3 (branch miami-sdl2)

PORTNAME="Grand Theft Auto Vice City"

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
source $controlfolder/device_info.txt

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
else
  LIBS="libs"
  REVC="reVC"
fi

# Adding support for GAMEPAD across more operating systems.
# (On Anbernic RG35XX H with ROCKNIX 20250118, the GAMEPAD is sourced from /proc/bus/input/devices.
# The H700 uses the joypad. The 'js0' device is retained, but it's unclear whether it's used by other devices.)
case "$CFW_NAME" in
        "ROCKNIX")
                GAMEPAD=$(grep -B 4 -E 'js0|joypad' /proc/bus/input/devices | awk 'BEGIN {FS="\""}; /Name/ {printf $2}')
                ;;
        *)
                GAMEPAD=$(cat /sys/class/input/js0/device/name)
                ;;
esac
sed -i "/JoystickName/c\JoystickName = ${GAMEPAD}" ${GAMEDIR}/reVC.ini

cd "$GAMEDIR"
$ESUDO chmod 666 /dev/uinput
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export LD_LIBRARY_PATH="$GAMEDIR/${LIBS}":$LD_LIBRARY_PATH
$GPTOKEYB "${REVC}" &
./${REVC} 2>&1 | tee log.txt

$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
printf "\033c" >> $CUR_TTY
