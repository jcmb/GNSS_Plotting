#! /usr/bin/awk
# Format mean/reference LLH for llh.mean (combined table with std dev in mm).

BEGIN {
    OFMT = "%.10f"
    PI = 3.141592653589793
    M_PER_DEG_LAT = 111320
    _write_report()
    exit
}

function absv(x) {
    return (x < 0) ? -x : x
}

function format_dms(coord, is_latitude,    hemi, a, d, m, s) {
    if (is_latitude) {
        hemi = (coord >= 0) ? "N" : "S"
    } else {
        hemi = (coord >= 0) ? "E" : "W"
    }
    a = absv(coord + 0)
    d = int(a)
    m = int((a - d) * 60)
    s = (a - d - m / 60) * 3600
    return sprintf("%d° %02d' %08.5f\" %s", d, m, s, hemi)
}

function std_lat_mm(std_deg) {
    return (std_deg + 0) * M_PER_DEG_LAT * 1000
}

function std_lon_mm(std_deg, lat_deg) {
    return (std_deg + 0) * M_PER_DEG_LAT * cos(lat_deg * PI / 180) * 1000
}

function std_height_mm(std_m) {
    return (std_m + 0) * 1000
}

function fmt_std_mm(value,    v) {
    v = value + 0
    if (v != v || v < 0) {
        return "n/a"
    }
    if (v > 0 && v < 0.01) {
        return sprintf("%.4f", v)
    }
    return sprintf("%.2f", v)
}

function _write_report(    lat_v, lon_v, height_v, records_v, lat_std_v, lon_std_v, height_std_v, lat_std_mm_v, lon_std_mm_v, height_std_mm_v) {
    lat_v = lat + 0
    lon_v = lon + 0
    height_v = height + 0
    records_v = records + 0
    lat_std_v = lat_std + 0
    lon_std_v = lon_std + 0
    height_std_v = height_std + 0
    lat_std_mm_v = "n/a"
    lon_std_mm_v = "n/a"
    height_std_mm_v = "n/a"

    if (mode == "computed") {
        print "Computed"
        if (records_v > 1) {
            lat_std_mm_v = fmt_std_mm(std_lat_mm(lat_std_v))
            lon_std_mm_v = fmt_std_mm(std_lon_mm(lon_std_v, lat_v))
            height_std_mm_v = fmt_std_mm(std_height_mm(height_std_v))
        }
    } else {
        print "Database"
    }

    print "REFERENCE_TABLE"
    print "Latitude|" sprintf("%.10f", lat_v) "|" format_dms(lat_v, 1) "|" lat_std_mm_v
    print "Longitude|" sprintf("%.10f", lon_v) "|" format_dms(lon_v, 0) "|" lon_std_mm_v
    print "Height|" sprintf("%.4f", height_v) "|" sprintf("%.4f", height_v) " m|" height_std_mm_v
    print "END_REFERENCE_TABLE"
}

END {
    # unused; report runs in BEGIN so no stdin is required
}
