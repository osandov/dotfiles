#!/bin/sh

echo "Updating top-level"
cd ~/.dotfiles
git pull

mkdir -p ~/.vim/autoload ~/.vim/bundle

cd ~/.vim/autoload
if [ -e pathogen.vim ]; then
    echo "Updating pathogen"
else
    echo "Installing pathogen"
fi
curl -Sso pathogen.vim https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim

cd ~/.vim/bundle
if [ -d vim-colors-solarized ]; then
    echo "Updating Vim Solarized"
    cd vim-colors-solarized
    git pull
else
    echo "Installing Vim Solarized"
    git clone https://github.com/altercation/vim-colors-solarized.git
fi

cd ~/.vim/bundle
if [ -d nerdcommenter ]; then
    echo "Updating NERD Commenter"
    cd nerdcommenter
    git pull
else
    echo "Installing NERD Commenter"
    git clone https://github.com/scrooloose/nerdcommenter.git
fi

cd ~/.vim/bundle
if [ -d vim-rsi ]; then
    echo "Updating rsi.vim"
    cd vim-rsi
    git pull
else
    echo "Installing rsi.vim"
    git clone https://github.com/tpope/vim-rsi.git
fi
