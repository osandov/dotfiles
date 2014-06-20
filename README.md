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

Besides `automated.sh`, there are two other scripts of interest included in the
top-level directory of the repo. `install.sh` will set up all of the necessary
symlinks of configuration files. It is run automatically upon initial install
by `automated.sh`, but if files are added or moved around, it may be necessary
to run it again.

`update.sh` will update the repository and installed plugins (e.g.,
pathogen.vim). Usually, this is enough to update the configuration entirely and
rerunning `install.sh` is not necessary.

Color Schemes
-------------
The color scheme uses [base16](https://github.com/chriskempson/base16).
Changing color schemes isn't automated yet, but the following files can be
manually modified to switch out the base16 palette and foreground/background
color. Automation should work at some point.

 * `Xresources`
 * `gtkrc-2.0`
 * `g?vimrc`
 * `xmonad/dzen_flags`
 * `xmonad/startxmonad`
 * `xmonad/status/status.lua`

### Dark
```
foreground = base05
background = base00
background' = base01
```

### Light
```
foreground = base02
background = base07
background' = base06
```
