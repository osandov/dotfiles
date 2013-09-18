#!/bin/sh

sudo add-apt-repository ppa:richardgv/compton
sudo apt-get update
sudo apt-get -y install compton conky curl git hsetroot \
    libghc-xmonad-contrib-dev libxft-dev libxinerama-dev libxrandr-dev \
    numlockx shimmer-themes suckless-tools thunar tmux trayer vim-gtk \
    volumeicon-alsa xclip xfce4-notifyd xfce4-power-manager \
    xfce4-screenshooter xmonad zsh
