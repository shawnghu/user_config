#!/bin/bash
# needs: vim, tmux
command -v git && echo "git is installed" || sudo apt install git || echo "git is NOT installed"
git config --global user.email shawnghu@gmail.com 
git config --global user.name "Shawn Hu"

sudo apt install vim-gtk3
command -v tmux && echo "tmux is installed" || sudo apt install tmux || echo "tmux is NOT installed"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s `pwd`/.tmux.conf ~
~/.tmux/plugins/tpm/bin/install_plugins

ln -s `pwd`/.bashrc ~
ln -s `pwd`/.bash_profile ~

ln -s `pwd`/.vimrc ~
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall

ln -s `pwd`/.claude_bash_logger.sh ~
ln -s `pwd`/.claude_command_parser.py ~
mkdir -p ~/.claude
ln -s `pwd`/settings.json ~/.claude

command -v npm && echo "npm is installed" || sudo apt install npm || echo "npm is NOT installed"
npm install -g @anthropic-ai/claude-code


