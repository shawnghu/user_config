#!/bin/bash
# needs: vim, tmux

command -v vim && echo "vim is installed" || sudo apt install vim || echo "vim is NOT installed"
command -v tmux && echo "tmux is installed" || sudo apt install tmux || echo "tmux is NOT installed"
command -v git && echo "git is installed" || sudo apt install git || echo "git is NOT installed"

ln -s `pwd`/.bashrc ~
ln -s `pwd`/.bash_profile ~

ln -s `pwd`/.vimrc ~
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -s `pwd`/.tmux.conf ~
~/.tmux/plugins/tpm/bin/install_plugins

git config --global user.email shawnghu@gmail.com 
git config --global user.name "Shawn Hu"
