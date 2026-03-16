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
GAMEDIR="/$directory/ports/soh2"

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG=$sdl_controllerconfig

# CD and set permissions
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
$ESUDO chmod +x "$GAMEDIR/2s2h.elf.${DEVICE_ARCH}"
$ESUDO chmod +x "$GAMEDIR/assets/otrgen"

# Close the menu if open
sed -i 's/"Menu": *1/"Menu": 0/' 2ship2harkinian.json

# -------------------- BEGIN FUNCTIONS --------------------

# Check imgui.ini and modify if needed
imgui_reset() {
    input_file="imgui.ini"
    temp_file="imgui_temp.ini"
    skip_section=0
    # Loop through each line in the input file
    while IFS= read -r line; do
        # Check if the line is a window header
        if [[ "$line" =~ ^\[Window\]\[Main\ Game\] || "$line" =~ ^\[Window\]\[Main\ -\ Deck\] ]]; then
            skip_section=1  # Set the flag to skip modifications for this section
        elif [[ "$line" =~ ^\[Window\] ]]; then
            skip_section=0  # Reset the flag for other windows
        fi

        # Modify Pos and Size only if the current section is not skipped
        if [[ $skip_section -eq 0 ]]; then
            if [[ "$line" =~ ^Pos=.* ]]; then
                echo "Pos=30,30" >> "$temp_file"
            elif [[ "$line" =~ ^Size=.* ]]; then
                echo "Size=400,300" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        else
            # If skipping, write the line unchanged
            echo "$line" >> "$temp_file"
        fi
    done < "$input_file"

    # Replace the original file with the modified one
    mv "$temp_file" "$input_file"
}

o2r_check() {

# Warn if mm.o2r is older than 2s2h.elf or 2ship.o2r
if [ -f "$GAMEDIR/mm.o2r" ]; then
    if [ -f "$GAMEDIR/2s2h.elf.${DEVICE_ARCH}" ] && [ "$GAMEDIR/2s2h.elf.${DEVICE_ARCH}" -nt "$GAMEDIR/mm.o2r" ] \
       || [ -f "$GAMEDIR/2ship.o2r" ] && [ "$GAMEDIR/2ship.o2r" -nt "$GAMEDIR/mm.o2r" ]; then
        pm_message "Notice: mm.o2r is older than 2s2h.elf and/or 2ship.o2r. Forcing regeneration."
        rm -f "$GAMEDIR/mm.o2r"
        REGEN=1
        export REGEN
    fi
fi

if [ ! -f "mm.o2r" ]; then
    # Ensure we have a rom file before attempting to generate o2r
    if ls "$GAMEDIR/baseroms/"*.*64 1> /dev/null 2>&1; then
        if [ -f "$controlfolder/utils/patcher.txt" ]; then
            export PATCHER_FILE="$GAMEDIR/assets/otrgen"
            export PATCHER_GAME="$(basename "${0%.*}")"
            export PATCHER_TIME="5 to 10 minutes"
            export controlfolder
            export DEVICE_ARCH
            source "$controlfolder/utils/patcher.txt"
            $ESUDO kill -9 $(pidof gptokeyb)
        else
            pm_message "This port requires the latest version of PortMaster."
        fi
    else
        pm_message "Missing ROM files in $GAMEDIR/baseroms! Can't generate o2r!"
        exit 1
    fi
    
    # Check if OTR files were generated
    if [ ! -f "mm.o2r" ]; then
        pm_message "No o2r files, can't run the game!"
        exit 1
    fi
fi
}

# --------------------- END FUNCTIONS ---------------------

# Perform functions
o2r_check

if [ -f "imgui.ini" ]; then
    imgui_reset
fi

# Run the game
$GPTOKEYB "2s2h.elf.${DEVICE_ARCH}" -c "soh2.gptk" & 
pm_platform_helper "2s2h.elf.${DEVICE_ARCH}" >/dev/null
./2s2h.elf.${DEVICE_ARCH}

# Cleanup
rm -rf "$GAMEDIR/logs"
pm_finish
