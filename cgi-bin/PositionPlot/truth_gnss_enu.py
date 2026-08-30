#!/usr/bin/env python3
"""Align ATS truth to GNSS trajectory and write ENU error X29 rows."""

from __future__ import annotations

import argparse
import math
import sys
from typing import Iterable

import GPS_TIME
from gnss_time import LEAP_SECONDS, gnss_week_sow_to_plot_unix
from parse_ats import AtsTruthPoint, parse_ats_file
WGS84_A = 6378137.0
WGS84_F = 1 / 298.257223563
WGS84_E2 = 2 * WGS84_F - WGS84_F ** 2


def llh_to_enu(lat_deg: float, lon_deg: float, h_m: float,
               lat0_deg: float, lon0_deg: float, h0_m: float) -> tuple[float, float, float]:
    lat = math.radians(lat_deg)
    lon = math.radians(lon_deg)
    lat0 = math.radians(lat0_deg)
    lon0 = math.radians(lon0_deg)
    sin_lat0 = math.sin(lat0)
    w = math.sqrt(1 - WGS84_E2 * sin_lat0 ** 2)
    n_radius = WGS84_A / w
    m_radius = WGS84_A * (1 - WGS84_E2) / w ** 3
    dlat = lat - lat0
    dlon = lon - lon0
    north = m_radius * dlat
    east = n_radius * math.cos(lat0) * dlon
    up = h_m - h0_m
    return north, east, up


def read_gnss_rows(path: str, sol_type: int | None) -> list[dict]:
    rows: list[dict] = []
    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.strip().replace(" ", "").replace("Nan", "")
            if not line:
                continue
            fields = line.split(",")
            if len(fields) < 71:
                continue
            if sol_type is not None:
                try:
                    if int(float(fields[8])) != sol_type:
                        continue
                except ValueError:
                    continue
            try:
                week = int(float(fields[0]))
                sow = float(fields[1])
                lat = float(fields[10])
                lon = float(fields[11])
                height = float(fields[12])
            except ValueError:
                continue
            rows.append({
                "fields": fields,
                "t": gnss_week_sow_to_plot_unix(week, sow),
                "lat": lat,
                "lon": lon,
                "height": height,
            })
    rows.sort(key=lambda row: row["t"])
    return rows


def trim_to_overlap(gnss_rows: list[dict], truth: list[AtsTruthPoint]) -> list[dict]:
    if not gnss_rows or not truth:
        return []
    t_min = truth[0].t
    t_max = truth[-1].t
    return [row for row in gnss_rows if t_min <= row["t"] <= t_max]


def has_sufficient_overlap(gnss_rows: list[dict], truth: list[AtsTruthPoint], min_matched: int = 2) -> bool:
    if not gnss_rows or len(truth) < min_matched:
        return False
    gnss_min = gnss_rows[0]["t"]
    gnss_max = gnss_rows[-1]["t"]
    ats_min = truth[0].t
    ats_max = truth[-1].t
    if gnss_max < ats_min or gnss_min > ats_max:
        return False
    return len(trim_to_overlap(gnss_rows, truth)) >= min_matched


def interpolate_truth(truth: list[AtsTruthPoint], t_query: float) -> tuple[float, float, float] | None:
    if not truth or t_query < truth[0].t or t_query > truth[-1].t:
        return None
    if t_query == truth[-1].t:
        last = truth[-1]
        return last.n, last.e, last.ele

    lo = 0
    hi = len(truth) - 1
    while lo + 1 < hi:
        mid = (lo + hi) // 2
        if truth[mid].t <= t_query:
            lo = mid
        else:
            hi = mid

    p0 = truth[lo]
    p1 = truth[hi]
    if p1.t == p0.t:
        frac = 0.0
    else:
        frac = (t_query - p0.t) / (p1.t - p0.t)
    n_val = p0.n + frac * (p1.n - p0.n)
    e_val = p0.e + frac * (p1.e - p0.e)
    ele_val = p0.ele + frac * (p1.ele - p0.ele)
    return n_val, e_val, ele_val


def solve_linear_system(matrix: list[list[float]], rhs: list[float]) -> list[float]:
    n = len(rhs)
    aug = [row[:] + [rhs[i]] for i, row in enumerate(matrix)]
    for col in range(n):
        pivot = col
        for row in range(col + 1, n):
            if abs(aug[row][col]) > abs(aug[pivot][col]):
                pivot = row
        if abs(aug[pivot][col]) < 1e-12:
            raise ValueError("Singular Helmert fit")
        if pivot != col:
            aug[col], aug[pivot] = aug[pivot], aug[col]
        div = aug[col][col]
        for row in range(col, n + 1):
            aug[col][row] /= div
        for row in range(n):
            if row == col:
                continue
            factor = aug[row][col]
            if factor == 0:
                continue
            for j in range(col, n + 1):
                aug[row][j] -= factor * aug[col][j]
    return [aug[i][n] for i in range(n)]


def _fit_helmert_2d_raw(src_n: list[float], src_e: list[float],
                        tgt_n: list[float], tgt_e: list[float]) -> tuple[float, float, float, float]:
    ata = [[0.0] * 4 for _ in range(4)]
    atb = [0.0] * 4
    for ns, es, nt, et in zip(src_n, src_e, tgt_n, tgt_e):
        for coeff_n, rhs in ((ns, -es, 1.0, 0.0, nt), (es, ns, 0.0, 1.0, et)):
            coeffs = list(coeff_n)
            for i in range(4):
                atb[i] += coeffs[i] * rhs
                for j in range(4):
                    ata[i][j] += coeffs[i] * coeffs[j]
    a_val, b_val, tx, ty = solve_linear_system(ata, atb)
    return a_val, b_val, tx, ty


def fit_helmert_2d(src_n: list[float], src_e: list[float],
                   tgt_n: list[float], tgt_e: list[float]) -> tuple[float, float, float, float]:
    """Fit 2D Helmert transform; center coordinates first for UTM-scale stability."""
    count = len(src_n)
    if count == 0:
        raise ValueError("No points for Helmert fit")
    mean_sn = sum(src_n) / count
    mean_se = sum(src_e) / count
    mean_tn = sum(tgt_n) / count
    mean_te = sum(tgt_e) / count
    src_n_c = [value - mean_sn for value in src_n]
    src_e_c = [value - mean_se for value in src_e]
    tgt_n_c = [value - mean_tn for value in tgt_n]
    tgt_e_c = [value - mean_te for value in tgt_e]
    a_val, b_val, tx_c, ty_c = _fit_helmert_2d_raw(src_n_c, src_e_c, tgt_n_c, tgt_e_c)
    tx = tx_c + mean_tn - (a_val * mean_sn - b_val * mean_se)
    ty = ty_c + mean_te - (b_val * mean_sn + a_val * mean_se)
    return a_val, b_val, tx, ty


def apply_helmert(a_val: float, b_val: float, tx: float, ty: float,
                  n_val: float, e_val: float) -> tuple[float, float]:
    return a_val * n_val - b_val * e_val + tx, b_val * n_val + a_val * e_val + ty


def helmert_rotation_deg(a_val: float, b_val: float) -> float:
    return math.degrees(math.atan2(b_val, a_val))


def helmert_scale(a_val: float, b_val: float) -> float:
    return math.hypot(a_val, b_val)


def write_report(path: str, *, matched: int, dropped_start: int, dropped_end: int,
                 height_offset: float, a_val: float, b_val: float, tx: float, ty: float,
                 horiz_rms: float, truth_count: int, gnss_count: int) -> None:
    rotation = helmert_rotation_deg(a_val, b_val)
    scale = helmert_scale(a_val, b_val)
    lines = [
        "TRUTH_SESSION",
        "Source: ATS truth file",
        f"ATS points: {truth_count}",
        f"GNSS points (input): {gnss_count}",
        f"Matched epochs: {matched}",
        f"Dropped before overlap: {dropped_start}",
        f"Dropped after overlap: {dropped_end}",
        f"Leap seconds ({LEAP_SECONDS} s) applied to GNSS plot time; ATS uses local civil POSIX",
        "ATS elevation: orthometric (offset removed)",
        f"Height offset (mean GNSS height - ATS Ele): {height_offset:.4f} m",
        f"truth_height_offset: {height_offset:.4f}",
        "Transform: data-driven 2D Helmert (ATS N/E to GNSS ENU)",
        f"Helmert a: {a_val:.8f}",
        f"Helmert b: {b_val:.8f}",
        f"Helmert tx: {tx:.4f} m",
        f"Helmert ty: {ty:.4f} m",
        f"Helmert rotation: {rotation:.4f} deg",
        f"Helmert scale: {scale:.8f}",
        f"Horizontal RMS after fit: {horiz_rms:.4f} m",
    ]
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def build_enu_errors(gnss_rows: list[dict], truth: list[AtsTruthPoint]) -> tuple[list[dict], dict]:
    trimmed = trim_to_overlap(gnss_rows, truth)
    dropped_start = sum(1 for row in gnss_rows if row["t"] < truth[0].t)
    dropped_end = sum(1 for row in gnss_rows if row["t"] > truth[-1].t)

    matched: list[dict] = []
    for row in trimmed:
        sample = interpolate_truth(truth, row["t"])
        if sample is None:
            continue
        n_ats, e_ats, ele_ats = sample
        matched.append({
            **row,
            "n_ats": n_ats,
            "e_ats": e_ats,
            "ele_ats": ele_ats,
        })

    if len(matched) < 2:
        raise ValueError("Not enough overlapping GNSS/ATS epochs for truth alignment")

    lat0 = sum(row["lat"] for row in matched) / len(matched)
    lon0 = sum(row["lon"] for row in matched) / len(matched)
    h0 = sum(row["height"] for row in matched) / len(matched)

    src_n: list[float] = []
    src_e: list[float] = []
    tgt_n: list[float] = []
    tgt_e: list[float] = []
    height_delta: list[float] = []

    for row in matched:
        n_g, e_g, _u_g = llh_to_enu(row["lat"], row["lon"], row["height"], lat0, lon0, h0)
        row["n_g"] = n_g
        row["e_g"] = e_g
        src_n.append(row["n_ats"])
        src_e.append(row["e_ats"])
        tgt_n.append(n_g)
        tgt_e.append(e_g)
        height_delta.append(row["height"] - row["ele_ats"])

    height_offset = sum(height_delta) / len(height_delta)
    a_val, b_val, tx, ty = fit_helmert_2d(src_n, src_e, tgt_n, tgt_e)

    horiz_sq = 0.0
    for row in matched:
        n_truth, e_truth = apply_helmert(a_val, b_val, tx, ty, row["n_ats"], row["e_ats"])
        row["n_err"] = row["n_g"] - n_truth
        row["e_err"] = row["e_g"] - e_truth
        row["u_err"] = row["height"] - row["ele_ats"] - height_offset
        horiz_sq += row["n_err"] ** 2 + row["e_err"] ** 2

    horiz_rms = math.sqrt(horiz_sq / (2 * len(matched)))
    meta = {
        "matched": len(matched),
        "dropped_start": dropped_start,
        "dropped_end": dropped_end,
        "height_offset": height_offset,
        "a": a_val,
        "b": b_val,
        "tx": tx,
        "ty": ty,
        "horiz_rms": horiz_rms,
        "truth_count": len(truth),
        "gnss_count": len(gnss_rows),
        "lat0": lat0,
        "lon0": lon0,
        "h0": h0,
    }
    return matched, meta


def write_enu_file(rows: Iterable[dict], out_path: str) -> None:
    with open(out_path, "w", encoding="utf-8") as handle:
        for row in rows:
            fields = row["fields"]
            fields[10] = f"{row['n_err']:.5f}"
            fields[11] = f"{row['e_err']:.5f}"
            fields[12] = f"{row['u_err']:.5f}"
            handle.write(",".join(fields) + "\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Build ENU errors from GNSS and ATS truth.")
    parser.add_argument("--ats", required=True, help="ATS truth log file")
    parser.add_argument("--sol", required=True, help="GNSS X29 .sol file")
    parser.add_argument("--out", required=True, help="Output ENU .enu file")
    parser.add_argument("--report", required=True, help="Truth report text file")
    parser.add_argument("--sol-type", type=int, default=None, help="Optional solution type filter")
    args = parser.parse_args(argv)

    truth = parse_ats_file(args.ats)
    if len(truth) < 2:
        print("ATS truth file has fewer than 2 usable ATSDataEvent points", file=sys.stderr)
        return 2

    all_gnss_rows = read_gnss_rows(args.sol, None)
    if not all_gnss_rows:
        print("No GNSS rows found in .sol file", file=sys.stderr)
        return 1

    if not has_sufficient_overlap(all_gnss_rows, truth):
        print("NO_OVERLAP: ATS time range does not overlap GNSS data sufficiently", file=sys.stderr)
        print(
            f"  GNSS UTC: {all_gnss_rows[0]['t']:.3f} .. {all_gnss_rows[-1]['t']:.3f}",
            file=sys.stderr,
        )
        print(
            f"  ATS UTC:  {truth[0].t:.3f} .. {truth[-1].t:.3f}",
            file=sys.stderr,
        )
        return 2

    gnss_rows = all_gnss_rows
    if args.sol_type is not None:
        gnss_rows = read_gnss_rows(args.sol, args.sol_type)
        if not gnss_rows:
            print(
                f"No GNSS rows match solution type {args.sol_type}",
                file=sys.stderr,
            )
            return 1
        if len(trim_to_overlap(gnss_rows, truth)) < 2:
            print(
                "NO_OVERLAP: ATS overlaps GNSS overall but fewer than 2 epochs "
                f"match solution type {args.sol_type} in the ATS window",
                file=sys.stderr,
            )
            print(
                f"  GNSS UTC (type {args.sol_type}): "
                f"{gnss_rows[0]['t']:.3f} .. {gnss_rows[-1]['t']:.3f}",
                file=sys.stderr,
            )
            print(
                f"  ATS UTC:  {truth[0].t:.3f} .. {truth[-1].t:.3f}",
                file=sys.stderr,
            )
            return 2

    matched, meta = build_enu_errors(gnss_rows, truth)
    write_enu_file(matched, args.out)
    write_report(
        args.report,
        matched=meta["matched"],
        dropped_start=meta["dropped_start"],
        dropped_end=meta["dropped_end"],
        height_offset=meta["height_offset"],
        a_val=meta["a"],
        b_val=meta["b"],
        tx=meta["tx"],
        ty=meta["ty"],
        horiz_rms=meta["horiz_rms"],
        truth_count=meta["truth_count"],
        gnss_count=meta["gnss_count"],
    )

    print(f"truth_gnss_enu: matched={meta['matched']} dropped_start={meta['dropped_start']} "
          f"dropped_end={meta['dropped_end']} height_offset={meta['height_offset']:.4f} "
          f"horiz_rms={meta['horiz_rms']:.4f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
