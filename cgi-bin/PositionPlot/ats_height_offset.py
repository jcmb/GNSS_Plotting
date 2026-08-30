#!/usr/bin/env python3
"""Estimate mean GNSS height minus ATS Ele over the overlapping time window."""

from __future__ import annotations

import argparse
import sys

from parse_ats import parse_ats_file
from truth_gnss_enu import interpolate_truth, read_gnss_rows


def compute_height_offset(sol_path: str, ats_path: str) -> dict | None:
    truth = parse_ats_file(ats_path)
    gnss_rows = read_gnss_rows(sol_path, None)
    if len(truth) < 2 or not gnss_rows:
        return None

    t_min = truth[0].t
    t_max = truth[-1].t
    matched: list[tuple[float, float]] = []
    for row in gnss_rows:
        if row["t"] < t_min or row["t"] > t_max:
            continue
        sample = interpolate_truth(truth, row["t"])
        if sample is None:
            continue
        _n, _e, ele = sample
        matched.append((row["height"], ele))

    if len(matched) < 2:
        return None

    gnss_mean = sum(height for height, _ele in matched) / len(matched)
    ats_mean = sum(ele for _height, ele in matched) / len(matched)
    offset = sum(height - ele for height, ele in matched) / len(matched)
    return {
        "matched": len(matched),
        "gnss_mean": gnss_mean,
        "ats_mean": ats_mean,
        "offset": offset,
    }


def write_report(path: str, stats: dict) -> None:
    lines = [
        "ATS_HEIGHT_OFFSET",
        f"Matched epochs: {stats['matched']}",
        f"Mean GNSS height: {stats['gnss_mean']:.4f} m",
        f"Mean ATS Ele: {stats['ats_mean']:.4f} m",
        f"Height offset (mean GNSS height - ATS Ele): {stats['offset']:.4f} m",
        f"ats_height_offset: {stats['offset']:.4f}",
        f"ats_height_matched: {stats['matched']}",
    ]
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Compute mean GNSS height minus ATS Ele in the overlap window.",
    )
    parser.add_argument("--sol", required=True, help="GNSS X29 .sol file")
    parser.add_argument("--ats", required=True, help="ATS truth log file")
    parser.add_argument("--report", required=True, help="Output report text file")
    args = parser.parse_args(argv)

    stats = compute_height_offset(args.sol, args.ats)
    if stats is None:
        print("Could not compute ATS/GNSS height offset (insufficient overlap)", file=sys.stderr)
        return 2

    write_report(args.report, stats)
    print(
        "ats_height_offset: matched={matched} offset={offset:.4f} gnss_mean={gnss_mean:.4f} "
        "ats_mean={ats_mean:.4f}".format(**stats)
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
