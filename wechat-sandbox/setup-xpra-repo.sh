#!/bin/bash
# Add the official xpra.org apt repository and install a current xpra.
#
# Ubuntu 24.04 (noble) ships xpra 3.1.5, which is too old for noble's
# pygobject (3.48) and Pillow (10.x): it throws
#   "Couldn't find foreign struct converter for 'cairo.Context'"   (UI stalls)
#   "PIL.Image has no attribute 'ANTIALIAS'"                       (icon crashes)
# The upstream xpra 6.x build fixes both. See:
#   https://github.com/Xpra-org/xpra/wiki/Download
#
# Requires root (apt + writes to /etc, /usr/share/keyrings).
# Idempotent: safe to re-run.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script modifies system apt sources; re-running with sudo." >&2
    exec sudo -- "$0" "$@"
fi

KEYRING="/usr/share/keyrings/xpra.asc"
SOURCES="/etc/apt/sources.list.d/xpra.sources"

echo "==> Installing prerequisites"
apt update
apt install -y apt-transport-https software-properties-common ca-certificates wget

echo "==> Fetching xpra.org signing key -> ${KEYRING}"
wget -qO "$KEYRING" https://xpra.org/xpra.asc

echo "==> Writing ${SOURCES}"
# Verbatim from packaging/repos/noble/xpra.sources (Signed-By must match KEYRING).
cat > "$SOURCES" <<'EOF'
Types: deb
URIs: https://xpra.org
Suites: noble
Components: main
Signed-By: /usr/share/keyrings/xpra.asc
Architectures: amd64 arm64
EOF

echo "==> Updating and installing xpra from xpra.org"
apt update
apt install -y xpra

echo
echo "xpra version now:"
xpra --version 2>/dev/null | head -1 || true
