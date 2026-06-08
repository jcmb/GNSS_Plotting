#! /bin/bash
#echo $1 "*" $2 "*" $3 "<br>"
echo $1 " " $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9 "<br>"
# $upload_file,$extension,$Sol,$Point,$Ant,$TrimbleTools,$Decimate,$Fixed_Range,$project;
#set -x

TrimbleTools=1

if [ "$Sol" = -1 ]
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

echo name="'$File: '" >file.plt
echo "$File" >file.html


#ln  -f $File.X29 file

$normalDir/x29_secs.py <$File.X29 >file
$normalDir/gnuplot file.plt $normalDir/X29_sol.plt

#echo "Solution Type $Sol";

eval $(awk -f $normalDir/x29_sol_type.awk $Sol < $File.X29);
echo "Solution Type $Sol_Name ($Sol)";


eval $(awk -f $normalDir/x29_mean2.awk $Sol <$File.X29)

echo "Latitude $Lat"
echo "Longitude $Long"
echo "Height $Height"
echo "Records $Records"

echo "Latitude: $Lat" > llh.mean
echo "Longitude: $Long" >> llh.mean
echo "Height: $Height" >> llh.mean
#echo "Records: $Records" >> llh.mean


$normalDir/kml_point.py $File $Lat $Long $Height

echo "</pre>"
echo "<a href=\"$File.kml\">$File.kml</a>"
echo "<a href=\"$File.kml\">$File.kml</a>">kml.html
echo "<pre>"



awk -f $normalDir/x29_sum.awk $Sol <$File.X29 | tee sum.txt

if [ $Sol ]
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
eval $(awk -f $normalDir/x29_mean2_enu.awk $Sol $Sol_HRange $Sol_VRange $Fixed_Range <$File.enu)

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

echo Plotting file for $FileFull
echo "Fixed Range: $Fixed_Range" 
echo "Horizontal Range for plotting $Sol_HRange"
echo "Vertical Range for plotting $Sol_VRange"
echo ""

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
#echo "pwd $PWD\n"
#echo "gnuplot file.plt $normalDir/X29_plot.plt\n"
$normalDir/gnuplot file.plt $normalDir/X29_plot.plt&
$normalDir/out_range.py -R 0.0305 < file --OUTAGE outage2.csv --DETAIL range2.csv --SUMMARY range2.sum
$normalDir/out_range.py -R 0.0455 < file --OUTAGE outage3.csv --DETAIL range3.csv --SUMMARY range3.sum
$normalDir/gnuplot file.plt $normalDir/range.plt
$normalDir/gnuplot file.plt $normalDir/range_hist.plt
wait
#rm file
echo Plotting completed
echo '</pre>'
#echo -n '<base href="http://trimbletools.com/results/Position/'
#echo -n $File
#echo '/" />'
ln -s $normalDir/index.shtml
cat index.shtml
#rm $File.X29 $File.x29
rm file
#rm $1
