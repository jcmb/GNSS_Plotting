#!/usr/bin/env python3
"""Export ATS truth N/E/Ele points as CSV for interactive plots."""

from __future__ import annotations

import csv
import sys

from parse_ats import parse_ats_file


def main(argv: list[str] | None = None) -> int:
    args = argv if argv is not None else sys.argv[1:]
    if len(args) != 1:
        print("usage: export_ats_csv.py ATS_FILE", file=sys.stderr)
        return 1

    points = parse_ats_file(args[0])
    if not points:
        return 1

    writer = csv.writer(sys.stdout, lineterminator="\n")
    writer.writerow(["unix_time", "n", "e", "ele"])
    for point in points:
        writer.writerow([
            f"{point.t:.3f}",
            f"{point.n:.6f}",
            f"{point.e:.6f}",
            f"{point.ele:.4f}",
        ])
    return 0


if __name__ == "__main__":
    sys.exit(main())
