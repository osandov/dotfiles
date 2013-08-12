#!/bin/sh

sudo apt-get install git cabal-install vim-gtk zsh numlockx hsetroot xcompmgr libxinerama-dev libxrandr-dev libxft-dev xclip conky curl trayer dmenu
# sudo apt-get install xfce4-volumed shimmer-themes
cabal update
cabal install xmonad xmonad-contrib
