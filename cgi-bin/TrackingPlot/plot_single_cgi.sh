#! /bin/bash
# File Name, Ext, TrimbleTools, Decimate, Project
logger "plot_single_cgi.sh $1 $2 $3 $4 $5"
echo $1 " " $2 " " $3 " " $4 " " $5 "<br>"
ViewDat=viewdat
Ext=$2
FileFull=`basename $1`;
File=`basename $1 $2`;
Dir=`dirname $0`;
normalDir=`cd "${Dir}";pwd`
TrimbleTools=$3
Decimate=$4
Project=$5
#echo $PATH
PATH=${normalDir}:~/bin:$PATH


mkdir -p /mnt/Results/Tracking$Project/$File
cd /mnt/Results/Tracking$Project/$File && rm * 2> /dev/null
TMP_DIR=/run/shm

#set -o verbose
#set -o xtrace

echo $File > file.html
echo "Creating Week File"
WEEK=-2
WEEK=`$ViewDat -d19 $1 | Week_From_T19.pl`
echo GPS Week: $WEEK
#echo $TMP_DIR/$$.X27

if [ ! -f $1 ] 
then
   logger $1 " Does not exist"
   exit 100
else
logger $1 " Does exist"
fi

echo Creating x27 file for $File

echo "Decimation interval: " $Decimate

if [ "$Decimate" = -1 ]
then
   $ViewDat -d27 -x --translate_rec35_sub19_to_rec27 -o$TMP_DIR/$$.x27 $1 
   echo "Computing decimation interval" 
   eval $(compute_decimate.py $TMP_DIR/$$.x27)
   rm $TMP_DIR/$$.x27
fi

if [ $Decimate = 0 ]
then
    echo "No Decimation"
    echo "All Data, Interval($interval)">Decimation
    echo "Creating SNRs file for $File"
    $ViewDat -d27 --translate_rec35_sub19_to_rec27 -x $1 | X27_SNRs.py $WEEK
else
    echo "Decimation interval: " $Decimate
    echo "Orginal interval: " $interval
    echo "Every: $Decimate (s), orginal ($interval)">Decimation
    echo "Creating SNRs file for $File"
    $ViewDat --dec=$Decimate -d27 --translate_rec35_sub19_to_rec27 -x $1 | X27_SNRs.py $WEEK
fi



echo "Computing Bands used"
Calc_Bands.py | sort >Tracked.Bands


echo "Computing SV used"
Calc_SVs.py | sort >Tracked.SVs

echo "Computing Stats"
SNR_STATS.py

echo "Plotting Singles"
logger "Plotting Singles"
Plot_Single_SVs.py $File | gnuplot&

echo "Plotting All"
logger "Plotting all"
Plot_All_SVs.py $File | gnuplot&

wait

SNR_Warning.sh $File >Low_SNRs.html

#mv $$.x29 $File.X29
#mv $1 $FileFull
#rm $1


echo Processing completed
logger "Processing completed"
ln -s $normalDir/SNR_Plot.shtml
ln -s $normalDir/Tracking_Plot.shtml
ln -s $normalDir/Slips_Plot.shtml
ln -s $normalDir/SV_Tracking_Plot.shtml
ln -s $normalDir/Buttons.html
ln -s $normalDir/Tracking_Buttons.html
ln -s $normalDir/index.shtml
echo '</pre>'
#echo -n '<base href="http://trimbletools.com/results/TRACKING/'
#echo -n $File
#echo '/" />'
#cat index.shtml
echo "</body>"
echo "</html>"
