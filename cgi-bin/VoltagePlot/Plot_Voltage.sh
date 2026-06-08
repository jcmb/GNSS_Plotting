#! /bin/bash 
#SERVER=gnssplot.eng.trimble.com
#SERVER=192.168.250.139

E_NO_ARGS=65

USAGE="Usage: $0 Type PROJ Station TZ GNSSFile1 GNSSFile2 .. GNSSFileN"


if [ $# -lt 5 ]  # Must have command-line args to demo script.
then
  echo $USAGE
  exit $E_NO_ARGS
fi

#normalDir=`pwd`
normalDir=/mnt/GPS_Admin/cgi-bin/VoltagePlot

PATH=$normalDir:$PATH
#echo $PATH

TYPE=$1
shift

PROJ=$1
shift

STATION=$1
shift
#echo "Station: $STATION"

Local_TZ=$1
shift

FileFull=`basename $1`;
File=`basename $1 $TYPE`;

mkdir -p /mnt/Results/Voltage/$PROJ/$STATION/$File 

echo "Plotting Voltage for" $File
logger "Plotting Voltage for $1"

logger `whereis viewdat`
logger `whereis /usr/lib/cgi-bin/VoltagePlot/X40_Power_To_Flat.py`
logger `whereis gnuplot`

#viewdat -d40 $1 
#viewdat -d40 -x $1 | $normalDir/X40_Power_To_Flat.py
viewdat -d40 -x $1 | $normalDir/X40_Power_To_Flat.py > /mnt/Results/Voltage/$PROJ/$STATION/$File/file

cd /mnt/Results/Voltage/$PROJ/$STATION/$File


if [ -s file ]
then
    echo $File "Has Voltage/Temp Records"
    logger $File "Has Voltage/Temp Records"

    echo "$File" >file.html

    echo name="'$File: '" >file.plt
    echo Local_TZ="$Local_TZ" >>file.plt

    gnuplot file.plt $normalDir/X40_Plot.plt
    ln -s $normalDir/index.shtml index.shtml
else
    echo $File "does not have Voltage/Temp Records"
    logger $File "does not have Voltage/Temp Records"
    rm file
    cd ..
    rmdir /var/www/html/results/Voltage/$PROJ/$STATION/$File
#    ln -s $normalDir/no_data_index.shtml index.shtml
fi
