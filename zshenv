typeset -U path manpath
# New environment variables of this sort can be added with typeset -TU. For
# example, for GOPATH:
# typeset -TU GOPATH gopath

add_to_path() {
	if [ -d "$1" ]; then
		path=("$1" "$path[@]")
	fi
}

add_to_manpath() {
	if [ -d "$1" ]; then
		manpath=("$1" "$manpath[@]" "")
	fi
}

add_to_path ~/.dotfiles/bin
add_to_path ~/.local/bin
add_to_manpath ~/.local/share/man

export PATH MANPATH

export EDITOR=vim
export VISUAL=vim
export PYTHONSTARTUP=~/.pythonrc
export PAGER=less
# Clear the screen properly and allow ANSI color escape sequences in less
export LESS=cR

if [ -r ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi
