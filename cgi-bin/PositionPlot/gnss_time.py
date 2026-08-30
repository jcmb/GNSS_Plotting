"""GNSS GPS-time vs POSIX unix conversions (leap-second handling)."""

from __future__ import annotations

import GPS_TIME

LEAP_SECONDS = 18


def gps_week_sow_to_gps_unix(week: int, sow: float) -> float:
    """Convert GPS week/SOW to internal GPS unix (no leap seconds)."""
    return GPS_TIME.Week_Seconds_To_Unix(week, sow)


def gps_unix_to_posix(gps_unix: float) -> float:
    """Convert internal GPS unix to POSIX unix for UTC/local display."""
    return gps_unix + LEAP_SECONDS


def posix_to_gps_unix(posix: float) -> float:
    """Convert POSIX unix (e.g. from datetime.timestamp()) to GPS unix."""
    return posix - LEAP_SECONDS
