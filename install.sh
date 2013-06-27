#!/bin/sh

DIR="`dirname \"$0\"`"
DIR="`cd "$DIR" && pwd`"

if [ -z "$DIR" ]
then
    echo "Could not determine path of install script"
    exit 1
fi

mkdir -p ~/.vim/tmp
mkdir -p ~/.vim/backup
mkdir -p ~/.config/Terminal

ln -ins "$DIR/xmonad" ~/.xmonad
ln -ins "$DIR/vim/plugin" ~/.vim/plugin
ln -ins "$DIR/vim/after" ~/.vim/after
ln -is "$DIR/vimrc" ~/.vimrc
ln -is "$DIR/gvimrc" ~/.gvimrc
ln -is "$DIR/zshenv" ~/.zshenv
ln -is "$DIR/zshrc" ~/.zshrc
ln -is "$DIR/pythonrc" ~/.pythonrc
ln -is "$DIR/dircolors" ~/.dircolors
cp -i "$DIR/terminalrc" ~/.config/Terminal/terminalrc
ln -is "$DIR/gtkrc-2.0" ~/.gtkrc-2.0
ln -is "$DIR/gtkrc-3.0" ~/.config/gtk-3.0/settings.ini
sudo ln -is "$DIR/xmonad/startxmonad" /usr/bin/startxmonad
sudo ln -is "$HOME/.cabal/bin/xmonad" /usr/bin/xmonad
sudo cp -i "$DIR/xmonad/xmonad.desktop" /usr/share/xsessions/
