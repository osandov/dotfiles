#!/usr/bin/env python3

import argparse
import os
from pathlib import Path
import re
import subprocess
import sys


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Temporarily set Keychron HIDRAW device permissions so that Launcher works"
    )
    parser.add_argument(
        "-u",
        "--user",
        help="user to grant permissions to (default: get from SUDO_USER or current user)",
    )
    args = parser.parse_args()

    if args.user is None:
        try:
            args.user = os.environ["SUDO_USER"]
        except KeyError:
            args.user = os.getlogin()

    devs = []
    for path in Path("/sys/class/hidraw").iterdir():
        try:
            uevent = (path / "device/uevent").read_text()
        except FileNotFoundError:
            continue

        if not re.search(r"^HID_ID=0003:00003434:", uevent, flags=re.MULTILINE):
            continue

        devs.append(Path("/dev") / path.name)

    if not devs:
        sys.exit("No Keychron HIDRAW devices found")

    saved_acls = subprocess.check_output(["getfacl", "-p", *devs])

    subprocess.check_call(["setfacl", "-m", f"u:{args.user}:rw", *devs])

    try:
        input("Permissions updated. Press enter to revert...")
    finally:
        subprocess.run(["setfacl", "--restore=-"], input=saved_acls)


if __name__ == "__main__":
    main()
