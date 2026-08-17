#!/usr/bin/env python3

import sys
from datetime import datetime

import GPS_TIME


def parse_unix(fields):
    if len(fields) < 2:
        return None
    week_raw = fields[0].strip() if fields[0] is not None else ""
    try:
        sow = float(fields[1])
    except (TypeError, ValueError):
        return None
    if sow > 1e9:
        return sow
    if week_raw != "":
        try:
            week = int(float(week_raw))
            if week >= 0:
                return GPS_TIME.Week_Seconds_To_Unix(week, sow)
        except (TypeError, ValueError):
            pass
    return None


def format_gps(unix_sec):
    week = GPS_TIME.DateTime_To_Week(unix_sec)
    sow = GPS_TIME.DateTime_To_Seconds_Of_Week(unix_sec)
    return "Week {}, {:.3f} s".format(week, sow)


def format_local(unix_sec):
    return datetime.fromtimestamp(unix_sec).strftime("%Y-%m-%d %H:%M:%S")


def main():
    min_unix = None
    max_unix = None

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        fields = line.replace(" ", "").split(",")
        unix = parse_unix(fields)
        if unix is None:
            continue
        if min_unix is None or unix < min_unix:
            min_unix = unix
        if max_unix is None or unix > max_unix:
            max_unix = unix

    if min_unix is None or max_unix is None:
        return

    print("Start GPS: {}".format(format_gps(min_unix)))
    print("End GPS: {}".format(format_gps(max_unix)))
    print("Start Local: {}".format(format_local(min_unix)))
    print("End Local: {}".format(format_local(max_unix)))


if __name__ == "__main__":
    main()
