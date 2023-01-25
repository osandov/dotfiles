typeset -U path manpath
# New environment variables of this sort can be added with typeset -TU. For
# example, for GOPATH:
# typeset -TU GOPATH gopath

add_to_path () {
	if [ -d "$1" ]; then
		path=("$1" "$path[@]")
	fi
}

append_to_path () {
	if [ -d "$1" ]; then
		path=("$path[@]" "$1")
	fi
}

add_to_manpath () {
	if [ -d "$1" ]; then
		manpath=("$1" "$manpath[@]" "")
	fi
}

# Arch Linux
add_to_path /usr/share/git/diff-highlight
# Fedora
add_to_path /usr/share/git-core/contrib

add_to_path ~/.dotfiles/bin
add_to_path ~/.local/bin
add_to_manpath ~/.local/share/man

export PATH MANPATH

if type vimx > /dev/null; then
	export EDITOR=vimx
elif type gvim > /dev/null; then
	export EDITOR="gvim -v"
fi
export VISUAL="$EDITOR"
export PAGER=less

export RIPGREP_CONFIG_PATH="$HOME/.dotfiles/ripgreprc"

# Used by .zshrc for the prompt. This is an SGR sequence, so the default "0"
# means normal text, but, e.g., "31;1" means bold red. See console_codes(4).
HOSTNAME_COLOR=0

if [ -r ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi
