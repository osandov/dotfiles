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
setopt hist_substpattern
setopt extendedglob
setopt inc_append_history
bindkey -e
export ZLE_REMOVE_SUFFIX_CHARS=""

if [ -r /usr/share/git/git-prompt.sh ]; then
    # Arch Linux
    source /usr/share/git/git-prompt.sh
elif [ -r /usr/share/git-core/contrib/completion/git-prompt.sh ]; then
    # Fedora
    source /usr/share/git-core/contrib/completion/git-prompt.sh
elif [ -r /etc/bash_completion.d/git-prompt ]; then
    # Ubuntu
    source /etc/bash_completion.d/git-prompt
fi

function () {
    local git_prompt=""
    if whence -f __git_ps1 &> /dev/null; then
	    git_prompt='%F{green}$(__git_ps1 " %s")%f'
    fi

    setopt prompt_subst

    PROMPT="┌[%n@%F{$HOSTNAME_COLOR}%m%f %F{cyan}%~%f$git_prompt]%(?.. %F{red}:(%f)
└%(#.#.$) "
}

# Disable Ctrl-S/Ctrl-Q flow control nonsense
stty -ixon

autoload -Uz zshmarks
zshmarks
AUTOMARKDIRS+=(~/repos ~/linux)
alias j='jump'

if [ -r /usr/share/doc/pkgfile/command-not-found.zsh ]; then
    # Arch Linux
    source /usr/share/doc/pkgfile/command-not-found.zsh
elif [ -r /etc/zsh_command_not_found ]; then
    # Ubuntu
    source /etc/zsh_command_not_found
fi

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias meminfo='watch -n 1 cat /proc/meminfo'
alias da='du --apparent-size'
alias info='info --vi-keys'
if [[ $VISUAL = "vimx" || $VISUAL = "gvim -v" ]]; then
	alias vim="$VISUAL"
fi

t() {
	if [[ $# -eq 0 ]]; then
		tmux
	elif [[ $# -eq 1 ]]; then
		tmux new-session -As "$1"
	else
		echo "usage: $0 [SESSION_NAME]" >&2
		return 1
	fi
}
ta() {
	if [[ $# -eq 0 ]]; then
		tmux attach-session
	elif [[ $# -eq 1 ]]; then
		tmux attach-session -t "$1"
	else
		echo "usage: $0 [SESSION_NAME]" >&2
		return 1
	fi
}
tj() {
	if [[ $# -ne 1 ]]; then
		echo "usage: $0 MARK" >&2
		return 1
	fi
	local dir
	dir="$(readmark "$1")" && tmux new-session -As "$1" -c "$dir"
}
alias tl='tmux list-sessions'
alias tk='tmux kill-session'
alias ts='tmux switch -t'

ssht() {
	ssh -t "$1" '$SHELL' -lc 'tmux\ new-session\ -As\ '"${1%%.*}"
}

pingg () {
	if [[ $1 -eq -6 ]]; then
		ping 2001:4860:4860::8888
	else
		ping 8.8.8.8
	fi
}

open () {
    xdg-open "$@" &!
}

index () {
    whatis -s "$1" -r . | less
}

prg() {
	rg --color=always --heading --line-number "$@" |
		sh -c 'if [ "${LESS+set}" != set ]; then export LESS=FRX; fi; exec "${PAGER-less}"'
}

vimrg() {
	vim "+Rg$(printf " %q" "$@")"
}

pxxd() {
	xxd -R always "$@" |
		sh -c 'if [ "${LESS+set}" != set ]; then export LESS=FRX; fi; exec "${PAGER-less}"'
}

with_github_token() {
	local token
	token=$(gawk '
match($0, /^(\S+):/, group) {
	hostname = group[1]
	next
}

hostname == "github.com" && match($0, /^\s+oauth_token:\s*(\S+)/, group) {
	print group[1]
	exit
}' ~/.config/gh/hosts.yml)
	if [[ -z "$token" ]]; then
		echo "oauth_token for github.com not found" >&2
		return 1
	fi
	env GITHUB_TOKEN="$token" "$@"
}

if [ -r ~/.zshrc.local ]; then
	source ~/.zshrc.local
fi
