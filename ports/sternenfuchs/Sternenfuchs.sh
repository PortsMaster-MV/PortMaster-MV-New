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

source "$controlfolder/control.txt"
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/sternenfuchs"
CONFDIR="$GAMEDIR/conf/"
BIN="$GAMEDIR/starfox.${DEVICE_ARCH}"

mkdir -p "$GAMEDIR/conf"
cd "$GAMEDIR"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

export XDG_DATA_HOME="$CONFDIR"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# SDL3 shim -> CFW's patched SDL2.
if [ -n "${SDL_VIDEODRIVER:-}" ]; then
  export SDL3SHIM_SDL2_VIDEODRIVER="$SDL_VIDEODRIVER"
  export SDL_VIDEODRIVER=sdl2
fi
if [ -n "${SDL_AUDIODRIVER:-}" ]; then
  export SDL3SHIM_SDL2_AUDIODRIVER="$SDL_AUDIODRIVER"
  export SDL_AUDIODRIVER=sdl2
fi
export SDL3SHIM_SDL2_LIB="${SDL3SHIM_SDL2_LIB:-libSDL2-2.0.so.0}"

if [ ! -f "$GAMEDIR/pregame.cfg" ] && [ -f "$GAMEDIR/prototype-pregame.cfg" ]; then
  cp "$GAMEDIR/prototype-pregame.cfg" "$GAMEDIR/pregame.cfg"
fi

# Use the first ROM whose CRC-32 (read from a gzip trailer, skipping any
# 512-byte copier header) is a supported retail revision.
if [ ! -f "$GAMEDIR/Starfox-Assets.BIN" ]; then
  for rom in "$GAMEDIR"/*.[sS][fFmM][cC]; do
    [ -f "$rom" ] || continue
    crc=$(tail -c +$(( $(wc -c < "$rom") % 1024 + 1 )) "$rom" | gzip -1 -c | tail -c 8 | head -c 4 | od -An -tx1 | tr -d ' \n')
    case "$crc" in
      d0e6c48f|4109ae0b|b27686b1|3f0ba641|418a66ad|711a5f86|2bda64ba|38a28cb4)
        export STARFOX_RETAIL_ROM="$rom"; break ;;
    esac
    echo "ROM skipped (unsupported revision): $rom"
  done
fi

$ESUDO chmod +x "$BIN"

$GPTOKEYB "starfox.${DEVICE_ARCH}" &

pm_platform_helper "$BIN"
"$BIN"

pm_finish
