#!/usr/bin/env python3

import argparse
import os
import sys
from datetime import datetime, timezone

import GPS_TIME

from gnss_time import LEAP_SECONDS, gnss_week_sow_to_plot_unix, plot_unix_to_gps_unix
from parse_ats import gnss_local_timezone


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
                return gnss_week_sow_to_plot_unix(week, sow)
        except (TypeError, ValueError):
            pass
    return None


def format_gps(plot_unix):
    gps_unix = plot_unix_to_gps_unix(plot_unix)
    week = GPS_TIME.DateTime_To_Week(gps_unix)
    sow = GPS_TIME.DateTime_To_Seconds_Of_Week(gps_unix)
    return "Week {}, {:.3f} s".format(week, sow)


def local_timezone():
    return gnss_local_timezone()


def format_tz_offset_line():
    raw = os.environ.get("GNSS_LOCAL_TZ_HOURS", "").strip()
    if raw:
        try:
            total_minutes = int(round(float(raw) * 60))
        except ValueError:
            total_minutes = 0
    else:
        tz = local_timezone()
        if isinstance(tz, timezone):
            offset = tz.utcoffset(datetime(2000, 1, 1))
        else:
            offset = datetime.now(tz).utcoffset()
        if offset is None:
            return "Local TZ offset: +0:00"
        total_minutes = int(offset.total_seconds() // 60)
    sign = -1 if total_minutes < 0 else 1
    abs_minutes = abs(total_minutes)
    hours = abs_minutes // 60
    minutes = abs_minutes % 60
    prefix = "-" if total_minutes < 0 else "+"
    return "Local TZ offset: {}{}:{:02d}".format(prefix, hours, minutes)


def format_local(plot_unix):
    return datetime.fromtimestamp(plot_unix, tz=local_timezone()).strftime(
        "%Y-%m-%d %H:%M:%S"
    )


def format_utc(plot_unix):
    return datetime.fromtimestamp(plot_unix, tz=timezone.utc).strftime(
        "%Y-%m-%d %H:%M:%S UTC"
    )


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
    from parse_ats import parse_ats_file

    truth = parse_ats_file(ats_path)
    if not truth:
        return
    first = truth[0]
    last = truth[-1]
    print("ATS Start GPS: {}".format(format_gps(first.t)))
    print("ATS End GPS: {}".format(format_gps(last.t)))
    print("ATS Start UTC: {}".format(format_utc(first.t)))
    print("ATS End UTC: {}".format(format_utc(last.t)))
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
    print("GNSS leap seconds: -{} s applied to plot time".format(LEAP_SECONDS))
    print_range("", min_unix, max_unix)

    if args.ats:
        print_ats_range(args.ats)


if __name__ == "__main__":
    main()
