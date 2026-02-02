#!/bin/bash
cat << 'EOF'
RunPod Sync Utilities
=====================

Low-Level Sync Scripts:
  ./sync_send.sh
      Creates tar archive of configured directories and sends via runpodctl.
      - Reads sync_config.conf for directories to sync
      - Auto-excludes large subdirs (>1GB by default)
      - Excludes patterns like .git/objects, __pycache__, node_modules

  ./sync_receive.sh [CODE]
      Receives archive via runpodctl and extracts to /workspace.
      - Prompts for code if not provided
      - Checks for conflicts before overwriting

  ./sync_config.conf
      Config file for sync scripts:
        [dirs]      - directories to sync (relative to home_dir)
        [exclude]   - patterns to exclude
        [settings]  - max_subdir_size, archive_name, home_dir

High-Level Management Scripts:
  ./migrate.sh [PRESET] [OPTIONS]
      Full migration: find datacenter, create volume, create pod, migrate data.
      Uses sync_send.sh/sync_receive.sh for smart data transfer.

      If run ON a RunPod pod: automatically migrates configured dirs to new pod.
      If run elsewhere: creates volume + pod without migration (use --migrate-from).

      Presets (positional or --preset):
        cpu      16 vCPU compute-optimized, Ubuntu 24.04, 64GB RAM
        1h100    1x H100 SXM (80GB), PyTorch 2.8
        2h100    2x H100 SXM (80GB), PyTorch 2.8

      All configurations:
        - Filter for H200-available datacenters
        - Expose HTTP ports: 8888, 8000, 8123, 5000-5005
        - Expose TCP port: 22 (SSH)

      Options:
        --preset PRESET     Use a preset (cpu, 1h100, 2h100)
        --volume ID         Use existing volume (skips creation & migration)
                            Use "current" for current pod's volume
        --migrate-from ID   Migrate from specific pod ID (SSH to it and send)
        --no-migrate        Skip data migration entirely
        --volume-only       Only create volume, skip pod creation
        --size SIZE         Volume size in GB (default: 1000)
        --name NAME         Name prefix
        --gpu GPU_TYPE      GPU type (default: "NVIDIA H200" = H200 SXM)
        --gpu-count N       Number of GPUs (default: 1)
        --datacenter DC     Force specific datacenter
        --template ID       Use template for pod creation
        --image IMAGE       Container image
        --no-wait           Don't wait for pod to be ready
        --dry-run           Show what would be done

      Examples:
        ./migrate.sh cpu                       # CPU pod in H200 datacenter
        ./migrate.sh 1h100 --no-migrate        # 1x H100, no data migration
        ./migrate.sh 2h100                     # 2x H100, full migration
        ./migrate.sh 1h100 --volume abc123     # New pod on existing volume
        ./migrate.sh 2h100 --volume current    # Upgrade: new pod, same volume
        ./migrate.sh --migrate-from abc123     # Migrate from specific pod
        ./migrate.sh --gpu "NVIDIA H200" --size 500  # Custom config

  ./check_availability.sh [GPU_TYPE] [MIN_COUNT]
      Find datacenters with available GPUs, sorted by preference tier.
      Default: "NVIDIA H200" (H200 SXM), min 2 available

      Common GPU IDs:
        "NVIDIA H200"           = H200 SXM
        "NVIDIA H200 NVL"       = H200 NVL
        "NVIDIA H100 80GB HBM3" = H100 SXM
        "NVIDIA H100 NVL"       = H100 NVL

  ./list.sh [volumes|pods|all]
      List network volumes and/or pods with status and SSH info.

  ./ssh.sh [POD_ID_OR_NAME] [--user USER]
      SSH to a running pod. Without args, lists running pods.
      Example: ./ssh.sh shawncpu --user shawnghu

Datacenter Preference Tiers:
  Tier A (highest): CA-MTL-3, US-GA-1, US-GA-2, US-KS-2
  Tier B: All other US + Canada sites
  Tier C: European sites (EU-*)
  Tier D: Iceland (EUR-IS-*), Japan, Australia, etc.

Typical Workflow (from existing RunPod pod):
  1. Run: ./migrate.sh
     - Finds best datacenter with H200 availability
     - Creates new 1TB volume there
     - Spins up new pod
     - Runs sync_send.sh to archive configured dirs
     - Runs sync_receive.sh on new pod to extract
     - Outputs SSH commands

Typical Workflow (from local machine):
  1. Check availability:  ./check_availability.sh "NVIDIA H200"
  2. Create + migrate:    ./migrate.sh --migrate-from <old_pod_id>
  3. SSH to new pod:      ./ssh.sh <new_pod_name>
  4. Run setup as root:   <startup command shown after migrate>

Manual Sync (without full migration):
  1. On source pod:  ./sync_send.sh
  2. Copy the receive code shown
  3. On dest pod:    ./sync_receive.sh <code>

Environment:
  Requires: age, jq, curl, runpodctl
  API key: ~/user_config/secrets.age (encrypted with SSH key)
  Auto-detects RunPod via: RUNPOD_POD_ID env var or /runpod-volume
EOF
