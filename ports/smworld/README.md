
###Extract Assets

For Windows 

Dependencies and requirements:

You'll need TCC and SDL2 in order to compile using TCC.
Rename your obtained US Super Mario World rom to smw.sfc and place it in the root folder.
Unzip both TCC and SDL2 and place them in third_party folder.
Double click run_with_tcc.bat
Wait for it to compile and the game will automatically boot-up.

For Mac OSX/Linux

Open a terminal
Install pip if not already installed
python3 -m ensurepip
Clone the repo and cd into it
git clone https://github.com/snesrev/smw.git
cd smw
Install SDL2
Ubuntu/Debian sudo apt install libsdl2-dev
Fedora Linux sudo dnf install SDL2-devel
Arch Linux sudo pacman -S sdl2
macOS: brew install sdl2
Place your US ROM file named smw.sfc in smw
Compile
make (suggested make -j$(nproc) )


Then we will have our .dat file  


Pack with smb1 and smbll boot script included. 
To extract the 2 rom file called smbll.sfc and smb1.sfc you need to place the us rom of super mario all star renamed smas.sfc inside the "other" folder and do this
pip install zstandard
then while inside the smw folder
cd other
python3 extract.py
at this point you should have the the 2 sfc files to copy in the root of the game folder