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

git clone https://github.com/osandov/rxvt-unicode.git /tmp/rxvt-unicode
cd /tmp/rxvt-unicode
./configure \
    --prefix=/usr/local \
    --with-terminfo=/usr/share/terminfo \
    --enable-256-color \
    --enable-combining \
    --enable-fading \
    --enable-font-styles \
    --enable-iso14755 \
    --enable-keepscrolling \
    --enable-lastlog \
    --enable-mousewheel \
    --enable-next-scroll \
    --enable-perl \
    --enable-pointer-blank \
    --enable-rxvt-scroll \
    --enable-selectionscrolling \
    --enable-slipwheeling \
    --disable-smart-resize \
    --enable-startup-notification \
    --enable-transparency \
    --enable-unicode3 \
    --enable-utmp \
    --enable-wtmp \
    --enable-xft \
    --enable-xim \
    --enable-xterm-scroll \
    --disable-pixbuf \
    --disable-frills
cvs -z3 -d :pserver:anonymous@cvs.schmorp.de/schmorpforge co libev
cvs -z3 -d :pserver:anonymous@cvs.schmorp.de/schmorpforge co libptytty
make
sudo make install

git clone https://github.com/osandov/dzen.git /tmp/dzen
cd /tmp/dzen
make
sudo make install

git clone https://github.com/osandov/trayer-srg.git /tmp/trayer-srg
cd /tmp/trayer-srg
./configure --prefix=/usr/local
make
sudo make install
