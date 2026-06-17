# Sandboxed WeChat (firejail)

Runs the official Tencent WeChat Linux client inside a [firejail](https://firejail.wordpress.com/)
sandbox with a default-deny home directory and an isolated nested X server.

## Install

```sh
~/user_config/wechat-sandbox/install.sh
```

This installs `firejail` + `Xephyr`, downloads/extracts the AppImage to
`~/wechat-sandbox/squashfs-root`, and symlinks the profile and launcher into
place. Re-running it is safe; delete `~/wechat-sandbox/WeChatLinux_x86_64.AppImage`
first to force a fresh download (i.e. to upgrade WeChat).

## Run

```sh
wechat-sandbox        # if ~/.local/bin is on PATH
```

or launch "WeChat (sandboxed)" from your application menu. WeChat appears
inside a nested Xephyr window.

## Source of the AppImage

Official vendor download only: <https://linux.weixin.qq.com/>
Direct: `https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage`

## Files

| File              | Role                                                        |
|-------------------|-------------------------------------------------------------|
| `install.sh`      | Installer (deps, download, extract, symlink, desktop entry) |
| `wechat.profile`  | firejail profile → `~/.config/firejail/wechat.profile`      |
| `run-wechat.sh`   | Launcher → `~/.local/bin/wechat-sandbox`                    |

Runtime locations (not in the repo):
- App: `~/wechat-sandbox/squashfs-root`
- WeChat data: `~/.xwechat` (created by WeChat; whitelisted in the profile)

## Security model

**Strong:** `caps.drop all`, `seccomp`, `noroot`, `nonewprivs`,
`private-tmp`/`private-cache`, D-Bus filtered to notifications only.

**Filesystem — default-deny:** `$HOME` is hidden behind a tmpfs; only the
whitelisted paths are visible (app dir, `~/.xwechat`, `~/Downloads`, the
wechat config stubs). Secrets such as `~/.ssh`, the GNOME keyring,
`~/.config/gh`, `~/.aws`, `~/.netrc`, and shell history are **not** visible.
If WeChat starts using a new data directory, add a `whitelist` line to
`wechat.profile`.

**X11 isolation:** runs under nested Xephyr so WeChat cannot keylog or
screenshot other windows on your desktop.

**Known gap — networking:** WeChat keeps full host networking, including
localhost and the LAN. Per-app network filtering needs root because
`/etc/firejail/firejail.config` ships with `restricted-network yes`, and a
WiFi-only uplink makes firejail's macvlan namespaces unreliable. See the
header of `run-wechat.sh` for the root-level steps to close this gap.
