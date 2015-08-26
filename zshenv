typeset -U path manpath

if [ -d ~/.dotfiles/bin ]; then
    path=(~/.dotfiles/bin "$path[@]")
fi

if [ -d ~/.local/bin ]; then
    path=(~/.local/bin "$path[@]")
fi

if [ -d ~/.local/share/man ]; then
	manpath=(~/.local/share/man "$manpath[@]" "")
fi

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
