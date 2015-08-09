#!/usr/bin/env python3

from collections import namedtuple
import email
import re
import sys
import unittest


PatchSubject = namedtuple('PatchSubject', ['prefix', 'title', 'index', 'total', 'version'])


def main():
    message = email.message_from_binary_file(sys.stdin.buffer)
    try:
        subject = parse_subject(message.get('Subject'))
    except ValueError as e:
        exit(e)
    path = []
    if subject.version is not None:
        path.append('v%d' % subject.version)
    if subject.index is not None:
        path.append('%04d' % subject.index)
    else:
        path.append('0001')
    path.append(sanitize_title(subject.title))
    with open('-'.join(path) + '.patch', 'wb') as f:
        f.write(message.as_bytes())


def parse_subject(subject):
    match = re.match(r'^\[([\w\s]+?)(?: [vV](\d+))?(?: (\d+)/(\d+))?\] (.*)$', subject)
    if match:
        prefix = match.group(1)
        title = match.group(5)
        index = int_or_none(match.group(3))
        total = int_or_none(match.group(4))
        version = int_or_none(match.group(2))
        return PatchSubject(prefix, title, index, total, version)

    match = re.match(r'^\[([\w\s]+?) (\d+)/(\d+) [vV](\d+)\] (.*)$', subject)
    if match:
        prefix = match.group(1)
        title = match.group(5)
        index = int_or_none(match.group(2))
        total = int_or_none(match.group(3))
        version = int_or_none(match.group(4))
        return PatchSubject(prefix, title, index, total, version)

    raise ValueError('could not parse subject')


def int_or_none(x):
    if x is None:
        return None
    else:
        return int(x, base=10)


def sanitize_title(title):
    title = re.sub(r'^[^a-zA-Z0-9._]+', r'', title)
    title = re.sub(r'[^a-zA-Z0-9._]+', r'-', title)
    title = re.sub(r'\.+', r'.', title)
    title = re.sub(r'[.-]+$', r'', title)
    return title


class TestParseSubject(unittest.TestCase):
    def test_git_format_patch(self):
        # Basic `git-format-patch` output
        self.assertEqual(
            parse_subject('[PATCH] sched/core: fix regression in cpuset_cpu_inactive for suspend'),
            PatchSubject('PATCH', 'sched/core: fix regression in cpuset_cpu_inactive for suspend', None, None, None)
        )
        self.assertEqual(
            parse_subject('[PATCH 0/2] btrfs device remove alias'),
            PatchSubject('PATCH', 'btrfs device remove alias', 0, 2, None)
        )

    def test_reroll_count(self):
        # Version with `git-format-patch --reroll-count`
        self.assertEqual(
            parse_subject('[PATCH v4] ext4: fix indirect punch hole corruption'),
            PatchSubject('PATCH', 'ext4: fix indirect punch hole corruption', None, None, 4)
        )
        self.assertEqual(
            parse_subject('[PATCH v2 1/5] Btrfs: remove misleading handling of missing device scrub'),
            PatchSubject('PATCH', 'Btrfs: remove misleading handling of missing device scrub', 1, 5, 2)
        )

    def test_subject_prefix(self):
        # Custom subject with `git-format-patch --subject-prefix`
        self.assertEqual(
            parse_subject('[RFC PATCH 4/5] direct_IO: use iov_iter_rw() instead of rw everywhere'),
            PatchSubject('RFC PATCH', 'direct_IO: use iov_iter_rw() instead of rw everywhere', 4, 5, None)
        )
        self.assertEqual(
            parse_subject('[PATCH RESEND] btrfs: unlock i_mutex after attempting to delete subvolume during send'),
            PatchSubject('PATCH RESEND', 'btrfs: unlock i_mutex after attempting to delete subvolume during send', None, None, None)
        )

    def test_manual_version(self):
        # Version incorrectly formatted or in the wrong place because someone
        # did it manually.
        self.assertEqual(
            parse_subject('[PATCH V2 03/11] Btrfs: Direct I/O read: Work on sectorsized blocks'),
            PatchSubject('PATCH', 'Btrfs: Direct I/O read: Work on sectorsized blocks', 3, 11, 2)
        )
        self.assertEqual(
            parse_subject('[PATCH 1/9 v8] fs_pin: Initialize value for fs_pin explicitly'),
            PatchSubject('PATCH', 'fs_pin: Initialize value for fs_pin explicitly', 1, 9, 8)
        )


class TestSanitizeTitle(unittest.TestCase):
    def test_spaces(self):
        self.assertEqual(sanitize_title('a b'), 'a-b')
        self.assertEqual(sanitize_title('a  b'), 'a-b')
        self.assertEqual(sanitize_title('  a  b'), 'a-b')
        self.assertEqual(sanitize_title('a  b  '), 'a-b')
        self.assertEqual(sanitize_title('  a  b  '), 'a-b')

    def test_special_chars(self):
        self.assertEqual(sanitize_title('a&b'), 'a-b')
        self.assertEqual(sanitize_title('a&&b'), 'a-b')
        self.assertEqual(sanitize_title('&&a&&b'), 'a-b')
        self.assertEqual(sanitize_title('a&&b&&'), 'a-b')
        self.assertEqual(sanitize_title('&&a&&b&&'), 'a-b')

    def test_dots(self):
        self.assertEqual(sanitize_title('a.b'), 'a.b')
        self.assertEqual(sanitize_title('a..b'), 'a.b')
        self.assertEqual(sanitize_title('a..b..'), 'a.b')
        self.assertEqual(sanitize_title('..a..b..'), '.a.b')

    def test_complex(self):
        self.assertEqual(
            sanitize_title('Btrfs: add RAID 5/6 BTRFS_RBIO_REBUILD_MISSING operation'),
            'Btrfs-add-RAID-5-6-BTRFS_RBIO_REBUILD_MISSING-operation'
        )
        self.assertEqual(sanitize_title(' . a'), '.-a')
        self.assertEqual(sanitize_title(' .. a'), '.-a')


if __name__ == '__main__':
    main()
