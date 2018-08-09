#!/bin/sh

# Automated installation script for Arch Linux. It is assumed that you have
# completed the install process, including installing X and your video drivers
# and setting up your network connection

set -e

cd "$(dirname "$0")"

if [ "$(pwd)" != ~/.dotfiles ]; then
    echo "This repo should be installed in ~/.dotfiles" >&2
    exit 1
fi

sudo pacman -Sy

# Install aurman manually from the AUR first.
sudo pacman --noconfirm -S --needed base-devel

if ! pacman -Q aurman > /dev/null 2>&1; then
	cd /tmp
	curl -O https://aur.archlinux.org/cgit/aur.git/snapshot/aurman.tar.gz
	tar -xvf aurman.tar.gz
	cd aurman
	makepkg -si --noconfirm --skippgpcheck
	rm -rf /tmp/aurman /tmp/aurman.tar.gz
fi

# Install the packages.
PACKAGES=(
	adobe-source-han-sans-jp-fonts
	alsa-utils
	clang
	compton
	dmenu
	evince
	feh
	firefox
	git
	google-chrome
	gtk3-print-backends
	gvfs
	gvim
	librsvg # For redshift-gtk
	mercurial
	moka-icon-theme-git
	mutt
	numlockx
	openssh
	pavucontrol
	pkgfile
	pulseaudio
	pulseaudio-alsa
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
	xf86-input-libinput
	xfce4-notifyd
	xfce4-power-manager
	xfce4-screenshooter
	xorg-server
	xorg-xdm
	xorg-xinit
	xorg-xinput
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

aurman --noconfirm -S --needed "${PACKAGES[@]}"

# Post-install stuff.
sudo systemctl enable xdm-archlinux.service
sudo pkgfile --update

~/.dotfiles/packages/update_packages.sh

chsh -s "$(which zsh)"

if [ $# -gt 0 ]; then
    ~/.dotfiles/install.sh "$@"
else
    ~/.dotfiles/install.sh -a
fi
