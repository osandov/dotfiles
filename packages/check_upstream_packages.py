#!/usr/bin/env python3

import os.path
import re
import subprocess
import sys


simple_pkgver_re = re.compile('pkgver=r[0-9]+\\.([a-f0-9]+)\n')
suckless_pkgver_re = re.compile('pkgver=[0-9]+\\.[0-9]+\\.r[0-9]+\\.g([a-f0-9]+)\n')


def green(s):
    if sys.stdout.isatty():
        return '\033[32m{}\033[0m'.format(s)
    else:
        return s


def red(s):
    if sys.stdout.isatty():
        return '\033[31m{}\033[0m'.format(s)
    else:
        return s


def get_git_head(remote):
    output = subprocess.check_output(['git', 'ls-remote', remote, 'HEAD'])
    return output.split()[0].decode('ascii')


def get_git_pkgver(path, pkgver_re):
    with open(path, 'r') as f:
        for line in f:
            match = pkgver_re.fullmatch(line)
            if match:
                return match.group(1)
    raise Exception("no pkgver match")


def check_git_package(package, remote, pkgver_re):
    head = get_git_head(remote)
    pkgver = get_git_pkgver(os.path.join(package, 'PKGBUILD'), pkgver_re)
    if head.startswith(pkgver):
        print(green('{} is up to date'.format(package)))
    else:
        print(red('{} is out of date'.format(package)))
    sys.stdout.flush()


if __name__ == '__main__':
    check_git_package('dwm-osandov', 'http://git.suckless.org/dwm',
                      suckless_pkgver_re)
    check_git_package('st-osandov', 'http://git.suckless.org/st',
                      suckless_pkgver_re)
    check_git_package('supavolumed-git', 'https://github.com/osandov/supavolumed.git',
                      simple_pkgver_re)
    check_git_package('verbar-git', 'https://github.com/osandov/verbar.git',
                      simple_pkgver_re)
