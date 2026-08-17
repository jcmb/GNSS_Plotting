#!/usr/bin/env python3
"""General trajectory summary for moving sessions (no fixed reference)."""

import math
import sys

records = 0
lat_min = lat_max = lon_min = lon_max = height_min = height_max = None
path_m = 0.0
prev_lat = prev_lon = None

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    fields = line.replace(" ", "").split(",")
    if len(fields) < 13:
        continue
    try:
        lat = float(fields[10])
        lon = float(fields[11])
        height = float(fields[12])
    except ValueError:
        continue

    records += 1
    lat_min = lat if lat_min is None else min(lat_min, lat)
    lat_max = lat if lat_max is None else max(lat_max, lat)
    lon_min = lon if lon_min is None else min(lon_min, lon)
    lon_max = lon if lon_max is None else max(lon_max, lon)
    height_min = height if height_min is None else min(height_min, height)
    height_max = height if height_max is None else max(height_max, height)

    if prev_lat is not None:
        r = 6378137.0
        dlat = math.radians(lat - prev_lat)
        dlon = math.radians(lon - prev_lon)
        a = math.sin(dlat / 2.0) ** 2 + math.cos(math.radians(prev_lat)) * math.cos(math.radians(lat)) * math.sin(dlon / 2.0) ** 2
        path_m += 2.0 * r * math.asin(min(1.0, math.sqrt(a)))
    prev_lat = lat
    prev_lon = lon

if records == 0:
    sys.exit(0)

print("Records: {}".format(records))
print("Latitude min: {:.8f}".format(lat_min))
print("Latitude max: {:.8f}".format(lat_max))
print("Longitude min: {:.8f}".format(lon_min))
print("Longitude max: {:.8f}".format(lon_max))
print("Height min: {:.4f} m".format(height_min))
print("Height max: {:.4f} m".format(height_max))
print("Height range: {:.4f} m".format(height_max - height_min))
print("Path length: {:.1f} m".format(path_m))
