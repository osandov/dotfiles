#!/bin/sh

cd "$(dirname "$0")"

if [ "$(pwd)" != ~/.dotfiles ]; then
	echo "This repo should be installed in ~/.dotfiles" >&2
	exit 1
fi

usage () {
	USAGE_STRING="Usage: $0 [-avstpgmd] [-y | -n]
$0 -h

Optional installation:
  -a    install all config
  -v    install Vim config
  -s    install shell (zsh and dircolors) config
  -t    install tmux config
  -p    install Python config
  -g    install Git and Mercurial config
  -m    install Mutt config
  -d    install desktop config

Prompts:
  -y    assume yes when prompted about overwriting a file
  -n    assume no when prompted about overwriting a file

Miscellaneous:
  -h    display this help message and exit"

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

while getopts "avstpgmdynh" OPT; do
	case "$OPT" in
		a)
			DO_ALL=1
			;;
		v)
			DO_VIM=1
			;;
		s)
			DO_SHELL=1
			;;
		t)
			DO_TMUX=1
			;;
		p)
			DO_PYTHON=1
			;;
		g)
			DO_GIT=1
			;;
		m)
			DO_MUTT=1
			;;
		d)
			DO_DESKTOP=1
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
			ln -Tfns "$1" "$2"
			;;
		n)
			if [ -e "$2" ]; then
				echo "$2 already exists; not installing" >&2
			else
				ln -Tfns "$1" "$2"
			fi
			;;
		*)
			if [ ! -L "$2" -o "$(readlink "$2")" != "$1" ]; then
				ln -Tins "$1" "$2"
			fi
			;;
	esac
}

do_install () {
	! [ -z "$DO_ALL" -a -z "$1" ]
}

if do_install "$DO_VIM"; then
	mkdir -p ~/.vim
	install_file ~/.dotfiles/vim/plugin ~/.vim/plugin
	install_file ~/.dotfiles/vim/after ~/.vim/after
	install_file ~/.dotfiles/vim/colors ~/.vim/colors
	install_file ~/.dotfiles/vimrc ~/.vimrc
	install_file ~/.dotfiles/gvimrc ~/.gvimrc

	mkdir -p ~/.vim/bundle
	if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
		git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	fi
	vim +VundleUpdate +qall
fi

if do_install "$DO_SHELL"; then
	install_file ~/.dotfiles/zsh ~/.zsh
	install_file ~/.dotfiles/zshenv ~/.zshenv
	install_file ~/.dotfiles/zshrc ~/.zshrc
	install_file ~/.dotfiles/dircolors ~/.dircolors
fi

if do_install "$DO_TMUX"; then
	install_file ~/.dotfiles/term/tmux.conf ~/.tmux.conf
fi

if do_install "$DO_GIT"; then
	install_file ~/.dotfiles/gitconfig ~/.gitconfig
	install_file ~/.dotfiles/hgrc ~/.hgrc
fi

if do_install "$DO_MUTT"; then
	mkdir -p ~/.mutt
	install_file ~/.dotfiles/muttrc ~/.mutt/muttrc
fi

if do_install "$DO_PYTHON"; then
	install_file ~/.dotfiles/pythonrc ~/.pythonrc
fi

if do_install "$DO_DESKTOP"; then
	install_file ~/.dotfiles/desktop/compton.conf ~/.config/compton.conf
	install_file ~/.dotfiles/desktop/gtkrc-2.0 ~/.gtkrc-2.0
	mkdir -p ~/.config/gtk-3.0
	install_file ~/.dotfiles/desktop/gtkrc-3.0 ~/.config/gtk-3.0/settings.ini
	install_file ~/.dotfiles/desktop/xinitrc ~/.xinitrc
	install_file ~/.dotfiles/desktop/Xmodmap ~/.Xmodmap
	install_file ~/.dotfiles/desktop/Xresources ~/.Xresources
	install_file ~/.dotfiles/desktop/xsession ~/.xsession
fi
