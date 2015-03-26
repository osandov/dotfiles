#!/usr/bin/env python3

import contextlib
import datetime
import errno
import os
import os.path
import re
import signal
import socket
import subprocess
import sys
import threading
import time


class SignalException(Exception):
    def __init__(self, signum):
        self.signum = signum

    def __str__(self):
        return str(self.signum)


def _raise_signal(signum, stackframe):
    raise SignalException(signum)


class StatusBar:
    def __init__(self, ac=None, battery=None, wifi_nic=None, dropbox_cli=None):
        """
        Initialize the system status monitor.

        Keyword arguments:
        ac -- AC device in /sys/class/power_supply
        battery -- battery device in /sys/class/power_supply
        wifi_nic -- Wi-Fi interface (e.g., wlp3s0)
        dropbox_cli -- Dropbox CLI command (e.g., dropbox.py)
        """

        self._ac = os.path.join('/sys/class/power_supply', ac)
        self._battery = os.path.join('/sys/class/power_supply', battery)
        self._wifi_nic = wifi_nic
        self._dropbox_cli = dropbox_cli

        self._cv = threading.Condition()
        self._event_pending = False

        self.stats = {}
        self.wordy = False

        display = os.getenv('DISPLAY')
        if not display:
            raise ValueError('$DISPLAY is not set')
        self._ctl_sock_path = os.path.expanduser('~/.statusbar-%s.ctl' % display)
        self._ctl_sock = socket.socket(family=socket.AF_UNIX, type=socket.SOCK_DGRAM)
        try:
            os.unlink(self._ctl_sock_path)
        except OSError as e:
            if e.errno != errno.ENOENT:
                raise e
        self._ctl_sock.bind(self._ctl_sock_path)
        thread = threading.Thread(target=self._handle_ctl)
        thread.start()

        signal.signal(signal.SIGINT, _raise_signal)
        signal.signal(signal.SIGTERM, _raise_signal)

    def _handle_ctl(self):
        while True:
            try:
                msg, ancdata, flags, addr = self._ctl_sock.recvmsg(20)
            except OSError as e:
                # EBADF occurs when the control socket is closed on exit, so we
                # should ignore that case.
                if e.errno != errno.EBADF:
                    raise e
                break
            if msg == b'togglewordy':
                with self._cv:
                    self.wordy ^= True
                    self._event_pending = True
                    self._cv.notify()

    def close(self):
        self._ctl_sock.shutdown(socket.SHUT_RDWR)
        self._ctl_sock.close()
        os.unlink(self._ctl_sock_path)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self.close()

    class _CpuUsage:
        def __init__(self):
            self._prev_active = 0
            self._prev_idle = 0

        def __call__(self):
            with open('/proc/stat', 'rb', 0) as f:
                for line in f:
                    tokens = line.split()
                    if tokens and tokens[0] == b'cpu':
                        break
                else:
                    raise ValueError("no cpu in /proc/stat")
            active = int(tokens[1]) + int(tokens[3])  # active = user + system
            idle = int(tokens[4])

            interval_active = active - self._prev_active
            interval_idle = idle - self._prev_idle
            interval_total = interval_active + interval_idle
            self._prev_active = active
            self._prev_idle = idle

            if interval_total:
                return 100 * (interval_active / interval_total)
            else:
                return 0

    def cpu_usage(self):
        """
        Return a callable object which returns the system CPU usage as a
        percent since the last time it was called. The results of the first
        call are undefined.
        """
        return self._CpuUsage()

    def mem_usage(self):
        """Return the current system memory usage as a percent."""
        total = None
        free = None
        buffers = None
        cached = None
        slab = None
        with open('/proc/meminfo', 'rb', 0) as f:
            for line in f:
                tokens = line.split()
                if tokens:
                    if tokens[0] == b'MemTotal:':
                        total = int(tokens[1])
                    elif tokens[0] == b'MemFree:':
                        free = int(tokens[1])
                    elif tokens[0] == b'Buffers:':
                        buffers = int(tokens[1])
                    elif tokens[0] == b'Cached:':
                        cached = int(tokens[1])
                    elif tokens[0] == b'Slab:':
                        slab = int(tokens[1])
        if total is None:
            raise ValueError('no MemTotal in /proc/meminfo')
        if free is None:
            raise ValueError('no MemFree in /proc/meminfo')
        if buffers is None:
            raise ValueError('no Buffers in /proc/meminfo')
        if cached is None:
            raise ValueError('no Cached in /proc/meminfo')
        if slab is None:
            raise ValueError('no Slab in /proc/meminfo')
        return 100 * ((total - free - buffers - cached - slab) / total)

    def power_supply(self):
        """
        Return the current power status, which is a tuple containing a boolean
        indicating whether the AC power supply is online (i.e., plugged in) and
        the current battery capacity as a percent.
        """
        with open(os.path.join(self._ac, 'online'), 'rb', 0) as f:
            ac_online = bool(int(f.read()))
        with open(os.path.join(self._battery, 'capacity'), 'rb', 0) as f:
            battery_capacity = int(f.read())
        return (ac_online, battery_capacity)

    _volume_muted_re = re.compile(br'\s+Mute: (yes|no)')
    _volume_line_re = re.compile(br'\s+Volume:')
    _volumes_re = re.compile(br'(\d+)%')

    def volume(self):
        """
        Return the current volume as a percent (multiple channels are averaged)
        or None if the volume is muted.
        """
        with subprocess.Popen(['pactl', 'list', 'sinks'], stdout=subprocess.PIPE) as proc:
            for line in proc.stdout:
                match = self._volume_muted_re.match(line)
                if match and match.group(1) == b'yes':
                    return None
                elif self._volume_line_re.match(line):
                    volumes = [int(x) for x in self._volumes_re.findall(line)]
                    return int(sum(volumes) / len(volumes))
        raise ValueError('no volume in pactl')

    _ssid_re = re.compile(br'\s+SSID: (.*)')
    _signal_re = re.compile(br'\s+signal: (-\d+) dBm')

    def wifi_status(self):
        """
        Return a tuple containing the current SSID we are connected to and the
        signal quality as a percentage, or None for both if there is no
        connection.
        """
        ssid = None
        signal = None
        # TODO: iw warns that it shouldn't be screenscraped. But, it's unlikely
        # that it will change and this is easier than using netlink, so just do
        # it this way for now.
        with subprocess.Popen(['iw', 'dev', self._wifi_nic, 'link'], stdout=subprocess.PIPE) as proc:
            for line in proc.stdout:
                match = self._ssid_re.match(line)
                if match:
                    ssid = match.group(1)
                    continue
                match = self._signal_re.match(line)
                if match:
                    signal = int(match.group(1))
                    continue
        if ssid is None or signal is None:
            return (None, None)
        else:
            # Convert dBm to percentage.
            if signal > -50:
                signal = -50
            elif signal < -100:
                signal = -100
            quality = 2 * (signal + 100)
            return (ssid, quality)

    def dropbox_status(self):
        """
        Return a triple containing whether Dropbox is running, whether it is up
        to date, and its current status message.
        """
        # TODO: is there a way to get this without dropbox.py?
        status = subprocess.check_output([self._dropbox_cli, 'status'])
        running = status != b"Dropbox isn't running!\n"
        uptodate = status in [b'Up to date\n', b'Idle\n']
        return running, uptodate, status

    def timer(self, interval):
        """
        Generate an event repeatedly at a time interval.

        Arguments:
        interval -- interval in seconds (can be fractional)
        """
        while True:
            yield
            time.sleep(interval)

    _volume_changed_re = re.compile(br"Event 'change' on sink")

    def volume_changed(self):
        """
        Generate an event when the volume changes.
        """
        # TODO: throttle this; sliding the volume up in alsamixer or pavucontrol
        # generates a ton of events that aren't all needed. Should that be
        # handled per-event generator or at the update level?
        with subprocess.Popen(['pactl', 'subscribe'], stdout=subprocess.PIPE) as proc:
            for line in proc.stdout:
                if self._volume_changed_re.match(line):
                    yield

    def _update_on(self, event, stats):
        for e in event:
            with self._cv:
                for stat_name, stat_func in stats:
                    self.stats[stat_name] = stat_func()
                self._event_pending = True
                self._cv.notify()

    def update_on(self, event, stats):
        """
        Update the status when the given event occurs. The statistics are also
        immediately updated once.

        Arguments:
        event -- a generator which yields when the event has occurred
        stats -- a list of the names of statistics to update
        """
        stats2 = []
        for stat_name in stats:
            if stat_name == 'cpu_usage':
                # Stateful status checkers.
                stat_func = getattr(self, stat_name)()
            else:
                stat_func = getattr(self, stat_name)
            try:
                self.stats[stat_name] = stat_func()
                stats2.append((stat_name, stat_func))
            except Exception as e:
                print(e, file=sys.stderr)
        thread = threading.Thread(target=self._update_on, args=(event, stats2), daemon=True)
        thread.start()

    @contextlib.contextmanager
    def wait_for_event(self):
        """
        Block until an event occurs and execute in the context of latest
        status.
        """
        with self._cv:
            while not self._event_pending:
                self._cv.wait()
            self._event_pending = False
            yield


def main():
    try:
        with StatusBar(
                ac='AC',
                battery='BAT0',
                wifi_nic='wlp3s0',
                dropbox_cli='dropbox-cli'
                ) as status:
            status.update_on(status.timer(1), [
                'cpu_usage',
                'mem_usage',
                'power_supply',
                'wifi_status',
                'dropbox_status'
            ])
            status.update_on(status.volume_changed(), ['volume'])
            while True:
                with status.wait_for_event():
                    show_statusbar(status)
    except SignalException as e:
        print('got signal %d; exiting' % e.signum, file=sys.stderr)


def icon_file(icon_name):
    return os.path.expanduser('~/.dotfiles/wm/icons/%s.xbm' % icon_name)


def icon(icon_name):
    return '\x1b]9;%s\a' % icon_file(icon_name)


def show_statusbar(status):
    sections = []

    now = datetime.datetime.now()

    # Dropbox
    if 'dropbox_status' in status.stats:
        db_running, db_uptodate, db_status = status.stats['dropbox_status']
        if db_running:
            if db_uptodate or int(time.monotonic()) % 2:
                i = icon('dropbox_idle')
            else:
                i = icon('dropbox_busy')
            if status.wordy:
                i += ' ' + db_status.decode('utf-8').splitlines()[0]
            sections.append(i)

    # Wi-Fi
    if 'wifi_status' in status.stats:
        ssid, quality = status.stats['wifi_status']
        if ssid is None:
            sections.append(icon('wifi0'))
        else:
            if quality >= 66:
                    i = icon('wifi3')
            elif quality >= 33:
                    i = icon('wifi2')
            else:
                    i = icon('wifi1')
            if status.wordy:
                i += ' %s %3d%%' % (ssid.decode('utf-8'), quality)
            sections.append(i)

    # CPU/memory usage
    sections.append(icon('cpu') + '%3.0f%%' % status.stats['cpu_usage'])
    sections.append(icon('mem') + '%3.0f%%' % status.stats['mem_usage'])

    # Power supply
    if 'power_supply' in status.stats:
        ac_online, battery_capacity = status.stats['power_supply']
        if ac_online:
            i = icon('ac')
        elif battery_capacity >= 55:
                i = icon('bat_full')
        elif battery_capacity > 20:
                i = icon('bat_low')
        else:
                i = icon('bat_empty')
        sections.append(i + ' %d%%' % battery_capacity)

    # Volume
    if 'volume' in status.stats:
        volume = status.stats['volume']
        if volume is None:
            sections.append(icon('spkr_mute') + ' MUTE')
        else:
            sections.append(icon('spkr_play') + ' %d%%' % volume)

    # Clock
    sections.append(icon('clock') + now.strftime(' %a, %b %d %I:%M:%S %p'))

    subprocess.check_call(['xsetroot', '-name', '  ' + ' | '.join(sections)])


if __name__ == '__main__':
    main()
