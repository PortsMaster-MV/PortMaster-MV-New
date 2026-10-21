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
GAMEDIR="/$directory/ports/melee"
cd "$GAMEDIR" || exit 1

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# The user supplies a Super Smash Bros. Melee (US 1.02) disc image; the game reads all four formats.
mkdir -p "$GAMEDIR/assets"
shopt -s nullglob nocaseglob
discs=("$GAMEDIR"/assets/*.iso "$GAMEDIR"/assets/*.gcm "$GAMEDIR"/assets/*.ciso "$GAMEDIR"/assets/*.rvz)
shopt -u nocaseglob
if [ ${#discs[@]} -eq 0 ]; then
  pm_message "No Melee disc image found in melee/assets. See README.md."
  sleep 15
  exit 1
fi

# Memory card, saves and shader cache stay inside the port directory.
export XDG_CONFIG_HOME="$GAMEDIR/runtime/config"
export XDG_STATE_HOME="$GAMEDIR/runtime/state"
export XDG_CACHE_HOME="$GAMEDIR/runtime/cache"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

chmod +x "$GAMEDIR/melee.aarch64"
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# The game links SDL3; libs.aarch64 holds only the SDL3-over-SDL2 shim, whose "sdl2" driver runs
# display/audio/input through the CFW's own SDL2. ROCKNIX's inner SDL2 needs wayland pinned.
export SDL_VIDEODRIVER=sdl2
if [ "$CFW_NAME" = "ROCKNIX" ]; then
  export SDL3SHIM_SDL2_VIDEODRIVER=wayland
fi

# Mali-G31 (r13p0) falsely triggers Aurora's draw-barrier probe in busy scenes, stalling the frame
# and flashing the stage black; force it off. A device that needs it can set the var itself.
export AURORA_GLES_DRAW_BARRIER="${AURORA_GLES_DRAW_BARRIER:-0}"

# gptokeyb2 only provides the Start+Select exit hotkey; the game reads the pad through SDL (melee.ini maps no keys).
$GPTOKEYB2 "melee.aarch64" -c "$GAMEDIR/melee.ini" >/dev/null 2>&1 &
# Older PortMaster builds have no pm_platform_helper (AmberELEC ships 2024.12.31, which lacks it).
type pm_platform_helper >/dev/null 2>&1 && pm_platform_helper "$GAMEDIR/melee.aarch64" >/dev/null

./melee.aarch64 "${discs[0]}"
status=$?

# dArkOS RE sets no video driver and SDL2 autodetect lands on a GL path our EGL can't see. Retry once
# forcing KMSDRM, and only on that exact failure.
if [ $status -ne 0 ] && [ -z "${SDL3SHIM_SDL2_VIDEODRIVER:-}" ] \
   && grep -q "SDL did not create an EGL display" "$GAMEDIR/log.txt"; then
  export SDL3SHIM_SDL2_VIDEODRIVER=kmsdrm
  ./melee.aarch64 "${discs[0]}"
  status=$?
fi

$ESUDO kill -9 $(pidof gptokeyb2) 2>/dev/null

# Any abnormal exit that is not the exit hotkey (137 SIGKILL / 143 SIGTERM): nudge to share the log.
if [ $status -ne 0 ] && [ $status -ne 137 ] && [ $status -ne 143 ]; then
  if grep -q "No usable graphics driver" "$GAMEDIR/log.txt"; then
    pm_message "This system's graphics driver cannot run Melee. Please share melee/log.txt."
  else
    pm_message "Melee exited unexpectedly. Please share melee/log.txt."
  fi
  sleep 10
fi

pm_finish
