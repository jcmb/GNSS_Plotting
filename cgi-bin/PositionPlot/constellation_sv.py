#!/usr/bin/env python3
"""Parse per-constellation SV tracked/used counts from viewdat X29 rows."""

from __future__ import annotations

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
