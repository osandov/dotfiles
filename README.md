Omar Sandoval's dotfiles
========================
This repo contains my workstation configuration, primarily consisting of zsh,
xmonad, and Vim config. You can get something up and running right away with
the following:

    git clone https://github.com/osandov/dotfiles.git ~/.dotfiles
    DISTRO=arch ~/.dotfiles/automated.sh

This will clone this repo into the proper directory and begin an automated
install process, including installing all dependencies in a distro-aware way
(currently only Ubuntu ["ubuntu"] and Arch Linux ["arch"] are supported).

`install.sh` will set up all of the necessary symlinks of configuration files.
It is run automatically upon initial install by `automated.sh`, but if files
are added or moved around, it may be necessary to run it again.

Color Schemes
-------------
The following files hard-code stuff relevant to the color scheme:

* `g?vimrc`
* `Xresources`
* `gtkrc-2.0`
* `xmonad/dzen_flags`
* `xmonad/startxmonad`
* `xmonad/status/status.lua`
