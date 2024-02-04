## Extract Assets

Rom Checksum 66871d66be19ad2c34c927d6b14cd8eb6fc3181965b6e517cb361f7316009cfb

For Windows users you just need to download https://github.com/RadzPrower/Zelda-3-Launcher and use your rom to create a windows build, that will include the .dat file that we need.

For Mac OSX/Linux

1. Open a terminal
2. Install pip if not already installed
     python3 -m ensurepip
3. Clone the repo and cd into it
     git clone https://github.com/snesrev/zelda3
     cd zelda3
4. Install requirements using pip
     python3 -m pip install -r requirements.txt
5. Install SDL2
     Ubuntu/Debian sudo apt install libsdl2-dev
     Fedora Linux sudo dnf install SDL2-devel
     Arch Linux sudo pacman -S sdl2
     macOS: brew install sdl2 
6. Place your US ROM file named zelda3.sfc in zelda3
7. Compile
     make (suggested make -j$(nproc) )

Then we will have our .dat file into the zelda3 folder 