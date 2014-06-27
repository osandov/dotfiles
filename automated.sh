#!/bin/sh

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

~/.dotfiles/install.sh "$@"

git clone https://github.com/osandov/dzen.git /tmp/dzen
cd /tmp/dzen
patch -p1 < ~/.dotfiles/dzen.patch
make
sudo make install

~/.dotfiles/update.sh
