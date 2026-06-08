#! /usr/bin/awk
BEGIN {FS=","
       OFS=","
       OFMT="%2.10f"
	if (ARGC <2) {
	   print "X29_MEAN2_enu <Solution Type> <Expected H Range> <Expected V Range> <Fixed Range><FileName "
           print ""
           print "Takes a X29 file and computes the mean for the LLH's of that solution type. RTK Fixed (4) if no solution type is passed"        
           print ""
           print "Outputs the mean in a format easy to use in a script"
           print ""
           print "Note that I mention LLH, the file could be in ENU as well"
           print ""
           print ""
	       print "JCMBsoft V1.2"
           print ""
	       exit  
           }
     North_Total = 0.0
     East_Total = 0.0
     Elev_Total = 0.0
   
     North_Min  =  1000000;
     North_Max  = -1000000;
     East_Min  =  1000000;
     East_Max  = -1000000;
     Elev_Min  =  1000000;
     Elev_Max  = -1000000;
     Sol_HRange = 0.1;
     Sol_VRange = 0.1;
     Sol_3DRange = Sol_VRange;
     Fixed_Range=0;

#     print "ARGC "   ARGC  "\n"
     Solution_Type = 4; #Default to RTK Fixed
     if (ARGC>=2) {
	 Solution_Type = ARGV[1];
     }

     if (ARGC>=4) {
	 Sol_HRange = ARGV[2];
	 Sol_VRange = ARGV[3];
     }


     if (ARGC>=5) {
	 Fixed_Range = ARGV[4]+0; 
#         print "Fix Range provided "   Compute_Range   "\n" ; 
    }

     ARGV[4] = ""
     ARGV[3] = ""
     ARGV[2] = ""
     ARGV[1] = ""
     Records = 0;

}


 {
     if ($9 == Solution_Type) {
        North_Total += $11
        if (North_Min > $11) {North_Min = $11};
        if (North_Max < $11) {North_Max = $11};
        East_Total += $12
        if (East_Min > $12) {East_Min = $12};
        if (East_Max < $12) {East_Max = $12};
        Elev_Total += $13
        if (Elev_Min > $13) {Elev_Min = $13};
        if (Elev_Max < $13) {Elev_Max = $13};
        Records++;
     }
 }

END {
 	if (Fixed_Range != 1 ) {
#	    print "Computed range\n"
	    if (North_Min < -Sol_HRange) {Sol_HRange = -North_Min};
	    if (North_Min > Sol_HRange) {Sol_HRange = North_Max};

	    if (East_Min < -Sol_HRange) {Sol_HRange = -East_Min};
	    if (East_Max > Sol_HRange) {Sol_HRange = East_Max};

	    if (Elev_Min < -Sol_VRange) {Sol_VRange = -Elev_Min};
	    if (Elev_Max > Sol_VRange) {Sol_VRange = Elev_Max};

	    if (Sol_VRange > Sol_HRange) {
		Sol_3DRange = Sol_VRange;
	    }
	    else {
		Sol_3DRange = Sol_HRange;
	    }
	}
	

	printf ("North=%2.10f;East=%2.10f;Elev=%2.10f;Records=%1i;North_Min=%2.4f;North_Max=%2.4f;North_Range=%2.4f;East_Min=%2.4f;East_Max=%2.4f;East_Range=%2.4f;Elev_Min=%2.4f;Elev_Max=%2.4f;Elev_Range=%2.4f;Sol_HRange=%2.3f;Sol_VRange=%2.3f;Sol_3DRange=%2.3f\n", North_Total / (Records) , East_Total / (Records) , Elev_Total / (Records), Records, North_Min, North_Max,North_Max-North_Min,East_Min,East_Max,East_Max-East_Min,Elev_Min,Elev_Max,Elev_Max-Elev_Min,Sol_HRange,Sol_VRange,Sol_3DRange);
}