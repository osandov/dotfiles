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


def _grep(f, regex):
    for line in f:
        match = regex.fullmatch(line)
        if match:
            return match.group(1)
    raise Exception("no match")


def grep_file(path, regex):
    with open(path, 'r') as f:
        return _grep(f, regex)


def grep_proc(cmd, regex):
    with subprocess.Popen(cmd, stdout=subprocess.PIPE) as proc:
        return _grep(proc.stdout, regex)


def _print_result(package, up_to_date):
    if up_to_date:
        print(green('{} is up to date'.format(package)))
    else:
        print(red('{} is out of date'.format(package)))
    sys.stdout.flush()


def check_git_package(package, remote, pkgver_re):
    head = get_git_head(remote)
    pkgver = grep_file(os.path.join(package, 'PKGBUILD'), pkgver_re)
    _print_result(package, head.startswith(pkgver))


def check_arch_package(package, source_package):
    pkgver_re = re.compile('_pkgver=([^\n]+)\n')
    pkgrel_re = re.compile('_pkgrel=([^\n]+)\n')
    version_re = re.compile(b'Version\\s*:\\s*([^\n]+)\n')
    pkgver = grep_file(os.path.join(package, 'PKGBUILD'), pkgver_re)
    pkgrel = grep_file(os.path.join(package, 'PKGBUILD'), pkgrel_re)
    pkgbuild_version = '{}-{}'.format(pkgver, pkgrel)
    sync_version = grep_proc(['pacman', '-Si', source_package], version_re).decode('ascii')
    _print_result(package, pkgbuild_version == sync_version)


def check_xfce4_notifyd():
    package = 'xfce4-notifyd-osandov'
    pkgver_re = re.compile('_pkgver=([^\n]+)\n')
    pkgrel_re = re.compile('_pkgrel=([^\n]+)\n')
    version_re = re.compile(b'Version\\s*:\\s*([^\n]+)\n')
    pkgver = grep_file(os.path.join(package, 'PKGBUILD'), pkgver_re)
    pkgrel = grep_file(os.path.join(package, 'PKGBUILD'), pkgrel_re)
    pkgbuild_version = '{}-{}'.format(pkgver, pkgrel)
    sync_version = grep_proc(['pacman', '-Si', 'xfce4-notifyd'], version_re).decode('ascii')
    _print_result(package, pkgbuild_version == sync_version)


if __name__ == '__main__':
    check_git_package('dwm-osandov', 'http://git.suckless.org/dwm',
                      suckless_pkgver_re)
    check_git_package('inputconfd-git', 'https://github.com/osandov/inputconfd.git',
                      simple_pkgver_re)
    check_git_package('st-osandov', 'http://git.suckless.org/st',
                      suckless_pkgver_re)
    check_git_package('supavolumed-git', 'https://github.com/osandov/supavolumed.git',
                      simple_pkgver_re)
    check_git_package('verbar-git', 'https://github.com/osandov/verbar.git',
                      simple_pkgver_re)
    check_arch_package('xfce4-notifyd-osandov', 'xfce4-notifyd')
    check_arch_package('xfce4-power-manager-osandov', 'xfce4-power-manager')
