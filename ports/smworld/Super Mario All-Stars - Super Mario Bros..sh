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
ZSTD="tools/zstd"
ROM_SMAS="smas.sfc"
ROM_SMAS_MD5_EXPECTED="53c038150ba00d5f8d8574b4d36283f2"
ROM_GAME="smb1.sfc"
ROM_GAME_MD5_EXPECTED="38c93291765e3eb520bfa29158566dc0"
ROM_GAME_ZST="tools/smb1.zst"
ROM_SMW="smw.sfc"
ROM_SMW_MD5_EXPECTED="cdd3c8c37322978ca8669b34bc89c804"

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
$ESUDO chmod -v +x "$GAMEDIR/$ZSTD"

# Check the game ROM file
echo "checking for $ROM_GAME..."
if [ -f "./$ROM_GAME" ]; then

	# We found the game ROM. Does the checksum match?
	echo "found $ROM_GAME!"
	ROM_GAME_MD5_ACTUAL=$(md5sum "./$ROM_GAME" | awk '{print $1}')
	if [ "$ROM_GAME_MD5_ACTUAL" = "$ROM_GAME_MD5_EXPECTED" ]; then

		# The checksum of the game ROM does match. Proceed.
		echo "$ROM_GAME : $ROM_GAME_MD5_ACTUAL matches expected checksum!"
	else

		# The checksum of the game ROM doesn't match. Where did this file even come from? Try again.
		echo "$ROM_GAME : $ROM_GAME_MD5_ACTUAL checksum mismatch, expected $ROM_GAME_MD5_EXPECTED!"
		pm_message "$GAMEDIR/$ROM_GAME does not match the expected checksum. Please delete $ROM_GAME, and then run this game again in order to regenerate $ROM_GAME from $ROM_SMAS."
		sleep 5
		exit 1
	fi
else

	# We didn't find the game ROM. Attempt to create it.
	echo "$ROM_GAME missing!"
	echo "attempting to dump $ROM_GAME from $ROM_SMAS..."

	# We need an All-Stars ROM for this
	echo "checking for $ROM_SMAS..."
	if [ -f "./$ROM_SMAS" ]; then

		# We found an All-Stars ROM. Does the checksum match?
		echo "found $ROM_SMAS!"
		ROM_SMAS_MD5_ACTUAL=$(md5sum "./$ROM_SMAS" | awk '{print $1}')
		if [ "$ROM_SMAS_MD5_ACTUAL" = "$ROM_SMAS_MD5_EXPECTED" ]; then

			# The All-Stars ROM does match the checksum. Try to dump the game ROM.
			echo "$ROM_SMAS : $ROM_SMAS_MD5_ACTUAL matches expected checksum!"
			echo "dumping $ROM_GAME from $ROM_SMAS..."
			"./$ZSTD" -D "./$ROM_SMAS" -d "./$ROM_GAME_ZST" -o "./$ROM_GAME"

			# Did the dump produce the expected game ROM?
			ROM_GAME_MD5_ACTUAL=$(md5sum "./$ROM_GAME" | awk '{print $1}')
			if [ "$ROM_GAME_MD5_ACTUAL" = "$ROM_GAME_MD5_EXPECTED" ]; then

				# Our newly dumped game ROM does match the checksum. Proceed.
				echo "$ROM_GAME : $ROM_GAME_MD5_ACTUAL matches expected checksum, dump successful!"
			else

				# Our newly dumped game ROM doesn't match the checksum. This probably can't ever happen. Try again?
				echo "$ROM_GAME : $ROM_GAME_MD5_ACTUAL checksum mismatch, expected $ROM_GAME_MD5_EXPECTED, dump failed!"
				pm_message "$GAMEDIR/$ROM_GAME does not match the expected checksum. Please delete $ROM_GAME, and then run this game again in order to regenerate $ROM_GAME from $ROM_SMAS."
				sleep 5
				exit 1
			fi
		else

			# The All-Stars ROM doesn't match the checksum. We can't use this All-Stars ROM.
			echo "$ROM_SMAS : $ROM_SMAS_MD5_ACTUAL checksum mismatch, expected $ROM_SMAS_MD5_EXPECTED!"
			echo "unable to dump $ROM_GAME from $ROM_SMAS!"
			pm_message "$GAMEDIR/$ROM_SMAS does not match the expected checksum. Please replace $ROM_SMAS with a valid ROM, having an MD5 checksum of $ROM_SMAS_MD5_EXPECTED. This file is required in order to generate $ROM_GAME."
			sleep 5
			exit 1
		fi
	else

		# We didn't find an All-Stars ROM to use
		echo "$ROM_SMAS missing!"
		pm_message "$GAMEDIR/$ROM_SMAS not found. Please supply a valid ROM file, having an MD5 checksum of $ROM_SMAS_MD5_EXPECTED. This file is required in order to generate $ROM_GAME."
		sleep 5
		exit 1
	fi
fi

# Check the SMW ROM, which is also required
echo "checking for $ROM_SMW..."
if [ -f "./$ROM_SMW" ]; then

	# We found an SMW ROM. Does the checksum match?
	echo "found $ROM_SMW!"
	ROM_SMW_MD5_ACTUAL=$(md5sum "./$ROM_SMW" | awk '{print $1}')
	if [ "$ROM_SMW_MD5_ACTUAL" = "$ROM_SMW_MD5_EXPECTED" ]; then

		# The SMW ROM does match the checksum. Proceed.
		echo "$ROM_SMW : $ROM_SMW_MD5_ACTUAL matches expected checksum!"
	else

		# The SMW ROM doesn't match the checksum. We can't use this SMW ROM.
		echo "$ROM_SMW : $ROM_SMW_MD5_ACTUAL checksum mismatch, expected $ROM_SMW_MD5_EXPECTED!"
		pm_message "$GAMEDIR/$ROM_SMW does not match the expected checksum. Please replace $ROM_SMW with a valid ROM, having an MD5 checksum of $ROM_SMW_MD5_EXPECTED."
		sleep 5
		exit 1
	fi
else

	# We didn't find an SMW ROM to use
	echo "$ROM_SMW missing!"
	pm_message "$GAMEDIR/$ROM_SMW not found. Please supply a valid ROM file, having an MD5 checksum of $ROM_SMW_MD5_EXPECTED."
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
echo "launching $GAME with $ROM_GAME"
"./$GAME" "$ROM_GAME"

# Cleanup
pm_finish
