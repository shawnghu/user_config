#!/bin/bash
# Install the firejail-sandboxed WeChat.
#
# Source of truth for config lives in this directory (~/user_config/wechat-sandbox).
# This script:
#   1. installs dependencies (firejail, Xephyr)
#   2. downloads the official Tencent WeChat AppImage (or reuses a local copy)
#   3. extracts it to ~/wechat-sandbox/squashfs-root
#   4. symlinks the firejail profile and launcher into place
#   5. installs a desktop entry
#
# Idempotent: safe to re-run (e.g. to upgrade WeChat -- delete the AppImage
# first to force a fresh download).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WECHAT_DIR="${HOME}/wechat-sandbox"
APPIMAGE_NAME="WeChatLinux_x86_64.AppImage"
# Official Tencent Linux download (https://linux.weixin.qq.com/)
APPIMAGE_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/${APPIMAGE_NAME}"
APPIMAGE_PATH="${WECHAT_DIR}/${APPIMAGE_NAME}"
FIREJAIL_PROFILE_DIR="${HOME}/.config/firejail"
BIN_DIR="${HOME}/.local/bin"

echo "==> Installing dependencies (firejail, xpra)"
command -v firejail >/dev/null && echo "    firejail present" || sudo apt install -y firejail

# Ubuntu's packaged xpra (3.1.x) is too old for noble's pygobject/Pillow and
# renders WeChat with constant UI stalls. Require xpra >= 5 from xpra.org.
xpra_major() { xpra --version 2>/dev/null | grep -oE '[0-9]+' | head -1; }
if ! command -v xpra >/dev/null || [ "$(xpra_major)" -lt 5 ] 2>/dev/null; then
    echo "    Installing current xpra from xpra.org (packaged version too old)"
    "${REPO_DIR}/setup-xpra-repo.sh"
else
    echo "    xpra present ($(xpra --version 2>/dev/null | head -1))"
fi

mkdir -p "$WECHAT_DIR" "$FIREJAIL_PROFILE_DIR" "$BIN_DIR"

# --- Acquire the AppImage --------------------------------------------------
if [ ! -f "$APPIMAGE_PATH" ]; then
    # Reuse an existing copy if we can find one (avoids a ~290MB re-download).
    for cand in "${HOME}/sandboxes/${APPIMAGE_NAME}" "${HOME}/Downloads/${APPIMAGE_NAME}"; do
        if [ -f "$cand" ]; then
            echo "==> Reusing existing AppImage: $cand"
            cp "$cand" "$APPIMAGE_PATH"
            break
        fi
    done
fi
if [ ! -f "$APPIMAGE_PATH" ]; then
    echo "==> Downloading WeChat AppImage from Tencent (official)"
    echo "    ${APPIMAGE_URL}"
    curl -fL --progress-bar -o "$APPIMAGE_PATH" "$APPIMAGE_URL"
fi
chmod +x "$APPIMAGE_PATH"

# --- Extract ---------------------------------------------------------------
echo "==> Extracting AppImage"
rm -rf "${WECHAT_DIR}/squashfs-root"
( cd "$WECHAT_DIR" && "$APPIMAGE_PATH" --appimage-extract >/dev/null )
if [ ! -x "${WECHAT_DIR}/squashfs-root/AppRun" ]; then
    echo "ERROR: extraction failed (no AppRun)." >&2
    exit 1
fi

# --- Install profile + launcher (symlinked to repo, dotfiles-style) --------
echo "==> Installing firejail profile and launcher"
ln -sf "${REPO_DIR}/wechat.profile" "${FIREJAIL_PROFILE_DIR}/wechat.profile"
chmod +x "${REPO_DIR}/run-wechat.sh"
ln -sf "${REPO_DIR}/run-wechat.sh"  "${BIN_DIR}/wechat-sandbox"

# --- Desktop entry (for app menus) -----------------------------------------
echo "==> Installing desktop entry"
DESKTOP_DIR="${HOME}/.local/share/applications"
mkdir -p "$DESKTOP_DIR"
cat > "${DESKTOP_DIR}/wechat-sandbox.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=WeChat (sandboxed)
Comment=WeChat running in a firejail sandbox
Exec=${BIN_DIR}/wechat-sandbox
Icon=${WECHAT_DIR}/squashfs-root/wechat.png
Terminal=false
Categories=Network;InstantMessaging;
EOF

echo
echo "Done. Launch with:  wechat-sandbox      (or ${REPO_DIR}/run-wechat.sh)"
case ":${PATH}:" in
    *":${BIN_DIR}:"*) ;;
    *) echo "NOTE: ${BIN_DIR} is not on your PATH; add it to use the 'wechat-sandbox' command." ;;
esac
