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

# Set variables
GAMEDIR="/$directory/ports/soh2"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Source Device Info
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

CUR_TTY="/dev/tty0"
# Set current virtual screen
if [ "$CFW_NAME" == "muOS" ]; then
  /opt/muos/extra/muxlog & CUR_TTY="/tmp/muxlog_info"
fi

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs:/usr/lib"

# Permissions
$ESUDO chmod 0777 /dev/tty0

cd $GAMEDIR

# Array of compatibility firmwares
CFW_NAMES=("ArkOS" "ArkOS wuMMLe" "ArkOS AeUX" "knulli")

# Function to check if a value is in an array
contains() {
    local value="$1"
    shift
    for item; do
        if [ "$item" == "$value" ]; then
            return 0
        fi
    done
    return 1
}

# Check if the current CFW name is in the array
if contains "$CFW_NAME" "${CFW_NAMES[@]}"; then
    cp -f "$GAMEDIR/bin/compatibility.elf" 2s2h.elf
    if [ "$(find "./mods" -name '*.o2r')" ]; then
        echo "WARNING: .OTR MODS FOUND! PERFORMANCE WILL BE LOW IF ENABLED!!" > $CUR_TTY
    fi
else
    cp -f "$GAMEDIR/bin/performance.elf" 2s2h.elf
fi

# Check if we need to generate any o2r files
if [ ! -f "mm.o2r" ]; then
    if ls *.*64 1> /dev/null 2>&1; then
        echo "We need to generate O2R files! Stand by..." > $CUR_TTY
        ./assets/extractor/otrgen.txt
    fi
fi

# Run the game
echo "Loading, please wait... (might take a while!)" > $CUR_TTY
$GPTOKEYB "2s2h.elf" -c "soh2.gptk" & 
./2s2h.elf

# Cleanup
rm -rf "$GAMEDIR/logs/"
$ESUDO systemctl restart oga_events & 
printf "\033c" >> /dev/tty1
printf "\033c" > /dev/tty0
