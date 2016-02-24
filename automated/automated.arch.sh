#!/bin/bash

# It is assumed that you have completed the install process, including
# installing X and your video drivers and setting up your network connection

set -e

sudo pacman -Sy

# Install yaourt manually from the AUR first.
sudo pacman --noconfirm -S --needed base-devel

cd /tmp
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/package-query.tar.gz
tar -xvf package-query.tar.gz
cd package-query
makepkg -s
sudo pacman --noconfirm -U package-query-*.pkg.tar.xz

cd /tmp
curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/yaourt.tar.gz
tar -xvf yaourt.tar.gz
cd yaourt
makepkg -s
sudo pacman --noconfirm -U yaourt-*.pkg.tar.xz

# Install the packages.
PACKAGES=(
	alsa-utils
	clang
	compton-git
	dmenu
	elementary-xfce-icons
	evince
	feh
	firefox
	git
	gvfs
	gvim
	librsvg # For redshift-gtk
	numlockx
	openssh
	pkgfile
	python
	python-gobject # For redshift-gtk
	python-xdg # For redshift-gtk
	redshift
	ristretto
	the_silver_searcher
	thunar
	thunar-volman
	tmux
	trayer-srg
	ttf-dejavu
	tumbler
	xautomation
	xclip
	xcursor-vanilla-dmz
	xdm-archlinux
	xfce4-notifyd
	xfce4-power-manager
	xfce4-screenshooter
	xfce-theme-greybird
	xorg-xdm
	xorg-xmessage
	xorg-xmodmap
	xorg-xrandr
	xorg-xrdb
	xorg-xset
	xorg-xsetroot
	xscreensaver
	xterm
	zsh
)

yaourt --noconfirm -S --needed "${PACKAGES[@]}"

# Post-install stuff.
sudo systemctl enable xdm-archlinux.service
sudo pkgfile --update

for package in dwm-osandov st-osandov supavolumed-git verbar-git; do
	cd ~/.dotfiles/packages/"$package"
	makepkg -sfCc
	sudo pacman -U --noconfirm "$package"-*.pkg.tar.xz
done
