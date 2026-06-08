#! /bin/awk -f
# x29_height_cdf. This output only the lines in which the GPS quailty is what the user asks

BEGIN {FS=","
       OFS=","
	if (ARGC != 2 || ARGV[1]=="?") {
	   print "x29_height_cdf.awk Records <FileName "
		print ""
      print "Takes a X29 file and report the sigma (25) at 68% and 95%"
      print ""
	   print ""
	   print "OUTPUT:"
      print ""
	   print "string suitable for eval in bash that will set sigma_cdf_68 and sigma_cdf_95"
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
    cdf_68=$25
    }
 if (NR==Rec_95) { 
    cdf_95=$25
    }
 }

 END {
     printf("sigma_cdf_68=%.2f;sigma_cdf_95=%.2f",cdf_68,cdf_95)
 }