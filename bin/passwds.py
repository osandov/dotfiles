#!/usr/bin/env python3

import argparse
import codecs
import getpass
import json
import os
import os.path
from subprocess import Popen, check_output, PIPE
import sys
import tempfile
import urllib.parse


def main():
    parser = argparse.ArgumentParser(description='Manage passwords')
    parser.add_argument(
        '--db', default=os.path.expanduser('~/.passwds.gpg'),
        help='password database to use (defaults to ~/.passwds.gpg)')
    subparsers = parser.add_subparsers(
        title='subcommands', description='password operations', dest='op')
    subparsers.required = True

    create_parser = subparsers.add_parser('create', help='create a password database')
    create_parser.set_defaults(func=cmd_create)

    reencrypt_parser = subparsers.add_parser('reencrypt', help='change the master passphrase')
    reencrypt_parser.set_defaults(func=cmd_reencrypt)

    list_parser = subparsers.add_parser('list', help='list known accounts')
    list_parser.set_defaults(func=cmd_list)

    get_parser = subparsers.add_parser('get', help='write the password for an account to stdout')
    get_parser.add_argument('account', help='account to read password for')
    get_parser.set_defaults(func=cmd_get)

    set_parser = subparsers.add_parser('set', help='read a password from stdin and save it')
    set_parser.add_argument('account', help='account to save password for')
    set_parser.set_defaults(func=cmd_set)

    rename_parser = subparsers.add_parser('rename', help='rename an account')
    rename_parser.add_argument('old', help='old account name')
    rename_parser.add_argument('new', help='new account name')
    rename_parser.set_defaults(func=cmd_rename)

    delete_parser = subparsers.add_parser('delete', help='delete a password')
    delete_parser.add_argument('account', help='account to delete')
    delete_parser.set_defaults(func=cmd_delete)

    lock_parser = subparsers.add_parser('lock', help='lock the password database')
    lock_parser.set_defaults(func=cmd_lock)

    unlock_parser = subparsers.add_parser('unlock', help='unlock the password database')
    unlock_parser.set_defaults(func=cmd_unlock)

    args = parser.parse_args()
    try:
        args.func(args)
    except PasswdsException as e:
        exit(e)


class PasswdsException(Exception):
    pass


class PasswdDbNotFoundException(PasswdsException):
    def __init__(self, path):
        super().__init__("Password database '%s' does not exist" % path)


class AccountNotFoundException(PasswdsException):
    def __init__(self, account):
        super().__init__("Account '%s' does not exist" % account)


def cmd_create(args):
    if os.path.exists(args.db):
        # This is racy but good enough.
        raise PasswdsException("Password database '%s' already exists" % args.db)
    invalidate_master_passphrase(args.db)
    passphrase = get_master_passphrase(args.db, repeat=1)
    save_passwd_db(args.db, {}, passphrase)


def cmd_reencrypt(args):
    db = load_passwd_db(args.db)
    invalidate_master_passphrase(args.db)
    passphrase = get_master_passphrase(args.db, prompt='New passphrase:',
                                       description='Enter new master passphrase\n',
                                       repeat=1)
    save_passwd_db(args.db, db, passphrase)


def cmd_list(args):
    db = load_passwd_db(args.db)
    for account in db:
        print(account)


def cmd_get(args):
    db = load_passwd_db(args.db)
    try:
        print(db[args.account])
    except KeyError:
        raise AccountNotFoundException(args.account)


def cmd_set(args):
    db, passphrase = load_passwd_db_and_passphrase(args.db)
    if os.isatty(sys.stdin.fileno()):
        password = getpass.getpass("Password for '%s': " % args.account)
    else:
        password = input()
    db[args.account] = password
    save_passwd_db(args.db, db, passphrase)


def cmd_rename(args):
    db, passphrase = load_passwd_db_and_passphrase(args.db)
    try:
        db[args.new] = db.pop(args.old)
    except KeyError:
        raise AccountNotFoundException(args.old)
    save_passwd_db(args.db, db, passphrase)


def cmd_delete(args):
    db, passphrase = load_passwd_db_and_passphrase(args.db)
    try:
        del db[args.account]
    except KeyError:
        raise AccountNotFoundException(args.account)
    save_passwd_db(args.db, db, passphrase)


def cmd_lock(args):
    if not os.path.exists(args.db):
        raise PasswdDbNotFoundException(args.db)
    invalidate_master_passphrase(args.db)


def cmd_unlock(args):
    load_passwd_db(args.db)


def gpg_connect_agent(command):
    proc = Popen(['gpg-connect-agent'], stdin=PIPE, stdout=PIPE)
    proc.stdin.write(command.encode('utf-8'))
    proc.stdin.close()
    for line in proc.stdout:
        line = line[:-1]
        if line == b'OK':
            return None
        elif line.startswith(b'OK '):
            return line[3:]
        elif line.startswith(b'ERR '):
            tokens = line.split(maxsplit=2)
            raise PasswdsException(tokens[-1].decode('utf-8'))
        elif line.startswith(b'S PROGRESS '):
            pass
        else:
            raise PasswdsException("Unrecognized output from gpg-connect-agent")


def get_master_passphrase(path, *, error_message=None, prompt='Passphrase:',
                          description='Enter master passphrase\n', repeat=0):
    if error_message is None:
        error_message = 'X'
    else:
        error_message = urllib.parse.quote(error_message)

    if prompt is None:
        prompt = 'X'
    else:
        prompt = urllib.parse.quote(prompt)

    if description is None:
        description = 'X'
    else:
        description = urllib.parse.quote(description)

    ipc = 'GET_PASSPHRASE --repeat=%d passwds.py:%s %s %s %s' % \
          (repeat, path, error_message, prompt, description)
    passphrase = gpg_connect_agent(ipc)
    if len(passphrase) == 0:
        raise PasswdsException("Invalid passphrase")
    else:
        return codecs.decode(passphrase, 'hex')


def invalidate_master_passphrase(path):
    ipc = 'CLEAR_PASSPHRASE passwds.py:%s' % path
    gpg_connect_agent(ipc)


def _load_passwd_db(file, passphrase):
    rd, wr = os.pipe()
    with os.fdopen(rd, 'rb') as pipe_rd, os.fdopen(wr, 'wb') as pipe_wr:
        cmd = ['gpg2', '--quiet', '--batch', '--passphrase-fd=%d' % rd, '--decrypt']
        gpg = Popen(cmd, stdin=file, stdout=PIPE, pass_fds=[rd])
        pipe_rd.close()
        pipe_wr.write(passphrase)
        pipe_wr.close()
        output = gpg.stdout.read()
        returncode = gpg.wait()
        if returncode != 0:
            raise PasswdsException("Failed to decrypt password database")
    return json.loads(output.decode('utf-8'))


def load_passwd_db(path):
    return load_passwd_db_and_passphrase(path)[0]


def load_passwd_db_and_passphrase(path):
    try:
        with open(path, 'rb') as file:
            passphrase = get_master_passphrase(path)
            return _load_passwd_db(file, passphrase), passphrase
    except PasswdsException as e:
        invalidate_master_passphrase(path)
        raise e
    except FileNotFoundError:
        raise PasswdDbNotFoundException(path)


def save_passwd_db(path, db, passphrase):
    rd, wr = os.pipe()
    parent_dir = os.path.dirname(path)
    parent_fd = os.open(parent_dir, os.O_RDONLY | os.O_DIRECTORY | os.O_CLOEXEC)
    try:
        file = tempfile.NamedTemporaryFile('wb', prefix='tmp_passwds',
                                           dir=parent_dir, delete=False)
        with os.fdopen(rd, 'rb') as pipe_rd, os.fdopen(wr, 'wb') as pipe_wr:
            cmd = ['gpg2', '--quiet', '--batch', '--passphrase-fd=%d' % rd, '--symmetric']
            gpg = Popen(cmd, stdin=PIPE, stdout=file, pass_fds=[rd])
            pipe_rd.close()
            pipe_wr.write(passphrase)
            pipe_wr.close()
            json.dump(db, codecs.getwriter('utf-8')(gpg.stdin))
            gpg.stdin.close()
            returncode = gpg.wait()
            if returncode != 0:
                invalidate_master_passphrase(path)
                file.close()
                os.unlink(file.name)
                raise PasswdsException("Failed to encrypt password database")

        file.flush()
        os.fsync(file.fileno())
        file.close()
        os.rename(file.name, path)
        os.fsync(parent_fd)
    finally:
        os.close(parent_fd)

if __name__ == '__main__':
    main()
