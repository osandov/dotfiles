typeset -U path

if [ -d ~/.dotfiles/bin ]; then
    path=(~/.dotfiles/bin "$path[@]")
fi

if [ -d ~/.local/bin ]; then
    path=(~/.local/bin "$path[@]")
fi

export PATH

export EDITOR=vim
export VISUAL=vim
export PYTHONSTARTUP=~/.pythonrc
export PAGER=less
export LESS=R
export CFLAGS="-Wall -pipe"

if [ -r ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi
