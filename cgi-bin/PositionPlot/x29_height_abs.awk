#! /usr/bin/awk -f

BEGIN {
    FS = ","
    OFS = ","
    OFMT = "%0.4f"
    if (ARGV[1] == "?") {
        print "x29_height_abs [field] <FileName"
        print ""
        print "Converts the given ENU error field (11=N, 12=E, 13=U) to absolute value."
        print "Default field is 13 (height)."
        print ""
        print "JCMBsoft V1.0"
        exit
    }
    field = 13
    if (ARGC > 1 && ARGV[1] != "") {
        field = ARGV[1] + 0
    }
    for (i = 1; i < ARGC; i++) {
        ARGV[i] = ""
    }
}

function abs(value) {
    return (value < 0 ? -value : value)
}

{
    $field = abs($field)
    print
}
