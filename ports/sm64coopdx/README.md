
# sm64coopdx port

[sm64coopdx](https://github.com/coop-deluxe/sm64coopdx) is a game based on the Super Mario 64 engine and modified to have multiplayer and mods.

CFW Tests:
[✓] AmberELEC
[✓] ArkOS
[✓] ROCKNIX
[✓] MuOS
[✓] Knulli (Optional)
[ ] Crossmix (Optional)

GPU driver: 
[✓] Mali
[✓] Panfrost (Mainline)
[✓] Adreno (SM8x50)

Resolutions: 
[ ] 480x320 (Optional)
[✓] 640x480
[✓] 720x720 (RGB30) (Optional)
[✓] Higher resolutions (e.g., 1280x720)

# Disclaimer

You must own a legal copy of the Super Mario 64 rom.

Don't ask Portmaster for help on how to obtain this copy.

# Requirements

1. A debian bullseye chroot for aarch64 architecture.
2. An original rom of Super Mario 64 (USA version).

# Build Instruccions

1. Inside the chroot, install these packages:

```
sudo apt install build-essential git python3 libglew-dev libsdl2-dev libz-dev libcurl4-openssl-dev
```

2. Get the latest source code in [sm64coopx](https://github.com/coop-deluxe/sm64coopdx/releases/latest) and decompress them.

3. Apply the patch fixsources.patch in the root directory

> [!WARNING]
> for compatibility reasons some libraries already compiled in the sm64coopdx source have to be recompiled and replaced, be careful when getting the packages and using the libraries not to cause problems on the world servers. (libcoopnet has not released a version, so you will have to get it via git clone or by downloading the package from the last commit, note that if the developers have not changed the library to this new version you will have to stick with the release and fix dates, additionally you will also have to change the headers to not have compatibility problems).

4. Compile the [libcoopdx](https://github.com/Isaac0-dev/coopnet.git) and [libjuice](https://github.com/paullouisageneau/libjuice) libraries and replace them in the lib/coopnet/linux directory:

libcoopdx-arm64.a
libjuice-arm64.a

5. Once the libraries have been replaced we proceed to compile with the following command:

```
make HANDHELD=1 -j(NUMBER OF JOBS)
```
(the parameter of the jobs are optional)

6. The binary and the folder where this list resides, now we have to delete some residual files that are no longer of importance, all the folders will be deleted except the following ones:

```
dynos/, lang/, mods/, palettes/,
```

additionally you have to modify the binary name to sm64coopdx.aarch64

7. The us_pc folder contains the binary and files, rename the folder to sm64coopdx and you will have your port ready.

# Post install

After installing the port via portmaster you will have to copy your rom to the port directory with the name “baserom.us.z64”.

run the port and enjoy!

