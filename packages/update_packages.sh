#!/bin/sh

find "$(dirname "$0")" -mindepth 1 -maxdepth 1 -type d \
	-execdir sh -c "cd {} && makepkg -si --noconfirm --needed" \;
