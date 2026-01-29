#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/sync_config.conf"

# Parse config
parse_config() {
    local section=""
    SYNC_DIRS=()
    SYNC_FILES=()
    EXCLUDE_PATTERNS=()
    MAX_SUBDIR_SIZE=10737418240
    ARCHIVE_NAME="sync_bundle.tar.gz"
    HOME_DIR="/workspace"

    while IFS= read -r line; do
        line="${line%%#*}"  # strip comments
        line="${line%"${line##*[![:space:]]}"}"  # trim trailing
        line="${line#"${line%%[![:space:]]*}"}"  # trim leading
        [[ -z "$line" ]] && continue

        if [[ "$line" =~ ^\[(.+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
        elif [[ "$section" == "dirs" ]]; then
            SYNC_DIRS+=("${line/#\~/$HOME_DIR}")
        elif [[ "$section" == "files" ]]; then
            SYNC_FILES+=("${line/#\~/$HOME_DIR}")
        elif [[ "$section" == "exclude" ]]; then
            EXCLUDE_PATTERNS+=("$line")
        elif [[ "$section" == "settings" && "$line" =~ ^([^=]+)=(.+)$ ]]; then
            key="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            [[ "$key" == "max_subdir_size" ]] && MAX_SUBDIR_SIZE="$val"
            [[ "$key" == "archive_name" ]] && ARCHIVE_NAME="$val"
            [[ "$key" == "home_dir" ]] && HOME_DIR="$val"
        fi
    done < "$CONFIG"
    # Re-expand paths now that HOME_DIR is set
    local tmp=("${SYNC_DIRS[@]}")
    SYNC_DIRS=()
    for d in "${tmp[@]}"; do
        SYNC_DIRS+=("${d/#\~/$HOME_DIR}")
    done
    tmp=("${SYNC_FILES[@]}")
    SYNC_FILES=()
    for f in "${tmp[@]}"; do
        SYNC_FILES+=("${f/#\~/$HOME_DIR}")
    done
}

parse_config

# Build exclude args
exclude_args=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    exclude_args+=(--exclude="$pattern")
done

# Find large subdirs to exclude
for dir in "${SYNC_DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r subdir; do
        size=$(du -sb "$subdir" 2>/dev/null | cut -f1)
        if [[ "$size" -ge "$MAX_SUBDIR_SIZE" ]]; then
            rel_path="${subdir#$HOME_DIR/}"
            exclude_args+=(--exclude="$rel_path")
            echo "Excluding large dir: $subdir ($(numfmt --to=iec $size))"
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
done

# Convert to paths relative to $HOME_DIR
rel_paths=()
for dir in "${SYNC_DIRS[@]}"; do
    [[ -d "$dir" ]] || { echo "Warning: $dir does not exist, skipping"; continue; }
    rel_paths+=("${dir#$HOME_DIR/}")
done
for file in "${SYNC_FILES[@]}"; do
    [[ -f "$file" ]] || { echo "Warning: $file does not exist, skipping"; continue; }
    rel_paths+=("${file#$HOME_DIR/}")
done

[[ ${#rel_paths[@]} -eq 0 ]] && { echo "Nothing to sync!"; exit 1; }

echo "Creating archive..."
cd "$HOME_DIR"
tar -czvf "/tmp/$ARCHIVE_NAME" "${exclude_args[@]}" "${rel_paths[@]}"

echo "Archive created: /tmp/$ARCHIVE_NAME ($(du -h "/tmp/$ARCHIVE_NAME" | cut -f1))"
echo "Sending via runpodctl..."
runpodctl send "/tmp/$ARCHIVE_NAME"
