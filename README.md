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

Click to download [`run.bat`](https://github.com/sid410/Google-Tiles-Fetcher/releases/latest/download/run.bat)

Double click `run.bat` to install and start the map select in browser.
