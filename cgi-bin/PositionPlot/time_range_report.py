#!/usr/bin/env python3

import argparse
import os
import sys
from datetime import datetime, timedelta, timezone

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


def local_timezone():
    raw = os.environ.get("GNSS_LOCAL_TZ_HOURS", "").strip()
    if raw:
        try:
            hours = float(raw)
            return timezone(timedelta(hours=hours))
        except ValueError:
            pass
    tzinfo = datetime.now().astimezone().tzinfo
    return tzinfo if tzinfo is not None else timezone.utc


def format_tz_offset_line():
    tz = local_timezone()
    if isinstance(tz, timezone):
        offset = tz.utcoffset(datetime(2000, 1, 1))
    else:
        offset = datetime.now(tz).utcoffset()
    if offset is None:
        return "Display TZ offset: +0:00"
    total_seconds = int(offset.total_seconds())
    sign = -1 if total_seconds < 0 else 1
    abs_seconds = abs(total_seconds)
    hours = abs_seconds // 3600
    minutes = (abs_seconds % 3600) // 60
    prefix = "-" if sign < 0 else "+"
    return "Display TZ offset: {}{}:{:02d}".format(prefix, hours, minutes)


def format_local(unix_sec):
    return datetime.fromtimestamp(unix_sec, tz=local_timezone()).strftime("%Y-%m-%d %H:%M:%S")


def format_utc(unix_sec):
    return datetime.fromtimestamp(unix_sec, tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")


def print_range(prefix, min_unix, max_unix):
    print("{}Start GPS: {}".format(prefix, format_gps(min_unix)))
    print("{}End GPS: {}".format(prefix, format_gps(max_unix)))
    print("{}Start UTC: {}".format(prefix, format_utc(min_unix)))
    print("{}End UTC: {}".format(prefix, format_utc(max_unix)))
    print("{}Start Local: {}".format(prefix, format_local(min_unix)))
    print("{}End Local: {}".format(prefix, format_local(max_unix)))


def read_gnss_range():
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

    return min_unix, max_unix


def print_ats_range(ats_path):
    from parse_ats import format_ats_utc_display, parse_ats_file

    truth = parse_ats_file(ats_path)
    if not truth:
        return
    first = truth[0]
    last = truth[-1]
    print("ATS Start UTC: {}".format(format_ats_utc_display(first.date_str, first.time_str)))
    print("ATS End UTC: {}".format(format_ats_utc_display(last.date_str, last.time_str)))
    print("ATS Start Local: {}".format(format_local(first.t)))
    print("ATS End Local: {}".format(format_local(last.t)))


def main():
    parser = argparse.ArgumentParser(description="Report GPS/UTC/local time range for GNSS data.")
    parser.add_argument("--ats", help="Optional ATS truth file to report its time span")
    args = parser.parse_args()

    min_unix, max_unix = read_gnss_range()
    if min_unix is None or max_unix is None:
        return

    print(format_tz_offset_line())
    print_range("", min_unix, max_unix)

    if args.ats:
        print_ats_range(args.ats)


if __name__ == "__main__":
    main()
