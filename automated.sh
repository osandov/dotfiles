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

mkdir -p ~/.vim/autoload ~/.vim/bundle
curl -Sso ~/.vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
cd ~/.vim/bundle
git clone https://github.com/altercation/vim-colors-solarized.git
git clone https://github.com/scrooloose/nerdcommenter.git
