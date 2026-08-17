#! /usr/bin/awk -f

BEGIN {
    FS = ","
    OFS = ","
    OFMT = "%0.4f"
    if (ARGV[1] == "?") {
        print "x29_sigma [n|e|u] <FileName"
        print ""
        print "Writes |error|/sigma ratio into field 25 for sorted CDF processing."
        print "  u (default): |U| / vertical precision (field 25)"
        print "  n: |N| / horizontal precision (field 24)"
        print "  e: |E| / horizontal precision (field 24)"
        print ""
        print "JCMBsoft V1.0"
        exit
    }
    component = "u"
    if (ARGC > 1 && ARGV[1] != "") {
        component = ARGV[1]
    }
    for (i = 1; i < ARGC; i++) {
        ARGV[i] = ""
    }
}

function abs(value) {
    return (value < 0 ? -value : value)
}

{
    if (component == "n") {
        $11 = abs($11)
        $25 = ($24 != 0 && $24 != "") ? $11 / $24 : 0
    } else if (component == "e") {
        $12 = abs($12)
        $25 = ($24 != 0 && $24 != "") ? $12 / $24 : 0
    } else {
        vprec = $25
        $13 = abs($13)
        $25 = (vprec != 0 && vprec != "") ? $13 / vprec : 0
    }
    print
}
