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
	clang
	cscope
	firefox
	git
	gnome
	google-chrome
	gvim
	inetutils
	man-db
	man-pages
	mercurial
	mutt
	noto-fonts-emoji
	openssh
	pkgfile
	python
	the_silver_searcher
	tmux
	ttf-dejavu
	ttf-liberation
	wl-clipboard
	xdg-utils
	zsh
)

aurman --noconfirm -S --needed "${PACKAGES[@]}"

# Post-install stuff.
sudo pkgfile --update

chsh -s "$(which zsh)"

if [ $# -gt 0 ]; then
    ~/.dotfiles/install.sh "$@"
else
    ~/.dotfiles/install.sh -a
fi
