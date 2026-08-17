#!/usr/bin/env python3

import re


def split_antenna_prefix(name):
    match = re.match(r'^(?:Ant(\d+)-)?(.+)$', name)
    if not match:
        return ("0", name)
    antenna = match.group(1) if match.group(1) is not None else "0"
    return (antenna, match.group(2))


def file_prefix_for_antennas(antennas, antenna):
    if len(antennas) <= 1 and antenna == "0":
        return ""
    return "Ant{}-".format(antenna)


def read_tracked_antennas(path="Tracked.Rx"):
    try:
        with open(path, "r") as antenna_file:
            antennas = [line.strip() for line in antenna_file if line.strip()]
    except OSError:
        antennas = []
    if not antennas:
        antennas = ["0"]
    return antennas
