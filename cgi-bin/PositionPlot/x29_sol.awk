# X29_SOL. This output only the lines in which the GPS quailty is what the user asks

BEGIN {FS=","
       OFS=","
	if (ARGC > 2 || ARGV[1]=="?") {
	   print "X29_SOL Solution_Type <FileName "
		print ""
      print "Takes a X29 file and filters the data to only output the"
	   print "records in which the solution type is a given type"	   
      print ""
	   print ""
	   print "OUTPUT:"
      print ""
	   print "Standard X29 file with only records in which position mode"
      print "is what was on the command line"
	   print ""   
	   print "JCMBsoft V1.0"
      print ""
	   exit  
           }
     Solution_Type = 4; #Default to RTK Fixed      
     if (ARGC==2) {  
        Solution_Type = ARGV[1]
        }
     ARGV[1] = ""

}

# By this time the file should have had GGKclean run on it so it is a good file.

 {
 if ($9 == Solution_Type) { 
    print
    }
 }
