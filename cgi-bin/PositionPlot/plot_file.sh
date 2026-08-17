#! /bin/bash
#echo $1 "*" $2 "*" $3 "<br>"
echo $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9 "<br>"
# $upload_file,$extension,$Sol,$Point,$Ant,$TrimbleTools,$Decimate,$Fixed_Range,$project;
#set -x

TrimbleTools=1
ALL_SOL_TYPES=0

if [ "$Sol" = "-2" ]
then
   ALL_SOL_TYPES=1
   Sol=""
elif [ "$Sol" = "-1" ]
then
   Sol=""
   echo "Solution type is automatically computed"
fi

#export PATH
#echo "$FileFull<br>$File<br>"
#ls -l $1


if [ "$TrimbleTools" = 1 ]
then
   echo "TrimbleTools"
   mkdir -p ~/public_html/results/Position$Project/$File
   cd ~/public_html/results/Position$Project/$File  && rm * 2> /dev/null
   TMP_DIR=~/tmp
else
    echo "Non Trimble Tools"
    mkdir -p /var/www/html/results/Postion$Project/$File
    cd /var/www/html/results/Position$Project/$File && rm * 2> /dev/null
    TMP_DIR=/run/shm
fi


rm $$.x29

echo "$File" >file.html

#echo "Solution Type $Sol";

if [ "$ALL_SOL_TYPES" = "1" ]
then
   Sol_Name="All Types"
   Sol_HRange=5
   Sol_VRange=10
   Sol_Latency=0
   Sol_3DRange=10
else
   eval $(awk -f $normalDir/x29_sol_type.awk $Sol < $File.X29);
fi
echo "Solution Type $Sol_Name ($Sol)";


if [ "$ALL_SOL_TYPES" = "1" ]
then
   eval $(awk -f $normalDir/x29_mean2.awk all <$File.X29)
else
   eval $(awk -f $normalDir/x29_mean2.awk $Sol <$File.X29)
fi

echo "Latitude $Lat"
echo "Longitude $Long"
echo "Height $Height"
echo "Records $Records"

awk -f $normalDir/llh_mean_report.awk \
    -v mode=computed \
    -v label="$Sol_Name (type $Sol)" \
    -v lat="$Lat" -v lon="$Long" -v height="$Height" \
    -v records="$Records" \
    -v lat_std="${Lat_Std:-0}" -v lon_std="${Long_Std:-0}" -v height_std="${Height_Std:-0}" \
    > llh.mean


$normalDir/kml_point.py $File $Lat $Long $Height

echo "</pre>"
echo "<a href=\"$File.kml\">$File.kml</a>"
echo "<a href=\"$File.kml\">$File.kml</a>">kml.html
echo "<pre>"



if [ -n "$Sol" ]
then
   awk -f $normalDir/x29_sum.awk $Sol <$File.X29 | tee sum.txt
else
   awk -f $normalDir/x29_sum.awk <$File.X29 | tee sum.txt
fi

if [ -n "$Sol" ]
then
   awk -f $normalDir/x29_sol.awk $Sol <$File.X29 >$File.sol
else
   cp $File.X29 $File.sol
fi

rm $File.X29

echo "Computing NEE Deltas"
awk -f $normalDir/x29_enu.awk $File.sol $Lat $Long $Height  >$File.enu

rm $File.sol

echo ""
echo "Computing NEE Mean"
MEAN_SOL="all"
if [ -n "$Sol" ]
then
   MEAN_SOL="$Sol"
fi
eval $(awk -f $normalDir/x29_mean2_enu.awk $MEAN_SOL $Sol_HRange $Sol_VRange $Fixed_Range <$File.enu)

echo "North: $North" | tee  nee.mean
echo "North Min: $North_Min" | tee  -a nee.mean
echo "North Max: $North_Max" | tee  -a nee.mean
echo "East: $East" | tee -a nee.mean
echo "East Min: $East_Min" | tee  -a nee.mean
echo "East Max: $East_Max" | tee  -a nee.mean
echo ""
echo "Elev: $Elev" | tee -a nee.mean
echo "Elev Min: $Elev_Min" | tee  -a nee.mean
echo "Elev Max: $Elev_Max" | tee  -a nee.mean
echo ""
echo "Records: $Records" | tee -a nee.mean
echo ""

echo Generating summaries for $FileFull
echo "Fixed Range: $Fixed_Range" 
echo "Horizontal Range for plotting $Sol_HRange"
echo "Vertical Range for plotting $Sol_VRange"
echo ""

echo "$FileFull" >file.html
#cp $normalDir/plot_index.html index.shtml
mv $File.enu file
$normalDir/out_range.py -R 0.0305 < file --OUTAGE outage2.csv --DETAIL range2.csv --SUMMARY range2.sum
$normalDir/out_range.py -R 0.0455 < file --OUTAGE outage3.csv --DETAIL range3.csv --SUMMARY range3.sum
#rm file
echo Processing completed
echo '</pre>'
#echo -n '<base href="http://trimbletools.com/results/Position/'
#echo -n $File
#echo '/" />'
ln -s $normalDir/index.shtml
cat index.shtml
#rm $File.X29 $File.x29
rm file
#rm $1
