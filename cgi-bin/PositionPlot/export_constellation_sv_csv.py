#!/usr/bin/env python3
"""Export per-constellation SV counts from a viewdat X29 .sol file."""

from __future__ import annotations

import csv
import sys

from constellation_sv import CONSTELLATION_KEYS, csv_header, parse_x29_line


def export_rows(path: str) -> list[tuple[float, dict[str, dict[str, int]]]]:
    rows: list[tuple[float, dict[str, dict[str, int]]]] = []
    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            parsed = parse_x29_line(raw)
            if parsed is None:
                continue
            rows.append(parsed)
    rows.sort(key=lambda row: row[0])
    return rows


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 1:
        print("usage: export_constellation_sv_csv.py SOL_FILE", file=sys.stderr)
        return 1

    rows = export_rows(args[0])
    if not rows:
        return 1

    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(csv_header())
    for unix_time, counts in rows:
        row = [f"{unix_time:.3f}"]
        for key in CONSTELLATION_KEYS:
            entry = counts[key]
            row.append(str(entry["tracked"]))
            row.append(str(entry["used"]))
        writer.writerow(row)
    return 0


if __name__ == "__main__":
    sys.exit(main())
