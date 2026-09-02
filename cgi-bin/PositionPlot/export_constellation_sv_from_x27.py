#!/usr/bin/env python3
"""Export per-constellation SV tracked counts from viewdat X27 tracking rows."""

from __future__ import annotations

import sys

from constellation_sv import parse_x27_stream, write_csv_rows


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 1:
        print("usage: export_constellation_sv_from_x27.py GPS_WEEK < X27_STREAM", file=sys.stderr)
        return 1

    try:
        gps_week = int(args[0], base=10)
    except ValueError:
        print("invalid GPS week", file=sys.stderr)
        return 1
    if gps_week < 0:
        return 1

    rows = parse_x27_stream(gps_week, sys.stdin)
    if not rows:
        return 1

    write_csv_rows(rows, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
