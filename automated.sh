#!/bin/sh

cd "$(dirname "$0")"

if [ "$(pwd)" != "$HOME/.dotfiles" ]
then
    echo 'This repo should be installed in ~/.dotfiles' >&2
    exit 1
fi

if [ ! -z "$DISTRO" -a -x "$HOME/.dotfiles/automated/automated.$DISTRO.sh" ]; then
    "$HOME/.dotfiles/automated/automated.$DISTRO.sh"
fi

~/.dotfiles/install.sh

git clone https://github.com/osandov/dzen.git /tmp/dzen
cd /tmp/dzen
make
sudo make install

~/.dotfiles/update.sh
