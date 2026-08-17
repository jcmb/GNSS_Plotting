#!/usr/bin/env python3
"""Write a KML linestring from an X29/LLH comma-separated trajectory file."""

import sys

try:
    import simplekml
except ImportError:
    sys.stderr.write("simplekml is required\n")
    sys.exit(1)

if len(sys.argv) != 3:
    sys.stderr.write("Usage: {} <Point Name> <trajectory.csv>\n".format(sys.argv[0]))
    sys.exit(1)

name = sys.argv[1]
path = sys.argv[2]
coords = []

with open(path, "r", encoding="utf-8", errors="replace") as handle:
    for line in handle:
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
        coords.append((lon, lat, height))

if not coords:
    sys.stderr.write("No trajectory coordinates found\n")
    sys.exit(1)

kml = simplekml.Kml()
line = kml.newlinestring(name=name, coords=coords)
line.style.linestyle.width = 3
line.style.linestyle.color = simplekml.Color.blue
kml.save(name + ".kml")
