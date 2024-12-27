# Google-Tiles-Fetcher

Fetches 3D Tiles from Google using Blosm for Blender.

## Installation

### For Linux / WSL

Clone and go to project root, make `install.sh` executable then run:

```bash
chmod +x ./install.sh
./install.sh
```

### For Windows

TBD

## How to run

### For Browser Map UI

Start the flask server,

```bash
blender --background --python main.py -- map_select_ui  
```

then open `http://localhost:5000/`

### For Terminal with args

Place the appropriate data after every `=`

```bash
blender --background --python main.py -- google_api_key= min_lat= min_lon= max_lat= max_lon= base_name=
```

### For Terminal changing config/config.yaml

Edit the config/config.yaml file following the format of the config_template.yaml:

```bash
blender --background --python main.py
```
