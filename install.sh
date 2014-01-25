#!/bin/sh

cd "$(dirname "$0")"

if [ "$(pwd)" != ~/.dotfiles ]; then
    echo "This repo should be installed in ~/.dotfiles" >&2
    exit 1
fi

usage () {
    USAGE_STRING="Usage: $0 [-vztpdgx] [-y | -n]
Usage: $0 -h

Optional installation:
  -v    Don't install Vim config
  -z    Don't install zsh config
  -t    Don't install tmux config
  -g    Don't install Git config
  -p    Don't install Python config
  -d    Don't install dircolors config
  -k    Don't install GTK config
  -x    Don't install xmonad config
  -w    Don't install Vimperator config

Prompts:
  -y    Assume yes when prompted about overwriting a file
  -n    Assume no when prompted about overwriting a file

Miscellaneous:
  -h    Display this help message and exit"

    case "$1" in
        out)
            echo "$USAGE_STRING"
            exit 0
            ;;
        err)
            echo "$USAGE_STRING" >&2
            exit 1
            ;;
    esac
}

while getopts ":vztpdgxwynh" OPT; do
    case "$OPT" in
        v)
            NO_VIM=1
            ;;
        z)
            NO_ZSH=1
            ;;
        t)
            NO_TMUX=1
            ;;
        g)
            NO_GIT=1
            ;;
        p)
            NO_PYTHON=1
            ;;
        d)
            NO_DIRCOLORS=1
            ;;
        k)
            NO_GTK=1
            ;;
        x)
            NO_XMONAD=1
            ;;
        w)
            NO_VIMPERATOR=1
            ;;
        y)
            ASSUME_ANSWER=y
            ;;
        n)
            ASSUME_ANSWER=n
            ;;
        h)
            usage "out"
            ;;
        *)
            usage "err"
            ;;
    esac
done

install_file () {
    case "$ASSUME_ANSWER" in
        y)
            ln -fns "$1" "$2"
            ;;
        n)
            if [ -e "$2" ]; then
                echo "$2 already exists; not installing" >&2
            else
                ln -nfs "$1" "$2"
            fi
            ;;
        *)
            ln -ins "$1" "$2"
            ;;
    esac
}

if [ -z "$NO_VIM" ]; then
    mkdir -p ~/.vim/tmp
    mkdir -p ~/.vim/backup

    install_file ~/.dotfiles/vim/plugin ~/.vim/plugin
    install_file ~/.dotfiles/vim/after ~/.vim/after
    install_file ~/.dotfiles/vimrc ~/.vimrc
    install_file ~/.dotfiles/gvimrc ~/.gvimrc
fi

if [ -z "$NO_ZSH" ]; then
    install_file ~/.dotfiles/zsh ~/.zsh
    install_file ~/.dotfiles/zshenv ~/.zshenv
    install_file ~/.dotfiles/zshrc ~/.zshrc
fi

if [ -z "$NO_TMUX" ]; then
    install_file ~/.dotfiles/tmux.conf ~/.tmux.conf
fi

if [ -z "$NO_GIT" ]; then
    install_file ~/.dotfiles/gitconfig ~/.gitconfig
fi

if [ -z "$NO_PYTHON" ]; then
    install_file ~/.dotfiles/pythonrc ~/.pythonrc
fi

if [ -z "$NO_DIRCOLORS" ]; then
    install_file ~/.dotfiles/dircolors ~/.dircolors
fi

if [ -z "$NO_GTK" ]; then
    mkdir -p ~/.config/gtk-3.0
    install_file ~/.dotfiles/gtkrc-2.0 ~/.gtkrc-2.0
    install_file ~/.dotfiles/gtkrc-3.0 ~/.config/gtk-3.0/settings.ini
fi

if [ -z "$NO_XMONAD" ]; then
    case "$DISTRO" in
        arch)
            install_file ~/.dotfiles/xmonad/startxmonad ~/.xinitrc
            ;;
        ubuntu)
            sudo install_file ~/.dotfiles/xmonad/startxmonad /usr/bin/startxmonad
            sudo install_file ~/.dotfiles/xmonad/xmonad.desktop /usr/share/xsessions/
            ;;
        *)
            echo "unrecognized distro; not installing X configuration" >&2
            exit 1
            ;;
    esac

    install_file ~/.dotfiles/xmonad ~/.xmonad
    install_file ~/.dotfiles/Xresources ~/.Xresources
fi

if [ -z "$NO_VIMPERATOR" ]; then
    install_file ~/.dotfiles/vimperatorrc ~/.vimperatorrc
fi
