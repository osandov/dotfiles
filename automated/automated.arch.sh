#!/bin/bash

# It is assumed that you have completed the install process, including
# installing X and your video drivers and setting up your network connection

set -e

sudo pacman -Sy

# Install yaourt manually from the AUR first.
sudo pacman --noconfirm -S --needed base-devel

if ! pacman -Q package-query >/dev/null 2>&1; then
	cd /tmp
	curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/package-query.tar.gz
	tar -xvf package-query.tar.gz
	cd package-query
	makepkg -s
	sudo pacman --noconfirm -U package-query-*.pkg.tar.xz
	rm -rf /tmp/package-query /tmp/package-query.tar.gz
fi

if ! pacman -Q yaourt >/dev/null 2>&1; then
	cd /tmp
	curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/yaourt.tar.gz
	tar -xvf yaourt.tar.gz
	cd yaourt
	makepkg -s
	sudo pacman --noconfirm -U yaourt-*.pkg.tar.xz
	rm -rf /tmp/yaourt /tmp/yaourt.tar.gz
fi

# Install the packages.
PACKAGES=(
	alsa-utils
	clang
	compton-git
	dmenu
	evince
	feh
	firefox
	git
	gvfs
	gvim
	librsvg # For redshift-gtk
	moka-icon-theme-git
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
	trayer-srg-git
	ttf-dejavu
	tumbler
	vertex-icons-git
	vertex-themes-git
	xautomation
	xclip
	xcursor-vanilla-dmz
	xdm-archlinux
	xfce4-screenshooter
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

~/.dotfiles/packages/update_packages.sh
