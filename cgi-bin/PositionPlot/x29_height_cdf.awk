#! /usr/bin/awk -f
# x29_height_cdf. This output only the lines in which the GPS quailty is what the user asks

BEGIN {FS=","
       OFS=","
	if (ARGC != 2 || ARGV[1]=="?") {
	   print "x29_height_cdf.awk Records <FileName "
		print ""
      print "Takes a X29 file and report the height at 68% and 95%"
      print ""
	   print ""
	   print "OUTPUT:"
      print ""
	   print "string suitable for eval in bash that will set cdf_68 and cdf_95"
	   print ""   
	   print "JCMBsoft V1.0"
      print ""
	   exit  
           }

     Records= ARGV[1]
     Rec_68=int(Records*0.68)
     Rec_95=int(Records*0.95)
     ARGV[1] = ""
#     print Rec_68
#     print Rec_95
#     print Records

}

# By this time the file should have had GGKclean run on it so it is a good file.

 {
 if (NR==Rec_68) { 
    cdf_68=$13
    }
 if (NR==Rec_95) { 
    cdf_95=$13
    }
 }

 END {
     printf("cdf_68=%.4f;cdf_95=%.4f",cdf_68,cdf_95)
 }