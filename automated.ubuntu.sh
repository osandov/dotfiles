#!/bin/sh

sudo apt-get install git cabal-install vim-gtk zsh numlockx hsetroot xcompmgr libxinerama-dev libxrandr-dev libxft-dev xclip conky curl trayer dmenu
# sudo apt-get install xfce4-terminal xfce4-volumed shimmer-themes
cabal update
cabal install xmonad xmonad-contrib

cd ~
git clone https://github.com/osandov/dotfiles.git
mv dotfiles .dotfiles
.dotfiles/install

git clone https://github.com/robm/dzen.git
cd dzen
git apply ~/.dotfiles/xmonad/dzen_relative_geometry.patch
make
sudo make install
cd ..
rm -rf dzen

mkdir -p ~/.vim/autoload ~/.vim/bundle
curl -Sso ~/.vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
cd ~/.vim/bundle
git clone https://github.com/altercation/vim-colors-solarized.git
git clone https://github.com/scrooloose/nerdcommenter.git
