BEGIN {
   FS=",";
   Latency[0]=0;
   Latency[1]=0;
   Latency[2]=0;
   Latency[3]=0;
   Latency[4]=0;
   Latency[5]=0;
   Latency[6]=0;
   
   for (i=0;i<=20;i++) {
      Pos[i] = 0.0;
      Unused[i] = 0.0;
      }

   Fixed=0;
   Current=0;

   OFMT="%0.0f";
   Filter_On="";
   if (ARGC > 1) {
      Filter_On=ARGV[1]
      #print "Unused SV count for solution type: " Filter_On "\n";
      ARGV[1]="";
      Filter_On = Filter_On + 0;
      }
   Count=0;
   }
  
   
{

Pos[$9] = Pos[$9]+1.0;

if ($9==15) {

    if ($10==2) {
        Fixed++
    }

    if ($10==1) {
        Current++
    }

}

#print Pos[6] " " $9
#print $9 " " Filter_On;

if (Filter_On == "" || $9==Filter_On) {
   Count++
   Unused[$4-$5]++;
   if ($29 == 0) {
      Latency[0]++;
      }
   else  
      {
      if ($29 <= 1) 
         {
         Latency[1]++;
         }
      else 
         {
         if ($29 <= 2) 
            {
            Latency[2]++;
            }
         else 
            {
            if ($29 <= 3) 
               {
               Latency[3]++;
               }
            else  
               {
               if ($29 <= 4)   
                  {
                  Latency[4]++;
                  }
               else {
                  if ($29 <= 5) 
                     {
                     Latency[5]++;
                     }
                  else 
                     {
                     Latency[6]++;
                     }
                  }
               }
            }
         }
      }
   }
}

END {
 print "Total Records: " NR;
 print "Filtered Records: " Count;
 print "==================";
 print ""; 
 print "Solution Age Report:"
 print "====================";
 print " 0 sec Latency: " Latency[0] " (" Latency[0]/Count* 100  "%)";
 print "<1 sec Latency: " Latency[1] " (" Latency[1]/Count* 100  "%)";
 print "<2 sec Latency: " Latency[2] " (" Latency[2]/Count* 100  "%)";
 print "<3 sec Latency: " Latency[3] " (" Latency[3]/Count* 100  "%)";
 print "<4 sec Latency: " Latency[4] " (" Latency[4]/Count* 100  "%)";
 print "<5 sec Latency: " Latency[5] " (" Latency[5]/Count* 100  "%)";
 print ">5 sec Latency: " Latency[6] " (" Latency[6]/Count* 100  "%)";

 print ""; 
 print "Position Type Report:";
 print "=====================";
  
 print "Autonomous:      " Pos[0] " ("Pos[0]/NR* 100  "%)";
 print "RTCM:            " Pos[1] " ("Pos[1]/NR* 100  "%)";
 print "SBAS:            " Pos[2] " ("Pos[2]/NR* 100  "%)";
 print "Float:           " Pos[3] " ("Pos[3]/NR* 100  "%)";
 print "Fixed:           " Pos[4] " ("Pos[4]/NR* 100  "%)";
 print "Type 5:          " Pos[5] " ("Pos[5]/NR* 100  "%)";
 print "Wide-area Fixed: " Pos[6] " ("Pos[6]/NR* 100  "%)";
 print "Wide-area Float: " Pos[7] " ("Pos[7]/NR* 100  "%)";
 print "Type 8:          " Pos[8] " ("Pos[8]/NR* 100  "%)";
 print "Kalman Auton:    " Pos[9] " ("Pos[9]/NR* 100  "%)";
 print "Kalman DGNSS:    " Pos[10] " ("Pos[10]/NR* 100  "%)";
 print "Kalman SBAS:     " Pos[11] " ("Pos[11]/NR* 100  "%)";
 print "RTX:             " Pos[15] " ("Pos[15]/NR* 100  "%)";
 print "RTX (Fixed):     " Fixed " (" Fixed/NR* 100  "%)";
 print "RTX (Current):   " Current " (" Current/NR* 100  "%)";
# for (i=10;i<=20;i++) {
#    print "Type " i ":        " Pos[i] " ("Pos[i]/NR* 100"%)";
#    }  

 
 print ""; 
 print "Unused SV's Report: For Solution type " Filter_On ;
 print "===================";
 print "All SV's Used: " Unused[0] " ("Unused[0]/NR* 100"%)";
 for (i=1;i<=10;i++) {
    print i " unused: " Unused[i] " ("Unused[i]/NR* 100"%)";
    }  

 }