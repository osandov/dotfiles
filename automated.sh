#!/bin/sh

~/.dotfiles/install.sh

if [ ! -z "$DISTRO" -a -x "~/.dotfiles/automated/automated.$DISTRO.sh" ]; then
    ~/.dotfiles/automated/automated.$DISTRO.sh 
fi

git clone https://github.com/robm/dzen.git /tmp/dzen
cd /tmp/dzen
git apply "~/.dotfiles/xmonad/dzen_relative_geometry.patch"
make
sudo make install
cd ..

~/.dotfiles/update.sh
