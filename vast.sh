#!/bin/bash
# Provision a vast.ai / runpod-style box end-to-end.
#
# Usage:
#     vast.sh -p PORT user@IP
#     vast.sh user@IP -p PORT
#
# Reads the age passphrase from (in order): $PWD/password.txt, $HOME/password.txt,
# or interactive prompt. The passphrase is shipped to the remote as
# ~/.age-passphrase so setup_service_auth.sh can decrypt non-interactively.
#
# Also scps a private SSH key (~/.ssh/id-ed25519-2 if present, else
# ~/.ssh/id_ed25519) to the remote as ~/.ssh/id_ed25519, so sync_server/sync.sh
# and any github clones on the remote have an identity.
#
# After setup, starts a detached tmux session `sync` on the remote running
# sync_server/sync.sh.

set -euo pipefail

ip="" port=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p) port="$2"; shift 2 ;;
        -p*) port="${1#-p}"; shift ;;
        *@*) ip="${1#*@}"; shift ;;
        *) shift ;;
    esac
done
if [[ -z "$ip" ]]; then
    echo "Usage: vast.sh -p PORT user@IP" >&2
    exit 1
fi
if [[ -z "$port" ]]; then
    echo "Usage: vast.sh -p PORT user@IP" >&2
    exit 1
fi

# ── Locate age passphrase ─────────────────────────────────────────────────────
password=""
for f in "$PWD/password.txt" "$HOME/password.txt"; do
    if [[ -f "$f" ]]; then
        password=$(tr -d '\r\n' < "$f")
        echo "Using age passphrase from $f"
        break
    fi
done
if [[ -z "$password" ]]; then
    read -rsp "age passphrase: " password
    echo
fi
if [[ -z "$password" ]]; then
    echo "No passphrase provided." >&2
    exit 1
fi

# ── Pick SSH key to copy to remote ────────────────────────────────────────────
key_src=""
if [[ -f "$HOME/.ssh/id-ed25519-2" ]]; then
    key_src="$HOME/.ssh/id-ed25519-2"
elif [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    key_src="$HOME/.ssh/id_ed25519"
else
    echo "No ~/.ssh/id-ed25519-2 or ~/.ssh/id_ed25519 found." >&2
    exit 1
fi
echo "Will copy SSH key from $key_src"

# ── Write ~/.ssh/config entry for `ssh vast` ──────────────────────────────────
touch ~/.ssh/config
awk '/^Host vast$/ {skip=1; next} skip && /^Host / {skip=0} !skip {print}' ~/.ssh/config > ~/.ssh/config.tmp
mv ~/.ssh/config.tmp ~/.ssh/config
cat >> ~/.ssh/config <<EOF

Host vast
    HostName $ip
    Port $port
    IdentityFile ~/.ssh/id_ed25519
    User shawnghu
    ForwardAgent yes
    LocalForward 9000 localhost:9000
EOF
chmod 600 ~/.ssh/config

SSH_OPTS=(-o StrictHostKeyChecking=accept-new)

# ── Phase 1: root creates the shawnghu user and installs system bits ──────────
echo "=== Phase 1: root provisioning ==="
ssh "${SSH_OPTS[@]}" -p "$port" "root@$ip" bash -s <<'REMOTE'
set -euxo pipefail
touch ~/.no_auto_tmux
cd /workspace
apt install -y sudo git
if [ ! -d user_config ]; then
    git clone https://github.com/shawnghu/user_config
fi
cd user_config
git remote get-url ssh >/dev/null 2>&1 || git remote add ssh git@github.com:shawnghu/user_config.git
./runpod.sh
REMOTE

# ── Ship the passphrase + private key to shawnghu's home ──────────────────────
echo "=== Copying passphrase and SSH key to shawnghu@$ip ==="
# Passphrase (via ssh stdin, no tempfile on local disk)
printf '%s\n' "$password" | ssh "${SSH_OPTS[@]}" -p "$port" "shawnghu@$ip" \
    'umask 077 && cat > ~/.age-passphrase'

# Private key
scp "${SSH_OPTS[@]}" -P "$port" "$key_src" "shawnghu@$ip:.ssh/id_ed25519"
ssh "${SSH_OPTS[@]}" -p "$port" "shawnghu@$ip" 'chmod 600 ~/.ssh/id_ed25519'

# ── Phase 2: shawnghu finishes install + init-repos + starts sync tmux ────────
echo "=== Phase 2: shawnghu install + init-repos + sync tmux ==="
ssh -A "${SSH_OPTS[@]}" -p "$port" "shawnghu@$ip" bash -s <<'REMOTE'
set -euxo pipefail
touch ~/.no_auto_tmux
cd /workspace/user_config
./install.sh
./init-repos.sh

# Launch sync.sh in a detached tmux session so it keeps running after ssh exits.
if ! tmux has-session -t sync 2>/dev/null; then
    tmux new-session -d -s sync "bash /workspace/user_config/sync_server/sync.sh 2>&1 | tee -a ~/sync.log; exec bash"
    echo "Started tmux session 'sync' (attach with: tmux attach -t sync)"
else
    echo "tmux session 'sync' already running"
fi
REMOTE

echo
echo "Provisioning complete. Run 'ssh vast' for an interactive session."
echo "Sync is running on the remote in tmux session 'sync' (tmux attach -t sync)."
