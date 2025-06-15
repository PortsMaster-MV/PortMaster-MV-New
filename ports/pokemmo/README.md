[PokeMMO port: https://github.com/lowlevel-1989/pokemmo-port](https://github.com/lowlevel-1989/pokemmo-port)

# PokeMMO Port for PortMaster

PokeMMO is a fan-made multiplayer online game that brings together multiple generations of Pokémon in a single MMO experience.

---

## 🛠 Installation Instructions

### CFW Tests:

|                        | 480x320 | 640x480 | 720x720 | Higher resolutions |
|------------------------|---------|---------|---------|--------------------|
| Playable?              | No      | Yes     | Yes     | Yes                |
| Create new character?  | No      | Yes (small, android)      | Yes     | Yes                |
| All regions?           | No      | Yes     | Yes     | Yes                |
| Global trade link                     | No      | Yes (small, android)    | Yes (small, android)    | Yes                |
| PC                     | No      | Yes (small, android)    | Yes (small, android)    | Yes                |

~~~
- [x] AmberELEC
- [x] ArkOS
- [x] Rocknix
    -> [x] Panfrost
    -> [x] Libmali
- [x] MuOS
- [x] Knulli
- [x] spruceOS (advanced user, tutorial coming soon)
    -> You only need to manually install PortMaster via ssh
~~~

### How do I enter the `security code` in PokeMMO?

- Press: Select + Y to enable virtual keyboard.
- Press: Select to toggle number/text
- Dpad Up/Down to select value,  A to add, B to remove.
- Start to disable virtual keyboard.

### What is `hack.jar`?

`hack.jar` is a Java package that allows loading optimized shaders into memory for the following custom firmware (CFW).  
If a `credentials.txt` file exists, it will use the username and password specified there, but only during application startup.

The source code can be found here:  
👉 [PokeMMO/src](https://github.com/lowlevel-1989/pokemmo-port/pokemmo/src)

| Operating System       | Requires `hack.jar`? | Known Issues Without `hack.jar`                                                   |
|------------------------|----------------------|------------------------------------------------------------------------------------|
| **ArkOS**              | ✅ Yes               | - Screen freezes when flying<br>- Starter Pokémon selection in NDS<br>- Freeze in Johto |
| **Rocknix (Panfrost)** | ❌ No                | - Works fine without `hack.jar`                                                   |
| **Rocknix (Libmali)**  | ✅ Yes               | - Same issues as ArkOS                                                             |
| **MuOS**               | ✅ Yes               | - Screen freezes when flying<br>- Starter Pokémon selection in NDS<br>- Freeze in Johto |
| **Knulli**             | ✅ Yes               | - Screen freezes when flying<br>- Starter Pokémon selection in NDS<br>- Freeze in Johto |
| **spruceOS**           | ✅ Yes               | - Screen freezes when flying<br>- Starter Pokémon selection in NDS<br>- Freeze in Johto |

### 🎮 Experiencing FPS Drops?

The default configuration included with this port is optimized and tested for **low-end devices**, prioritizing compatibility and performance in **power-saving mode**.

#### ⚙️ If You're Experiencing Lag:
- The most common reason for FPS drops is **changing the default FPS or render settings**. These defaults are intentionally conservative to ensure stable performance on less powerful hardware.
- If you have a more capable device, feel free to adjust these settings — but keep in mind that doing so **may cause instability or performance issues**, especially if you're on low-spec hardware.

#### 📝 About `main.properties`:
- This configuration file is tuned specifically for **very low-resource devices**.
- **Some areas may take longer to load**, especially the more demanding ones, but this is expected and **should not be frequent or break gameplay**.

✅ If performance issues persist even with the default settings, let us know — improvements and tweaks are always ongoing.

### Assigning Panfrost in Rocknix

To configure Rocknix to use the **Panfrost** driver, first ensure your device supports it and that it’s not the only available option. For example, the **Powkiddy RGB30** supports both **libMali (GLES 3.2)** and **Panfrost (GL 3.1/GLES 3.1)**, as shown [here](https://rocknix.org/devices/powkiddy/rgb30/#software).

To switch to the Panfrost driver:
![step 1](https://raw.githubusercontent.com/lowlevel-1989/pokemmo-port/refs/heads/master/docs/1.jpg)
![step 2](https://raw.githubusercontent.com/lowlevel-1989/pokemmo-port/refs/heads/master/docs/2.jpg)


### 1. Install/Update the Port [Video tutorial](https://www.youtube.com/watch?v=WtAtlXwQsZw)

Download pokemmo.zip Place the `.zip` into:  
`/PortMaster/autoinstall`

Launch **PortMaster**. It will automatically install the port.

#### 📂 Autoinstall Folder Locations

Here are the paths for the `autoinstall` folder for each CFW supported by PortMaster:

| System                             | `autoinstall` Path                                                                 |
|------------------------------------|-------------------------------------------------------------------------------------|
| **AmberELEC / ROCKNIX / uOS / Jelos** | `/roms/ports/PortMaster/autoinstall/`                                            |
| **muOS**                           | `/mmc/MUOS/PortMaster/autoinstall/`                                               |
| **ArkOS**                          | `/roms/tools/PortMaster/autoinstall/`                                             |
| **Knulli**                         | `/userdata/system/.local/share/PortMaster/autoinstall/`                           |

---

#### 📦 Manual Installation (Alternative)

If the `autoinstall` folder method doesn't work, you can manually unzip the port contents into the appropriate `ports` folders.  
**Note:** This may break the port and prevent it from launching properly.

| System                             | Ports Folder Location                                                              |
|------------------------------------|-------------------------------------------------------------------------------------|
| **AmberELEC / ROCKNIX / uOS / Jelos** | `/roms/ports/`                                                                     |
| **muOS**                           | Folders: `/mmc/ports/`  
|                                    | `.sh` files: `/mnt/mmc/ROMS/Ports/`                                                |
| **ArkOS**                          | `/roms/tools/PortMaster/autoinstall/` (same as autoinstall)                        |
| **Knulli**                         | `/userdata/system/.local/share/PortMaster/autoinstall/` (same as autoinstall)     |

---

### 2. Add Official PokeMMO Client Files

Go to the official PokeMMO website:  
[https://pokemmo.com/en/downloads/portable](https://pokemmo.com/en/downloads/portable)

Download the **portable version**, extract it, and copy these into:  
`/roms/ports/pokemmo/`

- `PokeMMO.exe`  
- `data/` folder

⚠️  Make sure not to replace the existing shaders folder and main.properties, as it contains optimized shaders.
Replacing them may negatively impact performance on low-end devices.

---

### 3. Add Required and Optional ROMs

To add the ROMs, place them inside the PokeMMO/roms folder and set the following values in `main.properties`:
~~~
client.roms.nds=roms/pokemon_black.nds  
client.roms.em=roms/pokemon_emerald.gba  
client.roms.fr=roms/pokemon_firered.gba  
client.roms.nds2=roms/pokemon_platinum.nds  
client.roms.nds3=roms/pokemon_heartgold.nds
~~~

**Required ROM:**  
- Pokémon Black or White (Version 1)

**Optional ROMs (enable more regions):**  
- Fire Red  
- Emerald  
- Platinum  
- HeartGold / SoulSilver

---


### 🎮 Login Without Keyboard Input

If your device does not have a keyboard, you can try one of the following methods to log in:

#### 🔧 Option 1: PokeMMO/credentials.txt

Edit the file PokeMMO/credentials.txt with your login credentials.

#### 🔧 Option 2: Connect a Keyboard for First Login

Temporarily connect a physical keyboard (USB or Bluetooth), log in as usual, and make sure to check the **"Remember Me"** option.

#### 📝 Option 3: Type Password in Username Field (thanks ddrsoul)

Type your password in the **username** field, then **copy and paste** it into the password field. This allows you to use system copy/paste functions even without a keyboard.

The game will now automatically log in when launched on PortMaster-compatible devices.

---

### Controls

| Button | Action |
|--|--| 
|start| menu focus |
|R1| mouse left |
|L1| mouse right |
|A| A|
|B| B|
|X| Bag |
|Y| Hotkey 1  |
|L2| Hotkey 2 |
|R2| Hotkey 3 |
|L3| Hotkey 4 |
|R3| Hotkey 5 |
|select + B  | Hotkey 6 |
|select + A  | Hotkey 7 |
|select + X  | Hotkey 8 |
|select + R1  | Hotkey 9 |
|select + R2  | screenshot |
|select + L2  | mode dpad mouse (on) |
|select + Y  | mode text (on) |

📝 Hotkeys are assigned by right-clicking on any item or element in the game and selecting register

#### Virtual Keyboard

| Button | Action |
|--|--| 
|start| mode text (off) |
|A| add character |
|B| backspace |
|X| space |
|Y| toggle case  |
|up | prev character |
|down | next character |
|select| toggle number/letter  |


---

### Known Bug

#### Calibrate cursor

![cursor](https://raw.githubusercontent.com/lowlevel-1989/pokemmo-port/refs/heads/master/docs/3.gif)
---

## Thanks

- [Jeod](https://github.com/JeodC/)
- [BinaryCounter](https://github.com/binarycounter)
- ddrsoul
- lil gabo
- Fran
- [rttn](https://github.com/rttncraft)
- [zerchu](https://github.com/SergioM0/)
- [Ganimoth](https://github.com/Ganimoth)
- antiNT
- cuongnv1312
- Brobba
- [noe](https://steamcommunity.com/id/itsnoe73)
- [Revela](https://www.youtube.com/watch?v=WtAtlXwQsZw)

## Refs

- Official site: [https://pokemmo.com](https://pokemmo.com)  
- Port suggestion on PortMaster: [View Suggestion](https://suggestions.portmaster.games/suggestion-details?id=ab4f9b6b87314eba96536a86804d7235)
---
