# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples


# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

alias xclip='xclip -selection clipboard'
alias dbash='f() { docker exec -it ${1:-$(docker ps | head -n 2 | tail -n 1 | cut -d " " -f 1)} /bin/bash; }; f'
alias dstart='f() { docker start ${1:-$(docker ps -a | head -n 2 | tail -n 1 | cut -d " " -f 1)}; }; f'
alias tback='f() { dir=$(basename $(pwd)); docker run --network none -v .:/mcp_server/$dir -i $dir uv --offline --directory /mcp_server run $dir mcp; }; f'
alias tfront='f() { dir=$(basename $(pwd)); docker_id=$(docker run --network none -d -v .:/mcp_server/$dir -i $dir uv --offline --directory /mcp_server run $dir mcp) && echo "http://localhost:5000/app?container_id=$docker_id&problem_id=${1:-train-sae-basic-strong-hint}&max_tokens=64000"; }; f' 
alias ttag='f() { docker tag "$1" "us-east1-docker.pkg.dev/gcp-taiga/dmodel/$2"; }; f'
alias tpush='f() { docker push "us-east1-docker.pkg.dev/gcp-taiga/dmodel/$1"; }; f'
alias tlist='gcloud artifacts docker images list us-east1-docker.pkg.dev/gcp-taiga/dmodel'
alias tpull='f() { docker pull "us-east1-docker.pkg.dev/gcp-taiga/dmodel/$1"; }; f'
alias shit='sudo $(fc -ln -1)' #for when you forget to sudo
alias ro='$(`fc -e -`)' # execute last output
alias co='echo `fc -e -` | xclip -in -selection clipboard' # copy last output    
alias vo='vim -p `fc -e -`' #vimopen last output-- note that interaction with fg is weird     
alias sudo='sudo ' #used so that sudo evaluates aliases
alias au='apt update'
alias agin='apt-get install '
alias agrm='apt-get remove '

alias grlog="reflog --date=format:\'%Y-%m-%d %H:%M'"
alias gc="git commit"
alias gcm="git commit -m"
alias ga="git add"
alias gau="git add -u"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gs="git status"
alias gsu="git status -uno"
alias gch="git checkout"
alias gsh="git show"
alias gshn="git show --name-status"
alias gd="git diff"
alias gdn="git diff --name-status"

alias ll='ls -lA'
alias lf='ls -lAf'
alias lfr='ls -lAfr'
alias fn='find . -name'
alias rg='rg -i'

#literally just for cd/ls typos
#function cd() { builtin cd "$@" && ls; }
function cl() { pushd "$@" && ls; }
function ccd() { pushd "$@" && ls; }
function d() { pushd "$@" && ls; }
#function cla() { builtin cd "$@" && ls -la; }
function sl() { ls; }
function lsc() { ls; }



commit() {
    local cmd="$*"
        git commit -a -m "$($cmd | tee /dev/tty)" -m "$cmd" --allow-empty
    }

histrun() {
    echo "history | grep -vE \"history|histrun\" | grep -oE \"$1.*$\" | tail -n 1"
    history -s "$(history | grep -vE "history|histrun" | grep -oE "$1.*$" | tail -n 1)"
}

gls() {
    FILES="$(git ls-tree --name-only HEAD .)"
    MAXLEN=0
    IFS="$(printf "\n\b")"
    for f in $FILES; do
        if [ ${#f} -gt $MAXLEN ]; then
            MAXLEN=${#f}
        fi
    done
    for f in $FILES; do
        str="$(git log -1 --pretty=format:"%C(green)%cr%Creset %x09 %C(cyan)%h%Creset %s %C(yellow)(%cn)%Creset" $f)"
        printf "%-${MAXLEN}s -- %s\n" "$f" "$str"
    done
}


pushd()
{
  if [ $# -eq 0 ]; then
    DIR="${HOME}"
  else
    DIR="$1"
  fi

  builtin pushd "${DIR}" > /dev/null
}

pushd_builtin()
{
  builtin pushd > /dev/null
}

popd()
{
  builtin popd > /dev/null
}

alias cd='pushd'
alias back='popd'
alias flip='pushd_builtin'

alias cp='cp -i'
alias mv='mv -i'

# enable color support of ls and grep
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

#vi mode for terminal
#set -o vi
set -o emacs

#avoid ctrl-s causing terminal xoff signal
# stty -ixon

shopt -s histverify
shopt -s histreedit
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar


# If not running interactively, don't do anything
#case $- in
#    *i*) ;;
#      *) return;;
#esac

#use vim by default to edit in most programs
export VISUAL=vim
export EDITOR="$VISUAL"

# don't put duplicate lines
# See bash(1) for more options
HISTCONTROL=ignoredups

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
#HISTSIZE=1000
#HISTFILESIZE=2000
#instead, set history size to be infinite
export HISTFILESIZE=
export HISTSIZE=

# Change the file location because certain bash sessions truncate .bash_history file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.bash_eternal_history

# put timestamps in history file
# export HISTTIMEFORMAT="%d/%m/%y %T "

hcmnt() {

# adds comments to bash history entries (or logs them)

# by Dennis Williamson - 2009-06-05 - updated 2009-06-19
# http://stackoverflow.com/questions/945288/saving-current-directory-to-bash-history
# (thanks to Lajos Nagy for the idea)

# the comments can include the directory
# that was current when the command was issued
# plus optionally, the date or other information

# set the bash variable PROMPT_COMMAND to the name
# of this function and include these options:

    # -e - add the output of an extra command contained in the hcmntextra variable
    # -i - add ip address of terminal that you are logged in *from*
    #      if you're using screen, the screen number is shown
    #      if you're directly logged in, the tty number or X display number is shown
    # -l - log the entry rather than replacing it in the history
    # -n - don't add the directory
    # -t - add the from and to directories for cd commands
    # -y - add the terminal device (tty)
    # text or a variable

# Example result for PROMPT_COMMAND='hcmnt -et $LOGNAME'
#     when hcmntextra='date "+%Y%m%d %R"'
# cd /usr/bin ### mike 20090605 14:34 /home/mike -> /usr/bin

# Example for PROMPT_COMMAND='hcmnt'
# cd /usr/bin ### /home/mike

# Example for detailed logging:
#     when hcmntextra='date "+%Y%m%d %R"'
#     and PROMPT_COMMAND='hcmnt -eityl ~/.hcmnt.log $LOGNAME@$HOSTNAME'
#     $ tail -1 ~/.hcmnt.log
#     cd /var/log ### dave@hammerhead /dev/pts/3 192.168.1.1 20090617 16:12 /etc -> /var/log


# INSTALLATION: source this file in your .bashrc

    # will not work if HISTTIMEFORMAT is used - use hcmntextra instead
    export HISTTIMEFORMAT=

    # HISTTIMEFORMAT still works in a subshell, however, since it gets unset automatically:

    #   $ htf="%Y-%m-%d %R "    # save it for re-use
    #   $ (HISTTIMEFORMAT=$htf; history 20)|grep 11:25

    local script=$FUNCNAME

    local hcmnt=
    local cwd=
    local extra=
    local text=
    local logfile=

    local options=":eil:nty"
    local option=
    OPTIND=1
    local usage="Usage: $script [-e] [-i] [-l logfile] [-n|-t] [-y] [text]"

    local newline=$'\n' # used in workaround for bash history newline bug
    local histline=     # used in workaround for bash history newline bug

    local ExtraOpt=
    local LogOpt=
    local NoneOpt=
    local ToOpt=
    local tty=
    local ip=

    # *** process options to set flags ***

    while getopts $options option
    do
        case $option in
            e ) ExtraOpt=1;;        # include hcmntextra
            i ) ip="$(who --ips -m)" # include the terminal's ip address
                ip=($ip)
                ip="${ip[4]}"
                if [[ -z $ip ]]
                then
                    ip=$(tty)
                fi;;
            l ) LogOpt=1            # log the entry
                logfile=$OPTARG;;
            n ) if [[ $ToOpt ]]
                then
                    echo "$script: can't include both -n and -t."
                    echo $usage
                    return 1
                else
                    NoneOpt=1       # don't include path
                fi;;
            t ) if [[ $NoneOpt ]]
                then
                    echo "$script: can't include both -n and -t."
                    echo $usage
                    return 1
                else
                    ToOpt=1         # cd shows "from -> to"
                fi;;
            y ) tty=$(tty);;
            : ) echo "$script: missing filename: -$OPTARG."
                echo $usage
                return 1;;
            * ) echo "$script: invalid option: -$OPTARG."
                echo $usage
                return 1;;
        esac
    done

    text=($@)                       # arguments after the options are saved to add to the comment
    text="${text[*]:$OPTIND - 1:${#text[*]}}"

    # *** process the history entry ***

    hcmnt=$(history 1)              # grab the most recent command

    # save history line number for workaround for bash history newline bug
    histline="${hcmnt%  *}"

    hcmnt="${hcmnt# *[0-9]*  }"     # strip off the history line number

    if [[ -z $NoneOpt ]]            # are we adding the directory?
    then
        if [[ ${hcmnt%% *} == "cd" ]]    # if it's a cd command, we want the old directory
        then                             #   so the comment matches other commands "where *were* you when this was done?"
            if [[ $ToOpt ]]
            then
                cwd="$OLDPWD -> $PWD"    # show "from -> to" for cd
            else
                cwd=$OLDPWD              # just show "from"
            fi
        else
            cwd=$PWD                     # it's not a cd, so just show where we are
        fi
    fi

    if [[ $ExtraOpt && $hcmntextra ]]    # do we want a little something extra?
    then
        extra=$(eval "$hcmntextra")
    fi

    # strip off the old ### comment if there was one so they don't accumulate
    # then build the string (if text or extra aren't empty, add them plus a space)
    hcmnt="${hcmnt% ### *} ### ${text:+$text }${tty:+$tty }${ip:+$ip }${extra:+$extra }$cwd"

    if [[ $LogOpt ]]
    then
        # save the entry in a logfile
        echo "$hcmnt" >> $logfile || echo "$script: file error." ; return 1
    else

        # workaround for bash history newline bug
        if [[ $hcmnt != ${hcmnt/$newline/} ]] # if there a newline in the command
        then
            history -d $histline # then delete the current command so it's not duplicated
        fi

        # replace the history entry
        history -s "$hcmnt"
    fi

} # END FUNCTION hcmnt

# set a default (must use -e option to include it)
export hcmntextra='date "+%Y%m%d %R"'      # you must be really careful to get the quoting right

# start using it
# log to this file because i can't figure out how to get this function to stop duplicating things in the pan-up history
# try "man history" to figure out the exact behavior of -s and -d above and/or whether the terminal history is independent of HISTFILE and see if you can fix it
export PROMPT_COMMAND='hcmnt -etl ~/.bash_extended_log' 
PROMPT_COMMAND="history -a; $PROMPT_COMMAND" # save history after every command; interleaves history between multiple terminals



# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes


if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
    else
    color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt


# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

#git branch in prompt, overrides all previous PS1
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="${PS1%?}\$(parse_git_branch)\[\033[00m\] "

export PATH="~/.local/bin:$PATH"

# put timestamps in history file
export HISTTIMEFORMAT="%d/%m/%y %T "

# prompts to install package when command not found
export COMMAND_NOT_FOUND_INSTALL_PROMPT=1


#docker
if [ -n "$CONTAINER" ]; then
  PS1_PREFIX="\[\033[01;35m\][docker] \[\033[00m\]"
else
  PS1_PREFIX=""
fi
unset color_prompt force_color_prompt
PS1="${PS1_PREFIX}${PS1}"

export PATH=~/.npm-global/bin:$PATH

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
