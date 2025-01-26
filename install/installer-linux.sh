#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

USER_HOME=$(eval echo "~$SUDO_USER")
if [[ -z "$USER_HOME" ]]; then
    echo "Unable to determine the user's home directory."
    exit 1
fi

echo "Updating system package list..."
apt-get update -y

echo "Checking for Git installation..."
if ! command -v git &>/dev/null; then
    echo "Git is not installed. Installing Git..."
    apt-get install -y git
fi

if command -v git &>/dev/null; then
    echo "Git has been installed successfully."
    git --version
else
    echo "Failed to install Git. Please check your package manager or install it manually."
    exit 1
fi

echo "Checking for cURL installation..."
if ! command -v curl &>/dev/null; then
    echo "cURL is not installed. Installing cURL..."
    apt-get install -y curl
fi

if command -v curl &>/dev/null; then
    echo "cURL has been installed successfully."
    curl --version
else
    echo "Failed to install cURL. Please check your package manager or install it manually."
    exit 1
fi

echo "Installing Blender dependencies..."
apt-get install -y build-essential software-properties-common libxrender1 libxrandr2 libxi6 libglu1-mesa libsm6 gnome-terminal dbus-x11

echo "Cloning the GitHub repository into the user's home directory..."
cd "$USER_HOME"
if [ ! -d "Google-Tiles-Fetcher" ]; then
    git clone https://github.com/sid410/Google-Tiles-Fetcher.git
else
    echo "Repository already exists. Skipping cloning."
fi

cd "$USER_HOME/Google-Tiles-Fetcher"

echo "Checking for 'blender_addon' folder..."
if [ ! -d "blender_addon" ]; then
    echo "Folder 'blender_addon' does not exist. Creating it..."
    mkdir blender_addon
else
    echo "Folder 'blender_addon' already exists."
fi

cd blender_addon

echo "Checking for 'blosm_2.7.10.zip'..."
if [ ! -f "blosm_2.7.10.zip" ]; then
    echo "'blosm_2.7.10.zip' is missing. Downloading it..."
    curl -L -o blosm_2.7.10.zip "https://drive.google.com/uc?export=download&id=1Ga8J8azsYzR0Ubb3xSb-BSaq1B2fPDfX"
    echo "'blosm_2.7.10.zip' has been downloaded successfully."
else
    echo "'blosm_2.7.10.zip' already exists. Skipping download."
fi

echo "Checking for Blender installation..."
if command -v blender &>/dev/null; then
    echo "Blender is already installed at $(command -v blender)"
    echo "Do you want to delete the current installation and replace it with a new one? (yes/no)"
    read -r REPLACE_CHOICE
    if [[ $REPLACE_CHOICE != "yes" ]]; then
        echo "Skipping Blender installation."
        exit 0
    fi
    echo "Removing the current Blender installation..."
    rm -rf /opt/blender
    rm -f /usr/local/bin/blender
fi

echo "Installing Blender..."
mkdir -p /opt/blender
cd /opt/blender
curl -o blender.tar.xz "https://mirrors.aliyun.com/blender/release/Blender4.2/blender-4.2.6-linux-x64.tar.xz"
echo "Extracting Blender..."
tar -xf blender.tar.xz --strip-components=1
rm blender.tar.xz

echo "Adding Blender to PATH..."
ln -sf /opt/blender/blender /usr/local/bin/blender

echo "Verifying Blender installation..."
if command -v blender &>/dev/null; then
    echo "Blender has been installed successfully."
    blender --version
else
    echo "Failed to verify Blender installation. Please check manually."
    exit 1
fi

echo "Finding Blender's Python path..."
BLENDER_PYTHON=$(/opt/blender/blender --background --python-expr "import sys; print(sys.executable)" 2>/dev/null | grep -Eo '^/.*python[0-9.]+')
if [ -z "$BLENDER_PYTHON" ]; then
    echo "Failed to determine Blender's embedded Python path."
    exit 1
fi
echo "Blender's Python path is: $BLENDER_PYTHON"

echo "Ensuring pip is installed and upgraded..."
"$BLENDER_PYTHON" -m ensurepip --upgrade
"$BLENDER_PYTHON" -m pip install --upgrade pip

echo "Installing Python packages (pyyaml, flask)..."
"$BLENDER_PYTHON" -m pip install pyyaml flask

echo "Verifying installed Python packages..."
"$BLENDER_PYTHON" -c "import yaml, flask; print('pyyaml and flask are installed successfully.')"
if [ $? -eq 0 ]; then
    echo "Verification successful: pyyaml and flask are properly installed."
else
    echo "Verification failed: pyyaml and/or flask are not installed correctly."
    exit 1
fi

echo "Creating symbolic link for 'fetch.sh'..."
if [ -f "$USER_HOME/Google-Tiles-Fetcher/fetch.sh" ]; then
    ln -sf "$USER_HOME/Google-Tiles-Fetcher/fetch.sh" /usr/local/bin/fetch-tiles
    chmod +x "$USER_HOME/Google-Tiles-Fetcher/fetch.sh"
    echo "Symbolic link created. You can now use 'fetch-tiles' from anywhere."
else
    echo "'fetch.sh' not found in the repository. Please ensure the file exists."
    exit 1
fi

echo "Installation complete. You can now run by: sudo fetch-tiles"
