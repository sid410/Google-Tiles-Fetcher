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

### Installation and How to Run

Click to download [`installer.bat`](https://github.com/sid410/Google-Tiles-Fetcher/releases/latest/download/installer.bat)

Right click `installer.bat` and run as admin. It should automatically install everything and create a shortcut on Desktop called `fetch`.

Right click `fetch` and run as admin. It should start the map_select_ui and automatically opens a default browser to show this.

Select the desired area by clicking two corners to define a rectangle. Enter your Google API key to request the Google Tiles. Enter a base name to describe that area (no need to be unique because lat/lon is also appended in the naming convention). Enter a scale factor (usually 1). Select the Level of details for the quality of the Google Tiles (more details have bigger file size).

###### Note: if the fetch shortcut creation failed, navigate to the Google-Tiles-Fetcher directory (under C:\Program Files) and instead run as admin `fetch.bat`.
