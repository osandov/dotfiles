if [ -f /etc/arch-release ]; then
    export DISTRO=arch
elif [ -f /etc/fedora-release ]; then
    export DISTRO=fedora
elif egrep 'NAME="Ubuntu"' /etc/os-release &> /dev/null; then
    export DISTRO=ubuntu
fi

# Add a directory to the PATH or move it to the front if it's already there
add_to_path () {
    export PATH="$(echo "$PATH" | sed -e "s!^$1:!!g" -e "s!:$1:!:!g" -e "s!^!$1:!")"
}

if [ -d ~/.dotfiles/bin ]; then
    add_to_path ~/.dotfiles/bin
fi

if [ -d ~/bin ]; then
    add_to_path ~/bin
fi

if [ -d ~/.cabal/bin ]; then
    add_to_path ~/.cabal/bin
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
