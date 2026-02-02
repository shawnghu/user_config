#!/bin/bash
# List RunPod resources
# Usage: ./list.sh [volumes|pods|all]

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

show_volumes() {
    echo "=== Network Volumes ==="
    local volumes
    volumes=$(list_volumes)
    echo "$volumes" | jq -r '.[] | "\(.id)\t\(.name)\t\(.size)GB\t\(.dataCenterId)"' 2>/dev/null | column -t -s $'\t'
    echo ""
}

show_pods() {
    echo "=== Pods ==="
    local pods
    pods=$(list_pods)
    echo "$pods" | jq -r '.[] | "\(.id)\t\(.name)\t\(.desiredStatus)\t\(.machine.dataCenterId // "?")\t\(.gpu.displayName // "?")"' 2>/dev/null | column -t -s $'\t'
    echo ""

    # Show SSH commands for running pods
    echo "=== SSH Commands for Running Pods ==="
    echo "$pods" | jq -r '.[] | select(.desiredStatus == "RUNNING") | "\(.id) \(.publicIp) \(.portMappings["22"] // "")"' 2>/dev/null | while read -r id ip port; do
        if [ -n "$ip" ] && [ -n "$port" ]; then
            echo "# $id"
            echo "ssh -A root@${ip} -p ${port}"
            echo ""
        fi
    done
}

case "${1:-all}" in
    volumes) show_volumes ;;
    pods) show_pods ;;
    all) show_volumes; show_pods ;;
    *) echo "Usage: $0 [volumes|pods|all]"; exit 1 ;;
esac
