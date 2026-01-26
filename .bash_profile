#function cd() { builtin cd "$@" && ls; }
function cl() { builtin cd "$@" && ls; }
#function cla() { builtin cd "$@" && ls -la; }
function sl() { ls; }

source ~/.bashrc

. "$HOME/.local/bin/env"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
