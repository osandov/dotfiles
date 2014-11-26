# Omar Sandoval's zshrc

# Gross hack because on several distros, PATH settings get blown away when
# /etc/profile is sourced by /etc/zsh/zprofile. This means that everything in
# zshenv must be idempotent.
source ~/.zshenv

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
export ZLE_REMOVE_SUFFIX_CHARS=""

if [ -r ~/.hostcolor ]; then
    source ~/.hostcolor
fi

if [ -r /usr/share/git/git-prompt.sh ]; then
    source /usr/share/git/git-prompt.sh
    GIT_PROMPT='%F{green}$(__git_ps1 " %s")%f'
fi

# One line prompt
# PROMPT="%F{blue}[%n@%{$PREHOST%}%m%{$POSTHOST%} %K{black}%F{cyan}%1~%k%F{blue}]%(#.#.$)%f "
# Two line prompt
setopt prompt_subst
PROMPT="%F{blue}┌[%n@%{$PREHOST%}%m%{$POSTHOST%} %K{black}%F{cyan}%~%k$GIT_PROMPT%F{blue}]
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

gpgconf --launch gpg-agent
export SSH_AUTH_SOCK=~/.gnupg/S.gpg-agent.ssh

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

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias meminfo='watch -n 1 cat /proc/meminfo'
alias cxclip='xclip -selection clipboard'
alias ag="ag --color-line-number=32 --color-path=34 --color-match='38;5;8;43'"
alias da='du --apparent-size'
alias pingg='ping 8.8.8.8'

alias tl='tmux list-sessions'
alias tk='tmux kill-session'
alias ts='tmux switch -t'

alias zathura='zathura --fork'
alias sml='rlwrap sml'
alias racket='rlwrap racket'

index () {
    whatis -s "$1" -r . | less
}

pag () {
    ag --color --group "$@" | "$PAGER"
}
