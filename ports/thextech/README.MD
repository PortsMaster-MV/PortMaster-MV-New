## WHAT IS THEXTECH ?

This is a direct continuation of the SMBX 1.3 engine. Originally it was written in VB6 for Windows, and later, it got ported/rewritten into C++ and became a cross-platform engine. 
It completely reproduces the old SMBX 1.3 engine (aside from its Editor), includes many of its logical bugs (critical bugs that lead the game to crash or freeze got fixed), and also adds a lot of new updates and features.  
This build is packed to be compatible with linux based handhelds that support Portmaster project (https://portmaster.games/)  
Thanks to TheXTech project, Portmaster Community and @ds-sloth developer who supported me.

## HOW TO BUILD

For better compatibility TheXTech was build in Ubuntu 20.04 arm64 chroot.

```
git clone --recurse-submodules https://github.com/TheXTech/TheXTech.git
```

then edit CMakeLists.txt (or else it will not build inside such old environment) and add line:
```
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
```
then we start to build:
```
mkdir build
cd ./build
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DUSE_SYSTEM_SDL2=ON -DTHEXTECH_BUILD_GL_DESKTOP_MODERN=OFF -DTHEXTECH_BUILD_GL_DESKTOP_LEGACY=OFF -DTHEXTECH_BUILD_GL_ES_LEGACY=OFF ..
make
```


## HOW TO RUN

Package contains only open source engine. For gaming you need assets (sprites, music and etc.), you can find them at the original github project. 
Default asset pack can be downloaded from https://github.com/TheXTech/TheXTech/releases, file "thextech-smbx13-assets-full.7z".  
Unpack content of the archive into
```
./thextech/assets/smbx
```
folder.
Game is ready to run!

Additional downloaded worlds and episodes can be put into
```
./thextech/worlds/smbx
```


## CONTROLS

Game uses GameController API for all inputs exept cursor movement.  
Adjust controls in OPTIONS - > CONTROLS -> GAMEPAD  
Cursor is mapped to right analog stick with the help of gptokeyb tool.  
R2 is left button mouse click  
L2 is right button mouse click  

To avoid problems with simultaneous cursor control from a gamepad and mouse, go to the  
OPTIONS -> CONTROLS -> Gamepad (In Use) -> Chose your gamepad -> Cursor controls  
and remove any mappings to real buttons.


## PERFORMANCE FIX

If your title screen is lagging because of many characters running at the same time, you can add
```
[intro]
enable-activity=true
max-players-count=2
```
inside 
```
./thextech/assets/assets_name_folder/gameinfo.ini
```


## ROCKNIX Powkiddy X55 gamepad fix

There are reports that TheXTech has problems detecting gamepad for this particular device. Solution is to edit TheXTech.sh line#34
```
$GPTOKEYB "thextech" -c "$GAMEDIR/thextech.gptk" &
```
replace with 
```
$GPTOKEYB "thextech" xbox360 &
```
