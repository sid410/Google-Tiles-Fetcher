#!/bin/bash

set -e

echo "Installing dependencies..."
sudo apt update && sudo apt install wget software-properties-common libxrender1 libxrandr2 libxi6 libglu1-mesa libsm6 -y

# BLENDER
echo "Downloading Blender..."
BLENDER_VERSION="4.2.3"
BLENDER_URL="https://mirrors.aliyun.com/blender/release/Blender4.2/blender-${BLENDER_VERSION}-linux-x64.tar.xz"
wget -q --show-progress $BLENDER_URL

echo "Extracting Blender..."
tar -xf blender-${BLENDER_VERSION}-linux-x64.tar.xz
sudo mv blender-${BLENDER_VERSION}-linux-x64 /opt/blender

echo "Creating symbolic link..."
sudo ln -sf /opt/blender/blender-${BLENDER_VERSION}-linux-x64/blender /usr/local/bin/blender

echo "Verifying Blender installation..."
if command -v blender &> /dev/null; then
    echo "Blender installed successfully. Version:"
    blender --version
else
    echo "Blender installation failed."
    exit 1
fi

#echo "Cleaning up..."
rm blender-${BLENDER_VERSION}-linux-x64.tar.xz

# PYTHON install: pyyaml and flask
echo "Getting Blender's embedded Python path..."
PYTHON_PATH=$(blender --background --python-expr "import sys; print(sys.executable)" 2>/dev/null | grep -Eo '^/.*python[0-9.]+')
if [[ -z "$PYTHON_PATH" ]]; then
    echo "Failed to retrieve Blender's Python path."
    exit 1
fi
echo "Blender's Python path: $PYTHON_PATH"

echo "Upgrading pip for Blender's Python..."
$PYTHON_PATH -m ensurepip --upgrade
$PYTHON_PATH -m pip install --upgrade pip

echo "Installing pyyaml with Blender's Python..."
$PYTHON_PATH -m pip install pyyaml

echo "Verifying pyyaml installation..."
if $PYTHON_PATH -m pip show pyyaml &> /dev/null; then
    echo "pyyaml installed successfully."
else
    echo "pyyaml installation failed."
    exit 1
fi

echo "Installing flask with Blender's Python..."
$PYTHON_PATH -m pip install flask

echo "Verifying flask installation..."
if $PYTHON_PATH -m pip show flask &> /dev/null; then
    echo "flask installed successfully."
else
    echo "flask installation failed."
    exit 1
fi

echo "All steps completed successfully!"
