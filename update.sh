#!/bin/sh

echo "Updating top-level"
cd ~/.dotfiles
git pull

echo "Updating pathogen"
curl -Sso ~/.vim/autoload/pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim

echo "Updating Vim Solarized"
cd ~/.vim/bundle/vim-colors-solarized
git pull

echo "Updating NERD Commenter"
cd ~/.vim/bundle/nerdcommenter
git pull
