#!/bin/bash
# https://claude.ai/chat/40158f0c-7f5c-42ab-a1fe-c6e9bb31024d
set -e

INSTALL_DIR="$HOME/utils/whisper-writer"
CONFIG_SOURCE="$HOME/user_config/whisper-writer-config.yaml"  # Change this to where you keep your config

# System dependencies
sudo apt update
sudo apt install -y \
    ffmpeg \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libavfilter-dev \
    libswscale-dev \
    libswresample-dev \
    libgirepository-2.0-dev \
    libportaudio2 \
    gcc \
    libcairo2-dev \
    pkg-config \
    python3-dev

# Clone repo
mkdir -p "$(dirname "$INSTALL_DIR")"
if [ -d "$INSTALL_DIR" ]; then
    echo "Directory exists, pulling latest..."
    cd "$INSTALL_DIR" && git pull
else
    git clone https://github.com/savbell/whisper-writer "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Create venv and install Python deps
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
uv pip install PyGObject

# Copy config
if [ -f "$CONFIG_SOURCE" ]; then
    cp "$CONFIG_SOURCE" "$INSTALL_DIR/src/config.yaml"
    echo "Config copied."
else
    echo "Warning: Config source not found at $CONFIG_SOURCE"
fi

echo "Done. Run with: cd $INSTALL_DIR && source .venv/bin/activate && python run.py"
