Omar Sandoval's dotfiles
========================
This repo contains my workstation configuration, primarily consisting of zsh,
xmonad, and Vim config. You can get something up and running right away with
the following:

    git clone https://github.com/osandov/dotfiles.git ~/.dotfiles
    ~/.dotfiles/automated.sh

This will clone this repo into the proper directory and begin an automated
install process, including installing all dependencies in a distro-aware way
(or at least that's the plan).

Besides `automated.sh`, there are two other scripts of interest included in the
top-level directory of the repo. `install.sh` will set up all of the necessary
symlinks of configuration files. It is run automatically upon initial install
by `automated.sh`, but if files are added or moved around, it may be necessary
to run it again.

`update.sh` will update the repository and installed plugins (e.g.,
pathogen.vim). Usually, this is enough to update the configuration entirely and
rerunning `install.sh` is not necessary.
