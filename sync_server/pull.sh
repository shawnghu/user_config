#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/sync_config.conf"

# --- Parse only the SSH and base settings from config ---
SSH_HOST="" SSH_PORT="" SSH_USER="" SSH_IDENTITY=""
LOCAL_BASE="/home/shawnghu" REMOTE_BASE="/home/shawnghu"

parse_config() {
    local section=""
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line%"${line##*[![:space:]]}"}"
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" ]] && continue

        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
        elif [[ "$section" == "ssh" && "$line" =~ ^([^=]+)=(.+)$ ]]; then
            case "${BASH_REMATCH[1]}" in
                host)     SSH_HOST="${BASH_REMATCH[2]}" ;;
                port)     SSH_PORT="${BASH_REMATCH[2]}" ;;
                user)     SSH_USER="${BASH_REMATCH[2]}" ;;
                identity) SSH_IDENTITY="${BASH_REMATCH[2]/#\~/$HOME}" ;;
            esac
        elif [[ "$section" == "settings" && "$line" =~ ^([^=]+)=(.+)$ ]]; then
            case "${BASH_REMATCH[1]}" in
                local_base)  LOCAL_BASE="${BASH_REMATCH[2]}" ;;
                remote_base) REMOTE_BASE="${BASH_REMATCH[2]}" ;;
            esac
        fi
    done < "$CONFIG"
}

parse_config

SSH_CMD="ssh -p $SSH_PORT -o StrictHostKeyChecking=accept-new"
if [[ -n "$SSH_IDENTITY" && -f "$SSH_IDENTITY" ]]; then
    SSH_CMD="$SSH_CMD -i $SSH_IDENTITY"
elif [[ -z "$SSH_AUTH_SOCK" ]]; then
    echo "Error: no usable identity file and SSH_AUTH_SOCK is not set." >&2
    exit 1
fi
SSH_DEST="$SSH_USER@$SSH_HOST"

DIR=".claude/projects"
SRC="$SSH_DEST:$REMOTE_BASE/$DIR/"
DST="$LOCAL_BASE/$DIR/"

echo "Pulling $SRC -> $DST (no deletes)"
rsync -az --update --mkpath --info=progress2 --no-whole-file \
    -e "$SSH_CMD" \
    "$SRC" "$DST"

echo "Done."
