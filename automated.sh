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

if [ $# -gt 0 ]; then
    ~/.dotfiles/install.sh "$@"
else
    ~/.dotfiles/install.sh -a
fi

git clone https://github.com/osandov/dzen.git /tmp/dzen
cd /tmp/dzen
make
sudo make install

git clone https://github.com/osandov/trayer-srg.git /tmp/trayer-srg
cd /tmp/trayer-srg
./configure --prefix=/usr/local
make
sudo make install
