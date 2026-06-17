# Firejail profile for WeChat
# Source of truth: ~/user_config/wechat-sandbox/wechat.profile
# Installed (symlinked) to ~/.config/firejail/wechat.profile by install.sh
# App is expected at: ~/wechat-sandbox/squashfs-root (extracted AppImage)

# Basic security - but NOT disable-exec (breaks AppImage)
include disable-common.inc
include disable-devel.inc
include disable-interpreters.inc
include disable-programs.inc

# ---------------------------------------------------------------------------
# Filesystem: WHITELIST model (default-deny for $HOME).
# Everything in $HOME is hidden behind a tmpfs EXCEPT the paths below.
# This replaces the old blacklist approach, which left the keyring, GitHub/
# AWS tokens, ~/.netrc, shell history, etc. fully readable.
#
# NOTE: these whitelist entries are the ONLY parts of $HOME WeChat can see.
# If WeChat starts using a new data directory, add it here.
# ---------------------------------------------------------------------------

# The extracted AppImage lives under $HOME, so it must be whitelisted or the
# app binary itself disappears from the sandbox view.
whitelist ${HOME}/wechat-sandbox/squashfs-root

# WeChat's real data directory (login session, account, chat files).
whitelist ${HOME}/.xwechat

# Legacy/stub data dirs (created by older versions of this profile; harmless).
mkdir ${HOME}/.config/wechat
mkdir ${HOME}/.local/share/wechat
whitelist ${HOME}/.config/wechat
whitelist ${HOME}/.local/share/wechat

# Downloads folder (for sending/receiving files).
mkdir ${HOME}/Downloads
whitelist ${HOME}/Downloads

# ---------------------------------------------------------------------------
# X11 isolation: run WeChat against a nested Xephyr server instead of the
# host X server. Without this, WeChat (an X11 client) can keylog and
# screenshot every other window on the desktop. Xephyr gives it an isolated
# display. (xpra would be more seamless but is not installed by default.)
# Screen size is set via --xephyr-screen in run-wechat.sh.
# ---------------------------------------------------------------------------
x11 xephyr

# ---------------------------------------------------------------------------
# Network: fine-grained filtering (allow internet, deny localhost/LAN) is NOT
# enabled here -- firejail.config ships with `restricted-network yes`, which
# limits --net/--netfilter to root, and a WiFi-only uplink makes macvlan
# netns unreliable. WeChat therefore keeps host networking.
# To harden this, see the note in run-wechat.sh.
# ---------------------------------------------------------------------------

# Filesystem restrictions
private-tmp
private-cache
noroot

# Disable potentially dangerous capabilities
caps.drop all
nonewprivs
seccomp

# D-Bus filtering (allow session bus for notifications)
dbus-user filter
dbus-user.talk org.freedesktop.Notifications
dbus-system none
