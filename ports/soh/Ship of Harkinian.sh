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

# Permissions
$ESUDO chmod 666 /dev/tty0
$ESUDO chmod 666 /dev/tty1

cd $GAMEDIR

# Remove soh generated logs and substitute our own
rm -rf $GAMEDIR/logs/* && exec > >(tee "$GAMEDIR/logs/log.txt") 2>&1

# Copy the right build to the main folder
if [ "$CFW_NAME" == 'ArkOS' ] || [ "$CFW_NAME" == 'ArkOS wuMMLe' ] || [ "$CFW_NAME" == "knulli" ]; then
	cp -f "$GAMEDIR/bin/compatibility.elf" soh.elf
	if [ "$(find "./mods" -name '*.otr')" ]; then
		echo "WARNING: .OTR MODS FOUND! PERFORMANCE WILL BE LOW IF ENABLED!!" > /dev/tty0
	fi
else
	cp -f "$GAMEDIR/bin/performance.elf" soh.elf
fi

# Run the game
echo "Loading, please wait... (might take a while!)" > /dev/tty0

$GPTOKEYB "soh.elf" -c "soh.gptk" & 
./soh.elf

# Cleanup
rm -rf "$GAMEDIR/logs/Ship of Harkinian.log"
$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events & 
printf "\033c" > /dev/tty1
printf "\033c" > /dev/tty0
