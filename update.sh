#!/bin/sh

cd ~/.dotfiles

OLD_COMMIT=$(git log -1 --pretty="%H" update.sh)
echo "Updating top-level"
git pull
NEW_COMMIT=$(git log -1 --pretty="%H" update.sh)

if [ $OLD_COMMIT != $NEW_COMMIT ]; then
    echo "update.sh has changed, running the new one instead"
    ./update.sh
else
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

    cd ~/.vim/bundle
    if [ -d vim-repeat ]; then
        echo "Updating repeat.vim"
        cd vim-repeat
        git pull
    else
        echo "Installing repeat.vim"
        git clone https://github.com/tpope/vim-repeat.git
    fi
fi
