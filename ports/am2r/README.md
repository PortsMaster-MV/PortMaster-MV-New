# AM2R - PortMaster + Community Patch
The latest AM2R experience is v1.5.5. Follow the below steps to obtain this version and set it up for PortMaster use.

## Installation
You will need the following:

- AM2R v1.1 (search for this on the web, DoctorM64 is a known and trusted source)
- OPTIONAL: The [community developer patch data](https://github.com/AM2R-Community-Developers/AM2R-Autopatcher-Windows/archive/refs/heads/master.zip), which will automatically result in the game being upgraded from v1.1 to v1.5.5 during patching

Copy both zip files (naming doesn't matter) to `ports/am2r/assets` and run the port. It may take some time to install. If you don't want to use the community patch, only copy AM2R v1.1.

Your directory structure should look like this:
```
ports/am2r/
├── assets/
│   ├── AM2R_11.zip                          <-- Game files (required)
│   ├── AM2R-Autopatcher-Windows-master.zip  <-- Community patch (optional)
└── (other files)
```

Launch AM2R from your device's game menu. The patcher will:
1. Detect the zip files
2. Extract and patch the game (takes 2-5 minutes)
3. Display "Patching process complete!"
4. Launch the game automatically on subsequent runs

## Troubleshooting

### Patcher completes instantly without actually patching

**Cause:** The patcher can't find a valid AM2R v1.1 zip file.

**Solution:** Ensure you have the correct `AM2R_11.zip` (or similarly named zip) that contains `data.win` in its root and is often around 73 MB zipped.

### macOS users: remove metadata files

If copying files from macOS, remove the `._` metadata files that macOS creates as this can sometimes interfere with the patcher:
```bash
find /path/to/ports/am2r/assets -name '._*' -delete
```

## Technical Notes
- The patcher creates `am2r.port` (a zip archive) containing the final game assets
- Successful patching creates `patchlog.txt` - the patcher skips if this file exists
- Game config is stored in `ports/am2r/conf/am2r/`

## Thanks
Thanks to JohnnyonFlame for the[ droidports](https://github.com/JohnnyonFlame/droidports) loader that makes this possible.
