#!/bin/sh

~/.dotfiles/install.sh

if [ ! -z "$DISTRO" -a -x "$HOME/.dotfiles/automated/automated.$DISTRO.sh" ]; then
    "$HOME/.dotfiles/automated/automated.$DISTRO.sh"
fi

git clone https://github.com/osandov/dzen.git /tmp/dzen
cd /tmp/dzen
make
sudo make install

~/.dotfiles/update.sh
