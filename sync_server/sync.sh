#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/sync_config.conf"

# --- Parse config ---
SSH_HOST="" SSH_PORT="" SSH_USER="" SSH_IDENTITY=""
LOCAL_BASE="/home/shawnghu" REMOTE_BASE="/home/shawnghu" INTERVAL=60
SYNC_DIRS=()    # each entry: "path"
SYNC_EXCLUDES=() # each entry: space-separated exclude patterns (or empty)

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
                interval)    INTERVAL="${BASH_REMATCH[2]}" ;;
            esac
        elif [[ "$section" == "dirs" ]]; then
            local dir="${line%% *}"
            local excludes=""
            if [[ "$line" == *" "* ]]; then
                excludes="${line#* }"
            fi
            SYNC_DIRS+=("$dir")
            SYNC_EXCLUDES+=("$excludes")
        fi
    done < "$CONFIG"
}

parse_config

SSH_CMD="ssh -p $SSH_PORT -o StrictHostKeyChecking=accept-new"
if [[ -n "$SSH_IDENTITY" && -f "$SSH_IDENTITY" ]]; then
    SSH_CMD="$SSH_CMD -i $SSH_IDENTITY"
elif [[ -n "$SSH_AUTH_SOCK" ]]; then
    [[ -n "$SSH_IDENTITY" ]] && echo "Note: identity file '$SSH_IDENTITY' not present; using forwarded agent."
else
    echo "Error: no usable identity file and SSH_AUTH_SOCK is not set (no agent to forward)." >&2
    exit 1
fi
SSH_DEST="$SSH_USER@$SSH_HOST"

echo "=== shitty AWS ==="
echo "Syncing ${#SYNC_DIRS[@]} dir(s) from $LOCAL_BASE -> $SSH_DEST:$REMOTE_BASE"
echo "Interval: ${INTERVAL}s"
echo ""

# --- Sync loop for a single directory (runs as background job) ---
sync_dir() {
    local dir="$1"
    local excludes="$2"
    local src="$LOCAL_BASE/$dir/"
    local dst="$SSH_DEST:$REMOTE_BASE/$dir/"

    # Build rsync exclude args
    local rsync_excludes=()
    if [[ -n "$excludes" ]]; then
        for pattern in $(echo "$excludes" | tr ',' ' '); do
            rsync_excludes+=(--exclude="$pattern")
        done
    fi

    echo "[$$:$dir] Starting sync loop"
    while true; do
        if [[ ! -d "$LOCAL_BASE/$dir" ]]; then
            echo "[$$:$dir] Source does not exist yet, waiting..."
            sleep "$INTERVAL"
            continue
        fi

        rsync -az --update --mkpath --info=progress2 --no-whole-file \
            "${rsync_excludes[@]}" \
            -e "$SSH_CMD" \
            "$src" "$dst" 2>&1 | while IFS= read -r line; do
                [[ -n "$line" ]] && echo "[$(date +%H:%M:%S) $dir] $line"
            done

        sleep "$INTERVAL"
    done
}

# --- Sync loop for a single file, renamed with a hostname suffix on the remote ---
sync_file_suffixed() {
    local rel="$1"        # path relative to $HOME on both sides
    local suffix="$2"
    local src="$HOME/$rel"
    local dst="$SSH_DEST:$REMOTE_BASE/${rel}-${suffix}"

    echo "[$$:$rel] Starting file sync loop -> ${rel}-${suffix}"
    while true; do
        if [[ -f "$src" ]]; then
            rsync -az --append-verify -e "$SSH_CMD" \
                "$src" "$dst" 2>&1 | while IFS= read -r line; do
                    [[ -n "$line" ]] && echo "[$(date +%H:%M:%S) $rel] $line"
                done
        fi
        sleep "$INTERVAL"
    done
}

# --- Spawn a background sync loop per directory ---
PIDS=()
for i in "${!SYNC_DIRS[@]}"; do
    sync_dir "${SYNC_DIRS[$i]}" "${SYNC_EXCLUDES[$i]}" &
    PIDS+=($!)
done

# --- Also sync bash history/log files, suffixed with the local hostname ---
HOST_SUFFIX="$(hostname)"
for f in .bash_eternal_history .bash_extended_log; do
    sync_file_suffixed "$f" "$HOST_SUFFIX" &
    PIDS+=($!)
done

# --- Cleanup on exit ---
cleanup() {
    echo ""
    echo "Stopping all sync jobs..."
    for pid in "${PIDS[@]}"; do
        kill "$pid" 2>/dev/null
    done
    wait
    echo "Done."
}
trap cleanup SIGINT SIGTERM

echo "Running ${#PIDS[@]} sync job(s). Ctrl+C to stop."
wait
