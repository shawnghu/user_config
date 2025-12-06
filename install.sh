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
vim +PluginInstall +qall

ln -s `pwd`/.claude_bash_logger.sh ~
ln -s `pwd`/.claude_command_parser.py ~
mkdir -p ~/.claude
ln -s `pwd`/settings.json ~/.claude

ln -s `pwd`/kanata.kbd ~/.config/kanata/kanata.kbd

sudo apt update
sudo apt install -y build-essential

sudo apt install -y ripgrep

mkdir ~/.npm-global
export PATH=~/.npm-global/bin:$PATH
command -v npm && echo "npm is installed" || sudo apt install -y npm || echo "npm is NOT installed"
npm config set prefix '~/.npm-global'
npm install -g @anthropic-ai/claude-code

sudo apt install docker.io
sudo apt install docker-buildx
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

touch ~/.Xauthority

curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
zoxide init --cmd cd bash

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all # untested; these might conflict


