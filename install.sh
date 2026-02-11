#!/bin/bash
# needs: vim, tmux
command -v git && echo "git is installed" || sudo apt install -y git || echo "git is NOT installed"
git config --global user.email shawnghu@gmail.com 
git config --global user.name "Shawn Hu"
git config --global alias.rlog "reflog --date=format:'%Y-%m-%d %H:%M'"

sudo apt install vim-gtk3
command -v tmux && echo "tmux is installed" || sudo apt install -y tmux || echo "tmux is NOT installed"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s `pwd`/.tmux.conf ~
~/.tmux/plugins/tpm/bin/install_plugins

ln -sf `pwd`/.bashrc ~ # overwrite amazon ec2 default
ln -sf `pwd`/.bash_profile ~

ln -s `pwd`/.vimrc ~
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
echo | vim +PluginInstall +qall # this pipes a newline into vim to press enter to deal with an error dialog

ln -s `pwd`/.claude_bash_logger.sh ~
ln -s `pwd`/.claude_command_parser.py ~
mkdir -p ~/.claude
ln -s `pwd`/settings.json ~/.claude

ln -s `pwd`/kanata.kbd ~/.config/kanata/kanata.kbd

sudo apt update
sudo apt install -y build-essential

sudo apt install -y ripgrep

curl -fsSL https://claude.ai/install.sh | bash

sudo apt install -y docker.io
sudo apt install -y docker-buildx
sudo usermod -a -G docker $USER

# Claude sandbox (containerized claude with network firewall)
if [ ! -d ~/claude-sandbox ]; then
    git clone https://github.com/shawnghu/claude-sandbox ~/claude-sandbox
fi
# Build requires docker group - may need to log out/in first if just added
if groups | grep -q docker; then
    ~/claude-sandbox/build.sh
else
    echo "NOTE: Log out and back in, then run ~/claude-sandbox/build.sh to build the sandbox image"
fi

curl -LsSf https://astral.sh/uv/install.sh | sh

# bun (required for hive-mind plugin)
curl -fsSL https://bun.sh/install | bash

# age encryption (for secrets)
if ! command -v age &>/dev/null; then
    curl -LO https://github.com/FiloSottile/age/releases/download/v1.2.0/age-v1.2.0-linux-amd64.tar.gz
    tar xzf age-v1.2.0-linux-amd64.tar.gz
    mkdir -p ~/.local/bin
    mv age/age age/age-keygen ~/.local/bin/
    rm -rf age age-v1.2.0-linux-amd64.tar.gz
fi

touch ~/.Xauthority

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
zoxide init --cmd cd bash

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all # untested; these might conflict

# install runpodctl
sudo wget --quiet --show-progress https://github.com/Run-Pod/runpodctl/releases/download/v1.14.3/runpodctl-linux-amd64 -O runpodctl && chmod +x runpodctl && sudo cp runpodctl /usr/bin/runpodctl

# Configure API keys from encrypted secrets
if command -v age &>/dev/null && [ -f "$(dirname "$0")/secrets.age" ]; then
    echo "Configuring services from encrypted secrets..."
    if eval "$(age -d -i ~/.ssh/id_ed25519 "$(dirname "$0")/secrets.age" 2>/dev/null)"; then
        # Hugging Face
        if [ -n "$HF_TOKEN" ]; then
            if command -v huggingface-cli &>/dev/null; then
                huggingface-cli login --token "$HF_TOKEN" --add-to-git-credential
                echo "  huggingface-cli: configured"
            else
                echo "  huggingface-cli: not installed, skipping"
            fi
        fi
        # Weights & Biases
        if [ -n "$WANDB_API_KEY" ]; then
            if command -v wandb &>/dev/null; then
                wandb login --relogin "$WANDB_API_KEY"
                echo "  wandb: configured"
            else
                echo "  wandb: not installed, skipping"
            fi
        fi
        # RunPod
        if [ -n "$RUNPOD_API_KEY" ]; then
            if command -v runpodctl &>/dev/null; then
                runpodctl config --apiKey="$RUNPOD_API_KEY"
                echo "  runpodctl: configured"
            else
                echo "  runpodctl: not installed, skipping"
            fi
        fi
    else
        echo "  Failed to decrypt secrets (SSH key not available?)"
    fi
else
    echo "Skipping service configuration (age or secrets.age not found)"
fi
