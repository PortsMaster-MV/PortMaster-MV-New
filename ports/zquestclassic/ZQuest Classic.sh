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

GAMEDIR=/$directory/ports/zquestclassic
BINARY=zplayer.${DEVICE_ARCH}

cd $GAMEDIR

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

ARCHIVE_FILE="gamedata.tar.gz"
if [[ -f "$ARCHIVE_FILE" ]]; then
    pm_message "Extracting game data, this can take a few minutes..."
    if gunzip -c "$ARCHIVE_FILE" | tar --no-same-owner -xf -; then
        pm_message "Extraction successful."
        $ESUDO rm -f "$ARCHIVE_FILE"
    else
        pm_message "Error: Extraction failed."
        sleep 5
        exit 1
    fi
elif [ ! -f 'modules/classic.zmod' ]; then
    pm_message "Error: No game data present and archive file $ARCHIVE_FILE not found."
    sleep 5
    exit 1
fi

for zip in quests/*.zip; do
    [ -f "$zip" ] || continue
    pm_message "Unpacking $(basename "$zip")..."
    if unzip -qo "$zip" -d "${zip%.zip}"; then
        $ESUDO rm -f "$zip"
    else
        pm_message "Error: Could not unpack $(basename "$zip")."
        sleep 5
    fi
done

export LD_LIBRARY_PATH="$GAMEDIR/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

if [ "${DISPLAY_WIDTH:-640}" -gt 1280 ]; then
  sed -i "s/^deadzone_scale = .*/deadzone_scale = 18/" "$GAMEDIR/zquestclassic.ini"
fi

$GPTOKEYB2 "zplayer" -c "$GAMEDIR/zquestclassic.ini" > /dev/null 2>&1 &

pm_platform_helper "$GAMEDIR/$BINARY"

./$BINARY -fullscreen

pm_finish
