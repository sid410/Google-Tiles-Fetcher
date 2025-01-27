# Google-Tiles-Fetcher

Fetches 3D Tiles from Google using Blosm for Blender.

## For Linux or inside WSL terminal

### Installation

Clone and go to project root, make `install.sh` executable then run:

```bash
chmod +x ./install.sh
./install.sh
```

### How to Run for Browser Map UI

Start the flask server,

```bash
blender --background --python main.py -- map_select_ui
```

then open `http://localhost:5000/`

### How to Run for Terminal with args

Place the appropriate data after every `=`

```bash
blender --background --python main.py -- google_api_key= min_lat= min_lon= max_lat= max_lon= base_name=
```

### How to Run for Terminal changing config/config.yaml

Edit the config/config.yaml file following the format of the config_template.yaml:

```bash
blender --background --python main.py
```

## For Windows

### Prerequisite

To ensure having `winget` and `curl` for Windows 10/11, update Windows to the latest version. Both should be part of the "App Installer" package.

### Installation and How to Run

Click to download [`installer-win.bat`](https://github.com/sid410/Google-Tiles-Fetcher/releases/latest/download/installer-win.bat)

Right click `installer-win.bat` and run as admin. It should automatically install everything and create a shortcut on Desktop called `fetch`.

Right click `fetch` and run as admin. It should start the map_select_ui and automatically opens a default browser to show this.

Select the desired area by clicking two corners to define a rectangle. Enter your Google API key to request the Google Tiles. Enter a base name to describe that area (no need to be unique because lat/lon is also appended in the naming convention). Enter a scale factor (usually 1). Select the Level of details for the quality of the Google Tiles (more details have bigger file size).

###### Note: if the fetch shortcut creation failed, navigate to the Google-Tiles-Fetcher directory (under C:\Program Files) and instead run as admin `fetch.bat`

## For Mac

### Prerequisite

Requires macOS 11.2 or later. Also check if `curl` is installed.

Another important thing: Go to AirDrop & Handoff and disable AirPlay Receiver, because this also uses the default flask port 5000. (Later I will change the flask server to another port)

### Installation and How to Run

Click to download [`installer-mac.sh`](https://github.com/sid410/Google-Tiles-Fetcher/releases/latest/download/installer-mac.sh)

make `installer-mac.sh` executable then run:

```bash
chmod +x ./installer-mac.sh
./installer-mac.sh
```

###### Note: We are using brew to handle all the dependencies. There are times brew might fail in setting the PATH, so follow their instruction how to fix and run the installer-mac script again

After installing, cd to the repo and start the flask server,

```bash
cd ~/Google-Tiles-Fetcher
/Applications/Blender.app/Contents/MacOS/Blender --background --python main.py -- map_select_ui
```

Currently there are problems with the symbolic links for Mac, so we need to use the whole blender path everytime...
