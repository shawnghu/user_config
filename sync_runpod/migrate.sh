#!/bin/bash
# Migrate to a new RunPod volume and optionally spin up a pod
# Usage: ./migrate.sh [preset] [options]
#
# If run on a RunPod pod without --migrate-from, automatically migrates /workspace
# to the new volume using sync_send.sh/sync_receive.sh.
#
# Presets (can be positional or use --preset):
#   cpu      16 vCPU compute-optimized, Ubuntu 24.04
#   1h100    1x H100 SXM, PyTorch 2.8
#   2h100    2x H100 SXM, PyTorch 2.8
#
# All presets filter for H200-available datacenters and expose ports:
#   HTTP: 8888, 8000, 8123, 5000-5005
#   TCP: 22
#
# Options:
#   --preset PRESET     Use a preset configuration (cpu, 1h100, 2h100)
#   --volume ID         Use existing volume (skips volume creation & migration)
#                       Use "current" to use the current pod's network volume
#   --migrate-from ID   Source volume or pod ID to migrate from
#   --no-migrate        Skip data migration entirely
#   --volume-only       Only create volume, don't create pod
#   --size SIZE         Volume size in GB (default: 1000)
#   --name NAME         Volume/pod name prefix
#   --gpu GPU_TYPE      GPU type (default: "NVIDIA H200")
#   --gpu-count N       Number of GPUs (default: 1)
#   --datacenter DC     Force specific datacenter (skip availability check)
#   --template ID       Use template ID for pod creation
#   --image IMAGE       Container image
#   --no-wait           Don't wait for pod to be ready
#   --dry-run           Show what would be done without doing it

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Defaults
VOLUME_SIZE=1000
NAME_PREFIX=""
GPU_TYPE="NVIDIA H200"
GPU_COUNT=1
IMAGE="runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04"
DATACENTER=""
TEMPLATE_ID=""
MIGRATE_FROM=""
VOLUME_ONLY=false
NO_MIGRATE=false
DRY_RUN=false
NO_WAIT=false
PRESET=""
IS_CPU_POD=false
VCPU_COUNT=0
EXISTING_VOLUME_ID=""

# Standard HTTP ports to expose
HTTP_PORTS="8888/http,8000/http,8123/http,5000/http,5001/http,5002/http,5003/http,5004/http,5005/http"

# Presets: cpu, 1h100, 2h100
apply_preset() {
    local preset="$1"
    case "$preset" in
        cpu)
            IS_CPU_POD=true
            VCPU_COUNT=16
            GPU_COUNT=0
            GPU_TYPE=""
            IMAGE="runpod/ubuntu:24.04"
            [ -z "$NAME_PREFIX" ] && NAME_PREFIX="shawn-cpu-$(date +%Y%m%d-%H%M)"
            ;;
        1h100)
            GPU_TYPE="NVIDIA H100 80GB HBM3"
            GPU_COUNT=1
            IMAGE="runpod/pytorch:2.8.0-py3.11-cuda12.4.1-devel-ubuntu22.04"
            [ -z "$NAME_PREFIX" ] && NAME_PREFIX="shawn-1h100-$(date +%Y%m%d-%H%M)"
            ;;
        2h100)
            GPU_TYPE="NVIDIA H100 80GB HBM3"
            GPU_COUNT=2
            IMAGE="runpod/pytorch:2.8.0-py3.11-cuda12.4.1-devel-ubuntu22.04"
            [ -z "$NAME_PREFIX" ] && NAME_PREFIX="shawn-2h100-$(date +%Y%m%d-%H%M)"
            ;;
        *)
            echo "Unknown preset: $preset"
            echo "Available presets: cpu, 1h100, 2h100"
            exit 1
            ;;
    esac
}

# Shawn's standard startup command (run as root after SSH)
STARTUP_CMD='cd /workspace && apt update && apt install -y sudo && (git clone https://github.com/shawnghu/user_config 2>/dev/null || true) && cd user_config && (git remote add ssh git@github.com:shawnghu/user_config.git 2>/dev/null || true); ./runpod.sh && su shawnghu -c "./install.sh"'

# Detect if running on RunPod
is_on_runpod() {
    [ -n "$RUNPOD_POD_ID" ] || [ -d "/runpod-volume" ] || [ -f "/.runpod" ]
}

# Get current pod's SSH info for remote execution
get_current_pod_ssh() {
    if [ -n "$RUNPOD_POD_ID" ]; then
        local pod_info
        pod_info=$(get_pod "$RUNPOD_POD_ID")
        local ip port
        ip=$(echo "$pod_info" | jq -r '.publicIp // empty')
        port=$(echo "$pod_info" | jq -r '.portMappings["22"] // empty')
        if [ -n "$ip" ] && [ -n "$port" ]; then
            echo "$ip:$port"
        fi
    fi
}

# Wait for a pod to be ready and return ip:port
wait_for_pod_ssh() {
    local pod_id="$1"
    local max_attempts="${2:-60}"

    for i in $(seq 1 "$max_attempts"); do
        local pod_info
        pod_info=$(get_pod "$pod_id")
        local status ip port
        status=$(echo "$pod_info" | jq -r '.desiredStatus')
        ip=$(echo "$pod_info" | jq -r '.publicIp // empty')
        port=$(echo "$pod_info" | jq -r '.portMappings["22"] // empty')

        if [ -n "$ip" ] && [ -n "$port" ]; then
            echo "$ip:$port"
            return 0
        fi

        echo "Waiting for pod $pod_id... ($i/$max_attempts) Status: $status" >&2
        sleep 5
    done

    return 1
}

# Run command on remote pod via SSH
ssh_to_pod() {
    local ip_port="$1"
    local user="${2:-root}"
    local cmd="$3"

    local ip="${ip_port%%:*}"
    local port="${ip_port##*:}"

    ssh -A -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$port" "${user}@${ip}" "$cmd"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --preset) PRESET="$2"; shift 2 ;;
        --volume) EXISTING_VOLUME_ID="$2"; shift 2 ;;
        --volume-only) VOLUME_ONLY=true; shift ;;
        --size) VOLUME_SIZE="$2"; shift 2 ;;
        --name) NAME_PREFIX="$2"; shift 2 ;;
        --gpu) GPU_TYPE="$2"; shift 2 ;;
        --gpu-count) GPU_COUNT="$2"; shift 2 ;;
        --datacenter) DATACENTER="$2"; shift 2 ;;
        --template) TEMPLATE_ID="$2"; shift 2 ;;
        --image) IMAGE="$2"; shift 2 ;;
        --migrate-from) MIGRATE_FROM="$2"; shift 2 ;;
        --no-migrate) NO_MIGRATE=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --no-wait) NO_WAIT=true; shift ;;
        cpu|1h100|2h100) PRESET="$1"; shift ;;  # Allow preset as positional arg
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Apply preset if specified
if [ -n "$PRESET" ]; then
    apply_preset "$PRESET"
fi

# Set default name if not set by preset or --name
[ -z "$NAME_PREFIX" ] && NAME_PREFIX="shawn-migrate-$(date +%Y%m%d-%H%M)"

# Detect migration source
ON_RUNPOD=false
if is_on_runpod; then
    ON_RUNPOD=true
    echo "Detected: Running on RunPod (pod: ${RUNPOD_POD_ID:-unknown})"
fi

if [ "$NO_MIGRATE" = false ] && [ -z "$MIGRATE_FROM" ] && [ "$ON_RUNPOD" = true ]; then
    MIGRATE_FROM="current"
    echo "Will migrate from current pod's /workspace"
fi

echo ""

# Step 1 & 2: Handle volume (use existing or create new)

# Handle --volume current
if [ "$EXISTING_VOLUME_ID" = "current" ]; then
    if [ -z "$RUNPOD_POD_ID" ]; then
        echo "ERROR: --volume current requires running on a RunPod pod"
        exit 1
    fi
    echo "=== Getting volume from current pod ==="
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would get volume from pod: $RUNPOD_POD_ID"
        EXISTING_VOLUME_ID="current-pod-volume-id"
    else
        CURRENT_POD_INFO=$(get_pod "$RUNPOD_POD_ID")
        EXISTING_VOLUME_ID=$(echo "$CURRENT_POD_INFO" | jq -r '.networkVolumeId // empty')
        if [ -z "$EXISTING_VOLUME_ID" ] || [ "$EXISTING_VOLUME_ID" = "null" ]; then
            echo "ERROR: Current pod has no network volume attached"
            exit 1
        fi
        echo "Current pod's volume: $EXISTING_VOLUME_ID"
    fi
fi

if [ -n "$EXISTING_VOLUME_ID" ]; then
    # Use existing volume - get its datacenter
    echo "=== Using existing volume: $EXISTING_VOLUME_ID ==="
    VOLUME_ID="$EXISTING_VOLUME_ID"

    if [ "$DRY_RUN" = false ]; then
        VOLUME_INFO=$(get_volume "$VOLUME_ID")
        VOLUME_DC=$(echo "$VOLUME_INFO" | jq -r '.dataCenterId // empty')
        VOLUME_NAME_EXISTING=$(echo "$VOLUME_INFO" | jq -r '.name // empty')

        if [ -z "$VOLUME_DC" ]; then
            echo "ERROR: Could not get datacenter for volume $VOLUME_ID"
            echo "$VOLUME_INFO"
            exit 1
        fi

        # Use volume's datacenter unless overridden
        if [ -z "$DATACENTER" ]; then
            DATACENTER="$VOLUME_DC"
        fi
        echo "Volume: $VOLUME_NAME_EXISTING"
        echo "Datacenter: $DATACENTER"
    else
        echo "[DRY RUN] Would use volume: $VOLUME_ID"
        [ -z "$DATACENTER" ] && DATACENTER="from-volume"
    fi

    # No migration needed when using existing volume
    NO_MIGRATE=true
    echo ""
else
    # Create new volume
    # Step 1: Find datacenter (always filter by H200 availability for preferred regions)
    if [ -z "$DATACENTER" ]; then
        echo "=== Finding datacenter with H200 availability ==="
        DATACENTER=$("$SCRIPT_DIR/check_availability.sh" "NVIDIA H200" 2 | tail -1)
        if [ -z "$DATACENTER" ]; then
            echo "ERROR: No datacenter found with H200 availability"
            exit 1
        fi
    fi
    echo "Using datacenter: $DATACENTER"
    echo ""

    # Step 2: Create volume
    VOLUME_NAME="${NAME_PREFIX}-vol"
    echo "=== Creating volume: $VOLUME_NAME ($VOLUME_SIZE GB) in $DATACENTER ==="

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would create volume: $VOLUME_NAME"
        VOLUME_ID="dry-run-volume-id"
    else
        VOLUME_RESULT=$(create_volume "$VOLUME_NAME" "$VOLUME_SIZE" "$DATACENTER")
        VOLUME_ID=$(echo "$VOLUME_RESULT" | jq -r '.id')
        if [ -z "$VOLUME_ID" ] || [ "$VOLUME_ID" = "null" ]; then
            echo "ERROR: Failed to create volume"
            echo "$VOLUME_RESULT"
            exit 1
        fi
        echo "Created volume: $VOLUME_ID"
    fi
    echo ""

    if [ "$VOLUME_ONLY" = true ]; then
        echo "=== Volume-only mode, skipping pod creation ==="
        echo "Volume ID: $VOLUME_ID"
        exit 0
    fi
fi

# Step 3: Create pod
POD_NAME="${NAME_PREFIX}-pod"
echo "=== Creating pod: $POD_NAME ==="

# Build ports array
PORTS_JSON=$(echo "$HTTP_PORTS,22/tcp" | tr ',' '\n' | jq -R . | jq -s .)

# Build pod creation JSON
if [ "$IS_CPU_POD" = true ]; then
    # CPU-only pod
    POD_JSON=$(jq -n \
        --arg name "$POD_NAME" \
        --arg image "$IMAGE" \
        --arg volumeId "$VOLUME_ID" \
        --arg datacenter "$DATACENTER" \
        --argjson vcpuCount "$VCPU_COUNT" \
        --argjson ports "$PORTS_JSON" \
        --arg templateId "$TEMPLATE_ID" \
        '{
            name: $name,
            imageName: $image,
            networkVolumeId: $volumeId,
            dataCenterIds: [$datacenter],
            dataCenterPriority: "custom",
            gpuCount: 0,
            vcpuCount: $vcpuCount,
            memoryInGb: 64,
            volumeInGb: 0,
            containerDiskInGb: 50,
            ports: $ports,
            volumeMountPath: "/workspace"
        } + (if $templateId != "" then {templateId: $templateId} else {} end)'
    )
else
    # GPU pod
    POD_JSON=$(jq -n \
        --arg name "$POD_NAME" \
        --arg image "$IMAGE" \
        --arg volumeId "$VOLUME_ID" \
        --arg datacenter "$DATACENTER" \
        --arg gpuType "$GPU_TYPE" \
        --argjson gpuCount "$GPU_COUNT" \
        --argjson ports "$PORTS_JSON" \
        --arg templateId "$TEMPLATE_ID" \
        '{
            name: $name,
            imageName: $image,
            networkVolumeId: $volumeId,
            dataCenterIds: [$datacenter],
            dataCenterPriority: "custom",
            gpuTypeIds: [$gpuType],
            gpuTypePriority: "custom",
            gpuCount: $gpuCount,
            volumeInGb: 0,
            containerDiskInGb: 50,
            ports: $ports,
            volumeMountPath: "/workspace"
        } + (if $templateId != "" then {templateId: $templateId} else {} end)'
    )
fi

if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would create pod with:"
    echo "$POD_JSON" | jq .
    POD_ID="dry-run-pod-id"
    NEW_POD_SSH="dry-run-ip:22"
else
    POD_RESULT=$(create_pod "$POD_JSON")
    POD_ID=$(echo "$POD_RESULT" | jq -r '.id')
    if [ -z "$POD_ID" ] || [ "$POD_ID" = "null" ]; then
        echo "ERROR: Failed to create pod"
        echo "$POD_RESULT"
        exit 1
    fi
    echo "Created pod: $POD_ID"
fi
echo ""

# Step 4: Wait for new pod to be ready
echo "=== Waiting for new pod to be ready ==="
if [ "$DRY_RUN" = false ]; then
    NEW_POD_SSH=$(wait_for_pod_ssh "$POD_ID" 60)
    if [ -z "$NEW_POD_SSH" ]; then
        echo "ERROR: Timed out waiting for pod to be ready"
        exit 1
    fi
    echo "New pod ready: $NEW_POD_SSH"
fi
echo ""

# Step 5: Migrate data using sync_send.sh / sync_receive.sh
if [ "$NO_MIGRATE" = false ] && [ -n "$MIGRATE_FROM" ]; then
    echo "=== Migrating data ==="

    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would migrate data from: $MIGRATE_FROM"
        echo "[DRY RUN] Would run: sync_send.sh (creates archive, sends via runpodctl)"
        echo "[DRY RUN] Would run: sync_receive.sh <code> on new pod"
    else
        echo "Starting data transfer using sync scripts..."

        if [ "$MIGRATE_FROM" = "current" ]; then
            # Running on source pod - run sync_send.sh locally
            echo "Running sync_send.sh locally..."

            SEND_OUTPUT=$("$SCRIPT_DIR/sync_send.sh" 2>&1) || {
                echo "ERROR: sync_send.sh failed"
                echo "$SEND_OUTPUT"
                exit 1
            }
            echo "$SEND_OUTPUT"

            # Extract the receive code (format: "runpodctl receive <code>")
            RECEIVE_CODE=$(echo "$SEND_OUTPUT" | grep -oP 'runpodctl receive \K\S+' | head -1)

            if [ -z "$RECEIVE_CODE" ]; then
                echo "ERROR: Could not extract receive code from send output"
                exit 1
            fi

            echo ""
            echo "Receive code: $RECEIVE_CODE"
            echo ""

            # Copy sync_receive.sh to new pod and run it
            echo "Running sync_receive.sh on new pod..."
            # First, ensure the sync scripts exist on new pod (clone user_config if needed)
            ssh_to_pod "$NEW_POD_SSH" "root" "cd /workspace && (git clone https://github.com/shawnghu/user_config 2>/dev/null || cd user_config && git pull) && cd user_config/sync_runpod && ./sync_receive.sh $RECEIVE_CODE"

            echo "Data migration complete!"
        else
            # MIGRATE_FROM is a pod ID - need to SSH to it
            echo "Getting SSH info for source pod: $MIGRATE_FROM..."
            SOURCE_SSH=$(wait_for_pod_ssh "$MIGRATE_FROM" 10) || {
                echo "ERROR: Could not get SSH info for source pod $MIGRATE_FROM"
                echo "Make sure the pod is running."
                exit 1
            }

            echo "Source pod: $SOURCE_SSH"
            echo "Running sync_send.sh on source pod..."

            SEND_OUTPUT=$(ssh_to_pod "$SOURCE_SSH" "root" "cd /workspace/user_config/sync_runpod && ./sync_send.sh" 2>&1) || {
                echo "ERROR: sync_send.sh failed on source pod"
                echo "$SEND_OUTPUT"
                exit 1
            }
            echo "$SEND_OUTPUT"

            RECEIVE_CODE=$(echo "$SEND_OUTPUT" | grep -oP 'runpodctl receive \K\S+' | head -1)

            if [ -z "$RECEIVE_CODE" ]; then
                echo "ERROR: Could not extract receive code"
                exit 1
            fi

            echo ""
            echo "Receive code: $RECEIVE_CODE"
            echo ""

            echo "Running sync_receive.sh on new pod..."
            ssh_to_pod "$NEW_POD_SSH" "root" "cd /workspace && (git clone https://github.com/shawnghu/user_config 2>/dev/null || cd user_config && git pull) && cd user_config/sync_runpod && ./sync_receive.sh $RECEIVE_CODE"

            echo "Data migration complete!"
        fi
    fi
    echo ""
fi

# Step 6: Output SSH info
NEW_IP="${NEW_POD_SSH%%:*}"
NEW_PORT="${NEW_POD_SSH##*:}"

echo "=== SSH Commands (copy-paste ready) ==="
echo ""
echo "# Root SSH:"
echo "ssh -A root@${NEW_IP} -p ${NEW_PORT}"
echo ""
echo "# User SSH (after setup):"
echo "ssh -A shawnghu@${NEW_IP} -p ${NEW_PORT}"
echo ""
echo "=== Initial Setup (run after root SSH) ==="
echo "$STARTUP_CMD"
echo ""

# Save quick connect script
if [ "$DRY_RUN" = false ]; then
    SSH_FILE="/tmp/runpod-ssh-${POD_ID}.sh"
    cat > "$SSH_FILE" << SSHEOF
#!/bin/bash
# SSH to pod $POD_ID ($POD_NAME) in $DATACENTER
ssh -A root@${NEW_IP} -p ${NEW_PORT}
SSHEOF
    chmod +x "$SSH_FILE"
    echo "# Quick connect: $SSH_FILE"
    echo ""
fi

echo "=== Summary ==="
echo "Volume ID: $VOLUME_ID"
echo "Pod ID: $POD_ID"
echo "Datacenter: $DATACENTER"
if [ -n "$MIGRATE_FROM" ] && [ "$NO_MIGRATE" = false ]; then
    echo "Migrated from: $MIGRATE_FROM"
fi
