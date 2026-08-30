#!/usr/bin/env python3
"""Parse Trimble ATS log files for ATSDataEvent truth positions."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import os

from gnss_time import gps_unix_to_posix, posix_to_gps_unix


@dataclass(frozen=True)
class AtsTruthPoint:
    t: float
    n: float
    e: float
    ele: float
    date_str: str
    time_str: str


def gnss_local_timezone():
    raw = os.environ.get("GNSS_LOCAL_TZ_HOURS", "").strip()
    if raw:
        try:
            return timezone(timedelta(hours=float(raw)))
        except ValueError:
            pass
    tzinfo = datetime.now().astimezone().tzinfo
    return tzinfo if tzinfo is not None else timezone.utc


def format_ats_local_display(date_str: str, time_str: str) -> str:
    """Return ATS Date/Time as recorded in the log (local time)."""
    return f"{date_str.strip()} {time_str.strip()}"


def format_ats_utc_display(date_str: str, time_str: str) -> str:
    """Return ATS local Date/Time converted to UTC."""
    gps_unix = _parse_ats_timestamp(date_str, time_str)
    return datetime.fromtimestamp(
        gps_unix_to_posix(gps_unix), tz=timezone.utc
    ).strftime("%Y-%m-%d %H:%M:%S UTC")


def _parse_ats_timestamp(date_str: str, time_str: str) -> float:
    date_str = date_str.strip()
    time_str = time_str.strip()
    local_tz = gnss_local_timezone()
    for fmt in ("%m/%d/%Y %H:%M:%S.%f", "%m/%d/%Y %H:%M:%S"):
        try:
            dt = datetime.strptime(f"{date_str} {time_str}", fmt)
            if isinstance(local_tz, timezone):
                dt = dt.replace(tzinfo=local_tz)
            else:
                dt = dt.replace(tzinfo=local_tz)
            return posix_to_gps_unix(dt.timestamp())
        except ValueError:
            continue
    raise ValueError(f"Unrecognized ATS date/time: {date_str!r} {time_str!r}")


def parse_ats_file(path: str) -> list[AtsTruthPoint]:
    """Return ATSDataEvent truth rows sorted by GPS unix time."""
    header_cols: dict[str, int] | None = None
    points: list[AtsTruthPoint] = []

    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw_line in handle:
            line = raw_line.rstrip("\r\n")
            if not line.strip():
                continue
            parts = line.split("\t")
            event = parts[0].strip()
            if event == "ATSDataEvent" and len(parts) > 1 and "N" in parts and "Ele" in parts:
                header_cols = {name.strip(): idx for idx, name in enumerate(parts)}
                continue
            if event != "ATSDataEvent" or header_cols is None:
                continue

            def field(name: str) -> str:
                idx = header_cols.get(name)
                if idx is None or idx >= len(parts):
                    return ""
                return parts[idx].strip()

            date_str = field("Date")
            time_str = field("Time")
            if not date_str or not time_str:
                continue
            try:
                n_val = float(field("N"))
                e_val = float(field("E"))
                ele_val = float(field("Ele"))
                t_val = _parse_ats_timestamp(date_str, time_str)
            except (ValueError, TypeError):
                continue

            points.append(
                AtsTruthPoint(
                    t=t_val,
                    n=n_val,
                    e=e_val,
                    ele=ele_val,
                    date_str=date_str,
                    time_str=time_str,
                )
            )

    points.sort(key=lambda p: p.t)
    dedup: list[AtsTruthPoint] = []
    for point in points:
        if dedup and abs(point.t - dedup[-1].t) < 1e-6:
            dedup[-1] = point
        else:
            dedup.append(point)
    return dedup


if __name__ == "__main__":
    import sys

    for path in sys.argv[1:]:
        rows = parse_ats_file(path)
        print(f"{path}: {len(rows)} ATSDataEvent points")
        if rows:
            first = rows[0]
            last = rows[-1]
            print(
                f"  t={first.t:.3f}..{last.t:.3f} "
                f"N={first.n:.3f} E={first.e:.3f} Ele={first.ele:.3f}"
            )
