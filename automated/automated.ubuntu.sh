#!/bin/sh

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install conky curl git hsetroot libghc-xmonad-contrib-dev \
    libxft-dev libxinerama-dev libxrandr-dev numlockx shimmer-themes \
    suckless-tools thunar tmux trayer vim-gtk volumeicon-alsa xclip xcompmgr \
    xfce4-notifyd xfce4-power-manager xfce4-screenshooter xmonad zsh
