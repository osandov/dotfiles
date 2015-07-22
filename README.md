Omar Sandoval's dotfiles
========================
This repo contains my workstation configuration, including configuration for
zsh, vim, tmux, dwm, st, and more. You can get something up and running right
away with the following:

    git clone https://github.com/osandov/dotfiles.git ~/.dotfiles
    DISTRO=arch ~/.dotfiles/automated.sh

This will clone this repo into the proper directory and begin an automated
install process, including installing all dependencies in a distro-aware way
(currenty only Arch Linux ["arch"] is fully supported, with untested, almost
certainly broken, support for Ubuntu ["ubuntu"]).

`install.sh` will set up all of the necessary symlinks of configuration files.
It is run automatically upon initial install by `automated.sh`, but if files
are added or moved around, it may be necessary to run it again.
