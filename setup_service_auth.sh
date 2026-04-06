#!/bin/bash
# Install age and configure API keys/service logins from encrypted secrets

# age encryption (for secrets)
sudo apt install age
if ! command -v age &>/dev/null; then
    curl -LO https://github.com/FiloSottile/age/releases/download/v1.2.0/age-v1.2.0-linux-amd64.tar.gz
    tar xzf age-v1.2.0-linux-amd64.tar.gz
    mkdir -p ~/.local/bin
    mv age/age age/age-keygen ~/.local/bin/
    rm -rf age age-v1.2.0-linux-amd64.tar.gz
fi

# Configure API keys from encrypted secrets
if command -v age &>/dev/null && [ -f "$(dirname "$0")/secrets.age" ]; then
    echo "Configuring services from encrypted secrets..."
    if eval "$(age -d "$(dirname "$0")/secrets.age")"; then
        # Hugging Face
        if [ -n "$HF_TOKEN" ]; then
            uvx --from huggingface_hub huggingface-cli login --token "$HF_TOKEN" --add-to-git-credential
            echo "  huggingface-cli: configured"
        fi
        # Weights & Biases
        if [ -n "$WANDB_API_KEY" ]; then
            uvx --from wandb wandb login --relogin "$WANDB_API_KEY"
            echo "  wandb: configured"
        fi
    else
        echo "  Failed to decrypt secrets"
    fi
else
    echo "Skipping service configuration (age or secrets.age not found)"
fi
