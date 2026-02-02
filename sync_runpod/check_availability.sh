#!/bin/bash
# Check GPU availability by datacenter, prioritized by preference tiers
# Usage: ./check_availability.sh [gpu_type] [min_count]
#   gpu_type: GPU type to check (default: "NVIDIA H200")
#   min_count: minimum available count (default: 2)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

GPU_TYPE="${1:-NVIDIA H200}"
MIN_COUNT="${2:-2}"

# GraphQL query to get GPU availability by datacenter
get_gpu_availability() {
    local query
    query='query { gpuTypes { id displayName nodeGroupDatacenters { id name gpuAvailability { stockStatus gpuTypeId } } } }'
    runpod_graphql "$query"
}

# Find datacenters with available GPUs of specified type
find_available_datacenters() {
    local gpu_type="$1"
    local result
    result=$(get_gpu_availability)

    # Extract datacenters where this specific GPU type has High or Medium stock
    echo "$result" | jq -r --arg gpu "$gpu_type" '
        .data.gpuTypes[]
        | select(.id == $gpu)
        | .nodeGroupDatacenters[]
        | select(.gpuAvailability[]? | select(.gpuTypeId == $gpu and (.stockStatus == "High" or .stockStatus == "Medium")))
        | .id
    ' 2>/dev/null | sort -u
}

main() {
    echo "Checking availability for: $GPU_TYPE (min: $MIN_COUNT)"
    echo ""

    local available_dcs
    available_dcs=$(find_available_datacenters "$GPU_TYPE")

    if [ -z "$available_dcs" ]; then
        echo "No datacenters found with available $GPU_TYPE"
        exit 1
    fi

    echo "Datacenters with $GPU_TYPE available:"
    echo "$available_dcs" | while read -r dc; do
        echo "  - $dc"
    done
    echo ""

    # Check each tier in preference order
    for tier_name in TIER_A TIER_B TIER_C TIER_D; do
        declare -n tier="$tier_name"
        for dc in "${tier[@]}"; do
            if echo "$available_dcs" | grep -q "^${dc}$"; then
                echo "RECOMMENDED: $dc (from $tier_name)"
                echo "$dc"  # Output just the datacenter for scripting
                exit 0
            fi
        done
    done

    # If none in our preferred list, return first available
    local first_dc
    first_dc=$(echo "$available_dcs" | head -1)
    echo "FALLBACK: $first_dc (not in preferred list)"
    echo "$first_dc"
}

# If sourced, just load functions; if executed, run main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
