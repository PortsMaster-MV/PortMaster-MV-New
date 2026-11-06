#!/bin/bash
# Gen1Recomp catalogue launcher; runtime and exit shortcut supplied by PortMaster.
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
if [ -d /opt/system/Tools/PortMaster ]; then
  controlfolder=/opt/system/Tools/PortMaster
elif [ -d /opt/tools/PortMaster ]; then
  controlfolder=/opt/tools/PortMaster
elif [ -d "$XDG_DATA_HOME/PortMaster" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder=/roms/ports/PortMaster
fi
source "$controlfolder/control.txt" || exit 1
[ -f "$controlfolder/mod_${CFW_NAME}.txt" ] && source "$controlfolder/mod_${CFW_NAME}.txt"
get_controls

SHDIR="$(cd "$(dirname "$0")" && pwd)"
GAMEDIR="$SHDIR/gen1recomp"
CONFDIR="$GAMEDIR/conf"
mkdir -p "$CONFDIR"
cd "$GAMEDIR" || exit 1
exec >"$GAMEDIR/log.txt" 2>&1
export XDG_DATA_HOME="$CONFDIR"
export XDG_CONFIG_HOME="$CONFDIR"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export POKEPORT_HANDHELD=1
export POKEPORT_PORTMASTER=1
export POKEPORT_PORTMASTER_MANAGED=1
export NINTENDO_LAYOUT=1
export POKEPORT_AUDIO_RATE=22050
export POKEPORT_IDLE_AFTER=10
export POKEPORT_IDLE_FPS=6
export LOVE_GRAPHICS_USE_OPENGLES=1

source "$controlfolder/runtimes/love_11.5/love.txt" || exit 1
$GPTOKEYB "$LOVE_GPTK" &
trap 'pm_finish' EXIT
pm_platform_helper "$LOVE_BINARY"
# LOVE_RUN intentionally contains the runtime command and its environment.
$LOVE_RUN "$GAMEDIR/lovegame"
exit $?
