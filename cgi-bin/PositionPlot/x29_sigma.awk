#! /bin/awk -f
# X29_SOL. This output only the lines in which the GPS quailty is what the user asks

BEGIN {FS=","
       OFS=","
       OFMT="%0.4f"
	if (ARGC > 1 || ARGV[1]=="?") {
	   print "X29_height_abs <FileName "
		print ""
      print "Takes a X29 file and converts the height, field 13,  which will be an error, to absolute error"
      print "Takes a X29 file and converts the sigma, field 25, to the rato of error to sigma"
      print ""
	   print ""
	   print "OUTPUT:"
      print ""
	   print "Standard X29 file with the height as an absolute value"
      print "is what was on the command line"
	   print ""   
	   print "JCMBsoft V1.0"
      print ""
	   exit  
           }
}


function abs(value)
{
    return (value<0?-value:value);
}

# By this time the file should have had GGKclean run on it so it is a good file.

 {
     $13=abs($13)
     $25=$13/$25
    print
 }
