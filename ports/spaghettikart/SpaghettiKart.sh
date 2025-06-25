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

GAMEDIR=/$directory/ports/spaghettikart
BINARY="Spaghettify"

cd "$GAMEDIR"

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Extract assets if necessary
if [ ! -f ./mk64.o2r ]; then
  export PATCHER_FILE="$GAMEDIR/torch/run_torch"
  export PATCHER_TIME="1 minute"

  if [ -f "$controlfolder/utils/patcher.txt" ]; then
    $ESUDO chmod a+x "$PATCHER_FILE"
    source "$controlfolder/utils/patcher.txt"
    $ESUDO kill -9 $(pidof gptokeyb)
  else
    pm_message "This port requires the latest version of PortMaster."
  fi

  rom=`find . -maxdepth 1 -name "*.z64"`
  rom=`basename "$rom"`
  cd torch
  ./torch o2r "../$rom"
  cd ..
  mv torch/mk64.o2r .
fi

export LD_LIBRARY_PATH=$GAMEDIR/libs.aarch64:$LD_LIBRARY_PATH

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

if [ -f "${controlfolder}/libgl_${CFW_NAME}.txt" ]; then
  source "${controlfolder}/libgl_${CFW_NAME}.txt"
else
  source "${controlfolder}/libgl_default.txt"
fi

if [[ "$CFW_NAME" = "ROCKNIX" ]] && \
    [[ ! -z `glxinfo | grep "OpenGL version string"` ]]; then
  cp bin/Spaghettify-OpenGL ./Spaghettify
else
  cp bin/Spaghettify-GLES ./Spaghettify
fi

$GPTOKEYB "$BINARY" -c "$BINARY.gptk" &

pm_platform_helper "$GAMEDIR/$BINARY"

./$BINARY

pm_finish
