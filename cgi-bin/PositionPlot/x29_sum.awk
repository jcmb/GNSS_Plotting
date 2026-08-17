BEGIN {
   FS=",";
   Latency[0]=0;
   Latency[1]=0;
   Latency[2]=0;
   Latency[3]=0;
   Latency[4]=0;
   Latency[5]=0;
   Latency[6]=0;
   
   for (i=0;i<=50;i++) {
      Pos[i] = 0.0;
      Unused[i] = 0.0;
      }

   Fixed=0;
   Current=0;

   Name[0]="Autonomous";
   Name[1]="RTCM";
   Name[2]="SBAS";
   Name[3]="Float";
   Name[4]="Fixed";
   Name[5]="OmniSTAR";
   Name[6]="Wide-area Fixed";
   Name[7]="Wide-area Float";
   Name[8]="Type 8";
   Name[9]="Kalman Auton";
   Name[10]="Kalman DGNSS";
   Name[11]="Kalman SBAS";
   Name[15]="RTX";
   Name[28]="xFill";
   Name[37]="QZSS";
   Name[41]="HAS";

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

function pct(count, total) {
   if (total <= 0) {
      return "0.0";
   }
   return sprintf("%.1f", count / total * 100);
}

function type_name(i) {
   if (i in Name) {
      return Name[i];
   }
   return "Type " i;
}

END {
 print "Total Records: " NR;
 print "Filtered Records: " Count;
 print "==================";
 print ""; 
 print "Solution Age Report:"
 print "====================";
 print " 0 sec Latency: " Latency[0] " (" pct(Latency[0], Count) "%)";
 print "<1 sec Latency: " Latency[1] " (" pct(Latency[1], Count) "%)";
 print "<2 sec Latency: " Latency[2] " (" pct(Latency[2], Count) "%)";
 print "<3 sec Latency: " Latency[3] " (" pct(Latency[3], Count) "%)";
 print "<4 sec Latency: " Latency[4] " (" pct(Latency[4], Count) "%)";
 print "<5 sec Latency: " Latency[5] " (" pct(Latency[5], Count) "%)";
 print ">5 sec Latency: " Latency[6] " (" pct(Latency[6], Count) "%)";

 print ""; 
 print "Position Type Report:";
 print "=====================";

 for (i = 0; i <= 50; i++) {
    if (Pos[i] > 0) {
       printf "%-17s %d (%s%%)\n", type_name(i) ":", Pos[i], pct(Pos[i], NR);
    }
 }
 if (Fixed > 0) {
    printf "%-17s %d (%s%%)\n", "RTX (Fixed):", Fixed, pct(Fixed, NR);
 }
 if (Current > 0) {
    printf "%-17s %d (%s%%)\n", "RTX (Current):", Current, pct(Current, NR);
 }

 
 print ""; 
 print "Unused SV's Report: For Solution type " Filter_On ;
 print "===================";
 print "All SV's Used: " Unused[0] " (" pct(Unused[0], Count) "%)";
 for (i=1;i<=10;i++) {
    print i " unused: " Unused[i] " (" pct(Unused[i], Count) "%)";
    }  

 }