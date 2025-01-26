#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as an administrator (root)."
    exit 1
fi

SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
cd "$SCRIPT_DIR"
echo "Now in $(pwd)"

echo "Starting Blender with main.py in a new terminal..."
gnome-terminal -- bash -c 'blender --background --python main.py -- map_select_ui; exec bash'

echo "Waiting for http://localhost:5000 to start..."
while ! curl -s http://localhost:5000 >/dev/null; do
    sleep 2
done

# Allow access to X server
xhost +SI:localuser:root

echo "Opening http://localhost:5000/"
xdg-open http://localhost:5000/ || {
    echo "Error: Failed to open the URL. Please open it manually: http://localhost:5000/"
}

echo "Server started successfully."
