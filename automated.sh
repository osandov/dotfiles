#!/bin/sh

set -e

cd "$(dirname "$0")"

if [ "$(pwd)" != ~/.dotfiles ]; then
    echo "This repo should be installed in ~/.dotfiles" >&2
    exit 1
fi

if [ ! -z "$DISTRO" -a -x "$HOME/.dotfiles/automated/automated.$DISTRO.sh" ]; then
    "$HOME/.dotfiles/automated/automated.$DISTRO.sh"
else
    echo "unrecognized distro; exiting" >&2
    exit 1
fi

chsh -s "$(which zsh)"

if [ $# -gt 0 ]; then
    ~/.dotfiles/install.sh "$@"
else
    ~/.dotfiles/install.sh -a
fi

mkdir -p ~/.vim/bundle
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim

git clone https://github.com/osandov/dwm.git ~/.dotfiles/dwm
cd ~/.dotfiles/dwm
make
make install

git clone https://github.com/osandov/st.git ~/.dotfiles/st
cd ~/.dotfiles/st
make
make install
