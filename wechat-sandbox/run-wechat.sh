#!/bin/bash
# Launch WeChat in a firejail sandbox (extracted AppImage + Xephyr).
# Source of truth: ~/user_config/wechat-sandbox/run-wechat.sh
# Installed (symlinked) to ~/.local/bin/wechat-sandbox by install.sh

WECHAT_DIR="${HOME}/wechat-sandbox/squashfs-root"

# WeChat runs in an isolated nested X server (Xephyr) so it cannot snoop on
# other windows. Set the nested screen size here.
XEPHYR_SCREEN="1280x1024"

if [ ! -x "${WECHAT_DIR}/AppRun" ]; then
    echo "WeChat is not installed at ${WECHAT_DIR}." >&2
    echo "Run the installer: ~/user_config/wechat-sandbox/install.sh" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Networking note:
# This sandbox does NOT restrict WeChat's network access (it can reach
# localhost and the LAN). Per-app network filtering requires root because
# /etc/firejail/firejail.config has `restricted-network yes`. To harden it:
#
#   1. As root, edit /etc/firejail/firejail.config and set:
#          restricted-network no
#          network yes
#   2. Add to wechat.profile:
#          net wlo1                          # your uplink interface
#          netfilter /etc/firejail/nolocal.net
#
# Caveat: `net wlo1` uses macvlan, which often fails on WiFi access points.
# If WeChat loses connectivity after adding it, revert step 2.
# ---------------------------------------------------------------------------

echo "Starting WeChat in firejail sandbox (Xephyr ${XEPHYR_SCREEN})..."
firejail --profile=wechat --xephyr-screen="${XEPHYR_SCREEN}" "${WECHAT_DIR}/AppRun"
