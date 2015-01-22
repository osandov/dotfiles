#!/bin/sh

cd "$(dirname "$0")"

if [ "$(pwd)" != ~/.dotfiles ]; then
    echo "This repo should be installed in ~/.dotfiles" >&2
    exit 1
fi

usage () {
    USAGE_STRING="Usage: $0 [-avzstgpdkx] [-y | -n]
       $0 -h

Optional installation:
  -a    Install all config
  -v    Install Vim config
  -z    Install zsh config
  -s    Install SSH/GnuPG config
  -t    Install tmux config
  -g    Install Git config
  -p    Install Python config
  -d    Install dircolors config
  -k    Install graphic application config (Vimperator, zathura)
  -x    Install xmonad config

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

if [ $# -eq 0 ]; then
    usage "err"
fi

while getopts ":avzstgpdkxynh" OPT; do
    case "$OPT" in
        a)
            DO_ALL=1
            ;;
        v)
            DO_VIM=1
            ;;
        z)
            DO_ZSH=1
            ;;
        s)
            DO_SSH=1
            ;;
        t)
            DO_TMUX=1
            ;;
        g)
            DO_GIT=1
            ;;
        p)
            DO_PYTHON=1
            ;;
        d)
            DO_DIRCOLORS=1
            ;;
        k)
            DO_GTK=1
            ;;
        x)
            DO_XMONAD=1
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

do_install () {
    ! [ -z "$DO_ALL" -a -z "$1" ]
}

if do_install "$DO_VIM"; then
    mkdir -p ~/.vim/tmp
    mkdir -p ~/.vim/backup

    install_file ~/.dotfiles/vim/plugin ~/.vim/plugin
    install_file ~/.dotfiles/vim/after ~/.vim/after
    install_file ~/.dotfiles/vimrc ~/.vimrc
    install_file ~/.dotfiles/gvimrc ~/.gvimrc
fi

if do_install "$DO_ZSH"; then
    install_file ~/.dotfiles/zsh ~/.zsh
    install_file ~/.dotfiles/zshenv ~/.zshenv
    install_file ~/.dotfiles/zshrc ~/.zshrc
fi

if do_install "$DO_SSH"; then
    mkdir -p ~/.gnupg
    install_file ~/.dotfiles/gnupg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
fi

if do_install "$DO_TMUX"; then
    install_file ~/.dotfiles/tmux.conf ~/.tmux.conf
fi

if do_install "$DO_GIT"; then
    install_file ~/.dotfiles/gitconfig ~/.gitconfig
fi

if do_install "$DO_PYTHON"; then
    install_file ~/.dotfiles/pythonrc ~/.pythonrc
fi

if do_install "$DO_DIRCOLORS"; then
    install_file ~/.dotfiles/dircolors ~/.dircolors
fi

if do_install "$DO_GTK"; then
    mkdir -p ~/.config/gtk-3.0
    mkdir -p ~/.config/zathura
    install_file ~/.dotfiles/gtkrc-2.0 ~/.gtkrc-2.0
    install_file ~/.dotfiles/gtkrc-3.0 ~/.config/gtk-3.0/settings.ini
    install_file ~/.dotfiles/vimperatorrc ~/.vimperatorrc
    install_file ~/.dotfiles/zathurarc ~/.config/zathura/zathurarc
fi

if do_install "$DO_XMONAD"; then
    install_file ~/.dotfiles/xmonad ~/.xmonad
    install_file ~/.dotfiles/x11/Xresources ~/.Xresources
    install_file ~/.dotfiles/x11/Xmodmap ~/.Xmodmap

    case "$DISTRO" in
        arch)
            install_file ~/.dotfiles/x11/xsession ~/.xsession
            install_file ~/.dotfiles/x11/xinitrc ~/.xinitrc
            ;;
        ubuntu)
            echo "Ubuntu xmonad configuration doesn't work right now" >&2
            exit 1
            # sudo install_file ~/.dotfiles/xmonad/startxmonad /usr/bin/startxmonad
            # sudo install_file ~/.dotfiles/xmonad/xmonad.desktop /usr/share/xsessions/
            ;;
        *)
            echo "unrecognized distro; not installing X configuration" >&2
            exit 1
            ;;
    esac
fi
