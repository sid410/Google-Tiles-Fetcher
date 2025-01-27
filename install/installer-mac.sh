#!/bin/bash

set -e

# Lots of problems when running sudo on mac...
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root. Please run it as a regular user."
    exit 1
fi

USER_HOME="$HOME"

echo "Checking for Homebrew installation..."
if ! command -v brew &>/dev/null; then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if command -v brew &>/dev/null; then
    echo "Homebrew has been installed successfully."
    brew --version
else
    echo "Failed to install Homebrew. Please check the installation logs or install it manually."
    exit 1
fi

echo "Checking for Git installation..."
if ! command -v git &>/dev/null; then
    echo "Git is not installed. Installing Git using Homebrew..."
    brew install git
fi

if command -v git &>/dev/null; then
    echo "Git has been installed successfully."
    git --version
else
    echo "Failed to install Git. Please check the installation process or install it manually."
    exit 1
fi

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

# BLENDER INSTALLATION
ARCH=$(uname -m)
if [[ $ARCH == "arm64" ]]; then
    echo "Detected Apple Silicon (ARM) architecture."
    BLENDER_URL="https://mirrors.aliyun.com/blender/release/Blender4.2/blender-4.2.6-macos-arm64.dmg"
elif [[ $ARCH == "x86_64" ]]; then
    echo "Detected Intel (x86_64) architecture."
    BLENDER_URL="https://ftp.halifax.rwth-aachen.de/blender/release/Blender4.2/blender-4.2.6-macos-x64.dmg"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Checking for Blender installation..."
if [ -d "/Applications/Blender.app" ]; then
    echo "Blender is already installed in /Applications/Blender.app"
    echo "Do you want to delete the current installation and replace it with a new one? (yes/no)"
    read -r REPLACE_CHOICE
    if [[ $REPLACE_CHOICE != "yes" ]]; then
        echo "Skipping Blender installation."
        exit 0
    fi

    echo "Removing the current Blender installation..."
    rm -rf "/Applications/Blender.app"

    SYMLINK_PATH="/usr/local/bin/blender"
    if [ -L "$SYMLINK_PATH" ]; then
        echo "Removing the symbolic link: $SYMLINK_PATH"
        rm -f "$SYMLINK_PATH"
    fi
fi

echo "Downloading Blender for $ARCH..."
TEMP_DMG=$(mktemp).dmg
curl -L -o "$TEMP_DMG" "$BLENDER_URL"

echo "Mounting the DMG file..."
MOUNT_DIR=$(hdiutil attach "$TEMP_DMG" | grep "/Volumes/" | awk '{print $3}')
if [ -z "$MOUNT_DIR" ]; then
    echo "Failed to mount the DMG file."
    exit 1
fi

echo "Installing Blender..."
cp -R "$MOUNT_DIR/Blender.app" /Applications/

echo "Unmounting the DMG file..."
hdiutil detach "$MOUNT_DIR"

echo "Cleaning up temporary files..."
rm -f "$TEMP_DMG"

# CURRENTLY HAVING PROBLEMS WITH SYMBOLIC LINKS IN MAC...
echo "Creating symbolic link for Blender..."
BLENDER_BINARY="/Applications/Blender.app/Contents/MacOS/Blender"
# SYMLINK_PATH="/usr/local/bin/blender"
# if [ ! -L "$SYMLINK_PATH" ]; then
#     ln -sf "$BLENDER_BINARY" "$SYMLINK_PATH"
#     echo "Symbolic link created: blender -> $BLENDER_BINARY"
# else
#     echo "Symbolic link already exists: $SYMLINK_PATH"
# fi

# echo "Verifying Blender installation..."
# if command -v blender &>/dev/null; then
#     echo "Blender has been installed successfully."
#     blender --version
# else
#     echo "Failed to verify Blender installation. Please check manually."
#     exit 1
# fi

# SO INSTEAD, WE USE THE REAL BINARY PATH OF BLENDER FOR NOW
echo "Finding Blender's Python path..."
BLENDER_PYTHON=$($BLENDER_BINARY --background --python-expr "import sys; print(sys.executable)" 2>/dev/null | grep -Eo '^/.*python[0-9.]+')
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

# LATER: Change the default port instead of 5000
echo "Installation complete. Disable AirPlay Receiver, because this also uses the default flask port 5000."
echo "To run, first cd to the project repository located at home, inside Google-Tiles-Fetcher, then run:"
echo "/Applications/Blender.app/Contents/MacOS/Blender --background --python main.py -- map_select_ui"

# echo "Creating symbolic link for 'fetch.sh'..."
# if [ -f "$USER_HOME/Google-Tiles-Fetcher/fetch.sh" ]; then
#     ln -sf "$USER_HOME/Google-Tiles-Fetcher/fetch.sh" /usr/local/bin/fetch-tiles
#     chmod +x "$USER_HOME/Google-Tiles-Fetcher/fetch.sh"
#     echo "Symbolic link created. You can now use 'fetch-tiles' from anywhere."
# else
#     echo "'fetch.sh' not found in the repository. Please ensure the file exists."
#     exit 1
# fi

# echo "Installation complete. You can now run by: sudo fetch-tiles"
