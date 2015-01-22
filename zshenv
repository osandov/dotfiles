if [ -f /etc/arch-release ]; then
    export DISTRO=arch
elif [ -f /etc/fedora-release ]; then
    export DISTRO=fedora
elif egrep 'NAME="Ubuntu"' /etc/os-release &> /dev/null; then
    export DISTRO=ubuntu
fi

typeset -U path

if [ -d ~/.dotfiles/bin ]; then
    path=(~/.dotfiles/bin "$path[@]")
fi

if [ -d ~/bin ]; then
    path=(~/bin "$path[@]")
fi

export EDITOR=vim
export VISUAL=vim
export PYTHONSTARTUP=~/.pythonrc
export PAGER=less
export LESS=R
export CFLAGS="-Wall -pipe"
if [ -z "$TERM_PROGRAM" ]; then
    export TERM_PROGRAM="$TERM"
fi

if [ -r ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi
