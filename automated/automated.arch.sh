#!/bin/sh

# It is assumed that you have completed the install process, including
# installing X and your video drivers, as well as NetworkManager

sudo pacman  -Sy
sudo pacman --noconfirm -S --needed archlinux-themes-slim alsa-utils \
    base-devel dmenu evince firefox git gnome-keyring gvim hsetroot \
    network-manager-applet numlockx openssh pkgfile ristretto slim thunar \
    tmux trayer ttf-dejavu volumeicon xcursor-vanilla-dmz xfce4-notifyd \
    xfce4-power-manager xfce4-screenshooter xmonad xmonad-contrib \
    xorg-xmessage xscreensaver xterm zsh

sudo sed -ri 's/(current_theme\s+)default/\1archlinux-simplyblack/' /etc/slim.conf
sudo systemctl enable slim

cd /tmp
curl -O https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
tar xvf package-query.tar.gz
cd package-query
makepkg -s
sudo pacman --noconfirm -U package-query-*.pkg.tar.xz

cd /tmp
curl -O https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz
tar xvf yaourt.tar.gz
cd yaourt
makepkg -s
sudo pacman --noconfirm -U yaourt-*.pkg.tar.xz

yaourt --noconfirm -S compton-git conky-lua elementary-xfce-icons \
    xfce-theme-greybird

sudo pkgfile --update
