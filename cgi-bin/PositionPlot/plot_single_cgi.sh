#! /bin/bash

logger "Plot_single_cgi start $1   $2   $3   $4   $5   $6    $7   $8 $9"
logger `whoami`
#echo $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8 "<br>"
# $upload_file,$extension,$Sol,$Point,$Ant,$Decimate,$Fixed_Range,$project;
#set -x

Ext=$2
Sol=$3
FileFull=`basename $1`;
File=`basename $1 $2`;
Dir=`dirname $0`;
normalDir=`cd "${Dir}";pwd`
#echo $PATH
PATH=${normalDir}:/usr/local/bin:~/bin:$PATH
Point=$4
Ant=$5
#TrimbleTools=$6
Decimate=$6
Fixed_Range=$7
Project=$8
SaveFile=$9

echo "Point $Point"
echo "Project $Project"

if [ ! $Point = -1 ]
then
   Project=$Project/$Point
fi
echo "Project $Project"
logger "Project $Project"

if [ $Sol = -1 ]
then
   Sol=""
   echo "Solution type is not provided"
fi

#export PATH
#echo "$FileFull<br>$File<br>"
#ls -l $1

. $normalDir/JCMBSoft_Config.sh
GNSS_CFG_DIR=`cd "$normalDir/../../admin/GNSS" 2>/dev/null && pwd`
if [ -z "$GNSS_CFG_DIR" ] || [ ! -f "$GNSS_CFG_DIR/GNSS_Paths.cfg" ]
then
   GNSS_CFG_DIR=/mnt/GPS_Admin/admin/GNSS
fi
if [ -f "$GNSS_CFG_DIR/GNSS_Paths.cfg" ]
then
   . "$GNSS_CFG_DIR/GNSS_Paths.cfg"
fi
if [ -z "$GNSS_RESULTS_DIR" ]
then
   GNSS_RESULTS_DIR=/mnt/Results
fi

RESULT_DIR="$GNSS_RESULTS_DIR/Position$Project/$File"
logger "$RESULT_DIR"
mkdir -p "$RESULT_DIR"
cd "$RESULT_DIR" && rm * 2> /dev/null
TMP_DIR=/run/shm/

logger `pwd`

echo Creating X29 file for $File
logger "Creating X29 file for $File"

viewdat -d29 --translate_rec35_sub2_to_rec29 -x -o$TMP_DIR$$.x29 $1

#viewdat -i -ofile.sum $1

#wait

#rm $1

# Skipping creating the file
#   echo "Decimation interval: " $Decimate

if [ "$Decimate" = -1 ]
then
   echo "Computing decimation interval"
   eval $(compute_decimate.py $TMP_DIR$$.x29)
fi

if [ $Decimate = 0 ]
then
   echo "No Decimation"
   echo "All Data">Decimation
   tail -n +5 $TMP_DIR$$.x29 > $TMP_DIR$File.X29
else
   echo "Decimation interval: " $Decimate
   echo "Orginal interval: " $interval
   echo "Every: $Decimate (s), orginal ($interval)">Decimation
   echo Creating Decimated file for $File
   decimate.py $Decimate <$TMP_DIR$$.x29 > $TMP_DIR$File.X29
#   cp $1 $FileFull

fi

if [ "$SaveFile" = 1 ]
then
    mv $TMP_DIR$$.x29 $File.x29
    echo "<a href=\"$File.x29\">$File.x29<a/>">SaveFile.html

else
    rm $TMP_DIR$$.x29
    echo "Not Saved">SaveFile.html
fi


echo name="'$File: '" >file.plt
echo "$File" >file.html


#ln  -f $File.X29 file

$normalDir/x29_secs.py <$TMP_DIR$File.X29 >file
$normalDir/gnuplot file.plt $normalDir/X29_sol.plt

#echo "Solution Type $Sol";

echo "Checking database for $Point"

#$normalDir/GNSS_TRUTH.py $Point

eval $($normalDir/GNSS_TRUTH.py $Point)

eval $(original-awk -f $normalDir/x29_sol_type.awk $Sol < $TMP_DIR$File.X29);
echo "Solution Type $Sol_Name ($Sol)";

if [ "$Lat" == "" ]
then
    eval $(original-awk -f $normalDir/x29_mean2.awk $Sol <$TMP_DIR$File.X29)
    echo "Computed" > llh.mean

else
    echo "Truth from point database"
    echo "From Database" > llh.mean
fi

echo "Latitude $Lat"
echo "Longitude $Long"
echo "Height $Height"
echo "Records $Records"

echo "Latitude: $Lat" >> llh.mean
echo "Longitude: $Long" >> llh.mean
echo "Height: $Height" >> llh.mean
#echo "Records: $Records" >> llh.mean


$normalDir/kml_point.py $File $Lat $Long $Height

echo "</pre>"
echo "<a href=\"$File.kml\">$File.kml</a>"
echo "<a href=\"$File.kml\">$File.kml</a>">kml.html
echo "<pre>"


original-awk -f $normalDir/x29_sum.awk $Sol <$TMP_DIR$File.X29 | tee sum.txt

if [ $Sol ]
then
   original-awk -f $normalDir/x29_sol.awk $Sol <$TMP_DIR$File.X29 >$File.sol
   rm $TMP_DIR$File.X29
else
   mv $TMP_DIR$File.X29 $File.sol
fi


echo "Computing NEE Deltas"
original-awk -f $normalDir/x29_enu.awk $File.sol $Lat $Long $Height  >$File.enu

rm $File.sol

echo ""
echo "Computing NEE Mean"
eval $(original-awk -f $normalDir/x29_mean2_enu.awk $Sol $Sol_HRange $Sol_VRange $Fixed_Range <$File.enu)


eval $(original-awk -f $normalDir/x29_height_abs.awk < $File.enu |  sort --field-separator=, --numeric-sort --key=13 | original-awk -f $normalDir/x29_height_cdf.awk $Records )
eval $(original-awk -f $normalDir/x29_sigma.awk < $File.enu |  sort --field-separator=, --numeric-sort --key=25 | original-awk -f $normalDir/x29_sigma_cdf.awk $Records )

echo "North: $North" | tee  nee.mean
echo "North Min: $North_Min" | tee  -a nee.mean
echo "North Max: $North_Max" | tee  -a nee.mean
echo "North Range: $North_Range" | tee  -a nee.mean
echo ""| tee -a nee.mean
echo "East: $East" | tee -a nee.mean
echo "East Min: $East_Min" | tee  -a nee.mean
echo "East Max: $East_Max" | tee  -a nee.mean
echo "East Range: $East_Range" | tee  -a nee.mean
echo ""| tee -a nee.mean
echo "Elev: $Elev" | tee -a nee.mean
echo "Elev Min: $Elev_Min" | tee  -a nee.mean
echo "Elev Max: $Elev_Max" | tee  -a nee.mean
echo "Elev Range: $Elev_Range" | tee  -a nee.mean
echo "Elev 68%: $cdf_68" | tee  -a nee.mean
echo "Elev 95%: $cdf_95" | tee  -a nee.mean
echo ""| tee -a nee.mean
echo "Elev Sigma 68%: $sigma_cdf_68" | tee  -a nee.mean
echo "Elev Sigma 95%: $sigma_cdf_95" | tee  -a nee.mean
echo ""| tee -a nee.mean
echo "Fixed Range: $Fixed_Range"  | tee  -a nee.mean
echo "Horizontal Range for plotting $Sol_HRange"  | tee  -a nee.mean
echo "Vertical Range for plotting $Sol_VRange"  | tee  -a nee.mean
echo "3D Range: $Sol_3DRange" | tee  -a nee.mean
echo ""| tee -a nee.mean
echo "Records: $Records" | tee -a nee.mean
echo ""| tee -a nee.mean


echo Plotting file for $FileFull
logger "Plotting file for $FileFull"

echo name="'$File, $Sol_Name: '" >file.plt
echo sol_type="'$Sol_Name'" >>file.plt
echo hrange=$Sol_HRange >>file.plt
echo vrange=$Sol_VRange >>file.plt
echo D3Range=$Sol_3DRange >>file.plt
echo latency=$Sol_Latency >>file.plt
echo records=$Records >>file.plt
echo "$FileFull" >file.html
#cp $normalDir/plot_index.html index.shtml
mv $File.enu file
cp file position_data.csv
#echo "pwd $PWD\n"
#echo "gnuplot file.plt $normalDir/X29_plot.plt\n"

$normalDir/gnuplot file.plt $normalDir/X29_plot.plt

$normalDir/out_range.py -R 0.0105 < file --OUTAGE outage1cm.csv --DETAIL /dev/null --SUMMARY range1cm.sum
$normalDir/out_range.py -R 0.0205 < file --OUTAGE outage2cm.csv --DETAIL /dev/null --SUMMARY range2cm.sum
$normalDir/out_range.py -R 0.0305 < file --OUTAGE outage2sig.csv --DETAIL range2sig.csv --SUMMARY range2sig.sum
$normalDir/out_range.py -R 0.0455 < file --OUTAGE outage3sig.csv --DETAIL range3sig.csv --SUMMARY range3sig.sum
#wait

$normalDir/gnuplot file.plt $normalDir/range.plt
$normalDir/gnuplot file.plt $normalDir/range_hist.plt


range_1cm=`$normalDir/range_summary.pl <range1cm.sum`
range_2cm=`$normalDir/range_summary.pl <range2cm.sum`
range_2_sigma=`$normalDir/range_summary.pl <range2sig.sum`
range_3_sigma=`$normalDir/range_summary.pl <range3sig.sum`
echo -n "$File," > $File.sum.csv
echo -n "$Elev_Range," >> $File.sum.csv
echo -n "$cdf_68," >> $File.sum.csv
echo -n "$cdf_95," >> $File.sum.csv
echo -n "$sigma_cdf_68," >> $File.sum.csv
echo -n "$sigma_cdf_95," >> $File.sum.csv
echo -n "$range_1cm," >> $File.sum.csv
echo -n "$range_2cm," >> $File.sum.csv
echo -n "$range_2_sigma," >> $File.sum.csv
echo  "$range_3_sigma" >> $File.sum.csv

echo "<a href=\"$File.sum.csv\">$File.sum.csv</a>">sum.html

#wait
#rm file
echo '</pre>'
#echo -n '<base href="http://trimbletools.com/results/Position/'
#echo -n $File
#echo '/" />'
cp $normalDir/index.shtml .
ln -sf $normalDir/interactive_plot.js
cat index.shtml
rm outage1cm.csv
rm outage2cm.csv
rm outage2sig.csv
rm outage3sig.csv
#rm range1cm.csv
#rm range2cm.csv
rm range2sig.csv
rm range3sig.csv
rm file
wait
echo Plotting completed 
logger "Plot_single_cgi finished $1 * $2 * $3 * $4 * $5 * $6 *  $7 * $8"
