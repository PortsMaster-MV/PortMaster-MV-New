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
get_controls

# Source Device Info
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

# Set variables
GAMEDIR="/$directory/ports/soh"

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs:/usr/lib":$LD_LIBRARY_PATH
export SDL_GAMECONTROLLERCONFIG=$sdl_controllerconfig
export PATCHER_FILE="$GAMEDIR/assets/extractor/otrgen"
export PATCHER_GAME="$(basename "${0%.*}")" # This gets the current script filename without the extension
export PATCHER_TIME="5 to 10 minutes"

# CD and set permissions
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x -R $GAMEDIR/*


# List of compatibility firmwares
CFW_NAMES="ArkOS:ArkOS wuMMLe:ArkOS AeUX:knulli:TrimUI"

# Check if the current CFW name is in the list
contains() {
    local value="$CFW_NAME"
    local item
    local tmp=$IFS
    IFS=":" # Use : as the delimiter
    echo "Checking if CFW_NAME '$value' is in the list..."
    for item in $CFW_NAMES; do
        echo "Comparing '$item' with '$value'..."
        if [ "$item" = "$value" ]; then
            echo "Match found: '$item'"
            IFS=$tmp
            return 0
        fi
    done
    echo "No match found for '$value'."
    IFS=$tmp
    return 1
}

# If it's in the list use the compatibility binary
if contains "$CFW_NAME" $CFW_NAMES; then
    cp -f "$GAMEDIR/bin/compatibility.elf" "$GAMEDIR/soh.elf"
    if [ "$(find ./mods -name '*.otr')" ]; then
        echo "WARNING: .OTR MODS FOUND! PERFORMANCE WILL BE LOW IF ENABLED!!" > $CUR_TTY
    fi
else
    cp -f "$GAMEDIR/bin/performance.elf" "$GAMEDIR/soh.elf"
fi

if [ ! -f "oot.otr" ] || [ ! -f "oot-mq.otr" ]; then
    # Ensure we have a rom file before attempting to generate otr
    if ls *.*64 1> /dev/null 2>&1; then
        if [ -f "$controlfolder/utils/patcher.txt" ]; then
            source "$controlfolder/utils/patcher.txt"
            $ESUDO kill -9 $(pidof gptokeyb)
        else
            echo "This port requires the latest version of PortMaster." > $CUR_TTY
        fi
    else
        echo "Missing ROM files! Can't generate otr!"
    fi
fi

# Check if OTR files were generated
if [ ! -f "oot.otr" ] && [ ! -f "oot-mq.otr" ]; then
    echo "No otr files, can't run the game!"
    exit 1
fi

# Run the game
echo "Loading, please wait... (might take a while!)" > $CUR_TTY
$GPTOKEYB "soh.elf" -c "soh.gptk" & 
./soh.elf

# Cleanup
rm -rf "$GAMEDIR/logs/"
$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events & 
printf "\033c" > /dev/tty1
printf "\033c" > /dev/tty0
