#!/bin/bash

set -e

echo "Installing dependencies..."
sudo apt update && sudo apt install wget software-properties-common libxrender1 libxrandr2 libxi6 libglu1-mesa libsm6 -y
echo

###
# BLENDER
BLENDER_VERSION="4.2.3"
BLENDER_URL="https://mirrors.aliyun.com/blender/release/Blender4.2/blender-${BLENDER_VERSION}-linux-x64.tar.xz"

echo "Checking for existing Blender installation..."
if command -v blender &>/dev/null; then
    INSTALLED_VERSION=$(blender --version | head -n 1 | awk '{print $2}')
    echo "Found Blender version: $INSTALLED_VERSION"
    if [ "$INSTALLED_VERSION" == "$BLENDER_VERSION" ]; then
        echo "Blender version $BLENDER_VERSION is already installed. Skipping installation."
        SKIP_INSTALL=true
    else
        echo "Blender version $INSTALLED_VERSION is installed, but version $BLENDER_VERSION is required."
        echo "Removing existing Blender installation..."
        sudo rm -rf /opt/blender/*
        sudo rm -f /usr/local/bin/blender
        SKIP_INSTALL=false
    fi
else
    echo "No Blender installation found. Proceeding with installation."
    SKIP_INSTALL=false
fi

echo
if [ "$SKIP_INSTALL" != true ]; then
    echo "Downloading Blender version $BLENDER_VERSION..."
    wget -q --show-progress $BLENDER_URL

    echo "Extracting Blender..."
    tar -xf blender-${BLENDER_VERSION}-linux-x64.tar.xz
    sudo mv blender-${BLENDER_VERSION}-linux-x64 /opt/blender

    echo "Creating symbolic link..."
    sudo ln -sf /opt/blender/blender-${BLENDER_VERSION}-linux-x64/blender /usr/local/bin/blender

    echo "Cleaning up..."
    rm blender-${BLENDER_VERSION}-linux-x64.tar.xz
else
    echo "Skipping Blender download and installation."
fi

echo
echo "Verifying Blender installation..."
if command -v blender &>/dev/null; then
    echo "Blender installed successfully. Version:"
    blender --version
else
    echo "Blender installation failed."
    exit 1
fi

###
# BLENDER ADD-ON
echo
echo "Checking for Blender add-on..."
ADDON_FOLDER="blender_addon"
# MAKE SURE TO MANUALLY MATCH THE ADDON_FILENAME TO THE GIVEN ADDON_URL
ADDON_URL="https://drive.google.com/uc?export=download&id=1Ga8J8azsYzR0Ubb3xSb-BSaq1B2fPDfX"
ADDON_FILENAME="blosm_2.7.10.zip"

if [ ! -d "$ADDON_FOLDER" ]; then
    mkdir -p "$ADDON_FOLDER"
    echo "Created directory: $ADDON_FOLDER"
fi

if [ -f "$ADDON_FOLDER/$ADDON_FILENAME" ]; then
    echo "Blender add-on already exists: $ADDON_FOLDER/$ADDON_FILENAME"
else
    echo "Blender add-on not found. Downloading..."
    wget --no-check-certificate --content-disposition "$ADDON_URL" -P "$ADDON_FOLDER"
    echo "Blender add-on downloaded to $ADDON_FOLDER/$ADDON_FILENAME."
fi

###
# PYTHON install: pyyaml and flask
echo
echo "Getting Blender's embedded Python path..."
PYTHON_PATH=$(blender --background --python-expr "import sys; print(sys.executable)" 2>/dev/null | grep -Eo '^/.*python[0-9.]+')
if [[ -z "$PYTHON_PATH" ]]; then
    echo "Failed to retrieve Blender's Python path."
    exit 1
fi
echo "Blender's Python path: $PYTHON_PATH"

echo
echo "Upgrading pip for Blender's Python..."
$PYTHON_PATH -m ensurepip --upgrade
$PYTHON_PATH -m pip install --upgrade pip

echo
echo "Installing pyyaml with Blender's Python..."
$PYTHON_PATH -m pip install pyyaml

echo "Verifying pyyaml installation..."
if $PYTHON_PATH -m pip show pyyaml &>/dev/null; then
    echo "pyyaml installed successfully."
else
    echo "pyyaml installation failed."
    exit 1
fi

echo
echo "Installing flask with Blender's Python..."
$PYTHON_PATH -m pip install flask

echo "Verifying flask installation..."
if $PYTHON_PATH -m pip show flask &>/dev/null; then
    echo "flask installed successfully."
else
    echo "flask installation failed."
    exit 1
fi

echo
echo
echo "All steps completed successfully!"
