# Omar Sandoval's zshrc

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]} l:|=* r:|=*' 'l:|=* r:|=*' 'r:|[._-]=** r:|=**'
zstyle :compinstall filename '/home/osandov/.zshrc'

fpath=(~/.zsh/completion ~/.zsh $fpath)
autoload -Uz compinit
compinit
# End of lines added by compinstall

setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt extendedglob
setopt inc_append_history
bindkey -e

if [ -r ~/.hostcolor ]; then
    source ~/.hostcolor
fi

# One line prompt
# PROMPT="%F{blue}[%n@%{$PREHOST%}%m%{$POSTHOST%} %K{black}%F{cyan}%1~%k%F{blue}]%(#.#.$)%f "
# Two line prompt
PROMPT="%F{blue}┌[%n@%{$PREHOST%}%m%{$POSTHOST%} %K{black}%F{cyan}%~%k%F{blue}]
└%(#.#.$)%f "

autoload -Uz zshmarks
zshmarks

case $DISTRO in
    arch)
        source /usr/share/doc/pkgfile/command-not-found.zsh
        ;;
    ubuntu)
        source /etc/zsh_command_not_found
        ;;
esac

case $TERM in
    xterm*)
        stty -ixon
        precmd () {print -Pn "\e]0;%~\a"}
        preexec () {
            COMMAND=$(echo "$1" | awk '{print $1}')
            print -n "\e]0;$COMMAND\a"
        }
        ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# if [ -z "$TMUX" ]; then
    # exec tmx
# elif [ "$TMUX" = "zlogin" ]; then
    # export TMUX=
# fi

export ZLE_REMOVE_SUFFIX_CHARS=""

index () {
    whatis -s "$1" -r . | less
}

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias meminfo='watch -n 1 cat /proc/meminfo'
alias cxclip='xclip -selection clipboard'
alias ag="ag --color-line-number=32 --color-path=34 --color-match='35;1'"
alias da='du --apparent-size'
alias pingg='ping 8.8.8.8'

alias tl='tmux list-sessions'
alias tk='tmux kill-session'
alias ts='tmux switch -t'

alias zathura='zathura --fork'
alias sml='rlwrap sml'
alias racket='rlwrap racket'
