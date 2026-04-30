#!/bin/bash
# https://claude.ai/chat/40158f0c-7f5c-42ab-a1fe-c6e9bb31024d
# set -e

INSTALL_DIR="$HOME/utils/whisper-writer"
CONFIG_SOURCE="$HOME/user_config/whisper-writer-config.yaml"  # Change this to where you keep your config

# System dependencies
# sudo apt update
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
    git clone git@github.com:shawnghu/whisper-writer.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Create venv and install Python deps
uv venv --python 3.11
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

# Install systemd user service so whisper-writer auto-starts on login.
cat <<EOF

WhisperWriter can run in two modes:
  1) local  — transcribes on this machine. Loads the Whisper model in-process;
              needs decent CPU/GPU here.
  2) remote — sends audio over an SSH tunnel to the transcription server on
              'gratitude' (run.py --remote auto-spawns the tunnel). Requires
              'gratitude' to be reachable via ~/.ssh/config with a key.

EOF
read -rp "Install which service? [local/remote/none]: " WW_MODE
WW_MODE="${WW_MODE,,}"  # lowercase

case "$WW_MODE" in
    remote) UNIT_SRC="$INSTALL_DIR/systemd/whisper-writer-remote.service" ;;
    local)  UNIT_SRC="$INSTALL_DIR/systemd/whisper-writer-local.service" ;;
    none|"") UNIT_SRC="" ;;
    *) echo "Unrecognized choice '$WW_MODE'; skipping service install."; UNIT_SRC="" ;;
esac

if [ -n "$UNIT_SRC" ]; then
    UNIT_NAME="$(basename "$UNIT_SRC")"
    UNIT_DEST="$HOME/.config/systemd/user/$UNIT_NAME"
    OTHER_UNIT="whisper-writer-remote.service"
    [ "$UNIT_NAME" = "whisper-writer-remote.service" ] && OTHER_UNIT="whisper-writer-local.service"

    mkdir -p "$HOME/.config/systemd/user"
    # Disable the other mode's unit if previously installed, so they don't fight.
    if systemctl --user list-unit-files "$OTHER_UNIT" --no-legend 2>/dev/null | grep -q "$OTHER_UNIT"; then
        systemctl --user disable --now "$OTHER_UNIT" || true
    fi
    cp "$UNIT_SRC" "$UNIT_DEST"
    systemctl --user daemon-reload
    systemctl --user enable --now "$UNIT_NAME"
    echo "Installed and started $UNIT_NAME."
    echo "  status: systemctl --user status $UNIT_NAME"
    echo "  logs:   journalctl --user -u $UNIT_NAME -f"
fi

echo "Done. Run manually with: cd $INSTALL_DIR && uv run python run.py"
