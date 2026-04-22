#!/bin/bash
# Install age and configure API keys/service logins from encrypted secrets.
# Non-interactive mode: if a passphrase file exists at one of the locations
# below, age is driven via script(1) (providing a PTY) with that passphrase
# on stdin. Otherwise falls back to an interactive tty prompt.
#
# Passphrase lookup order:
#   1. $HOME/.age-passphrase
#   2. $PWD/password.txt
#   3. $HOME/password.txt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_AGE="$SCRIPT_DIR/secrets.age"

# age encryption (for secrets)
if ! command -v age &>/dev/null; then
    sudo apt install -y age || true
fi
if ! command -v age &>/dev/null; then
    curl -LO https://github.com/FiloSottile/age/releases/download/v1.2.0/age-v1.2.0-linux-amd64.tar.gz
    tar xzf age-v1.2.0-linux-amd64.tar.gz
    mkdir -p ~/.local/bin
    mv age/age age/age-keygen ~/.local/bin/
    rm -rf age age-v1.2.0-linux-amd64.tar.gz
    export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v age &>/dev/null || [ ! -f "$SECRETS_AGE" ]; then
    echo "Skipping service configuration (age or secrets.age not found)"
    exit 0
fi

PASSPHRASE_FILE=""
for f in "$HOME/.age-passphrase" "$PWD/password.txt" "$HOME/password.txt"; do
    if [ -f "$f" ]; then
        PASSPHRASE_FILE="$f"
        break
    fi
done

echo "Configuring services from encrypted secrets..."

_decrypted=""
if [ -n "$PASSPHRASE_FILE" ]; then
    echo "  Decrypting non-interactively (passphrase: $PASSPHRASE_FILE)"
    _tmp=$(mktemp)
    chmod 600 "$_tmp"
    # script(1) supplies a PTY so age can read its passphrase from /dev/tty;
    # we feed the passphrase via script's stdin. -e propagates age's exit code.
    if script -qefc "age -d '$SECRETS_AGE' > '$_tmp'" /dev/null < "$PASSPHRASE_FILE" >/dev/null 2>&1; then
        _decrypted=$(cat "$_tmp")
    fi
    shred -u "$_tmp" 2>/dev/null || rm -f "$_tmp"
else
    _decrypted=$(age -d "$SECRETS_AGE")
fi

if [ -n "$_decrypted" ]; then
    (umask 077 && printf '%s\n' "$_decrypted" > ~/.secrets_env)
    eval "$_decrypted"
    unset _decrypted
    if [ -n "$HF_TOKEN" ]; then
        uvx --from huggingface_hub huggingface-cli login --token "$HF_TOKEN" --add-to-git-credential
        echo "  huggingface-cli: configured"
    fi
    if [ -n "$WANDB_API_KEY" ]; then
        uvx --from wandb wandb login --relogin "$WANDB_API_KEY"
        echo "  wandb: configured"
    fi
else
    echo "  Failed to decrypt secrets"
    exit 1
fi
