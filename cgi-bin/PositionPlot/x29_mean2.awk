#! /usr/bin/awk
BEGIN {
    FS = ","
    OFS = ","
    OFMT = "%2.10f"
    if (ARGC != 2) {
        print "X29_MEAN [Solution Type] <FileName "
        print ""
        print "Takes a X29 file and computes the mean for the LLH's of that solution type. RTK Fixed (4) if no solution type is passed"
        print ""
        print "Outputs the mean in a format easy to use in a script"
        print ""
        print "Note that I mention LLH, the file could be in ENU as well"
        print ""
        print ""
        print "JCMBsoft V1.0"
        print ""
        exit
    }
    mean_lat = 0.0
    mean_long = 0.0
    mean_height = 0.0
    M2_lat = 0.0
    M2_long = 0.0
    M2_height = 0.0

    Solution_Type = 4
    All_Types = 0
    if (ARGC == 2) {
        if (ARGV[1] == "all") {
            All_Types = 1
        } else if (ARGV[1] != "") {
            Solution_Type = ARGV[1]
        }
    }
    ARGV[1] = ""
    Records = 0
}

{
    if (All_Types || $9 == Solution_Type) {
        Records++
        lat = $11 + 0
        long = $12 + 0
        height = $13 + 0

        delta = lat - mean_lat
        mean_lat += delta / Records
        M2_lat += delta * (lat - mean_lat)

        delta = long - mean_long
        mean_long += delta / Records
        M2_long += delta * (long - mean_long)

        delta = height - mean_height
        mean_height += delta / Records
        M2_height += delta * (height - mean_height)
    }
}

END {
    if (Records == 0) {
        printf("Lat=0;Long=0;Height=0;Records=0;Lat_Std=0;Long_Std=0;Height_Std=0\n")
        exit
    }

    if (Records > 1) {
        lat_var = M2_lat / (Records - 1)
        long_var = M2_long / (Records - 1)
        height_var = M2_height / (Records - 1)
        if (lat_var < 0) lat_var = 0
        if (long_var < 0) long_var = 0
        if (height_var < 0) height_var = 0
        lat_std = sqrt(lat_var)
        long_std = sqrt(long_var)
        height_std = sqrt(height_var)
    } else {
        lat_std = 0
        long_std = 0
        height_std = 0
    }

    printf("Lat=%2.10f;Long=%2.10f;Height=%2.10f;Records=%d;Lat_Std=%.10f;Long_Std=%.10f;Height_Std=%.10f\n", mean_lat, mean_long, mean_height, Records, lat_std, long_std, height_std)
}
