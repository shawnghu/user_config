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

# List network volumes (via GraphQL)
list_volumes() {
    runpod_graphql "{ myself { networkVolumes { id name dataCenterId size } } }" \
        | jq '.data.myself.networkVolumes'
}

# Get volume by ID (via GraphQL)
get_volume() {
    local volume_id="$1"
    runpod_graphql "{ myself { networkVolumes { id name dataCenterId size } } }" \
        | jq --arg id "$volume_id" '.data.myself.networkVolumes[] | select(.id == $id)'
}

# Create network volume (via GraphQL)
# Note: Requires API key with write permissions
create_volume() {
    local name="$1"
    local size="${2:-1000}"  # Default 1TB
    local datacenter="$3"

    local mutation="mutation { createNetworkVolume(input: { name: \\\"$name\\\", size: $size, dataCenterId: \\\"$datacenter\\\" }) { id name dataCenterId size } }"
    local result=$(runpod_graphql "$mutation")

    # Check for errors
    local error=$(echo "$result" | jq -r '.errors[0].message // empty')
    if [ -n "$error" ]; then
        echo "ERROR: $error" >&2
        echo "Note: Volume creation requires an API key with write permissions." >&2
        echo "Create volumes manually at https://www.runpod.io/console/user/storage" >&2
        return 1
    fi

    echo "$result" | jq '.data.createNetworkVolume'
}

# List pods (via GraphQL)
list_pods() {
    runpod_graphql "{ myself { pods { id name networkVolume { id name dataCenterId } desiredStatus runtime { ports { privatePort publicPort ip isIpPublic } } } } }" \
        | jq '.data.myself.pods'
}

# Get pod by ID (via GraphQL)
# Transforms response to be compatible with expected format:
#   - .networkVolumeId (from .networkVolume.id)
#   - .dataCenterId (from .networkVolume.dataCenterId)
#   - .publicIp (from runtime.ports where isIpPublic=true)
#   - .portMappings["22"] (from array of {publicPort, privatePort})
get_pod() {
    local pod_id="$1"
    runpod_graphql "{ myself { pods { id name networkVolume { id name dataCenterId } desiredStatus runtime { ports { privatePort publicPort ip isIpPublic } } } } }" \
        | jq --arg id "$pod_id" '
            .data.myself.pods[] | select(.id == $id) |
            . + {
                networkVolumeId: .networkVolume.id,
                dataCenterId: .networkVolume.dataCenterId,
                publicIp: (if .runtime.ports then (.runtime.ports[] | select(.isIpPublic) | .ip) else null end)
            } |
            .portMappings = (if .runtime.ports then (.runtime.ports | map({(.privatePort | tostring): .publicPort}) | add) else {} end)
        '
}

# Create pod (via runpodctl)
# Accepts JSON with: name, imageName, networkVolumeId, dataCenterIds, gpuTypeIds,
#                    gpuCount, volumeInGb, containerDiskInGb, ports, volumeMountPath,
#                    vcpuCount, memoryInGb
create_pod() {
    local json="$1"

    # Extract fields from input JSON
    local name=$(echo "$json" | jq -r '.name')
    local image=$(echo "$json" | jq -r '.imageName')
    local volume_id=$(echo "$json" | jq -r '.networkVolumeId // empty')
    local datacenter=$(echo "$json" | jq -r '.dataCenterIds[0] // empty')
    local gpu_type=$(echo "$json" | jq -r '.gpuTypeIds[0] // empty')
    local gpu_count=$(echo "$json" | jq -r '.gpuCount // 0')
    local volume_gb=$(echo "$json" | jq -r '.volumeInGb // 0')
    local container_gb=$(echo "$json" | jq -r '.containerDiskInGb // 20')
    local mount_path=$(echo "$json" | jq -r '.volumeMountPath // "/workspace"')
    local vcpu_count=$(echo "$json" | jq -r '.vcpuCount // 1')
    local memory_gb=$(echo "$json" | jq -r '.memoryInGb // 20')

    # Build runpodctl command
    local cmd="runpodctl create pod --name \"$name\" --imageName \"$image\" --containerDiskSize $container_gb --volumeSize $volume_gb --volumePath \"$mount_path\" --startSSH"

    # Add GPU configuration
    if [ "$gpu_count" -gt 0 ] && [ -n "$gpu_type" ]; then
        cmd="$cmd --gpuCount $gpu_count --gpuType \"$gpu_type\""
    else
        cmd="$cmd --gpuCount 0"
    fi

    # Add CPU/memory configuration
    cmd="$cmd --vcpu $vcpu_count --mem $memory_gb"

    # Add network volume if specified
    if [ -n "$volume_id" ]; then
        cmd="$cmd --networkVolumeId \"$volume_id\""
    fi

    # Add datacenter if specified
    if [ -n "$datacenter" ]; then
        cmd="$cmd --dataCenterId \"$datacenter\""
    fi

    # Add ports
    local ports_array=$(echo "$json" | jq -r '.ports[]')
    for port in $ports_array; do
        cmd="$cmd --ports \"$port\""
    done

    # Run the command and capture output
    local output
    output=$(eval "$cmd" 2>&1)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        echo "{\"error\": \"$output\"}" >&2
        return 1
    fi

    # Parse pod ID from output (format: "pod <id> created")
    local pod_id=$(echo "$output" | grep -oP 'pod \K[a-z0-9]+(?= created)' || echo "$output" | grep -oP '^[a-z0-9]+$')

    if [ -n "$pod_id" ]; then
        echo "{\"id\": \"$pod_id\", \"name\": \"$name\"}"
    else
        # Return raw output as JSON if we can't parse it
        echo "{\"id\": null, \"output\": \"$output\"}"
    fi
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
