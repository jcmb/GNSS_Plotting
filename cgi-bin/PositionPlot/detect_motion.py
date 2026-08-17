#!/usr/bin/env python3
"""Detect moving vs static session using 2D error / horizontal sigma outliers."""

import math
import sys

SIGMA_THRESHOLD = 10.0
FRACTION_THRESHOLD = 0.01

valid = 0
outliers = 0

for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    fields = line.replace(" ", "").split(",")
    if len(fields) < 24:
        continue
    try:
        north = float(fields[10])
        east = float(fields[11])
        hprec = float(fields[23])
    except ValueError:
        continue
    if hprec <= 0:
        continue
    h_sigma = math.sqrt(2.0) * hprec
    ratio_2d = math.hypot(north, east) / h_sigma
    valid += 1
    if ratio_2d > SIGMA_THRESHOLD:
        outliers += 1

if valid == 0:
    fraction = 0.0
    detected = "static"
else:
    fraction = outliers / valid
    detected = "moving" if fraction > FRACTION_THRESHOLD else "static"

print("detected: {}".format(detected))
print("outlier_fraction: {:.2f}".format(fraction * 100.0))
print("outlier_count: {}".format(outliers))
print("valid_count: {}".format(valid))
