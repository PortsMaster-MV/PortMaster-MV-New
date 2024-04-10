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
source $controlfolder/device_info.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Set variables
GAMEDIR="/$directory/ports/soh"

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/libs:/usr/lib"

cd $GAMEDIR

# Apply config.ini settings
apply_settings() {
    # Check preset value and copy preset.json accordingly
    preset_value=$(grep -Po 'preset=\K\w+' config.ini)
    case $preset_value in
        default)
            cp "presets/default.json" "shipofharkinian.json"
            ;;
        vanillaplus)
            cp "presets/vanillaplus.json" "shipofharkinian.json"
            ;;
        enhanced)
            cp "presets/enhanced.json" "shipofharkinian.json"
            ;;
        randomizer)
            cp "presets/randomizer.json" "shipofharkinian.json"
            ;;
        custom)
            ;;
        *)
            cp "presets/default.json" "shipofharkinian.json"
            ;;
    esac

	# Define array of keys to extract
	keys=("internalresolution" "interpolationfps" "authenticlogo" "disablelod" "disabledrawdistance" "disablekokiridrawdistance" "usecustomtextures" "remembersavelocation" "fileselectmoreinfo")

	# Iterate over keys and extract corresponding values from config.ini
	for key in "${keys[@]}"; do
		value=$(grep -Po "${key}=\K[^;]+" config.ini)
		declare "$key=$value"
	done

    # Modify the copied shipofharkinian.json according to additional options
    sed -i -E \
		-e "s/gAltAssets\": [01]+,/gAltAssets\": $usecustomtextures,/" \
		-e "s/gAuthenticLogo\": [01],/gAuthenticLogo\": $authenticlogo,/" \
		-e "s/gDisableLOD\": [01]+,/gDisableLOD\": $disablelod,/" \
		-e "s/gDisableDrawDistance\": [01]+,/gDisableDrawDistance\": $disabledrawdistance,/" \
		-e "s/gDisableKokiriDrawDistance\": [01]+,/gDisableKokiriDrawDistance\": $disablekokiridrawdistance,/" \
		-e "s/gFileSelectMoreInfo\": [01]+,/gFileSelectMoreInfo\": $fileselectmoreinfo,/" \
		-e "s/gInternalResolution\": [0-9]+(\.[0-9]+)?,/gInternalResolution\": $internalresolution,/" \
		-e "s/gInterpolationFPS\": [0-9]+,/gInterpolationFPS\": $interpolationfps,/" \
		-e "s/gRememberSaveLocation\": [01]+,/gRememberSaveLocation\": $remembersavelocation,/" \
        shipofharkinian.json
}

apply_settings

# Copy the right build to the main folder
if [ $CFW_NAME == "ArkOS" ]; then
	cp -f bin/compatibility.elf soh.elf
	cp -f bin/compatibility.otr soh.otr
	if [ "$(find "./mods" -name '*.otr')" ]; then
		echo "WARNING: .OTR MODS FOUND! PERFORMANCE WILL BE LOW IF ENABLED!!" > /dev/tty0
	fi
else
	cp -f bin/performance.elf soh.elf
	cp -f bin/performance.otr soh.otr
fi

# Run the game
echo "Loading, please wait... (might take a while!)" > /dev/tty0
$GPTOKEYB "soh.elf" -c "soh.gptk" & 
./soh.elf
$ESUDO systemctl restart oga_events & 
printf "\033c" >> /dev/tty1
printf "\033c" > /dev/tty0
