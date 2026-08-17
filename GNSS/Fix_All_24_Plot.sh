#! /bin/bash

   
#cd /Volumes/GPS_MYSQL/GPS_Data/BTN/24_HOUR
logger "Fix_All_24_Plot.sh started"
logger "Fix_All_24_Plot.sh user" `whoami`
logger "Fix_All_24_Plot.sh path $PATH"

cd /mnt/hgfs/results/Tracking/BTN
shopt -s nullglob
for d in *
do
#   cd /Volumes/GPS_MYSQL/GPS_Data/BTN/24_HOUR/$d
    echo "Processing base: $d"
    cd /mnt/hgfs/results/Tracking/BTN/$d
    for d2 in *
       do
        cd /mnt/hgfs/results/Tracking/BTN/$d/$d2
        echo "Processing File: $d2"
#   /Volumes/GPS_MYSQL/admin/Plot_File_Script.sh BTN $d *.T02
	if [ ! -f Low_SNRs_Table.html ] 
	   then
	   echo "$d $d2 Reprocessing"
           /usr/lib/cgi-bin/Tracking/Plot_Single_SVs.py $d2 > /dev/null
           /usr/lib/cgi-bin/Tracking/Plot_All_SVs.py $d2 > /dev/null
           /usr/lib/cgi-bin/Tracking/SNR_Warning.sh $d2 >Low_SNRs.html
#           (/usr/lib/cgi-bin/Tracking/Plot_Single_SVs.py $d | gnuplot)&
#           (/usr/lib/cgi-bin/Tracking/Plot_All_SVs.py $d | gnuplot)&
	   wait
#        else 
#           (/usr/lib/cgi-bin/Tracking/Plot_Single_SVs.py $d | gnuplot)&
#           (/usr/lib/cgi-bin/Tracking/Plot_All_SVs.py $d | gnuplot)&
#	   wait

	   fi
        done
done


