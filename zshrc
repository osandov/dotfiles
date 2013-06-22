# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' matcher-list '' 'r:|[._-]=** r:|=**' 'l:|=* r:|=*'
zstyle :compinstall filename '/home/osandov/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

setopt hist_ignore_space
setopt hist_ignore_all_dups

setopt extendedglob

autoload -U promptinit
promptinit
prompt redhat

PROMPT="%F{blue}$PROMPT%f"

source /etc/zsh_command_not_found

case $TERM in
    xterm*)
        precmd () {print -Pn "\e]0;%~\a"}
        preexec () {
            COMMAND=`echo "$1" | awk '{print $1}'`
            print -n "\e]0;$COMMAND\a"
        }
        ;;
esac

if [ -x /usr/bin/dircolors ]
then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias sml='rlwrap sml'
alias racket='rlwrap racket'
alias attu='ssh attu.cs.washington.edu'
alias karl='curl'
alias pimp='gimp'
alias meminfo='watch -n 1 cat /proc/meminfo'
alias plymouth='sudo plymouthd; sudo plymouth --show-splash; sleep 2; sudo plymouth quit'

function index() {
    whatis -s "$1" -r . | less
}

export PYTHONSTARTUP=~/.pythonrc
