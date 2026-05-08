#!/bin/bash

# PortMaster preamble
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
GAMEDIR="/$directory/ports/smworld"
GAME="smworld"
ROM="smw.sfc"
ROM_MD5_EXPECTED="cdd3c8c37322978ca8669b34bc89c804"

# Set up logging. log.txt will be overwritten with each new launch of the game.
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Log device info
echo "Device info:"
$controlfolder/device_info.txt 2> /dev/null

# Enter the game directory
echo "entering $GAMEDIR"
cd $GAMEDIR
echo "ls -lAh $GAMEDIR:"
ls -lAh $GAMEDIR

# Ensure executable permissions
$ESUDO chmod -v +x "$GAMEDIR/$GAME"

# Check the SMW ROM
echo "checking for $ROM..."
if [ -f "./$ROM" ]; then

	# We found an SMW ROM. Does the checksum match?
	echo "found $ROM!"
	ROM_MD5_ACTUAL=$(md5sum "./$ROM" | awk '{print $1}')
	if [ "$ROM_MD5_ACTUAL" = "$ROM_MD5_EXPECTED" ]; then

		# The SMW ROM does match the checksum. Proceed.
		echo "$ROM : $ROM_MD5_ACTUAL matches expected checksum!"
	else

		# The SMW ROM doesn't match the checksum. We can't use this SMW ROM.
		echo "$ROM : $ROM_MD5_ACTUAL checksum mismatch, expected $ROM_MD5_EXPECTED!"
		pm_message "$GAMEDIR/$ROM does not match the expected checksum. Please replace $ROM with a valid ROM, having an MD5 checksum of $ROM_MD5_EXPECTED."
		sleep 5
		exit 1
	fi
else

	# We didn't find an SMW ROM to use
	echo "$ROM missing!"
	pm_message "$GAMEDIR/$ROM not found. Please supply a valid ROM file, having an MD5 checksum of $ROM_MD5_EXPECTED."
	sleep 5
	exit 1
fi

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# Log the controller configuration
echo "SDL_GAMECONTROLLERCONFIG=$SDL_GAMECONTROLLERCONFIG"

# Launch the game
$GPTOKEYB2 "$GAME" -c "$GAMEDIR/$GAME.gptk" &>/dev/null &
pm_platform_helper "$GAME"
echo "launching $GAME"
"./$GAME"

# Cleanup
pm_finish
