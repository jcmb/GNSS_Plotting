#! /usr/bin/awk -f

BEGIN {
    FS = ","
    OFS = ","
    if (ARGC < 2 || ARGV[1] == "?") {
        print "x29_height_cdf.awk Records [field] <FileName"
        print ""
        print "Reports the sorted absolute error at 68% and 95% for field 11=N, 12=E, or 13=U."
        print "Default field is 13 (height)."
        print ""
        print "Outputs: cdf_68=...;cdf_95=..."
        print ""
        print "JCMBsoft V1.0"
        exit
    }

    Records = ARGV[1] + 0
    field = 13
    if (ARGC > 2 && ARGV[2] != "") {
        field = ARGV[2] + 0
    }
    ARGV[1] = ""
    ARGV[2] = ""

    if (Records < 1) {
        Rec_68 = 0
        Rec_95 = 0
    } else {
        Rec_68 = int(Records * 0.68)
        Rec_95 = int(Records * 0.95)
        if (Rec_68 < 1) Rec_68 = 1
        if (Rec_95 < 1) Rec_95 = 1
    }
}

{
    if (NR == Rec_68) {
        cdf_68 = $field
    }
    if (NR == Rec_95) {
        cdf_95 = $field
    }
}

END {
    if (Records < 1) {
        printf("cdf_68=0;cdf_95=0")
        exit
    }
    printf("cdf_68=%.4f;cdf_95=%.4f", cdf_68, cdf_95)
}
