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
GAMEDIR="/$directory/ports/dusklight"
cd "$GAMEDIR" || exit 1

# Keep the previous launch's log; warm-boot diagnostics are read from it.
cp -f "$GAMEDIR/log.txt" "$GAMEDIR/log.prev.txt" 2>/dev/null
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

mkdir -p "$GAMEDIR/assets"

# Look for a user-supplied disc image (GameCube/Wii .iso, or Dolphin/nodtool .rvz)
shopt -s nullglob nocaseglob
discs=("$GAMEDIR"/assets/*.iso "$GAMEDIR"/assets/*.rvz)
shopt -u nocaseglob
if [ ${#discs[@]} -eq 0 ]; then
    pm_message "No Twilight Princess disc image found in dusklight/assets. See README.md for dumping instructions."
    sleep 15
    exit 1
fi

# Keep config/saves/shader caches inside the port directory instead of $HOME
export XDG_DATA_HOME="$GAMEDIR/runtime"
mkdir -p "$XDG_DATA_HOME"

# Config, saves and shader caches (SDL pref path TwilitRealm/Dusklight).
DUSK_USER_DIR="$XDG_DATA_HOME/TwilitRealm/Dusklight"
mkdir -p "$DUSK_USER_DIR"

# Seed the live config from the shipped defaults only when absent, so in-game
# and hand edits survive. Restore with `cp config.json.default config.json`.
if [ ! -f "$DUSK_USER_DIR/config.json" ] && [ -f "$DUSK_USER_DIR/config.json.default" ]; then
  echo "Seeding config.json from config.json.default (first run)."
  cp -f "$DUSK_USER_DIR/config.json.default" "$DUSK_USER_DIR/config.json"
fi

# Wipe the shader caches only when a newer binary is installed; normal launches
# keep them so warm boots skip the cold compile storm.
CACHE_DIR="$DUSK_USER_DIR"
if [ "$GAMEDIR/dusklight.aarch64" -nt "$CACHE_DIR/pipeline_cache.db" ]; then
  # Plain echo, not pm_message: its GUI helper grabs the display and breaks rendering.
  echo "New Dusklight build detected - clearing stale shader caches."
  rm -f "$CACHE_DIR"/pipeline_cache.db* "$CACHE_DIR"/program_binary_cache.db* \
        "$CACHE_DIR"/program_binary_cache.loading
fi

export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Pin SDL3 to the bundled shim's "sdl2" driver: aurora only takes the borrowed-EGL
# + EFB present path under that driver, and it's the only path that reaches the
# panel. On a real Mesa stack SDL3 would otherwise grab native wayland and skip the
# shim -> black screen. The shim clears SDL_VIDEODRIVER before initializing the
# inner firmware SDL2, so the inner layer still auto-picks.
export SDL_VIDEODRIVER=sdl2

# ROCKNIX's inner SDL2 doesn't reliably auto-pick wayland (lands on x11/kmsdrm
# and fails), so pin it there only.
if [ "$CFW_NAME" = "ROCKNIX" ]; then
  export SDL3SHIM_SDL2_VIDEODRIVER=wayland
fi

# Pin CPU/GPU/DMC governors to performance for the session, restore on exit.
# Ondemand costs ~3 fps on RK3326 under this game's bursty load. Generic sysfs
# globs rather than the CFW's perfmax (which hardcodes RK3326 paths and grabs
# the tty); nodes without a "performance" governor are left alone.
GOV_NODES=()
GOV_PREV=()
for g in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor \
         /sys/class/devfreq/*/governor; do
  [ -f "$g" ] || continue   # unmatched glob stays literal without nullglob
  case "$g" in
    */cpufreq/*) avail="${g%/*}/scaling_available_governors" ;;
    *)           avail="${g%/*}/available_governors" ;;
  esac
  if [ -r "$avail" ] && ! grep -qw performance "$avail"; then
    continue
  fi
  prev="$(cat "$g" 2>/dev/null)"
  [ "$prev" = "performance" ] && continue
  GOV_NODES+=("$g")
  GOV_PREV+=("$prev")
  $ESUDO sh -c "echo performance > '$g'" 2>/dev/null
done

restore_governors() {
  local i
  for i in "${!GOV_NODES[@]}"; do
    [ -n "${GOV_PREV[$i]}" ] && \
      $ESUDO sh -c "echo '${GOV_PREV[$i]}' > '${GOV_NODES[$i]}'" 2>/dev/null
  done
}

$GPTOKEYB "dusklight.aarch64" >/dev/null 2>&1 &

pm_platform_helper "$GAMEDIR/dusklight.aarch64" > /dev/null
# --dvd: without it a fresh install drops into the prelaunch disc-picker.
# --backend opengles stays on the CLI, not in config: a missing or corrupted
#   config.json resolves backend "auto", and the failed Vulkan attempt breaks the
#   following EFB present init -> startup abort. This keeps a bad config bootable.
# --log-level info: borealis log levels are words; drops the per-resource flood.
./dusklight.aarch64 --backend opengles --log-level info --dvd "${discs[0]}"

$ESUDO kill -9 $(pidof gptokeyb2) 2>/dev/null
restore_governors
pm_finish
