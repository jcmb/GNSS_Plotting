"""GNSS/ATS plot time: POSIX unix with GPS leap-second offset applied to GNSS only."""

from __future__ import annotations

import GPS_TIME

LEAP_SECONDS = 18


def gnss_week_sow_to_plot_unix(week: int, sow: float) -> float:
    """Convert GPS week/SOW to plot time (subtract leap seconds from GPS unix)."""
    return GPS_TIME.Week_Seconds_To_Unix(week, sow) - LEAP_SECONDS


def plot_unix_to_gps_unix(plot_unix: float) -> float:
    """Convert plot POSIX unix back to GPS-time unix for week/SOW formatting."""
    return plot_unix + LEAP_SECONDS


def ats_local_to_plot_unix(posix: float) -> float:
    """Convert ATS local civil time (datetime.timestamp()) to plot unix."""
    return posix
