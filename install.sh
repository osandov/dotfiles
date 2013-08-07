#!/bin/sh

DIR="$(cd $(dirname "$0") && pwd)"

if [ "$DIR" != "$HOME/.dotfiles" ]
then
    echo 'This repo should be installed in ~/.dotfiles'
    exit 1
fi

mkdir -p ~/.vim/tmp
mkdir -p ~/.vim/backup
mkdir -p ~/.config/Terminal

ln -ins ~/.dotfiles/xmonad ~/.xmonad
ln -is ~/.dotfiles/xmonad/startxmonad ~/.xinitrc

ln -ins ~/.dotfiles/vim/plugin ~/.vim/plugin
ln -ins ~/.dotfiles/vim/after ~/.vim/after
ln -is  ~/.dotfiles/vimrc ~/.vimrc
ln -is  ~/.dotfiles/gvimrc ~/.gvimrc
ln -is  ~/.dotfiles/vimperatorrc ~/.vimperatorrc

cp -i   ~/.dotfiles/terminalrc ~/.config/Terminal/terminalrc
ln -is  ~/.dotfiles/zshenv ~/.zshenv
ln -is  ~/.dotfiles/zshrc ~/.zshrc
ln -is  ~/.dotfiles/tmux.conf ~/.tmux.conf

ln -is  ~/.dotfiles/pythonrc ~/.pythonrc
ln -is  ~/.dotfiles/dircolors ~/.dircolors

ln -is  ~/.dotfiles/gtkrc-2.0 ~/.gtkrc-2.0
ln -is  ~/.dotfiles/gtkrc-3.0 ~/.config/gtk-3.0/settings.ini

# Ubuntu
# sudo ln -is ~/.dotfiles/xmonad/startxmonad /usr/bin/startxmonad
# sudo cp -i ~/.dotfiles/xmonad/xmonad.desktop /usr/share/xsessions/
