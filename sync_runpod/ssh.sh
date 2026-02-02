#!/bin/bash
# Quick SSH to a RunPod pod
# Usage: ./ssh.sh [pod_id_or_name] [--user shawnghu]

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

POD_SEARCH="${1:-}"
SSH_USER="root"

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --user) SSH_USER="$2"; shift 2 ;;
        -*) echo "Unknown option: $1"; exit 1 ;;
        *) POD_SEARCH="$1"; shift ;;
    esac
done

# Get running pods
PODS=$(list_pods)
RUNNING_PODS=$(echo "$PODS" | jq -r '.[] | select(.desiredStatus == "RUNNING")')

if [ -z "$RUNNING_PODS" ]; then
    echo "No running pods found"
    exit 1
fi

# If no search term, list all running pods
if [ -z "$POD_SEARCH" ]; then
    echo "Running pods:"
    echo ""
    echo "$PODS" | jq -r '.[] | select(.desiredStatus == "RUNNING") |
        "  \(.id)  \(.name // "unnamed")\n    ssh -A root@\(.publicIp) -p \(.portMappings["22"] // "?")\n"'
    echo ""
    echo "Usage: $0 <pod_id_or_name> [--user shawnghu]"
    exit 0
fi

# Find matching pod
POD=$(echo "$PODS" | jq -r --arg search "$POD_SEARCH" '
    .[] | select(.desiredStatus == "RUNNING") |
    select(.id == $search or (.name | test($search; "i")))
' | head -1)

if [ -z "$POD" ]; then
    echo "No running pod found matching: $POD_SEARCH"
    exit 1
fi

PUBLIC_IP=$(echo "$POD" | jq -r '.publicIp // empty')
PORT_22=$(echo "$POD" | jq -r '.portMappings["22"] // empty')
POD_NAME=$(echo "$POD" | jq -r '.name // .id')

if [ -z "$PUBLIC_IP" ] || [ -z "$PORT_22" ]; then
    echo "Pod $POD_NAME is not ready for SSH yet"
    exit 1
fi

echo "Connecting to $POD_NAME as $SSH_USER..."
exec ssh -A "${SSH_USER}@${PUBLIC_IP}" -p "${PORT_22}"
