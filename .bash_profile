#function cd() { builtin cd "$@" && ls; }
function cl() { builtin cd "$@" && ls; }
#function cla() { builtin cd "$@" && ls -la; }
function sl() { ls; }

source ~/.bashrc
