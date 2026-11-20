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

# Set variables
GAMEDIR="/$directory/ports/starship"

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}":$LD_LIBRARY_PATH
export SDL_GAMECONTROLLERCONFIG=$sdl_controllerconfig

# CD and set log
cd $GAMEDIR
: > "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x "$GAMEDIR/Starship.${DEVICE_ARCH}" "$GAMEDIR/assets/torch.${DEVICE_ARCH}"
mkdir -p "$GAMEDIR/mods"

# -------------------- BEGIN FUNCTIONS --------------------

# torch reads config.yml and assets/yaml/ from the working directory
unzip_assets() {
    if [ -f "$GAMEDIR/assets/extractor.zip" ]; then
        $LOVE_RUN "$GAMEDIR/extract" --text "Unpacking extractor assets..." assets/extractor.zip || exit 1
        rm -f "$GAMEDIR/assets/extractor.zip"
    fi
}

# Starship's in-game extraction needs a desktop file dialog, so convert the roms with the
# standalone torch instead: US -> sf64.o2r, JP/EU/CN -> mods/sf64*.o2r voice packs
find_roms() {
    ROMS=()
    if [ ! -f "sf64.o2r" ]; then
        for rom in "$GAMEDIR/baseroms/"*.z64; do
            [ -f "$rom" ] && ROMS+=("$rom")
        done
        if [ ${#ROMS[@]} -eq 0 ]; then
            pm_message "Missing ROM! Place a Star Fox 64 US .z64 in baseroms/"
            sleep 5
            pm_finish
            exit 0
        fi
    fi
}

extract_roms() {
    [ ${#ROMS[@]} -eq 0 ] && return
    # The extract app shows the message while torch runs (a pm_message window stays up and
    # uses CPU); a failed voice-pack rom must not stop the others
    args=()
    for rom in "${ROMS[@]}"; do
        r=$(printf %q "$rom")
        args+=(--run "assets/torch.${DEVICE_ARCH} o2r $r || echo torch failed on $r")
    done
    $LOVE_RUN "$GAMEDIR/extract" --text "Converting roms, this can take a few minutes..." "${args[@]}"
    if [ ! -f "sf64.o2r" ]; then
        pm_message "No sf64.o2r created! A Star Fox 64 US v1.0 or v1.1 rom is required."
        sleep 5
        pm_finish
        exit 0
    fi
}

# --------------------- END FUNCTIONS ---------------------

# Launcher (Love2D): frame rate, low-res mode, voices, invert Y; also closes the menu bar and
# enables controller navigation in starship.cfg.json
rm -f "$GAMEDIR/launch.cfg"
source $controlfolder/runtimes/"love_11.5"/love.txt
$LOVE_RUN "$GAMEDIR/launcher" "$GAMEDIR/starship.cfg.json" "$GAMEDIR/launch.cfg"

# Continue only if the user chose Play (launcher writes LAUNCHER_PLAY=1 to launch.cfg)
if ! grep -qx "LAUNCHER_PLAY=1" "$GAMEDIR/launch.cfg" 2>/dev/null; then
  pm_finish
  exit 0
fi

# Perform functions
unzip_assets
find_roms ||{ pm_finish; exit 0; }
extract_roms

# Run the game
$GPTOKEYB "Starship.${DEVICE_ARCH}" -c "starship.gptk" &
pm_platform_helper "Starship.${DEVICE_ARCH}" >/dev/null
./Starship.${DEVICE_ARCH}

# Cleanup
rm -rf "$GAMEDIR/logs/"
pm_finish
