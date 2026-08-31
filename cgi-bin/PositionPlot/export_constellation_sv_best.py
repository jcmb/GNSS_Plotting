#!/usr/bin/env python3
"""Pick the best constellation SV export from multiple viewdat-derived CSV candidates."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from constellation_sv import (
    apply_proportional_used,
    load_csv_rows,
    load_sol_totals_by_time,
    score_export_rows,
    write_csv_rows,
)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sol", required=True, help="Filtered X29 .sol file for used totals")
    parser.add_argument(
        "candidates",
        nargs="*",
        help="Candidate constellation_sv CSV files (sol, native X29, X27 tracking, ...)",
    )
    args = parser.parse_args(argv)

    sol_path = Path(args.sol)
    if not sol_path.is_file():
        return 1

    totals_by_time = load_sol_totals_by_time(str(sol_path))
    best_rows: list = []
    best_score = 999_999_999
    best_source = ""

    for index, candidate in enumerate(args.candidates):
        path = Path(candidate)
        if not path.is_file():
            continue
        rows = load_csv_rows(str(path))
        if not rows:
            continue
        score = score_export_rows(rows)
        if score < best_score:
            best_score = score
            best_rows = rows
            best_source = path.name

    if not best_rows:
        return 1

    if best_source.startswith("from_x27") or sum(entry["used"] for _, counts in best_rows for entry in counts.values()) <= 0:
        best_rows = apply_proportional_used(best_rows, totals_by_time)

    write_csv_rows(best_rows, sys.stdout)
    return 0


if __name__ == "__main__":
    sys.exit(main())
