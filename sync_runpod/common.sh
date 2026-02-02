#!/bin/bash
# Common functions for RunPod management scripts

# Datacenter preference tiers (highest to lowest priority)
# Tier A: User's preferred sites
TIER_A=(CA-MTL-3 US-GA-1 US-GA-2 US-KS-2)
# Tier B: All other US and Canada sites
TIER_B=(CA-MTL-1 CA-MTL-2 CA-MTL-4 US-CA-2 US-DE-1 US-IL-1 US-NC-1 US-TX-1 US-TX-3 US-TX-4 US-WA-1 US-KS-3 US-MO-1)
# Tier C: European sites
TIER_C=(EU-RO-1 EU-CZ-1 EU-FR-1 EU-NL-1 EU-SE-1)
# Tier D: Iceland and other regions
TIER_D=(EUR-IS-1 EUR-IS-2 EUR-IS-3 EUR-IS-4 EUR-NO-1 OC-AU-1 AP-JP-1)

ALL_PREFERRED_DCS=("${TIER_A[@]}" "${TIER_B[@]}" "${TIER_C[@]}" "${TIER_D[@]}")

# Load API key from encrypted secrets
load_api_key() {
    if [ -n "$RUNPOD_API_KEY" ]; then
        return 0
    fi
    if command -v age &>/dev/null && [ -f ~/user_config/secrets.age ]; then
        eval "$(age -d -i ~/.ssh/id_ed25519 ~/user_config/secrets.age 2>/dev/null)" || {
            echo "Failed to decrypt secrets" >&2
            return 1
        }
    else
        echo "Cannot load API key: age or secrets.age not found" >&2
        return 1
    fi
}

# REST API helper
runpod_api() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    load_api_key || return 1

    local args=(
        --silent
        --request "$method"
        --url "https://rest.runpod.io/v1${endpoint}"
        --header "Authorization: Bearer $RUNPOD_API_KEY"
        --header "Content-Type: application/json"
    )

    if [ -n "$data" ]; then
        args+=(--data "$data")
    fi

    curl "${args[@]}"
}

# GraphQL API helper
runpod_graphql() {
    local query="$1"

    load_api_key || return 1

    curl --silent \
        --request POST \
        --url "https://api.runpod.io/graphql" \
        --header "Authorization: Bearer $RUNPOD_API_KEY" \
        --header "Content-Type: application/json" \
        --data "{\"query\": \"$query\"}"
}

# List network volumes
list_volumes() {
    runpod_api GET /networkvolumes
}

# Get volume by ID
get_volume() {
    local volume_id="$1"
    runpod_api GET "/networkvolumes/$volume_id"
}

# Create network volume
create_volume() {
    local name="$1"
    local size="${2:-1000}"  # Default 1TB
    local datacenter="$3"

    runpod_api POST /networkvolumes "{\"name\": \"$name\", \"size\": $size, \"dataCenterId\": \"$datacenter\"}"
}

# List pods
list_pods() {
    runpod_api GET /pods
}

# Get pod by ID
get_pod() {
    local pod_id="$1"
    runpod_api GET "/pods/$pod_id"
}

# Create pod
create_pod() {
    local json="$1"
    runpod_api POST /pods "$json"
}

# Get SSH command for a pod
get_ssh_commands() {
    local pod_id="$1"
    local pod_info
    pod_info=$(get_pod "$pod_id")

    local public_ip port_22
    public_ip=$(echo "$pod_info" | jq -r '.publicIp // empty')
    port_22=$(echo "$pod_info" | jq -r '.portMappings["22"] // empty')

    if [ -n "$public_ip" ] && [ -n "$port_22" ]; then
        echo "# SSH as root:"
        echo "ssh -A root@${public_ip} -p ${port_22}"
        echo ""
        echo "# SSH as shawnghu:"
        echo "ssh -A shawnghu@${public_ip} -p ${port_22}"
    else
        echo "# Pod not ready yet (no public IP or port mapping)"
        echo "# Pod ID: $pod_id"
    fi
}
