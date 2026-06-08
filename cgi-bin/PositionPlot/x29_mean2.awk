#! /usr/bin/awk 
BEGIN {FS=","
       OFS=","
       OFMT="%2.10f"
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
     Lat_Total = 0.0
     Long_Total = 0.0
     Height_Total = 0.0

     Solution_Type = 4; #Default to RTK Fixed
     if (ARGC==2) {
        Solution_Type = ARGV[1]
     }
     ARGV[1] = ""
     Records = 0;

}

# By this time the file should have had GGKclean run on it so it is a good file.

 {
     if ($9 == Solution_Type) {
        Lat_Total += $11
        Long_Total += $12
        Height_Total += $13
        Records++;
     }
 }

END {
    printf ("Lat=%2.10f;Long=%2.10f;Height=%2.10f;Records=%1i\n", Lat_Total / (Records) , Long_Total / (Records) , Height_Total / (Records), Records);
   }