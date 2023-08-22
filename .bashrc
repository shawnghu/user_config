# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples


# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

alias shit='sudo $(fc -ln -1)' #for when you forget to sudo
alias ro='$(`fc -e -`)' # execute last output
alias co='echo `fc -e -` | xclip -in -selection clipboard' # copy last output    
alias vo='vim -p `fc -e -`' #vimopen last output-- note that interaction with fg is weird     
alias sudo='sudo ' #used so that sudo evaluates aliases
alias au='apt update'
alias agin='apt-get install '
alias agrm='apt-get remove '

histrun() {
    echo "history | grep -vE \"history|histrun\" | grep -oE \"$1.*$\" | tail -n 1"
    history -s "$(history | grep -vE "history|histrun" | grep -oE "$1.*$" | tail -n 1)"
}

git-ls() {
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

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

#literally just for cd/ls typos
#function cd() { builtin cd "$@" && ls; }
function cl() { pushd "$@" && ls; }
function ccd() { pushd "$@" && ls; }
function d() { pushd "$@" && ls; }
#function cla() { builtin cd "$@" && ls -la; }
function sl() { ls; }
function lsc() { ls; }

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

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

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

# use vim to read man pages
export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma' -\""

# put timestamps in history file
export HISTTIMEFORMAT="%d/%m/%y %T "

# prompts to install package when command not found
export COMMAND_NOT_FOUND_INSTALL_PROMPT=1


# deal with dark blue on black color scheme for bash on ubuntu on windows
#LS_COLORS='rs=0:di=1;35:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lz=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.axv=01;35:*.anx=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.axa=00;36:*.oga=00;36:*.spx=00;36:*.xspf=00;36:';
#export LS_COLORS

#cuda commands
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64"
export CUDA_HOME=/usr/local/cuda

#turn off the annoying error sound for bash on ubuntu on windows
bind 'set bell-style none'

#howto: change terminal color scheme
#wget -O gogh https://git.io/vQgMr && chmod +x gogh && ./gogh && rm gogh

###########################################################
#work, specifically crossover machine

#machine specific

#docker
if [ -n "$CONTAINER" ]; then
  PS1_PREFIX="\[\033[01;35m\][docker] \[\033[00m\]"
else
  PS1_PREFIX=""
fi
unset color_prompt force_color_prompt
PS1="${PS1_PREFIX}${PS1}"

#normally set by drive script but avoided because it fucks up the container for CI
#export DISPLAY=:0

alias scrapebag='python ~/scripts/scrape_ros_bags.py'

alias s3mount='s3fs plusai ~/s3 -o uid=${UID},gid=${UID},umask=227,passwd_file=${HOME}/.passwd-s3fs-us -d'
#https://github.com/s3fs-fuse/s3fs-fuse/issues/333
#https://github.com/s3fs-fuse/s3fs-fuse/issues/305
#alias s3szmount='s3fs public-plusai ~/s3 -o url=http://18.222.250.114:8888,uid=${UID},gid=${UID},umask=227,passwd_file=${HOME}/.passwd-s3fs-suzhou,sigv2,use_path_request_style -f -d'

alias rostime='rosparam set use_sim_time true'
alias tmks='tmux kill-session -t runtime'
alias wtls='git worktree list'
alias wtlsp='git worktree list --porcelain'

export PATH=/usr/local/cuda/bin:$PATH
export ROS_MASTER_URI=http://localhost:11311
export GLOG_v=3

#drive repo
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/nvidia-410
#export DRIVE_ROOT=/home/shawnghu/drive
export DISTCC_HOSTS=localhost/32

#logs
alias cddlog='cd ~/drive/opt/debug/log/plusai'
alias cdrlog='cd ~/drive/opt/relwithdebinfo/log/plusai'

#autoformatting
alias format='clang-format -style=file -i'

alias cleardisplayenv='unset DISPLAY; unset XAUTHORITY; unset XSOCK;'

# need to surround arg in quotes when calling this function
function getsnip() {
    echo "$1"
    END=$(echo "$1" | grep -oE "end=[0-9]*" | grep -oE "[0-9]*")
    START=$(echo "$1" | grep -oE "start=[0-9]*" | grep -oE "[0-9]*")
    BAGNAME=$(echo "$1" | grep -oE "202[0-2][^/&]*.db")
    
    echo $END
    echo $START
    echo $BAGNAME
    wget "$1" -O ${BAGNAME%%.*}_${START}to${END}.db

}
