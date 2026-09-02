#!/usr/bin/env python3
"""Parse per-constellation SV tracked/used counts from viewdat X29 rows."""

from __future__ import annotations

import csv

from gnss_time import gnss_week_sow_to_plot_unix

X29_MIN_FIELDS = 71
X29_BASE_FIELDS = 29
X29_PAIR_START = 29
X29_PAIR_FIELD_COUNT = 12
X29_EXTENDED_SV_START = 41
X29_SV_USED_FLAG = 0x02

# Flag values seen when viewdat exports SV flags without id/type (0x22 = used+dgnss).
_FLAGS_ONLY_VALUES = frozenset({0, 34})

CONSTELLATION_KEYS = (
    "GPS",
    "GLONASS",
    "Galileo",
    "BeiDou",
    "QZSS",
    "SBAS",
    "NavIC",
)

PAIR_ORDERS = (
    ("GPS", "GLONASS", "Galileo", "BeiDou", "QZSS", "SBAS"),
    ("GPS", "GLONASS", "Galileo", "BeiDou", "QZSS", "SBAS", "NavIC"),
    ("GPS", "SBAS", "GLONASS", "Galileo", "QZSS", "BeiDou"),
    ("GPS", "SBAS", "GLONASS", "Galileo", "BeiDou", "QZSS"),
)

TRIPLET_ORDERS = (
    ("id_type_flags", 0, 1, 2),
    ("type_id_flags", 1, 0, 2),
)


def empty_counts() -> dict[str, dict[str, int]]:
    return {key: {"tracked": 0, "used": 0} for key in CONSTELLATION_KEYS}


def _field_int(fields: list[str], index: int) -> int | None:
    if index < 0 or index >= len(fields):
        return None
    raw = fields[index].strip()
    if not raw or raw.lower() == "nan":
        return None
    try:
        if raw.lower().startswith("0x"):
            return int(raw, 16)
        return int(float(raw))
    except ValueError:
        return None


def sv_type_to_constellation(sv_type: int) -> str | None:
    match sv_type:
        case 0:
            return "GPS"
        case 1:
            return "SBAS"
        case 2:
            return "GLONASS"
        case 3:
            return "Galileo"
        case 4:
            return "QZSS"
        case 5 | 7 | 10:
            return "BeiDou"
        case 9:
            return "NavIC"
        case _:
            return None


def _score_counts(
    counts: dict[str, dict[str, int]],
    total_tracked: int,
    total_used: int,
) -> int:
    tracked_sum = sum(entry["tracked"] for entry in counts.values())
    used_sum = sum(entry["used"] for entry in counts.values())
    err = abs(tracked_sum - total_tracked) + abs(used_sum - total_used)
    for entry in counts.values():
        if entry["tracked"] > 80 or entry["used"] > 80:
            err += 200
        if entry["used"] > entry["tracked"]:
            err += 50
    return err


def _pairs_populated(fields: list[str], start: int, pair_fields: int) -> bool:
    for index in range(pair_fields):
        if _field_int(fields, start + index) is not None:
            return True
    return False


def parse_count_pairs(fields: list[str], start: int, names: tuple[str, ...]) -> dict[str, dict[str, int]]:
    counts = empty_counts()
    for index, name in enumerate(names):
        if name not in counts:
            continue
        tracked = _field_int(fields, start + index * 2)
        used = _field_int(fields, start + index * 2 + 1)
        if tracked is None:
            continue
        if used is None:
            used = 0
        counts[name]["tracked"] = max(0, tracked)
        counts[name]["used"] = max(0, used)
    return counts


def _normalize_sparse_triplet(vals: list[int | None]) -> tuple[int | None, int | None, int | None]:
    sv_id, sv_type, flags = vals[0], vals[1], vals[2]
    if all(v is None for v in vals):
        return None, None, None
    if all(v is None or v in _FLAGS_ONLY_VALUES for v in vals):
        flags = next((v for v in vals if v is not None), None)
        return None, None, flags
    if sv_id == sv_type == flags and sv_id is not None:
        return None, None, sv_id
    if sv_type in _FLAGS_ONLY_VALUES:
        sv_type = None
    if sv_id is not None and sv_id <= 0:
        sv_id = None
    if sv_id in _FLAGS_ONLY_VALUES and sv_type is None:
        sv_id = None
    return sv_id, sv_type, flags


def parse_sparse_sv_triplets(fields: list[str], start: int, end: int) -> dict[str, dict[str, int]]:
    counts = empty_counts()
    for base in range(start, min(len(fields) - 2, end), 3):
        vals = [_field_int(fields, base + offset) for offset in range(3)]
        sv_id, sv_type, flags = _normalize_sparse_triplet(vals)
        if flags is None:
            continue
        if sv_type is None:
            continue
        key = sv_type_to_constellation(sv_type)
        if key is None:
            continue
        counts[key]["tracked"] += 1
        if flags & X29_SV_USED_FLAG:
            counts[key]["used"] += 1
    return counts


def parse_sv_triplets(
    fields: list[str],
    start: int,
    end: int,
    order: tuple[str, int, int, int],
) -> dict[str, dict[str, int]]:
    _, id_idx, type_idx, flags_idx = order
    counts = empty_counts()
    for base in range(start, min(len(fields) - 2, end), 3):
        sv_id = _field_int(fields, base + id_idx)
        sv_type = _field_int(fields, base + type_idx)
        sv_flags = _field_int(fields, base + flags_idx)
        if sv_id is None or sv_id <= 0 or sv_type is None:
            continue
        if sv_type in _FLAGS_ONLY_VALUES:
            continue
        key = sv_type_to_constellation(sv_type)
        if key is None:
            continue
        counts[key]["tracked"] += 1
        if sv_flags is not None and (sv_flags & X29_SV_USED_FLAG):
            counts[key]["used"] += 1
    return counts


def _extended_sv_end(fields: list[str]) -> int:
    return min(len(fields), X29_EXTENDED_SV_START + max(0, len(fields) - X29_EXTENDED_SV_START))


def parse_constellation_sv_counts(fields: list[str]) -> dict[str, dict[str, int]]:
    if len(fields) < X29_MIN_FIELDS:
        return empty_counts()

    total_tracked = _field_int(fields, 3) or 0
    total_used = _field_int(fields, 4) or 0
    if total_tracked <= 0 and total_used <= 0:
        return empty_counts()

    candidates: list[tuple[int, dict[str, dict[str, int]]]] = []
    extended = len(fields) > X29_MIN_FIELDS

    if _pairs_populated(fields, X29_PAIR_START, X29_PAIR_FIELD_COUNT):
        for names in PAIR_ORDERS:
            if len(names) * 2 > X29_PAIR_FIELD_COUNT:
                continue
            counts = parse_count_pairs(fields, X29_PAIR_START, names)
            candidates.append((_score_counts(counts, total_tracked, total_used), counts))

    sv_end = _extended_sv_end(fields) if extended else 71
    sparse_counts = parse_sparse_sv_triplets(fields, X29_EXTENDED_SV_START, sv_end)
    candidates.append((_score_counts(sparse_counts, total_tracked, total_used), sparse_counts))

    for order in TRIPLET_ORDERS:
        for start, end in ((X29_EXTENDED_SV_START, sv_end), (29, 70)):
            counts = parse_sv_triplets(fields, start, end, order)
            candidates.append((_score_counts(counts, total_tracked, total_used), counts))

    best_score, best_counts = min(candidates, key=lambda item: item[0])
    if best_score > 4:
        return empty_counts()
    return best_counts


def parse_x29_line(raw: str) -> tuple[float, dict[str, dict[str, int]]] | None:
    line = raw.strip().replace(" ", "")
    if not line:
        return None
    fields = ["" if part.lower() == "nan" else part for part in line.split(",")]
    if len(fields) < X29_MIN_FIELDS:
        return None
    try:
        week = int(float(fields[0]))
        sow = float(fields[1])
    except ValueError:
        return None
    counts = parse_constellation_sv_counts(fields)
    if not any(entry["tracked"] or entry["used"] for entry in counts.values()):
        return None
    return gnss_week_sow_to_plot_unix(week, sow), counts


def csv_header() -> list[str]:
    columns = ["unix_time"]
    for key in CONSTELLATION_KEYS:
        columns.append(f"{key}_tracked")
        columns.append(f"{key}_used")
    return columns


X27_MIN_FIELDS = 71
X27_HEADER_FIELDS = 11
X27_MAX_BANDS = 6
X27_FIELDS_PER_BAND = 13
X27_BAND_RANGE = 3
X27_BAND_ANTENNA = 9
X27_MIN_RANGE_METERS = 1.0e7
X27_MAX_RANGE_METERS = 5.0e7

X27_SYSTEM_TO_CONSTELLATION: dict[int, str] = {
    0: "GPS",
    1: "SBAS",
    2: "GLONASS",
    3: "Galileo",
    4: "QZSS",
    9: "NavIC",
    10: "BeiDou",
}


def _time_lookup_key(unix_time: float) -> float:
    return round(unix_time, 3)


def _x27_valid_range(value: str) -> bool:
    if not value:
        return False
    try:
        meters = float(value)
    except ValueError:
        return False
    return X27_MIN_RANGE_METERS <= meters <= X27_MAX_RANGE_METERS


def _x27_band_valid(fields: list[str], band_start: int) -> bool:
    if band_start + X27_BAND_ANTENNA >= len(fields):
        return False
    if not fields[band_start] or not fields[band_start + 1]:
        return False
    if not _x27_valid_range(fields[band_start + X27_BAND_RANGE]):
        return False
    return True


def _x27_iter_band_starts(fields: list[str]):
    band_start = X27_HEADER_FIELDS
    bands_found = 0
    band_limit = X27_HEADER_FIELDS + X27_MAX_BANDS * X27_FIELDS_PER_BAND
    while bands_found < X27_MAX_BANDS and band_start < band_limit:
        if band_start + X27_FIELDS_PER_BAND > len(fields):
            break
        if _x27_band_valid(fields, band_start):
            yield band_start
            band_start += X27_FIELDS_PER_BAND
            bands_found += 1
        else:
            band_start += 1


def _x27_sv_key(system: int, sv_raw: int) -> tuple[int, int]:
    sv_int = sv_raw
    if system == 1:
        sv_int = sv_raw - 119
    return system, sv_int


def parse_x27_tracking_line(
    fields: list[str],
    epoch_sets: dict[str, set[tuple[int, int]]],
) -> bool:
    if len(fields) < X27_MIN_FIELDS:
        return False
    try:
        system = int(fields[7], base=10)
    except (ValueError, IndexError):
        return False
    constellation = X27_SYSTEM_TO_CONSTELLATION.get(system)
    if constellation is None:
        return False
    try:
        sv_raw = int(fields[5], base=10)
    except (ValueError, IndexError):
        return False
    if not any(_x27_band_valid(fields, band_start) for band_start in _x27_iter_band_starts(fields)):
        return False
    epoch_sets.setdefault(constellation, set()).add(_x27_sv_key(system, sv_raw))
    return True


def finalize_x27_epoch(
    gps_week: int,
    sow: float,
    epoch_sets: dict[str, set[tuple[int, int]]],
) -> tuple[float, dict[str, dict[str, int]]] | None:
    if not epoch_sets:
        return None
    counts = empty_counts()
    for key, sv_set in epoch_sets.items():
        counts[key]["tracked"] = len(sv_set)
    return gnss_week_sow_to_plot_unix(gps_week, sow), counts


def parse_x27_stream(gps_week: int, lines) -> list[tuple[float, dict[str, dict[str, int]]]]:
    rows: list[tuple[float, dict[str, dict[str, int]]]] = []
    current_sow: float | None = None
    epoch_sets: dict[str, set[tuple[int, int]]] = {}

    for raw in lines:
        line = raw.strip().replace(" ", "")
        if not line or line.startswith("Time"):
            continue
        fields = line.split(",")
        if len(fields) < X27_MIN_FIELDS:
            continue
        try:
            sow = float(fields[0])
        except (ValueError, IndexError):
            continue
        if current_sow is not None and sow != current_sow:
            finalized = finalize_x27_epoch(gps_week, current_sow, epoch_sets)
            if finalized is not None:
                rows.append(finalized)
            epoch_sets = {}
        current_sow = sow
        parse_x27_tracking_line(fields, epoch_sets)

    if current_sow is not None:
        finalized = finalize_x27_epoch(gps_week, current_sow, epoch_sets)
        if finalized is not None:
            rows.append(finalized)

    rows.sort(key=lambda row: row[0])
    return rows


def parse_x29_sol_totals(raw: str) -> tuple[float, int, int] | None:
    line = raw.strip().replace(" ", "")
    if not line:
        return None
    fields = ["" if part.lower() == "nan" else part for part in line.split(",")]
    if len(fields) < 5:
        return None
    try:
        week = int(float(fields[0]))
        sow = float(fields[1])
    except ValueError:
        return None
    tracked = _field_int(fields, 3)
    used = _field_int(fields, 4)
    if tracked is None and used is None:
        return None
    return gnss_week_sow_to_plot_unix(week, sow), tracked or 0, used or 0


def load_sol_totals_by_time(path: str) -> dict[float, tuple[int, int]]:
    totals: dict[float, tuple[int, int]] = {}
    with open(path, encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            parsed = parse_x29_sol_totals(raw)
            if parsed is None:
                continue
            unix_time, tracked, used = parsed
            totals[_time_lookup_key(unix_time)] = (tracked, used)
    return totals


def load_csv_rows(path: str) -> list[tuple[float, dict[str, dict[str, int]]]]:
    rows: list[tuple[float, dict[str, dict[str, int]]]] = []
    with open(path, encoding="utf-8", errors="replace") as handle:
        reader = csv.reader(handle)
        header = next(reader, None)
        if not header:
            return rows
        header = [part.strip() for part in header]
        time_idx = header.index("unix_time") if "unix_time" in header else -1
        if time_idx < 0:
            return rows
        for parts in reader:
            if time_idx >= len(parts):
                continue
            try:
                unix_time = float(parts[time_idx])
            except ValueError:
                continue
            counts = empty_counts()
            for key in CONSTELLATION_KEYS:
                tracked_idx = header.index(f"{key}_tracked") if f"{key}_tracked" in header else -1
                used_idx = header.index(f"{key}_used") if f"{key}_used" in header else -1
                if tracked_idx >= 0 and tracked_idx < len(parts):
                    counts[key]["tracked"] = int(float(parts[tracked_idx] or 0))
                if used_idx >= 0 and used_idx < len(parts):
                    counts[key]["used"] = int(float(parts[used_idx] or 0))
            if any(entry["tracked"] or entry["used"] for entry in counts.values()):
                rows.append((unix_time, counts))
    rows.sort(key=lambda row: row[0])
    return rows


def score_export_rows(rows: list[tuple[float, dict[str, dict[str, int]]]]) -> int:
    if not rows:
        return 999_999_999
    tracked = sum(entry["tracked"] for _, counts in rows for entry in counts.values())
    used = sum(entry["used"] for _, counts in rows for entry in counts.values())
    if tracked <= 0:
        return 999_999_999
    constellations = sum(
        1
        for key in CONSTELLATION_KEYS
        if any(counts[key]["tracked"] > 0 for _, counts in rows)
    )
    penalty = 0
    if used <= 0:
        penalty += 5_000
    return penalty - constellations * 10_000 - tracked * 10 - used


def apply_proportional_used(
    rows: list[tuple[float, dict[str, dict[str, int]]]],
    totals_by_time: dict[float, tuple[int, int]],
) -> list[tuple[float, dict[str, dict[str, int]]]]:
    adjusted: list[tuple[float, dict[str, dict[str, int]]]] = []
    for unix_time, counts in rows:
        if sum(entry["used"] for entry in counts.values()) > 0:
            adjusted.append((unix_time, counts))
            continue
        total_tracked = sum(entry["tracked"] for entry in counts.values())
        if total_tracked <= 0:
            adjusted.append((unix_time, counts))
            continue
        sol_totals = totals_by_time.get(_time_lookup_key(unix_time))
        if not sol_totals:
            adjusted.append((unix_time, counts))
            continue
        sol_tracked, sol_used = sol_totals
        if sol_tracked <= 0 or sol_used <= 0:
            adjusted.append((unix_time, counts))
            continue
        new_counts = empty_counts()
        keys_with_tracked = [key for key in CONSTELLATION_KEYS if counts[key]["tracked"] > 0]
        allocated = 0
        for key in keys_with_tracked[:-1]:
            used = int(round(counts[key]["tracked"] * sol_used / sol_tracked))
            used = min(used, counts[key]["tracked"])
            new_counts[key]["tracked"] = counts[key]["tracked"]
            new_counts[key]["used"] = used
            allocated += used
        last_key = keys_with_tracked[-1]
        new_counts[last_key]["tracked"] = counts[last_key]["tracked"]
        new_counts[last_key]["used"] = min(
            counts[last_key]["tracked"],
            max(0, sol_used - allocated),
        )
        adjusted.append((unix_time, new_counts))
    return adjusted


def write_csv_rows(rows: list[tuple[float, dict[str, dict[str, int]]]], out) -> None:
    writer = csv.writer(out, lineterminator="\n")
    writer.writerow(csv_header())
    for unix_time, counts in rows:
        row = [f"{unix_time:.3f}"]
        for key in CONSTELLATION_KEYS:
            row.append(str(counts[key]["tracked"]))
            row.append(str(counts[key]["used"]))
        writer.writerow(row)
