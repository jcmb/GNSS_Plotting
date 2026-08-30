#!/usr/bin/env python3
"""Export GNSS ellipsoidal heights from an X29 .sol file for ATS comparison plots."""

from __future__ import annotations

import csv
import sys

import GPS_TIME

LEAP_SECONDS = 18


def gnss_unix_utc(week: int, sow: float) -> float:
    return GPS_TIME.Week_Seconds_To_Unix(week, sow) + LEAP_SECONDS


def export_gnss_heights(path: str) -> list[tuple[float, float]]:
    rows: list[tuple[float, float]] = []
    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.strip().replace(" ", "").replace("Nan", "")
            if not line:
                continue
            fields = line.split(",")
            if len(fields) < 13:
                continue
            try:
                week = int(float(fields[0]))
                sow = float(fields[1])
                height = float(fields[12])
            except ValueError:
                continue
            rows.append((gnss_unix_utc(week, sow), height))
    rows.sort(key=lambda row: row[0])
    return rows


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 1:
        print("usage: export_gnss_height_csv.py SOL_FILE", file=sys.stderr)
        return 1

    rows = export_gnss_heights(args[0])
    if not rows:
        return 1

    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(["unix_time", "height"])
    for unix_time, height in rows:
        writer.writerow([f"{unix_time:.3f}", f"{height:.4f}"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
