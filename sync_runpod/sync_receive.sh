#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/sync_config.conf"

# Parse config (just need archive_name)
ARCHIVE_NAME="sync_bundle.tar.gz"
while IFS= read -r line; do
    if [[ "$line" =~ ^archive_name=(.+)$ ]]; then
        ARCHIVE_NAME="${BASH_REMATCH[1]}"
        break
    fi
done < "$CONFIG"

ARCHIVE_PATH="/tmp/$ARCHIVE_NAME"

# Get receive code
if [[ -n "$1" ]]; then
    CODE="$1"
else
    read -p "Enter runpodctl receive code: " CODE
fi

[[ -z "$CODE" ]] && { echo "No code provided"; exit 1; }

echo "Receiving via runpodctl..."
cd /tmp
runpodctl receive "$CODE"

if [[ ! -f "$ARCHIVE_PATH" ]]; then
    echo "Error: Expected $ARCHIVE_PATH but not found"
    exit 1
fi

# Check for conflicts
echo "Checking for conflicts..."
conflicts=()
while IFS= read -r entry; do
    target="$HOME/$entry"
    [[ -e "$target" ]] && conflicts+=("$target")
done < <(tar -tzf "$ARCHIVE_PATH" | grep -v '/$' | head -20)

if [[ ${#conflicts[@]} -gt 0 ]]; then
    echo "Warning: The following files already exist:"
    printf '  %s\n' "${conflicts[@]}"
    [[ ${#conflicts[@]} -eq 20 ]] && echo "  ... (showing first 20 only)"
    echo ""
    read -p "Overwrite existing files? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting. Archive preserved at: $ARCHIVE_PATH"
        echo "Manual extract: tar -xzvf $ARCHIVE_PATH -C \$HOME"
        exit 0
    fi
fi

echo "Extracting to $HOME..."
tar -xzvf "$ARCHIVE_PATH" -C "$HOME"
echo "Done. Archive at: $ARCHIVE_PATH"
